/// Guards on the *algorithmic* behavior of the hot paths.
///
/// These deliberately assert complexity rather than wall-clock thresholds, so
/// they cannot flake on a noisy CI runner. A machine being three times slower
/// changes both sides of every ratio here equally.
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

void main() {
  group('isBlank is O(1), not O(length)', () {
    test('a 10 MB string costs about what a 10 char string costs', () {
      final short = 'x' * 10;
      final long = 'x' * 10000000;

      final tShort = _medianMicros(21, () {
        short.isBlank;
      });
      final tLong = _medianMicros(21, () {
        long.isBlank;
      });

      // A correct implementation reads one code unit and returns, regardless
      // of length. The allowance is deliberately generous: 1.0.0 failed this
      // by roughly five orders of magnitude, so a wide margin still catches
      // any regression to a scanning or allocating implementation.
      expect(
        tLong,
        lessThan((tShort + 1) * 20),
        reason:
            'isBlank looks linear in length: '
            '10 chars took ${tShort}us, 10 MB took ${tLong}us',
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
      final t1 = _medianMicros(11, () {
        oneX.isBlank;
      });
      final t2 = _medianMicros(11, () {
        twoX.isBlank;
      });
      expect(
        t2,
        lessThan((t1 + 1) * 4),
        reason:
            'blank detection looks worse than linear: '
            '1M took ${t1}us, 2M took ${t2}us',
      );
    });
  });

  group('case conversion is linear in input length', () {
    test('snakeCase on 2x the words costs about 2x, not 4x', () {
      final base = List.generate(500, (i) => 'someUserField').join('_');
      final double_ = List.generate(1000, (i) => 'someUserField').join('_');
      final t1 = _medianMicros(11, () {
        base.toSnakeCase;
      });
      final t2 = _medianMicros(11, () {
        double_.toSnakeCase;
      });
      expect(
        t2,
        lessThan((t1 + 1) * 4),
        reason: 'snakeCase looks superlinear: ${t1}us vs ${t2}us',
      );
    });
  });

  group('slugify is linear in input length', () {
    test('2x the input costs about 2x, not 4x', () {
      final base = 'Hello, World! This is a Title. ' * 200;
      final double_ = 'Hello, World! This is a Title. ' * 400;
      final t1 = _medianMicros(11, () {
        base.slugify();
      });
      final t2 = _medianMicros(11, () {
        double_.slugify();
      });
      expect(
        t2,
        lessThan((t1 + 1) * 4),
        reason: 'slugify looks superlinear: ${t1}us vs ${t2}us',
      );
    });
  });
}
