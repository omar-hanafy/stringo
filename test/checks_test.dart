import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('blank checks', () {
    test('isEmptyOrNull covers null, empty, and whitespace', () {
      expect((null as String?).isEmptyOrNull, isTrue);
      expect(''.isEmptyOrNull, isTrue);
      expect('   '.isEmptyOrNull, isTrue);
      expect('\t\n'.isEmptyOrNull, isTrue);
      expect('x'.isEmptyOrNull, isFalse);
      expect('  x  '.isEmptyOrNull, isFalse);
    });

    test('isBlank is an alias for isEmptyOrNull', () {
      expect('   '.isBlank, isTrue);
      expect('x'.isBlank, isFalse);
      expect((null as String?).isBlank, isTrue);
    });

    test('negated forms', () {
      expect('x'.isNotEmptyOrNull, isTrue);
      expect('   '.isNotEmptyOrNull, isFalse);
      expect('x'.isNotBlank, isTrue);
      expect((null as String?).isNotBlank, isFalse);
    });
  });

  group('character predicates', () {
    test('isAlphanumeric', () {
      expect('abc123'.isAlphanumeric, isTrue);
      expect('abc'.isAlphanumeric, isTrue);
      expect('a b'.isAlphanumeric, isFalse);
      expect('a-b'.isAlphanumeric, isFalse);
      expect(''.isAlphanumeric, isFalse);
      expect((null as String?).isAlphanumeric, isFalse);
    });

    test('startsWithNumber', () {
      expect('2nd'.startsWithNumber, isTrue);
      expect('2'.startsWithNumber, isTrue);
      expect('second'.startsWithNumber, isFalse);
      expect((null as String?).startsWithNumber, isFalse);
    });

    test('containsDigits', () {
      expect('abc1'.containsDigits, isTrue);
      expect('abc'.containsDigits, isFalse);
      expect((null as String?).containsDigits, isFalse);
    });

    test('hasCapitalLetter', () {
      expect('Hello'.hasCapitalLetter, isTrue);
      expect('hello'.hasCapitalLetter, isFalse);
      expect((null as String?).hasCapitalLetter, isFalse);
    });

    test('isNumeric accepts ASCII digits only, ignoring outer whitespace', () {
      expect('12345'.isNumeric, isTrue);
      expect(' 12345 '.isNumeric, isTrue);
      expect('12.34'.isNumeric, isFalse);
      expect('-12'.isNumeric, isFalse);
      expect('1 2'.isNumeric, isFalse);
      expect(''.isNumeric, isFalse);
      expect((null as String?).isNumeric, isFalse);
    });

    test(
      'isAlphabet accepts ASCII letters only, ignoring outer whitespace',
      () {
        expect('abcDEF'.isAlphabet, isTrue);
        expect(' abcDEF '.isAlphabet, isTrue);
        expect('abc1'.isAlphabet, isFalse);
        expect('a b'.isAlphabet, isFalse);
        expect(''.isAlphabet, isFalse);
        expect((null as String?).isAlphabet, isFalse);
      },
    );
  });

  group('hasMatch', () {
    test('matches a pattern anywhere in the string', () {
      expect('hello'.hasMatch('ell'), isTrue);
      expect('hello'.hasMatch(r'^h'), isTrue);
      expect('hello'.hasMatch(r'^e'), isFalse);
    });

    test('honors caseSensitive', () {
      expect('HELLO'.hasMatch('hello'), isFalse);
      expect('HELLO'.hasMatch('hello', caseSensitive: false), isTrue);
    });

    test('honors multiLine', () {
      expect('a\nb'.hasMatch(r'^b'), isFalse);
      expect('a\nb'.hasMatch(r'^b', multiLine: true), isTrue);
    });

    test('honors dotAll', () {
      expect('a\nb'.hasMatch('a.b'), isFalse);
      expect('a\nb'.hasMatch('a.b', dotAll: true), isTrue);
    });

    test('null never matches', () {
      expect((null as String?).hasMatch('.*'), isFalse);
    });
  });

  group('exported regex patterns', () {
    test('are usable directly', () {
      expect(RegExp(regexNumeric).hasMatch('123'), isTrue);
      expect(RegExp(regexAlphabet).hasMatch('abc'), isTrue);
      expect(RegExp(regexAlphanumeric).hasMatch('a1'), isTrue);
      expect(RegExp(regexStartsWithNumber).hasMatch('1a'), isTrue);
      expect(RegExp(regexContainsDigits).hasMatch('a1'), isTrue);
      expect(RegExp(regexHasCapitalLetter).hasMatch('aB'), isTrue);
    });
  });
}
