import 'package:stringo/src/ops/case.dart';
import 'package:stringo/src/title_case_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('the 14 conversions on a camelCase input', () {
    const input = 'helloWorld';
    test('produce their documented shapes', () {
      expect(pascalCase(input), 'HelloWorld');
      expect(camelCase(input), 'helloWorld');
      expect(snakeCase(input), 'hello_world');
      expect(kebabCase(input), 'hello-world');
      expect(dotCase(input), 'hello.world');
      expect(flatCase(input), 'helloworld');
      expect(screamingCase(input), 'HELLOWORLD');
      expect(screamingSnakeCase(input), 'HELLO_WORLD');
      expect(screamingKebabCase(input), 'HELLO-WORLD');
      expect(pascalSnakeCase(input), 'Hello_World');
      expect(pascalKebabCase(input), 'Hello-World');
      expect(camelSnakeCase(input), 'hello_World');
      expect(camelKebabCase(input), 'hello-World');
      expect(titleCase(input), 'Hello World');
    });
  });

  group('input shape does not change the result', () {
    test('snake, kebab, spaced, and pascal inputs all agree', () {
      const inputs = [
        'hello_world',
        'hello-world',
        'hello world',
        'HelloWorld',
        'helloWorld',
        'HELLO_WORLD',
      ];
      for (final input in inputs) {
        expect(snakeCase(input), 'hello_world', reason: input);
        expect(camelCase(input), 'helloWorld', reason: input);
        expect(pascalCase(input), 'HelloWorld', reason: input);
      }
    });

    test('conversions are stable when already converted', () {
      expect(snakeCase('hello_world'), 'hello_world');
      expect(camelCase('helloWorld'), 'helloWorld');
      expect(pascalCase('HelloWorld'), 'HelloWorld');
    });

    test('mixed separators split correctly', () {
      expect(words('helloWorld_example-Text'), [
        'hello',
        'World',
        'example',
        'Text',
      ]);
    });
  });

  group('titleCase', () {
    test('always capitalizes the first word, even a stop word', () {
      expect(titleCase('the lord of the rings'), 'The Lord of the Rings');
      expect(titleCase('of mice and men'), 'Of Mice and Men');
      expect(titleCase('a tale of two cities'), 'A Tale of Two Cities');
    });

    test('leaves later stop words lowercase', () {
      expect(titleCase('war and peace'), 'War and Peace');
    });

    test('leaves digit-leading words lowercase after the first', () {
      expect(titleCase('2nd place'), '2nd Place');
    });

    test('titleCaseExceptions is public and holds the stop words', () {
      expect(titleCaseExceptions, contains('the'));
      expect(titleCaseExceptions, contains('and'));
      expect(titleCaseExceptions, isNot(contains('lord')));
    });
  });

  group('title preserves separators', () {
    test('keeps - and _ where titleCase would normalize them', () {
      expect(
        title('example-string_for general use-sample.'),
        'Example-String_For General Use-Sample.',
      );
    });

    test('each segment gets its own first-word capitalization', () {
      expect(title('the-lord_of the rings'), 'The-Lord_Of the Rings');
    });
  });

  group('defect 1: leading separator no longer corrupts camelCase', () {
    test('_leading yields leading, not Leading', () {
      expect(camelCase('_leading'), 'leading');
      expect(camelCase('  leading'), 'leading');
      expect(camelCase('--leading'), 'leading');
      expect(camelSnakeCase('_a_b'), 'a_B');
    });

    test('pascalCase is unaffected, since it capitalizes every word', () {
      expect(pascalCase('_leading'), 'Leading');
    });

    test('trailing and repeated separators produce no phantom word', () {
      expect(snakeCase('trailing_'), 'trailing');
      expect(snakeCase('  spaced  out  '), 'spaced_out');
      expect(pascalCase('_a_'), 'A');
    });
  });

  group('unicode is preserved, never ascii-folded', () {
    test('casing uses Dart native mapping for non-ascii input', () {
      expect(snakeCase('\u{00C9}COLE'), '\u{00E9}cole');
      expect(capitalizeFirstLowerRest('\u{00C9}COLE'), '\u{00C9}cole');
      expect(screamingCase('caf\u{00E9}'), 'CAF\u{00C9}');
    });

    test('non-ascii letters never create a word boundary', () {
      expect(words('caf\u{00C9}au'), ['caf\u{00C9}au']);
      expect(
        snakeCase('\u{00DC}n\u{00EF}code W\u{00F6}rd'),
        '\u{00FC}n\u{00EF}code_w\u{00F6}rd',
      );
    });

    test('surrogate pairs survive intact', () {
      expect(words('a\u{1F600}B'), ['a\u{1F600}B']);
      expect(snakeCase('a\u{1F600}B'), 'a\u{1F600}b');
    });
  });

  group('empty and separator-only input', () {
    test('every conversion returns the empty string', () {
      for (final input in ['', '   ', '___', '-_-']) {
        expect(pascalCase(input), '', reason: input);
        expect(camelCase(input), '', reason: input);
        expect(snakeCase(input), '', reason: input);
        expect(kebabCase(input), '', reason: input);
        expect(titleCase(input), '', reason: input);
        expect(flatCase(input), '', reason: input);
      }
      expect(words(''), isEmpty);
    });
  });

  group('first-character helpers', () {
    test('capitalizeFirst leaves the rest untouched', () {
      expect(capitalizeFirst('flutter AND DART'), 'Flutter AND DART');
      expect(capitalizeFirst('dart'), 'Dart');
      expect(capitalizeFirst(''), '');
    });

    test('lowercaseFirst leaves the rest untouched', () {
      expect(lowercaseFirst('FLUTTER AND DART'), 'fLUTTER AND DART');
      expect(lowercaseFirst(''), '');
    });

    test('capitalizeFirstLowerRest lowercases the rest', () {
      expect(capitalizeFirstLowerRest('FLUTTER AND DART'), 'Flutter and dart');
      expect(capitalizeFirstLowerRest('DART'), 'Dart');
      expect(capitalizeFirstLowerRest(''), '');
    });

    test('whitespace-only input is returned unchanged', () {
      expect(capitalizeFirst('   '), '   ');
      expect(lowercaseFirst('   '), '   ');
      expect(capitalizeFirstLowerRest('   '), '   ');
    });
  });

  group('supplementary-plane first characters are cased', () {
    // 1.0.0 used s[0], a lone high surrogate for astral characters, and
    // casing a lone surrogate is the identity. The first letter of Deseret,
    // Osage, or Adlam text was silently left alone by every capitalizing
    // conversion.
    const deseretLower = '\u{10428}\u{10429}'; // two lowercase letters
    const deseretUpper = '\u{10400}\u{10401}';

    test('capitalizeFirst uppercases an astral first character', () {
      expect(capitalizeFirst(deseretLower), '\u{10400}\u{10429}');
    });

    test('lowercaseFirst lowercases an astral first character', () {
      expect(lowercaseFirst(deseretUpper), '\u{10428}\u{10401}');
    });

    test('capitalizeFirstLowerRest handles an astral first character', () {
      expect(capitalizeFirstLowerRest(deseretLower), '\u{10400}\u{10429}');
    });

    test('conversions with a capitalize mode inherit the fix', () {
      expect(pascalCase(deseretLower), '\u{10400}\u{10429}');
      expect(titleCase(deseretLower), '\u{10400}\u{10429}');
    });

    test('a caseless astral character is left alone', () {
      expect(capitalizeFirst('\u{1F600}a'), '\u{1F600}a');
    });

    test('the surrogate pair is never torn apart', () {
      for (final f in [
        capitalizeFirst,
        lowercaseFirst,
        capitalizeFirstLowerRest,
      ]) {
        final out = f(deseretLower);
        expect(out.runes.length, 2, reason: 'produced a lone surrogate');
      }
    });
  });

  group('preserved 1.0.0 quirks', () {
    test('digits never create a word boundary', () {
      expect(words('abc123Def'), ['abc123Def']);
      expect(words('user2Name'), ['user2Name']);
      expect(snakeCase('abc123Def'), 'abc123def');
    });

    test('acronyms keep their run', () {
      expect(words('HTTPServer'), ['HTTP', 'Server']);
      expect(words('parseHTTPResponse'), ['parse', 'HTTP', 'Response']);
      expect(words('ABC'), ['ABC']);
      expect(snakeCase('parseHTTPResponse'), 'parse_http_response');
      expect(kebabCase('XMLHttpRequest'), 'xml-http-request');
    });

    test('shouldIgnoreCapitalization matches the documented rule', () {
      expect(shouldIgnoreCapitalization('the'), isTrue);
      expect(shouldIgnoreCapitalization('OF'), isTrue);
      expect(shouldIgnoreCapitalization('2nd'), isTrue);
      expect(shouldIgnoreCapitalization('lord'), isFalse);
      expect(shouldIgnoreCapitalization(''), isFalse);
    });
  });
}
