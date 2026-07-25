import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('case extensions delegate to the core', () {
    test('every conversion matches its Stringo counterpart', () {
      const inputs = [
        'helloWorld',
        'hello_world',
        'HTTPServer',
        '_leading',
        '',
        'the lord of the rings',
      ];
      for (final s in inputs) {
        expect(s.toWords, Stringo.words(s), reason: s);
        expect(s.toPascalCase, Stringo.pascalCase(s), reason: s);
        expect(s.toCamelCase, Stringo.camelCase(s), reason: s);
        expect(s.toSnakeCase, Stringo.snakeCase(s), reason: s);
        expect(s.toKebabCase, Stringo.kebabCase(s), reason: s);
        expect(s.toDotCase, Stringo.dotCase(s), reason: s);
        expect(s.toFlatCase, Stringo.flatCase(s), reason: s);
        expect(s.toScreamingCase, Stringo.screamingCase(s), reason: s);
        expect(
          s.toScreamingSnakeCase,
          Stringo.screamingSnakeCase(s),
          reason: s,
        );
        expect(
          s.toScreamingKebabCase,
          Stringo.screamingKebabCase(s),
          reason: s,
        );
        expect(s.toPascalSnakeCase, Stringo.pascalSnakeCase(s), reason: s);
        expect(s.toPascalKebabCase, Stringo.pascalKebabCase(s), reason: s);
        expect(s.toCamelSnakeCase, Stringo.camelSnakeCase(s), reason: s);
        expect(s.toCamelKebabCase, Stringo.camelKebabCase(s), reason: s);
        expect(s.toTitleCase, Stringo.titleCase(s), reason: s);
        expect(s.toTitle, Stringo.title(s), reason: s);
        expect(s.capitalizeFirstLetter, Stringo.capitalizeFirst(s), reason: s);
        expect(s.lowercaseFirstLetter, Stringo.lowercaseFirst(s), reason: s);
        expect(
          s.capitalizeFirstLowerRest,
          Stringo.capitalizeFirstLowerRest(s),
          reason: s,
        );
      }
    });

    test('toTrainCase is an alias of toPascalKebabCase', () {
      // The canonical implementation is toPascalKebabCase; this asserts the
      // delegation, and does not duplicate its test suite.
      expect('helloWorld'.toTrainCase, 'helloWorld'.toPascalKebabCase);
      expect('some_mixed input'.toTrainCase, 'Some-Mixed-Input');
    });

    test('documented shapes', () {
      expect('hello_world'.toPascalCase, 'HelloWorld');
      expect('hello_world'.toCamelCase, 'helloWorld');
      expect('helloWorld'.toSnakeCase, 'hello_world');
      expect('helloWorld'.toKebabCase, 'hello-world');
      expect('parseHTTPResponse'.toSnakeCase, 'parse_http_response');
      expect('hello_world'.toTitleCase, 'Hello World');
      expect('war and peace'.toTitleCase, 'War and Peace');
    });

    test('shouldIgnoreCapitalization and titleCaseExceptions', () {
      expect('the'.shouldIgnoreCapitalization, isTrue);
      expect('OF'.shouldIgnoreCapitalization, isTrue);
      expect('2nd'.shouldIgnoreCapitalization, isTrue);
      expect('lord'.shouldIgnoreCapitalization, isFalse);
      expect(titleCaseExceptions, contains('the'));
      expect(titleCaseExceptions, isNot(contains('lord')));
    });
  });

  group('behavior changes visible through the extensions', () {
    test('toWords no longer emits phantom empty words', () {
      expect(''.toWords, isEmpty);
      expect('_leading'.toWords, ['leading']);
      expect('trailing_'.toWords, ['trailing']);
      expect('  spaced  out  '.toWords, ['spaced', 'out']);
    });

    test('a leading separator no longer capitalizes camelCase', () {
      expect('_leading'.toCamelCase, 'leading');
      expect('_leading'.toPascalCase, 'Leading');
    });

    test('truncate counts the suffix against the limit', () {
      expect('Hello World'.truncate(5), 'He...');
      expect('Hello World'.truncate(5, suffix: '!'), 'Hell!');
      expect('Hello'.truncate(10), 'Hello');
      expect('abc'.truncate(0), '');
      expect((null as String?).truncate(3), isNull);
    });

    test('mask on a null receiver now yields null, not the empty string', () {
      expect((null as String?).mask(), isNull);
      expect('12345'.mask(visibleStart: 1), '1****');
    });

    test('insert on a null receiver now yields null', () {
      expect((null as String?).insert(0, 'x'), isNull);
      expect('abc'.insert(1, 'Z'), 'aZbc');
    });

    test('insert rejects a negative index even on a null receiver', () {
      // Argument validation must not depend on receiver nullness, the same
      // rule mask follows. Without this, null.insert(-1, 'x') silently
      // returned null and swallowed a programmer error.
      expect(() => 'abc'.insert(-1, 'Z'), throwsRangeError);
      expect(
        () => (null as String?).insert(-1, 'x'),
        throwsRangeError,
        reason: 'a negative index is invalid whatever the receiver is',
      );
      expect((null as String?).insert(5, 'x'), isNull);
    });

    test('toCharArray keeps surrogate pairs whole', () {
      expect('\u{1F600}'.toCharArray(), ['\u{1F600}']);
      expect('abc'.toCharArray(), ['a', 'b', 'c']);
      expect(''.toCharArray(), isEmpty);
      expect('   '.toCharArray(), isEmpty, reason: 'blank stays empty');
      expect((null as String?).toCharArray(), isEmpty);
    });

    test('slugify treats every separator kind uniformly', () {
      expect('a-b'.slugify(separator: '_'), 'a_b');
      expect('Hello, World!'.slugify(), 'hello-world');
      expect('Hello World'.slugify(separator: '--'), 'hello--world');
      expect(() => 'Hello'.slugify(separator: ''), throwsArgumentError);
    });
  });

  group('transform extensions', () {
    test('null-ifying helpers', () {
      expect(''.nullIfEmpty, isNull);
      expect('text'.nullIfEmpty, 'text');
      expect('   '.nullIfEmpty, '   ');
      expect('   '.nullIfBlank, isNull);
      expect('\t'.nullIfBlank, isNull);
      expect('text'.nullIfBlank, 'text');
      expect((null as String?).orEmpty, '');
      expect('x'.orEmpty, 'x');
    });

    test('whitespace handling', () {
      expect('Line1\n\n\nLine2'.removeEmptyLines, 'Line1\nLine2');
      expect('Line1\nLine2'.toOneLine, 'Line1Line2');
      expect('a b c'.removeWhiteSpaces, 'abc');
      expect('a b\nc'.clean, 'abc');
      expect('  Line   1 \n Line 2  '.normalizeWhitespace(), 'Line 1 Line 2');
    });

    test('nullable whitespace variants pass null through', () {
      const String? nothing = null;
      expect(nothing.toOneLine, isNull);
      expect(nothing.removeWhiteSpaces, isNull);
      expect(nothing.clean, isNull);

      String? something = ' a \t b ';
      expect(something.removeWhiteSpaces, 'ab');
      expect(something.clean, 'ab');
      something = null;
      expect(something.clean, isNull);
    });

    test('splitting', () {
      expect('Hello World'.words, ['Hello', 'World']);
      expect('  Hello   World  '.words, ['Hello', 'World']);
      expect(''.words, isEmpty);
      expect('Line 1\nLine 2'.lines, ['Line 1', 'Line 2']);
      expect('Line 1\r\nLine 2'.lines, ['Line 1', 'Line 2']);
      expect(''.lines, ['']);
    });

    test('words and toWords are different splitters', () {
      expect('helloWorld'.words, ['helloWorld']);
      expect('helloWorld'.toWords, ['hello', 'World']);
    });

    test('insert bounds', () {
      expect('abc'.insert(0, 'Z'), 'Zabc');
      expect('abc'.insert(3, 'Z'), 'abcZ');
      expect(() => 'abc'.insert(4, 'Z'), throwsRangeError);
      expect(() => 'abc'.insert(-1, 'Z'), throwsRangeError);
    });

    test('equalsIgnoreCase', () {
      expect('Hello'.equalsIgnoreCase('hello'), isTrue);
      expect('Hello'.equalsIgnoreCase('world'), isFalse);
      expect((null as String?).equalsIgnoreCase(null), isTrue);
      expect('A'.equalsIgnoreCase(null), isFalse);
      expect((null as String?).equalsIgnoreCase('A'), isFalse);
    });

    test('removeSurrounding', () {
      expect('"value"'.removeSurrounding('"'), 'value');
      expect('value'.removeSurrounding('"'), 'value');
      expect('"value'.removeSurrounding('"'), '"value');
      expect((null as String?).removeSurrounding('"'), isNull);
    });

    test('replaceAfter and replaceBefore', () {
      expect('foo=bar'.replaceAfter('=', 'baz'), 'foo=baz');
      expect('foo=bar'.replaceBefore('=', 'baz'), 'baz=bar');
      expect('foo'.replaceAfter(':', 'x', 'fallback'), 'fallback');
      expect('foo'.replaceBefore(':', 'x', 'fallback'), 'fallback');
      expect('foo'.replaceAfter(':', 'x'), 'foo');
      expect((null as String?).replaceAfter('=', 'x'), isNull);
      expect((null as String?).replaceBefore('=', 'x'), isNull);
    });

    test('mask', () {
      expect('1234567890'.mask(visibleStart: 2, visibleEnd: 2), '12******90');
      expect('12345'.mask(), '*****');
      expect('12345'.mask(visibleStart: 1, char: '#'), '1####');
      expect('123'.mask(visibleStart: 2, visibleEnd: 2), '123');
    });

    test('mask rejects negative bounds even on a null receiver', () {
      expect(() => 'abc'.mask(visibleStart: -1), throwsArgumentError);
      expect(() => 'abc'.mask(visibleEnd: -1), throwsArgumentError);
      expect(
        () => (null as String?).mask(visibleStart: -1),
        throwsArgumentError,
        reason: 'argument validation must not depend on receiver nullness',
      );
    });
  });

  group('checks extensions', () {
    test('blank checks', () {
      expect((null as String?).isBlank, isTrue);
      expect(''.isBlank, isTrue);
      expect('   '.isBlank, isTrue);
      expect('\t\n'.isBlank, isTrue);
      expect('x'.isBlank, isFalse);
      expect('  x  '.isBlank, isFalse);
      expect('x'.isNotBlank, isTrue);
      expect((null as String?).isNotBlank, isFalse);
    });

    test('character predicates', () {
      expect('abc123'.isAlphanumeric, isTrue);
      expect('a b'.isAlphanumeric, isFalse);
      expect('2nd'.startsWithNumber, isTrue);
      expect('second'.startsWithNumber, isFalse);
      expect('abc1'.containsDigits, isTrue);
      expect('abc'.containsDigits, isFalse);
      expect('Hello'.hasCapitalLetter, isTrue);
      expect('hello'.hasCapitalLetter, isFalse);
      expect(' 12345 '.isNumeric, isTrue);
      expect('12.34'.isNumeric, isFalse);
      expect(' ABC '.isAlphabet, isTrue);
      expect('ab1'.isAlphabet, isFalse);
    });

    test('hasMatch honors its flags', () {
      expect('hello'.hasMatch('ell'), isTrue);
      expect('Hello'.hasMatch('hello'), isFalse);
      expect('Hello'.hasMatch('hello', caseSensitive: false), isTrue);
      expect('a\nb'.hasMatch(r'^b', multiLine: true), isTrue);
      expect('a\nb'.hasMatch('a.b', dotAll: true), isTrue);
      expect((null as String?).hasMatch('.*'), isFalse);
    });

    test('nullable case helpers', () {
      expect('ABC'.tryToLowerCase(), 'abc');
      expect((null as String?).tryToLowerCase(), isNull);
      expect('abc'.tryToUpperCase(), 'ABC');
      expect((null as String?).tryToUpperCase(), isNull);
    });
  });

  group('exported patterns are reachable from the public entry point', () {
    test('both the String sources and the precompiled objects', () {
      expect(RegExp(regexNumeric).hasMatch('123'), isTrue);
      expect(patternNumeric.hasMatch('123'), isTrue);
      expect(patternAlphabet.hasMatch('abc'), isTrue);
      expect(patternAlphanumeric.hasMatch('a1'), isTrue);
      expect(patternContainsDigits.hasMatch('a1'), isTrue);
      expect(patternStartsWithNumber.hasMatch('1a'), isTrue);
      expect(patternHasCapitalLetter.hasMatch('aA'), isTrue);
    });
  });
}
