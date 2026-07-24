import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('toWords', () {
    test('splits camelCase', () {
      expect('helloWorld'.toWords, ['hello', 'World']);
    });

    test('splits snake_case, kebab-case, and spaces', () {
      expect('hello_world'.toWords, ['hello', 'world']);
      expect('already-kebab'.toWords, ['already', 'kebab']);
      expect('hello world'.toWords, ['hello', 'world']);
    });

    test('splits mixed separators', () {
      expect('helloWorld_example-Text'.toWords, [
        'hello',
        'World',
        'example',
        'Text',
      ]);
    });

    test('keeps leading acronyms intact', () {
      expect('HTTPServer'.toWords, ['HTTP', 'Server']);
      expect('parseHTTPResponse'.toWords, ['parse', 'HTTP', 'Response']);
      expect('XMLHttpRequest'.toWords, ['XML', 'Http', 'Request']);
    });

    test('does not split on digit boundaries', () {
      expect('user2Name'.toWords, ['user2Name']);
    });

    test('treats an all-caps token as one word', () {
      expect('ABC'.toWords, ['ABC']);
    });

    test('single character and empty input', () {
      expect('a'.toWords, ['a']);
      expect(''.toWords, ['']);
    });

    test('leading and trailing separators yield empty words', () {
      expect('_leading'.toWords, ['', 'leading']);
      expect('trailing_'.toWords, ['trailing', '']);
    });
  });

  group('case conversions', () {
    test('toPascalCase', () {
      expect('hello_world'.toPascalCase, 'HelloWorld');
      expect('helloWorld'.toPascalCase, 'HelloWorld');
      expect('a'.toPascalCase, 'A');
    });

    test('toCamelCase', () {
      expect('hello_world'.toCamelCase, 'helloWorld');
      expect('HelloWorld'.toCamelCase, 'helloWorld');
    });

    test('toSnakeCase', () {
      expect('helloWorld'.toSnakeCase, 'hello_world');
      expect('HTTPServer'.toSnakeCase, 'http_server');
      expect('parseHTTPResponse'.toSnakeCase, 'parse_http_response');
    });

    test('toKebabCase', () {
      expect('helloWorld'.toKebabCase, 'hello-world');
    });

    test('toScreamingSnakeCase', () {
      expect('helloWorld'.toScreamingSnakeCase, 'HELLO_WORLD');
    });

    test('toScreamingKebabCase', () {
      expect('helloWorld'.toScreamingKebabCase, 'HELLO-WORLD');
    });

    test('toPascalSnakeCase', () {
      expect('helloWorld'.toPascalSnakeCase, 'Hello_World');
    });

    test('toCamelSnakeCase', () {
      expect('helloWorld'.toCamelSnakeCase, 'hello_World');
    });

    test('toCamelKebabCase', () {
      expect('helloWorld'.toCamelKebabCase, 'hello-World');
    });

    test('toDotCase', () {
      expect('helloWorld'.toDotCase, 'hello.world');
    });

    test('toFlatCase', () {
      expect('HelloWorld'.toFlatCase, 'helloworld');
      expect('Hello World'.toFlatCase, 'helloworld');
    });

    test('toScreamingCase', () {
      expect('helloWorld'.toScreamingCase, 'HELLOWORLD');
    });

    test('toTrainCase and toPascalKebabCase are aliases', () {
      expect('helloWorld'.toTrainCase, 'Hello-World');
      expect('helloWorld'.toPascalKebabCase, 'Hello-World');
      expect(
        'some_mixed input'.toTrainCase,
        'some_mixed input'.toPascalKebabCase,
      );
    });

    test('conversions are stable when already converted', () {
      expect('hello_world'.toSnakeCase, 'hello_world');
      expect('helloWorld'.toCamelCase, 'helloWorld');
      expect('HelloWorld'.toPascalCase, 'HelloWorld');
    });

    test('empty input stays empty', () {
      expect(''.toCamelCase, '');
      expect(''.toSnakeCase, '');
      expect(''.toPascalCase, '');
      expect(''.toKebabCase, '');
    });

    test('a leading separator drops the empty first word', () {
      // The empty leading word has nothing to lowercase, so the second word
      // keeps its capital.
      expect('_leading'.toCamelCase, 'Leading');
      expect('_leading'.toPascalCase, 'Leading');
    });
  });

  group('toTitleCase', () {
    test('capitalizes each significant word', () {
      expect('hello_world'.toTitleCase, 'Hello World');
    });

    test('always capitalizes the first word, even a stop word', () {
      expect('the lord of the rings'.toTitleCase, 'The Lord of the Rings');
      expect('of mice and men'.toTitleCase, 'Of Mice and Men');
      expect('a tale of two cities'.toTitleCase, 'A Tale of Two Cities');
    });

    test('leaves later stop words lowercase', () {
      expect('war and peace'.toTitleCase, 'War and Peace');
    });

    test('leaves digit-leading words alone', () {
      expect('2nd place'.toTitleCase, '2nd Place');
    });
  });

  group('toTitle', () {
    test('preserves - and _ separators', () {
      expect(
        'example-string_for general use-sample.'.toTitle,
        'Example-String_For General Use-Sample.',
      );
    });

    test('each segment gets its own first-word capitalization', () {
      expect('the-lord_of the rings'.toTitle, 'The-Lord_Of the Rings');
    });
  });

  group('capitalization helpers', () {
    test('capitalizeFirstLetter preserves the rest', () {
      expect('flutter AND DART'.capitalizeFirstLetter, 'Flutter AND DART');
      expect('dart'.capitalizeFirstLetter, 'Dart');
    });

    test('lowercaseFirstLetter preserves the rest', () {
      expect('FLUTTER AND DART'.lowercaseFirstLetter, 'fLUTTER AND DART');
    });

    test('capitalizeFirstLowerRest lowercases the rest', () {
      expect('FLUTTER AND DART'.capitalizeFirstLowerRest, 'Flutter and dart');
      expect('DART'.capitalizeFirstLowerRest, 'Dart');
    });

    test('blank input is returned unchanged', () {
      expect(''.capitalizeFirstLetter, '');
      expect('   '.capitalizeFirstLetter, '   ');
      expect(''.lowercaseFirstLetter, '');
      expect(''.capitalizeFirstLowerRest, '');
    });
  });

  group('shouldIgnoreCapitalization', () {
    test('true for stop words and digit-leading words', () {
      expect('the'.shouldIgnoreCapitalization, isTrue);
      expect('OF'.shouldIgnoreCapitalization, isTrue);
      expect('2nd'.shouldIgnoreCapitalization, isTrue);
    });

    test('false for ordinary words', () {
      expect('lord'.shouldIgnoreCapitalization, isFalse);
    });
  });

  group('titleCaseExceptions', () {
    test('exposes the stop-word list', () {
      expect(titleCaseExceptions, contains('the'));
      expect(titleCaseExceptions, contains('and'));
      expect(titleCaseExceptions, isNot(contains('lord')));
    });
  });

  group('nullable case helpers', () {
    test('tryToLowerCase', () {
      expect('ABC'.tryToLowerCase(), 'abc');
      expect((null as String?).tryToLowerCase(), isNull);
    });

    test('tryToUpperCase', () {
      expect('abc'.tryToUpperCase(), 'ABC');
      expect((null as String?).tryToUpperCase(), isNull);
    });
  });
}
