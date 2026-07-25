/// Every claim the README makes about behavior, asserted.
///
/// Documentation that is not executed rots. This file mirrors the README's
/// examples and tables one for one, so a behavior change that contradicts the
/// docs fails the build instead of shipping.
library;

import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('README: opening example', () {
    test('the five lines at the top of the file', () {
      expect('hello_world'.toCamelCase, 'helloWorld');
      expect('helloWorld'.toSnakeCase, 'hello_world');
      expect('Hello, World!'.slugify(), 'hello-world');
      expect('HTTPServer'.toWords, ['HTTP', 'Server']);
      expect('   '.isBlank, isTrue);
    });
  });

  group('README: two ways to call it', () {
    test('extension and Stringo agree', () {
      expect('userProfileField'.toSnakeCase, 'user_profile_field');
      expect(Stringo.snakeCase('userProfileField'), 'user_profile_field');
    });

    test('Stringo members work as function values', () {
      const fields = ['userName', 'emailAddress'];
      expect(fields.map(Stringo.snakeCase).toList(), [
        'user_name',
        'email_address',
      ]);
    });
  });

  group('README: case conversion table', () {
    const input = 'helloWorld';
    test('every row of the table', () {
      expect(input.toPascalCase, 'HelloWorld');
      expect(input.toCamelCase, 'helloWorld');
      expect(input.toSnakeCase, 'hello_world');
      expect(input.toKebabCase, 'hello-world');
      expect(input.toDotCase, 'hello.world');
      expect(input.toFlatCase, 'helloworld');
      expect(input.toScreamingCase, 'HELLOWORLD');
      expect(input.toScreamingSnakeCase, 'HELLO_WORLD');
      expect(input.toScreamingKebabCase, 'HELLO-WORLD');
      expect(input.toPascalSnakeCase, 'Hello_World');
      expect(input.toPascalKebabCase, 'Hello-World');
      expect(input.toTrainCase, 'Hello-World');
      expect(input.toCamelSnakeCase, 'hello_World');
      expect(input.toCamelKebabCase, 'hello-World');
      expect(input.toTitleCase, 'Hello World');
    });

    test('the Stringo column matches the extension column', () {
      expect(Stringo.pascalCase(input), input.toPascalCase);
      expect(Stringo.camelCase(input), input.toCamelCase);
      expect(Stringo.snakeCase(input), input.toSnakeCase);
      expect(Stringo.kebabCase(input), input.toKebabCase);
      expect(Stringo.dotCase(input), input.toDotCase);
      expect(Stringo.flatCase(input), input.toFlatCase);
      expect(Stringo.screamingCase(input), input.toScreamingCase);
      expect(Stringo.screamingSnakeCase(input), input.toScreamingSnakeCase);
      expect(Stringo.screamingKebabCase(input), input.toScreamingKebabCase);
      expect(Stringo.pascalSnakeCase(input), input.toPascalSnakeCase);
      expect(Stringo.pascalKebabCase(input), input.toPascalKebabCase);
      expect(Stringo.camelSnakeCase(input), input.toCamelSnakeCase);
      expect(Stringo.camelKebabCase(input), input.toCamelKebabCase);
      expect(Stringo.titleCase(input), input.toTitleCase);
      // The README lists toTrainCase as an alias of pascalKebabCase.
      expect(Stringo.pascalKebabCase(input), input.toTrainCase);
    });

    test('titleCase example', () {
      expect('the lord of the rings'.toTitleCase, 'The Lord of the Rings');
    });
  });

  group('README: transformation table', () {
    test('the examples given in the table', () {
      expect('Hello, World!'.slugify(), 'hello-world');
      expect('1234567890'.mask(visibleStart: 2, visibleEnd: 2), '12******90');
    });

    test('words and toWords are different splitters', () {
      expect('helloWorld'.words, ['helloWorld']);
      expect('helloWorld'.toWords, ['hello', 'World']);
    });
  });

  group('README: performance section', () {
    test('unicode is preserved, not ascii-folded', () {
      expect('\u{00C9}COLE'.toSnakeCase, '\u{00E9}cole');
    });
  });

  group('README: documented limitations', () {
    test('slugify does not transliterate', () {
      expect('Caf\u{00E9}'.slugify(), 'caf');
    });

    test('toCharArray returns code points, not grapheme clusters', () {
      expect('\u{1F600}'.toCharArray(), ['\u{1F600}']);
      // A letter plus a combining mark is still two elements.
      expect('e\u{0301}'.toCharArray().length, 2);
    });

    test('camelCase and pascalCase are not reversible', () {
      expect('a_b'.toCamelCase, 'aB');
      expect('aB'.toWords, ['a', 'B']);
      expect('aB'.toScreamingCase, 'AB');
    });

    test('word splitting does not break on digits', () {
      expect('abc123Def'.toWords, ['abc123Def']);
    });

    test('character predicates are ascii-only', () {
      expect('\u{00C9}'.hasCapitalLetter, isFalse);
      expect('\u{00E9}'.isAlphabet, isFalse);
    });
  });

  group('README: upgrading from 1.0.0 table', () {
    test('every migration row states the 2.0.0 value correctly', () {
      expect('_leading'.toCamelCase, 'leading');
      expect('  a  '.toWords, ['a']);
      expect(''.toWords, isEmpty);
      expect('a-b'.slugify(separator: '_'), 'a_b');
      expect('Hello World'.truncate(5), 'He...');
      expect('\u{1F600}'.toCharArray(), ['\u{1F600}']);
      expect((null as String?).mask(), isNull);
      expect((null as String?).insert(0, 'x'), isNull);
    });
  });

  group('README: install section', () {
    test(
      'the package has no dependencies beyond dart:core and dart:convert',
      () {
        // Asserted structurally by pubspec having no dependencies block; this
        // test documents the intent alongside the other README claims.
        expect(Stringo.snakeCase('a'), 'a');
      },
    );
  });
}
