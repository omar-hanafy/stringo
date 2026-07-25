import 'package:stringo/src/ops/checks.dart';
import 'package:stringo/src/patterns.dart';
import 'package:test/test.dart';

void main() {
  group('isBlank', () {
    test('covers null, empty, and whitespace-only', () {
      expect(isBlank(null), isTrue);
      expect(isBlank(''), isTrue);
      expect(isBlank('   '), isTrue);
      expect(isBlank('\t\n'), isTrue);
      expect(isBlank('\u{00A0}'), isTrue, reason: 'NBSP is whitespace');
      expect(isBlank('\u{3000}'), isTrue, reason: 'ideographic space');
      expect(isBlank('\u{FEFF}'), isTrue, reason: 'BOM');
    });

    test('false as soon as one non-whitespace character exists', () {
      expect(isBlank('x'), isFalse);
      expect(isBlank('  x  '), isFalse);
      expect(isBlank('\u{1F600}'), isFalse);
    });

    test('isNotBlank is the exact negation', () {
      for (final s in <String?>[null, '', '  ', 'x', ' x ']) {
        expect(isNotBlank(s), !isBlank(s), reason: '$s');
      }
    });
  });

  group('character predicates', () {
    test('isAlphanumeric', () {
      expect(isAlphanumeric('abc123'), isTrue);
      expect(isAlphanumeric('abc'), isTrue);
      expect(isAlphanumeric('a b'), isFalse);
      expect(isAlphanumeric('a-b'), isFalse);
      expect(isAlphanumeric(''), isFalse);
      expect(isAlphanumeric(null), isFalse);
    });

    test('startsWithNumber', () {
      expect(startsWithNumber('2nd'), isTrue);
      expect(startsWithNumber('2'), isTrue);
      expect(startsWithNumber('second'), isFalse);
      expect(startsWithNumber(''), isFalse);
      expect(startsWithNumber(null), isFalse);
    });

    test('containsDigits', () {
      expect(containsDigits('abc1'), isTrue);
      expect(containsDigits('1abc'), isTrue);
      expect(containsDigits('abc'), isFalse);
      expect(containsDigits(''), isFalse);
      expect(containsDigits(null), isFalse);
    });

    test('hasCapitalLetter', () {
      expect(hasCapitalLetter('Hello'), isTrue);
      expect(hasCapitalLetter('helloX'), isTrue);
      expect(hasCapitalLetter('hello'), isFalse);
      expect(hasCapitalLetter(null), isFalse);
      expect(
        hasCapitalLetter('\u{00C9}'),
        isFalse,
        reason: 'ASCII-only by design',
      );
    });

    test('isNumeric accepts ASCII digits only, ignoring outer whitespace', () {
      expect(isNumeric('12345'), isTrue);
      expect(isNumeric(' 12345 '), isTrue);
      expect(isNumeric('12.34'), isFalse);
      expect(isNumeric('-1'), isFalse);
      expect(isNumeric('12a'), isFalse);
      expect(isNumeric(''), isFalse);
      expect(isNumeric(null), isFalse);
    });

    test(
      'isAlphabet accepts ASCII letters only, ignoring outer whitespace',
      () {
        expect(isAlphabet('abc'), isTrue);
        expect(isAlphabet(' ABC '), isTrue);
        expect(isAlphabet('ab1'), isFalse);
        expect(isAlphabet(''), isFalse);
        expect(isAlphabet(null), isFalse);
      },
    );
  });

  group('equalsIgnoreCase', () {
    test('compares case-insensitively', () {
      expect(equalsIgnoreCase('Hello', 'hello'), isTrue);
      expect(equalsIgnoreCase('HELLO', 'hello'), isTrue);
      expect(equalsIgnoreCase('Hello', 'world'), isFalse);
      expect(equalsIgnoreCase('Hello', 'hell'), isFalse);
    });

    test('two nulls are equal, one null is not', () {
      expect(equalsIgnoreCase(null, null), isTrue);
      expect(equalsIgnoreCase('A', null), isFalse);
      expect(equalsIgnoreCase(null, 'A'), isFalse);
    });

    test('handles non-ascii through the unicode path', () {
      expect(equalsIgnoreCase('\u{00C9}COLE', '\u{00E9}cole'), isTrue);
      expect(equalsIgnoreCase('\u{00C9}', '\u{00E8}'), isFalse);
    });

    test('length-changing case folding still compares correctly', () {
      // The German sharp s uppercases to two characters, so the equal-length
      // fast path must not be reached here.
      expect(equalsIgnoreCase('stra\u{00DF}e', 'STRASSE'), isFalse);
      expect(equalsIgnoreCase('stra\u{00DF}e', 'STRA\u{00DF}E'), isTrue);
    });
  });

  group('hasMatch', () {
    test('matches a pattern anywhere in the string', () {
      expect(hasMatch('hello', 'ell'), isTrue);
      expect(hasMatch('hello', r'^h'), isTrue);
      expect(hasMatch('hello', r'\d'), isFalse);
    });

    test('honors caseSensitive', () {
      expect(hasMatch('Hello', 'hello'), isFalse);
      expect(hasMatch('Hello', 'hello', caseSensitive: false), isTrue);
    });

    test('honors multiLine', () {
      expect(hasMatch('a\nb', r'^b'), isFalse);
      expect(hasMatch('a\nb', r'^b', multiLine: true), isTrue);
    });

    test('honors dotAll', () {
      expect(hasMatch('a\nb', 'a.b'), isFalse);
      expect(hasMatch('a\nb', 'a.b', dotAll: true), isTrue);
    });

    test('null never matches', () {
      expect(hasMatch(null, '.*'), isFalse);
    });
  });

  group('exported patterns', () {
    test('the String sources are usable directly', () {
      expect(RegExp(regexNumeric).hasMatch('123'), isTrue);
      expect(RegExp(regexAlphabet).hasMatch('abc'), isTrue);
      expect(RegExp(regexAlphanumeric).hasMatch('a1'), isTrue);
      expect(RegExp(regexContainsDigits).hasMatch('a1'), isTrue);
      expect(RegExp(regexStartsWithNumber).hasMatch('1a'), isTrue);
      expect(RegExp(regexHasCapitalLetter).hasMatch('aA'), isTrue);
    });

    test('the precompiled objects agree with their sources', () {
      const samples = ['', 'abc', '123', 'a1', 'A', ' 1 ', 'a-b'];
      for (final s in samples) {
        expect(patternNumeric.hasMatch(s), RegExp(regexNumeric).hasMatch(s));
        expect(patternAlphabet.hasMatch(s), RegExp(regexAlphabet).hasMatch(s));
        expect(
          patternAlphanumeric.hasMatch(s),
          RegExp(regexAlphanumeric).hasMatch(s),
        );
        expect(
          patternContainsDigits.hasMatch(s),
          RegExp(regexContainsDigits).hasMatch(s),
        );
        expect(
          patternStartsWithNumber.hasMatch(s),
          RegExp(regexStartsWithNumber).hasMatch(s),
        );
        expect(
          patternHasCapitalLetter.hasMatch(s),
          RegExp(regexHasCapitalLetter).hasMatch(s),
        );
      }
    });
  });
}
