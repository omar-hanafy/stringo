import 'package:stringo/src/ops/transform.dart';
import 'package:test/test.dart';

void main() {
  group('whitespace handling', () {
    test('removeEmptyLines collapses blank lines', () {
      expect(removeEmptyLines('Line1\n\n\nLine2'), 'Line1\nLine2');
    });

    test('oneLine drops newlines without a separator', () {
      expect(oneLine('Line1\nLine2'), 'Line1Line2');
      expect(oneLine('no newlines here'), 'no newlines here');
    });

    test('removeWhitespace drops every whitespace character', () {
      expect(removeWhitespace('a b c'), 'abc');
      expect(removeWhitespace('Line 1\tLine 2'), 'Line1Line2');
      expect(removeWhitespace('a\u{00A0}b'), 'ab');
    });

    test('normalizeWhitespace collapses and trims', () {
      expect(normalizeWhitespace('  Line   1 \n Line 2  '), 'Line 1 Line 2');
      expect(normalizeWhitespace('   \n\t  '), '');
      expect(normalizeWhitespace(''), '');
    });
  });

  group('splitting', () {
    test('splitWhitespace splits on whitespace runs', () {
      expect(splitWhitespace('Hello World'), ['Hello', 'World']);
      expect(splitWhitespace('  Hello   World  '), ['Hello', 'World']);
      expect(splitWhitespace('Hello\nWorld'), ['Hello', 'World']);
    });

    test('splitWhitespace returns empty for blank input', () {
      expect(splitWhitespace(''), isEmpty);
      expect(splitWhitespace('   '), isEmpty);
    });

    test('lines handles both LF and CRLF', () {
      expect(lines('Line 1\nLine 2'), ['Line 1', 'Line 2']);
      expect(lines('Line 1\r\nLine 2'), ['Line 1', 'Line 2']);
    });

    test('lines on empty input yields one empty line', () {
      expect(lines(''), ['']);
    });

    test('a lone carriage return is not a line ending', () {
      expect(lines('a\rb'), ['a\rb']);
    });
  });

  group('characters (defect 6: surrogate pairs)', () {
    test('splits plain text into single characters', () {
      expect(characters('abc'), ['a', 'b', 'c']);
      expect(characters(''), isEmpty);
    });

    test('keeps a surrogate pair as one element', () {
      expect(characters('\u{1F600}'), ['\u{1F600}']);
      expect(characters('a\u{1F600}b'), ['a', '\u{1F600}', 'b']);
    });

    test('whitespace is preserved, not dropped', () {
      expect(characters('a b'), ['a', ' ', 'b']);
    });

    test('the returned list is growable, for every input', () {
      // A fixed-length list here threw UnsupportedError on add/removeLast,
      // and only for non-blank input, so the contract varied by argument.
      for (final input in ['ab', '', '  ', '\u{1F600}']) {
        final list = characters(input);
        expect(
          () => list.add('x'),
          returnsNormally,
          reason: 'characters("$input") must be growable',
        );
      }
    });
  });

  group('removeEmptyLines: audit regressions', () {
    test('collapses blank-line runs, including indented ones', () {
      expect(removeEmptyLines('Line1\n\n\nLine2'), 'Line1\nLine2');
      expect(removeEmptyLines('a\n  \n\t\nb'), 'a\nb');
      expect(removeEmptyLines('a\r\n\r\nb'), 'a\nb');
      expect(removeEmptyLines('a\r\rb'), 'a\nb');
    });

    test('leaves an unterminated whitespace run untouched', () {
      // The case the old regex handled quadratically: spaces with no line
      // break after them are ordinary content and must survive verbatim.
      expect(removeEmptyLines('a    b'), 'a    b');
      expect(removeEmptyLines('   '), '   ');
      expect(removeEmptyLines(''), '');
      expect(removeEmptyLines('a\t\tb'), 'a\t\tb');
    });

    test('trailing indentation before a break still collapses', () {
      expect(removeEmptyLines('a   \n   \nb'), 'a\nb');
      expect(removeEmptyLines('a\n   '), 'a\n   ');
    });
  });

  group('slugify', () {
    test('converts to a lowercase slug', () {
      expect(slugify('Hello, World!'), 'hello-world');
    });

    test('collapses underscores and spaces', () {
      expect(slugify('Foo__Bar  Baz'), 'foo-bar-baz');
    });

    test('collapses repeated separators', () {
      expect(slugify('Already--slug'), 'already-slug');
    });

    test('trims separators from both ends', () {
      expect(slugify('---'), '');
      expect(slugify('-hello-'), 'hello');
    });

    test('retains numbers', () {
      expect(slugify('Version 2 Update'), 'version-2-update');
    });

    test('supports a custom separator', () {
      expect(slugify('Hello World', separator: '_'), 'hello_world');
    });

    test('supports a multi-character separator', () {
      expect(slugify('Hello World', separator: '--'), 'hello--world');
      expect(slugify('a  b', separator: '--'), 'a--b');
    });

    test('supports regex-special separators literally', () {
      expect(slugify('a b', separator: '.'), 'a.b');
      expect(slugify('a b', separator: r'$'), r'a$b');
      expect(slugify('a b', separator: '+'), 'a+b');
    });

    test('returns empty for blank or symbol-only input', () {
      expect(slugify(''), '');
      expect(slugify('   '), '');
      expect(slugify('!!!'), '');
    });

    test('drops non-ASCII rather than transliterating', () {
      expect(slugify('Caf\u{00E9}'), 'caf');
      expect(slugify('na\u{00EF}ve'), 'nave');
    });

    test('rejects an empty separator', () {
      expect(() => slugify('Hello', separator: ''), throwsArgumentError);
    });

    group('defect 3: every separator kind produces the chosen separator', () {
      test('an input hyphen no longer survives a different separator', () {
        expect(slugify('a-b', separator: '_'), 'a_b');
        expect(slugify('a-b', separator: '.'), 'a.b');
        expect(slugify('a_b', separator: '-'), 'a-b');
      });

      test('mixed separator runs collapse to exactly one separator', () {
        expect(slugify('a -_- b', separator: '_'), 'a_b');
        expect(slugify('a-_ b'), 'a-b');
      });
    });

    test('is idempotent for conventional separators', () {
      for (final input in [
        'Hello, World!',
        'a-_ b',
        '--x--',
        'Version 2 Update',
      ]) {
        for (final sep in ['-', '_', 'x', '9']) {
          final once = slugify(input, separator: sep);
          expect(slugify(once, separator: sep), once, reason: '$input / $sep');
        }
      }
    });

    test('is NOT idempotent for a separator outside a-z0-9, by nature', () {
      // The separator is written verbatim and is not itself filtered, so on a
      // second pass its own characters meet the drop rule. Documented rather
      // than fixed: the alternative is filtering the caller's separator,
      // which would silently produce a slug they did not ask for.
      expect(slugify('hello world', separator: '::'), 'hello::world');
      expect(slugify('hello::world', separator: '::'), 'helloworld');
      expect(slugify('hello world', separator: 'X'), 'helloXworld');
      expect(slugify('helloXworld', separator: 'X'), 'helloxworld');
    });

    test('a character whose lowercase is ascii survives', () {
      // The doc says non-ascii is dropped; these are the stated exceptions.
      expect(slugify('\u{212A}'), 'k', reason: 'Kelvin sign');
      expect(
        slugify('\u{0130}stanbul'),
        'istanbul',
        reason: 'dotted capital I',
      );
    });
  });

  group('truncate (defect 5: length is the maximum)', () {
    test('the suffix counts against the limit', () {
      expect(truncate('Hello World', 5), 'He...');
      expect(truncate('Hello World', 5).length, 5);
      expect(truncate('Hello World', 5, suffix: '!'), 'Hell!');
      expect(truncate('Hello World', 8), 'Hello...');
    });

    test('leaves short-enough strings alone', () {
      expect(truncate('Hello', 10), 'Hello');
      expect(truncate('Hello', 5), 'Hello');
    });

    test('non-positive length yields empty', () {
      expect(truncate('abc', 0), '');
      expect(truncate('abc', -1), '');
    });

    test('a suffix longer than the limit yields exactly the suffix', () {
      expect(truncate('abcdefgh', 2), '...');
      expect(truncate('abcdefgh', 3), '...');
    });

    test('never exceeds max(length, suffix.length)', () {
      const input = 'abcdefghijklmnop';
      for (var n = 0; n <= input.length + 5; n++) {
        final result = truncate(input, n);
        expect(
          result.length,
          lessThanOrEqualTo(n > 3 ? n : 3),
          reason: 'n=$n gave "$result"',
        );
      }
    });
  });

  group('mask', () {
    test('keeps the requested edges visible', () {
      expect(mask('1234567890', visibleStart: 2, visibleEnd: 2), '12******90');
      expect(mask('12345', visibleStart: 1), '1****');
      expect(mask('12345'), '*****');
    });

    test('supports a custom mask character', () {
      expect(mask('12345', visibleStart: 1, char: '#'), '1####');
    });

    test('returns the input when it is too short to mask', () {
      expect(mask('123', visibleStart: 2, visibleEnd: 2), '123');
      expect(mask('ab', visibleStart: 5), 'ab');
    });

    test('rejects negative bounds', () {
      expect(() => mask('abc', visibleStart: -1), throwsArgumentError);
      expect(() => mask('abc', visibleEnd: -1), throwsArgumentError);
    });
  });

  group('insert', () {
    test('inserts at an interior index and both boundaries', () {
      expect(insert('abc', 1, 'Z'), 'aZbc');
      expect(insert('abc', 0, 'Z'), 'Zabc');
      expect(insert('abc', 3, 'Z'), 'abcZ');
    });

    test('rejects an out-of-range index', () {
      expect(() => insert('abc', 4, 'Z'), throwsRangeError);
      expect(() => insert('abc', -1, 'Z'), throwsRangeError);
    });
  });

  group('removeSurrounding', () {
    test('strips only when present at both ends', () {
      expect(removeSurrounding('"value"', '"'), 'value');
      expect(removeSurrounding('value', '"'), 'value');
      expect(removeSurrounding('"value', '"'), '"value');
    });

    test('a single delimiter-length string is not stripped twice', () {
      expect(removeSurrounding('"', '"'), '"');
    });
  });

  group('replaceAfter / replaceBefore', () {
    test('replaces around the first delimiter', () {
      expect(replaceAfter('foo=bar', '=', 'baz'), 'foo=baz');
      expect(replaceBefore('foo=bar', '=', 'baz'), 'baz=bar');
    });

    test('falls back when the delimiter is missing', () {
      expect(replaceAfter('foo', ':', 'x', 'fallback'), 'fallback');
      expect(replaceBefore('foo', ':', 'x', 'fallback'), 'fallback');
      expect(replaceAfter('foo', ':', 'x'), 'foo');
      expect(replaceBefore('foo', ':', 'x'), 'foo');
    });

    test('a blank default value is ignored', () {
      expect(replaceAfter('foo', ':', 'x', '   '), 'foo');
      expect(replaceBefore('foo', ':', 'x', ''), 'foo');
    });
  });
}
