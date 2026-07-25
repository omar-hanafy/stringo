/// Direct coverage of the `Stringo` facade.
///
/// The extensions delegate to these functions, so extension tests exercise the
/// ops indirectly. They do NOT prove the facade itself delegates correctly: a
/// member wired to the wrong op, or one passing its arguments in the wrong
/// order, would still pass every extension test.
///
/// Every member is therefore called here directly, with asymmetric arguments
/// wherever a swap would otherwise go unnoticed.
library;

import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('splitting', () {
    test('words is the identifier tokenizer', () {
      expect(Stringo.words('helloWorld'), ['hello', 'World']);
      expect(Stringo.words('HTTPServer'), ['HTTP', 'Server']);
      expect(Stringo.words(''), isEmpty);
    });

    test('splitWhitespace is the prose splitter, not the tokenizer', () {
      // If these two were wired to the same op, this would fail.
      expect(Stringo.splitWhitespace('helloWorld'), ['helloWorld']);
      expect(Stringo.splitWhitespace('  a  b  '), ['a', 'b']);
      expect(Stringo.splitWhitespace('   '), isEmpty);
    });

    test('lines splits on line endings only', () {
      expect(Stringo.lines('a\nb'), ['a', 'b']);
      expect(Stringo.lines('a\r\nb'), ['a', 'b']);
      expect(Stringo.lines(''), ['']);
    });

    test('characters splits by code point', () {
      expect(Stringo.characters('abc'), ['a', 'b', 'c']);
      expect(Stringo.characters('\u{1F600}'), ['\u{1F600}']);
    });
  });

  group('case conversion', () {
    const input = 'helloWorld';
    test('each conversion produces its own distinct shape', () {
      expect(Stringo.pascalCase(input), 'HelloWorld');
      expect(Stringo.camelCase(input), 'helloWorld');
      expect(Stringo.snakeCase(input), 'hello_world');
      expect(Stringo.kebabCase(input), 'hello-world');
      expect(Stringo.dotCase(input), 'hello.world');
      expect(Stringo.flatCase(input), 'helloworld');
      expect(Stringo.screamingCase(input), 'HELLOWORLD');
      expect(Stringo.screamingSnakeCase(input), 'HELLO_WORLD');
      expect(Stringo.screamingKebabCase(input), 'HELLO-WORLD');
      expect(Stringo.pascalSnakeCase(input), 'Hello_World');
      expect(Stringo.pascalKebabCase(input), 'Hello-World');
      expect(Stringo.camelSnakeCase(input), 'hello_World');
      expect(Stringo.camelKebabCase(input), 'hello-World');
      expect(Stringo.titleCase(input), 'Hello World');
    });

    test('title preserves separators where titleCase normalizes them', () {
      expect(Stringo.title('a-b_c d'), 'A-B_C D');
      expect(Stringo.titleCase('a-b_c d'), 'A B C D');
    });

    test('the three first-character helpers differ from each other', () {
      const mixed = 'fLUTTER and DART';
      expect(Stringo.capitalizeFirst(mixed), 'FLUTTER and DART');
      expect(Stringo.lowercaseFirst(mixed), 'fLUTTER and DART');
      expect(Stringo.capitalizeFirstLowerRest(mixed), 'Flutter and dart');
    });

    test('shouldIgnoreCapitalization', () {
      expect(Stringo.shouldIgnoreCapitalization('the'), isTrue);
      expect(Stringo.shouldIgnoreCapitalization('2nd'), isTrue);
      expect(Stringo.shouldIgnoreCapitalization('lord'), isFalse);
    });
  });

  group('transformation', () {
    test('slugify honors its named separator', () {
      expect(Stringo.slugify('Hello, World!'), 'hello-world');
      expect(Stringo.slugify('Hello World', separator: '_'), 'hello_world');
      expect(() => Stringo.slugify('x', separator: ''), throwsArgumentError);
    });

    test('truncate takes length positionally and suffix by name', () {
      expect(Stringo.truncate('Hello World', 5), 'He...');
      expect(Stringo.truncate('Hello World', 5, suffix: '!'), 'Hell!');
      expect(Stringo.truncate('Hi', 5), 'Hi');
    });

    test('mask keeps start and end distinct', () {
      // Asymmetric on purpose: swapping visibleStart and visibleEnd changes
      // the result, so a mis-wired delegation cannot pass.
      expect(
        Stringo.mask('1234567890', visibleStart: 3, visibleEnd: 1),
        '123******0',
      );
      expect(Stringo.mask('12345', visibleStart: 1, char: '#'), '1####');
      expect(() => Stringo.mask('x', visibleStart: -1), throwsArgumentError);
    });

    test('the four whitespace operations are each distinct', () {
      const messy = 'a  b\n\n\nc \t d';
      expect(Stringo.normalizeWhitespace(' $messy '), 'a b c d');
      expect(Stringo.removeWhitespace(messy), 'abcd');
      expect(Stringo.removeEmptyLines('L1\n\n\nL2'), 'L1\nL2');
      expect(Stringo.oneLine('L1\nL2'), 'L1L2');
    });

    test('insert takes index then value, in that order', () {
      expect(Stringo.insert('abc', 1, 'Z'), 'aZbc');
      expect(() => Stringo.insert('abc', 9, 'Z'), throwsRangeError);
    });

    test('removeSurrounding strips only when present at both ends', () {
      expect(Stringo.removeSurrounding('"v"', '"'), 'v');
      expect(Stringo.removeSurrounding('"v', '"'), '"v');
    });

    test('replaceAfter and replaceBefore differ, and argument order holds', () {
      // delimiter '=', replacement 'baz'. Swapping them would yield 'foobaz'
      // or throw, so this pins the parameter order.
      expect(Stringo.replaceAfter('foo=bar', '=', 'baz'), 'foo=baz');
      expect(Stringo.replaceBefore('foo=bar', '=', 'baz'), 'baz=bar');
      expect(Stringo.replaceAfter('foo', ':', 'x', 'fallback'), 'fallback');
      expect(Stringo.replaceBefore('foo', ':', 'x', 'fallback'), 'fallback');
      expect(Stringo.replaceAfter('foo', ':', 'x'), 'foo');
    });
  });

  group('checks', () {
    test('blank checks accept null', () {
      expect(Stringo.isBlank(null), isTrue);
      expect(Stringo.isBlank('  '), isTrue);
      expect(Stringo.isBlank('x'), isFalse);
      expect(Stringo.isNotBlank(null), isFalse);
      expect(Stringo.isNotBlank('x'), isTrue);
    });

    test('each character predicate is wired to its own rule', () {
      expect(Stringo.isAlphanumeric('a1'), isTrue);
      expect(Stringo.isAlphanumeric('a-1'), isFalse);
      expect(Stringo.isNumeric(' 12 '), isTrue);
      expect(Stringo.isNumeric('a1'), isFalse);
      expect(Stringo.isAlphabet(' ab '), isTrue);
      expect(Stringo.isAlphabet('a1'), isFalse);
      expect(Stringo.startsWithNumber('1a'), isTrue);
      expect(Stringo.startsWithNumber('a1'), isFalse);
      expect(Stringo.containsDigits('a1'), isTrue);
      expect(Stringo.containsDigits('ab'), isFalse);
      expect(Stringo.hasCapitalLetter('aB'), isTrue);
      expect(Stringo.hasCapitalLetter('ab'), isFalse);
      expect(Stringo.isAlphanumeric(null), isFalse);
    });

    test('equalsIgnoreCase compares both arguments', () {
      expect(Stringo.equalsIgnoreCase('AB', 'ab'), isTrue);
      expect(Stringo.equalsIgnoreCase('AB', 'ac'), isFalse);
      expect(Stringo.equalsIgnoreCase(null, null), isTrue);
      expect(Stringo.equalsIgnoreCase('a', null), isFalse);
    });

    test('hasMatch takes the subject first and the pattern second', () {
      // Swapping the two would make this pass wrongly, so the pattern is
      // chosen to be invalid as a subject-side literal match.
      expect(Stringo.hasMatch('a1b', r'\d'), isTrue);
      expect(Stringo.hasMatch('abc', r'\d'), isFalse);
      expect(Stringo.hasMatch(null, r'\d'), isFalse);
      expect(Stringo.hasMatch('A', 'a', caseSensitive: false), isTrue);
      expect(Stringo.hasMatch('A', 'a'), isFalse);
      expect(Stringo.hasMatch('a\nb', r'^b', multiLine: true), isTrue);
      expect(Stringo.hasMatch('a\nb', 'a.b', dotAll: true), isTrue);
      expect(Stringo.hasMatch('\u{1F600}', r'^.$', unicode: true), isTrue);
    });
  });

  group('facade and extensions agree on every shared member', () {
    const samples = ['helloWorld', 'hello_world', '', '_x_', 'HTTPServer'];
    test('case members', () {
      for (final s in samples) {
        expect(Stringo.words(s), s.toWords, reason: s);
        expect(Stringo.pascalCase(s), s.toPascalCase, reason: s);
        expect(Stringo.camelCase(s), s.toCamelCase, reason: s);
        expect(Stringo.snakeCase(s), s.toSnakeCase, reason: s);
        expect(Stringo.kebabCase(s), s.toKebabCase, reason: s);
        expect(Stringo.dotCase(s), s.toDotCase, reason: s);
        expect(Stringo.flatCase(s), s.toFlatCase, reason: s);
        expect(Stringo.screamingCase(s), s.toScreamingCase, reason: s);
        expect(
          Stringo.screamingSnakeCase(s),
          s.toScreamingSnakeCase,
          reason: s,
        );
        expect(
          Stringo.screamingKebabCase(s),
          s.toScreamingKebabCase,
          reason: s,
        );
        expect(Stringo.pascalSnakeCase(s), s.toPascalSnakeCase, reason: s);
        expect(Stringo.pascalKebabCase(s), s.toPascalKebabCase, reason: s);
        expect(Stringo.camelSnakeCase(s), s.toCamelSnakeCase, reason: s);
        expect(Stringo.camelKebabCase(s), s.toCamelKebabCase, reason: s);
        expect(Stringo.titleCase(s), s.toTitleCase, reason: s);
        expect(Stringo.title(s), s.toTitle, reason: s);
        expect(Stringo.capitalizeFirst(s), s.capitalizeFirstLetter, reason: s);
        expect(Stringo.lowercaseFirst(s), s.lowercaseFirstLetter, reason: s);
        expect(
          Stringo.capitalizeFirstLowerRest(s),
          s.capitalizeFirstLowerRest,
          reason: s,
        );
        expect(
          Stringo.shouldIgnoreCapitalization(s),
          s.shouldIgnoreCapitalization,
          reason: s,
        );
      }
    });

    test('transform and check members', () {
      for (final s in samples) {
        expect(Stringo.splitWhitespace(s), s.words, reason: s);
        expect(Stringo.lines(s), s.lines, reason: s);
        expect(Stringo.slugify(s), s.slugify(), reason: s);
        expect(
          Stringo.normalizeWhitespace(s),
          s.normalizeWhitespace(),
          reason: s,
        );
        expect(Stringo.removeWhitespace(s), s.removeWhiteSpaces, reason: s);
        expect(Stringo.removeEmptyLines(s), s.removeEmptyLines, reason: s);
        expect(Stringo.oneLine(s), s.toOneLine, reason: s);
        expect(Stringo.truncate(s, 3), s.truncate(3), reason: s);
        expect(
          Stringo.mask(s, visibleStart: 1),
          s.mask(visibleStart: 1),
          reason: s,
        );
        expect(
          Stringo.removeSurrounding(s, '_'),
          s.removeSurrounding('_'),
          reason: s,
        );
        expect(
          Stringo.replaceAfter(s, 'l', 'X'),
          s.replaceAfter('l', 'X'),
          reason: s,
        );
        expect(
          Stringo.replaceBefore(s, 'l', 'X'),
          s.replaceBefore('l', 'X'),
          reason: s,
        );
        expect(Stringo.isBlank(s), s.isBlank, reason: s);
        expect(Stringo.isNotBlank(s), s.isNotBlank, reason: s);
        expect(Stringo.isAlphanumeric(s), s.isAlphanumeric, reason: s);
        expect(Stringo.isNumeric(s), s.isNumeric, reason: s);
        expect(Stringo.isAlphabet(s), s.isAlphabet, reason: s);
        expect(Stringo.startsWithNumber(s), s.startsWithNumber, reason: s);
        expect(Stringo.containsDigits(s), s.containsDigits, reason: s);
        expect(Stringo.hasCapitalLetter(s), s.hasCapitalLetter, reason: s);
        expect(Stringo.hasMatch(s, 'l'), s.hasMatch('l'), reason: s);
        expect(
          Stringo.equalsIgnoreCase(s, s.toUpperCase()),
          s.equalsIgnoreCase(s.toUpperCase()),
          reason: s,
        );
        if (s.isNotEmpty) {
          expect(Stringo.insert(s, 1, 'Z'), s.insert(1, 'Z'), reason: s);
        }
        expect(
          Stringo.characters(s),
          s.isEmpty ? isEmpty : s.toCharArray(),
          reason: s,
        );
      }
    });
  });
}
