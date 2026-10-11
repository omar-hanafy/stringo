/// Guards on the *algorithmic* behavior of the hot paths.
///
/// Complexity guards compare adjacent batches, alternating their order to reduce
/// scheduler and JIT bias. Wall-clock measurements can still vary on a busy host;
/// pairing samples avoids comparing medians from separate load conditions.
///
/// The blank-check test is the one that matters: stringo 1.0.0 answered
/// `isBlank` by allocating two whole-string copies and compiling a regex,
/// which made it linear in the length of the input. On a 10 MB string that
/// took milliseconds. This test fails loudly against that implementation.
library;

import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

/// Median wall time of [body] over [samples] runs, in microseconds.
///
/// The median blunts scheduler noise far better than a single run or a mean.
int _medianMicros(int samples, void Function() body) {
  for (var i = 0; i < 200; i++) {
    body();
  }
  final timings = <int>[];
  for (var s = 0; s < samples; s++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      body();
    }
    sw.stop();
    timings.add(sw.elapsedMicroseconds);
  }
  timings.sort();
  return timings[timings.length ~/ 2];
}

/// Median of adjacent second/first timing ratios over [samples] runs.
///
/// Warm both inputs together and reverse batch order on alternate samples so
/// compilation, collection, or changing host load does not consistently affect
/// only the larger input. Keep the original 50-call batches and one-microsecond
/// denominator allowance used by the complexity guards.
({double ratio, int firstMicros, int secondMicros}) _medianRatio(
  int samples,
  void Function() first,
  void Function() second,
) {
  for (var i = 0; i < 200; i++) {
    if (i.isEven) {
      first();
      second();
    } else {
      second();
      first();
    }
  }
  final timings = <({double ratio, int firstMicros, int secondMicros})>[];
  for (var sample = 0; sample < samples; sample++) {
    late final int firstMicros;
    late final int secondMicros;
    if (sample.isEven) {
      firstMicros = _batchMicros(first);
      secondMicros = _batchMicros(second);
    } else {
      secondMicros = _batchMicros(second);
      firstMicros = _batchMicros(first);
    }
    timings.add((
      ratio: secondMicros / (firstMicros + 1),
      firstMicros: firstMicros,
      secondMicros: secondMicros,
    ));
  }
  timings.sort((a, b) => a.ratio.compareTo(b.ratio));
  return timings[timings.length ~/ 2];
}

int _batchMicros(void Function() body) {
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 50; i++) {
    body();
  }
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds;
}

void main() {
  group('isBlank is O(1), not O(length)', () {
    test('a 10 MB string costs about what a 10 char string costs', () {
      final short = 'x' * 10;
      final long = 'x' * 10000000;

      final timing = _medianRatio(
        21,
        () {
          short.isBlank;
        },
        () {
          long.isBlank;
        },
      );

      // A correct implementation reads one code unit and returns, regardless
      // of length. The allowance is deliberately generous: 1.0.0 failed this
      // by roughly five orders of magnitude, so a wide margin still catches
      // any regression to a scanning or allocating implementation.
      expect(
        timing.ratio,
        lessThan(20),
        reason:
            'isBlank looks linear in length: '
            '10 chars took ${timing.firstMicros}us, '
            '10 MB took ${timing.secondMicros}us '
            '(median paired ratio ${timing.ratio})',
      );
    });

    test('detection short-circuits at the first non-whitespace character', () {
      final leadingContent = 'x${' ' * 10000000}';
      final t = _medianMicros(21, () {
        leadingContent.isBlank;
      });
      expect(
        t,
        lessThan(5000),
        reason: 'took ${t}us for 50 calls; expected an immediate return',
      );
    });

    test('a genuinely blank string is still only one pass', () {
      // The worst case for isBlank: it must read every character to prove the
      // string is blank. That is unavoidable and must stay a single pass with
      // no allocation, so 2x the length should cost about 2x, not 4x.
      final oneX = ' ' * 1000000;
      final twoX = ' ' * 2000000;
      final timing = _medianRatio(
        11,
        () {
          oneX.isBlank;
        },
        () {
          twoX.isBlank;
        },
      );
      expect(
        timing.ratio,
        lessThan(4),
        reason:
            'blank detection looks worse than linear: '
            '1M took ${timing.firstMicros}us, '
            '2M took ${timing.secondMicros}us '
            '(median paired ratio ${timing.ratio})',
      );
    });
  });

  group('case conversion is linear in input length', () {
    test('snakeCase on 2x the words costs about 2x, not 4x', () {
      final base = List.generate(500, (i) => 'someUserField').join('_');
      final double_ = List.generate(1000, (i) => 'someUserField').join('_');
      final timing = _medianRatio(
        11,
        () {
          base.toSnakeCase;
        },
        () {
          double_.toSnakeCase;
        },
      );
      expect(
        timing.ratio,
        lessThan(4),
        reason:
            'snakeCase looks superlinear: ${timing.firstMicros}us vs '
            '${timing.secondMicros}us (median paired ratio ${timing.ratio})',
      );
    });
  });

  group('removeEmptyLines is linear in input length', () {
    test('a whitespace run with no line break does not blow up', () {
      // This was quadratic until the regex was replaced by a scanner: the
      // pattern consumed a whole run of spaces, then backtracked one
      // character at a time looking for a line break that was not there.
      // A 20 KB run of spaces took about 7 seconds.
      final oneX = ' ' * 8000;
      final twoX = ' ' * 16000;
      final timing = _medianRatio(
        11,
        () {
          oneX.removeEmptyLines;
        },
        () {
          twoX.removeEmptyLines;
        },
      );
      expect(
        timing.ratio,
        lessThan(4),
        reason:
            'removeEmptyLines looks superlinear in run length: '
            '8k took ${timing.firstMicros}us, '
            '16k took ${timing.secondMicros}us '
            '(median paired ratio ${timing.ratio})',
      );
    });

    test('an indented document is not disproportionately slower', () {
      final flat = List.filled(2000, 'line').join('\n');
      final indented = List.filled(2000, '${' ' * 40}line').join('\n');
      final timing = _medianRatio(
        11,
        () {
          flat.removeEmptyLines;
        },
        () {
          indented.removeEmptyLines;
        },
      );
      expect(
        timing.ratio,
        lessThan(12),
        reason:
            'indentation costs too much: ${timing.firstMicros}us vs '
            '${timing.secondMicros}us (median paired ratio ${timing.ratio})',
      );
    });
  });

  group('slugify is linear in input length', () {
    test('2x the input costs about 2x, not 4x', () {
      final base = 'Hello, World! This is a Title. ' * 200;
      final double_ = 'Hello, World! This is a Title. ' * 400;
      final timing = _medianRatio(
        11,
        () {
          base.slugify();
        },
        () {
          double_.slugify();
        },
      );
      expect(
        timing.ratio,
        lessThan(4),
        reason:
            'slugify looks superlinear: ${timing.firstMicros}us vs '
            '${timing.secondMicros}us (median paired ratio ${timing.ratio})',
      );
    });
  });
}
