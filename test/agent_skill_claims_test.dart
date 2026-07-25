/// Every factual claim the AI plugin skills make, asserted against the API.
///
/// `tooling/ai/stringo/skills/` tells coding assistants what this package
/// does. Those files are excluded from the pub archive, so nothing else in the
/// build would notice them going stale, and a wrong skill is worse than a
/// missing one: it makes an assistant confidently generate broken code.
///
/// AGENTS.md requires skill facts to match the source. This is that rule,
/// enforced.
library;

import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  test(
    'every factual claim in the AI plugin skills matches the shipped API',
    () {
      final failures = <String>[];
      void check(String claim, Object? actual, Object? expected) {
        if (actual.toString() == expected.toString()) return;
        failures.add(
          '$claim\n    skill says: $expected\n    actual    : $actual',
        );
      }

      // --- use-stringo SKILL.md: the case conversion table ---
      check('toWords', 'helloWorld'.toWords, ['hello', 'World']);
      check('toCamelCase', 'helloWorld'.toCamelCase, 'helloWorld');
      check('toPascalCase', 'helloWorld'.toPascalCase, 'HelloWorld');
      check('toSnakeCase', 'helloWorld'.toSnakeCase, 'hello_world');
      check('toKebabCase', 'helloWorld'.toKebabCase, 'hello-world');
      check('toDotCase', 'helloWorld'.toDotCase, 'hello.world');
      check('toTitleCase', 'helloWorld'.toTitleCase, 'Hello World');
      check(
        'toScreamingSnakeCase',
        'helloWorld'.toScreamingSnakeCase,
        'HELLO_WORLD',
      );
      check(
        'toScreamingKebabCase',
        'helloWorld'.toScreamingKebabCase,
        'HELLO-WORLD',
      );
      check('toPascalSnakeCase', 'helloWorld'.toPascalSnakeCase, 'Hello_World');
      check('toPascalKebabCase', 'helloWorld'.toPascalKebabCase, 'Hello-World');
      check('toTrainCase alias', 'helloWorld'.toTrainCase, 'Hello-World');
      check('toCamelSnakeCase', 'helloWorld'.toCamelSnakeCase, 'hello_World');
      check('toCamelKebabCase', 'helloWorld'.toCamelKebabCase, 'hello-World');
      check('toFlatCase', 'helloWorld'.toFlatCase, 'helloworld');
      check('toScreamingCase', 'helloWorld'.toScreamingCase, 'HELLOWORLD');

      // --- use-stringo: 'key semantics agents get wrong' ---
      check(
        'titleCase first word',
        'the lord of the rings'.toTitleCase,
        'The Lord of the Rings',
      );
      check(
        'toTitle preserves separators',
        'example-string_for general use'.toTitle,
        'Example-String_For General Use',
      );
      check(
        'capitalizeFirstLowerRest',
        'FLUTTER AND DART'.capitalizeFirstLowerRest,
        'Flutter and dart',
      );
      check(
        'capitalizeFirstLetter',
        'flutter AND DART'.capitalizeFirstLetter,
        'Flutter AND DART',
      );
      check('toWords no empty', ''.toWords, []);
      check('toWords trims', '  a  '.toWords, ['a']);
      check('unicode not folded', 'ÉCOLE'.toSnakeCase, 'école');

      // --- use-stringo: transforms block ---
      check(
        'normalizeWhitespace',
        '  Line   1 \n Line 2  '.normalizeWhitespace(),
        'Line 1 Line 2',
      );
      check(
        'removeEmptyLines',
        'Line1\n\n\nLine2'.removeEmptyLines,
        'Line1\nLine2',
      );
      check('clean', 'a b\nc'.clean, 'abc');
      check('words', 'Hello World'.words, ['Hello', 'World']);
      check('lines', 'a\r\nb'.lines, ['a', 'b']);
      check('slugify', 'Hello, World!'.slugify(), 'hello-world');
      check('truncate NEW', 'Hello World'.truncate(5), 'He...');
      check(
        'mask',
        '1234567890'.mask(visibleStart: 2, visibleEnd: 2),
        '12******90',
      );
      check('removeSurrounding', '"quoted"'.removeSurrounding('"'), 'quoted');
      check('replaceAfter', 'foo=bar'.replaceAfter('=', 'baz'), 'foo=baz');
      check('insert', 'abc'.insert(1, 'Z'), 'aZbc');

      // --- use-stringo: traps ---
      check('clean joins w/o separator', 'Line1\nLine2'.clean, 'Line1Line2');
      check('words != toWords', 'helloWorld'.words, ['helloWorld']);
      check('nullIfEmpty', '   '.nullIfEmpty, '   ');
      check('nullIfBlank', '   '.nullIfBlank, null);
      check('slugify separators uniform', 'a-b'.slugify(separator: '_'), 'a_b');
      check('mask null -> null', (null as String?).mask(), null);
      check('insert null -> null', (null as String?).insert(0, 'x'), null);

      // --- use-stringo: documented limitations ---
      check('slugify ascii only', 'Café'.slugify(), 'caf');
      check('toCharArray code points', '😀'.toCharArray(), ['😀']);
      check('toWords no digit split', 'user2Name'.toWords, ['user2Name']);
      check('camel not reversible', 'a_b'.toCamelCase, 'aB');

      // --- use-stringo: Stringo core + precompiled patterns ---
      check(
        'Stringo.snakeCase',
        Stringo.snakeCase('userProfileField'),
        'user_profile_field',
      );
      check(
        'Stringo as fn value',
        ['aB', 'cD'].map(Stringo.snakeCase).toList(),
        ['a_b', 'c_d'],
      );
      check('patternNumeric', patternNumeric.hasMatch('123'), true);
      check(
        'regexNumeric still exported',
        RegExp(regexNumeric).hasMatch('123'),
        true,
      );
      check(
        'titleCaseExceptions public',
        titleCaseExceptions.contains('the'),
        true,
      );

      // --- migrate-stringo-v1-to-v2 SKILL.md claims ---
      check('migrate: _leading', '_leading'.toCamelCase, 'leading');
      check('migrate: trailing', 'trailing_'.toWords, ['trailing']);
      check(
        'migrate: truncate suffix',
        'Hello World'.truncate(5, suffix: '!'),
        'Hell!',
      );
      check('migrate: emoji', '😀'.toCharArray().length, 1);
      check('migrate: slugify hyphen', 'a-b'.slugify(separator: '_'), 'a_b');

      expect(
        failures,
        isEmpty,
        reason:
            'The AI plugin skills under tooling/ai/stringo/skills/ state these '
            'as fact. AGENTS.md requires skill facts to match the source, so '
            'either the behavior change was unintended or the skill needs '
            'updating in the same PR:\n${failures.join('\n')}',
      );
    },
  );
}
