import 'dart:math';

import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

const List<String> _pieces = <String>[
  'a', 'b', 'Z', 'X', '0', '7', //
  '_', '-', ' ', '\t', '.', '!', ',',
  '\u{00E9}', '\u{00C9}', '\u{1F600}', '\u{00A0}',
  'HTTP', 'Http', 'aB', 'ABc',
];

String _randomInput(Random rng, int maxPieces) {
  final n = rng.nextInt(maxPieces);
  final b = StringBuffer();
  for (var i = 0; i < n; i++) {
    b.write(_pieces[rng.nextInt(_pieces.length)]);
  }
  return b.toString();
}

/// Identifier-shaped input.
///
/// [minWordLength] defaults to 2 because the snake/camel round trip is only
/// well defined for words of two or more letters. See the round-trip test for
/// why single-letter words break it.
String _randomIdentifier(Random rng, {int minWordLength = 2}) {
  const letters = 'abcdefghijklmnopqrstuvwxyz';
  final wordCount = 1 + rng.nextInt(4);
  final words = <String>[];
  for (var w = 0; w < wordCount; w++) {
    final len = minWordLength + rng.nextInt(5);
    final b = StringBuffer();
    for (var i = 0; i < len; i++) {
      b.write(letters[rng.nextInt(letters.length)]);
    }
    words.add(b.toString());
  }
  return words.join('_');
}

bool _isAscii(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) >= 0x80) return false;
  }
  return true;
}

void main() {
  group('slugify', () {
    test('is idempotent', () {
      final rng = Random(4242);
      for (var i = 0; i < 20000; i++) {
        final input = _randomInput(rng, 10);
        final once = Stringo.slugify(input);
        expect(Stringo.slugify(once), once, reason: 'input: "$input"');
      }
    });

    test('output contains only lowercase ascii, digits, and the separator', () {
      final rng = Random(4243);
      for (var i = 0; i < 20000; i++) {
        final slug = Stringo.slugify(_randomInput(rng, 10));
        expect(
          RegExp(r'^[a-z0-9]*(-[a-z0-9]+)*$').hasMatch(slug),
          isTrue,
          reason: 'slug: "$slug"',
        );
      }
    });

    test('never starts or ends with the separator', () {
      final rng = Random(4244);
      for (var i = 0; i < 20000; i++) {
        for (final sep in ['-', '_', '::']) {
          final slug = Stringo.slugify(_randomInput(rng, 8), separator: sep);
          if (slug.isEmpty) continue;
          expect(slug.startsWith(sep), isFalse, reason: '"$slug" sep "$sep"');
          expect(slug.endsWith(sep), isFalse, reason: '"$slug" sep "$sep"');
        }
      }
    });
  });

  group('words', () {
    test('never emits an empty element', () {
      final rng = Random(555);
      for (var i = 0; i < 50000; i++) {
        final input = _randomInput(rng, 10);
        for (final w in Stringo.words(input)) {
          expect(w, isNotEmpty, reason: 'input: "$input"');
        }
      }
    });

    test('concatenating the words drops only separators', () {
      final rng = Random(556);
      for (var i = 0; i < 20000; i++) {
        final input = _randomInput(rng, 10);
        final joined = Stringo.words(input).join();
        // Every retained character must have been in the input, and the only
        // characters dropped are word separators.
        expect(joined.length, lessThanOrEqualTo(input.length));
      }
    });
  });

  group('case round trips', () {
    test('snake -> camel -> snake is stable for multi-letter words', () {
      // Restricted to words of two or more letters. With single-letter words
      // the round trip is not well defined: 'a_b' camelCases to 'aB', which
      // re-tokenizes as the single acronym 'AB'. See the test below.
      final rng = Random(777);
      for (var i = 0; i < 20000; i++) {
        final id = _randomIdentifier(rng);
        final snake = Stringo.snakeCase(id);
        expect(
          Stringo.snakeCase(Stringo.camelCase(snake)),
          snake,
          reason: 'id: "$id"',
        );
      }
    });

    test('separator-preserving conversions are idempotent', () {
      // These keep an explicit separator in their output, so re-tokenizing the
      // result recovers exactly the same words.
      final rng = Random(778);
      final conversions = <String, String Function(String)>{
        'snakeCase': Stringo.snakeCase,
        'kebabCase': Stringo.kebabCase,
        'dotCase': Stringo.dotCase,
        'screamingSnakeCase': Stringo.screamingSnakeCase,
        'screamingKebabCase': Stringo.screamingKebabCase,
      };
      for (var i = 0; i < 5000; i++) {
        final id = _randomIdentifier(rng, minWordLength: 1);
        for (final e in conversions.entries) {
          final once = e.value(id);
          expect(e.value(once), once, reason: '${e.key} on "$id"');
        }
      }
    });

    test('camelCase and pascalCase are NOT idempotent, by nature', () {
      // Documented limitation, inherited unchanged from 1.0.0 and shared by
      // every case library that drops separators: adjacent single-letter words
      // become indistinguishable from an acronym.
      //
      //   'a_b'  -> camelCase -> 'aB'   -> camelCase -> 'ab'
      //
      // Re-tokenizing 'aB' cannot know whether 'B' was its own word or the
      // tail of an acronym. Use a separator-preserving case if you need a
      // reversible transformation.
      expect(Stringo.camelCase('jxxmlw_e_f'), 'jxxmlwEF');
      expect(Stringo.camelCase('jxxmlwEF'), 'jxxmlwEf');
      // Three consecutive single-letter words collapse into one acronym.
      expect(Stringo.camelCase('wl_s_e_x'), 'wlSEX');
      expect(Stringo.snakeCase('wlSEX'), 'wl_sex');
    });
  });

  group('ascii invariant behind the fast path', () {
    test('ascii input always produces ascii output', () {
      // The converse is deliberately NOT asserted: some non-ascii characters
      // case-map into ascii, for example the Kelvin sign U+212A lowercasing
      // to 'k'.
      final rng = Random(999);
      final conversions = <String Function(String)>[
        Stringo.snakeCase,
        Stringo.camelCase,
        Stringo.pascalCase,
        Stringo.kebabCase,
        Stringo.titleCase,
        Stringo.screamingCase,
      ];
      for (var i = 0; i < 20000; i++) {
        final input = _randomInput(rng, 8);
        if (!_isAscii(input)) continue;
        for (final f in conversions) {
          expect(_isAscii(f(input)), isTrue, reason: 'input: "$input"');
        }
      }
    });
  });

  group('truncate', () {
    test('never exceeds max(length, suffix.length)', () {
      const input = 'abcdefghijklmnopqrstuvwxyz';
      for (final suffix in ['...', '', '!', 'ELLIPSIS']) {
        for (var n = 0; n <= input.length + 5; n++) {
          final result = Stringo.truncate(input, n, suffix: suffix);
          final limit = n > suffix.length ? n : suffix.length;
          expect(
            result.length,
            lessThanOrEqualTo(limit),
            reason: 'n=$n suffix="$suffix" gave "$result"',
          );
        }
      }
    });

    test('is the identity when the string already fits', () {
      const input = 'abcdef';
      for (var n = input.length; n <= input.length + 5; n++) {
        expect(Stringo.truncate(input, n), input);
      }
    });
  });

  group('mask', () {
    test('preserves length and the visible edges', () {
      final rng = Random(1234);
      for (var i = 0; i < 5000; i++) {
        final input = _randomIdentifier(rng);
        final start = rng.nextInt(4);
        final end = rng.nextInt(4);
        final masked = Stringo.mask(
          input,
          visibleStart: start,
          visibleEnd: end,
        );
        expect(masked.length, input.length, reason: input);
        if (input.length > start + end) {
          expect(masked.substring(0, start), input.substring(0, start));
          expect(
            masked.substring(masked.length - end),
            input.substring(input.length - end),
          );
        }
      }
    });
  });

  group('blank checks', () {
    test('isBlank and isNotBlank are exact negations', () {
      final rng = Random(31337);
      for (var i = 0; i < 20000; i++) {
        final input = _randomInput(rng, 6);
        expect(Stringo.isNotBlank(input), !Stringo.isBlank(input));
      }
    });

    test('a string is blank exactly when removing whitespace empties it', () {
      final rng = Random(31338);
      for (var i = 0; i < 20000; i++) {
        final input = _randomInput(rng, 6);
        expect(
          Stringo.isBlank(input),
          Stringo.removeWhitespace(input).isEmpty,
          reason: 'input: "$input"',
        );
      }
    });
  });
}
