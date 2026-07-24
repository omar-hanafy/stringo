import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('null-ifying helpers', () {
    test('nullIfEmpty only treats zero-length as empty', () {
      expect(''.nullIfEmpty, isNull);
      expect('text'.nullIfEmpty, 'text');
      expect('   '.nullIfEmpty, '   ');
    });

    test('nullIfBlank also treats whitespace as empty', () {
      expect('   '.nullIfBlank, isNull);
      expect('\t'.nullIfBlank, isNull);
      expect(' \n \t '.nullIfBlank, isNull);
      expect('text'.nullIfBlank, 'text');
    });

    test('orEmpty', () {
      expect((null as String?).orEmpty, '');
      expect('x'.orEmpty, 'x');
    });
  });

  group('whitespace handling', () {
    test('removeEmptyLines collapses blank lines', () {
      expect('Line1\n\n\nLine2'.removeEmptyLines, 'Line1\nLine2');
    });

    test('toOneLine drops newlines without a separator', () {
      expect('Line1\nLine2'.toOneLine, 'Line1Line2');
    });

    test('removeWhiteSpaces drops every whitespace character', () {
      expect('a b c'.removeWhiteSpaces, 'abc');
      expect('Line 1\tLine 2'.removeWhiteSpaces, 'Line1Line2');
    });

    test('clean combines both', () {
      expect('a b\nc'.clean, 'abc');
    });

    test('nullable variants pass null through', () {
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

    test('normalizeWhitespace collapses and trims', () {
      expect('  Line   1 \n Line 2  '.normalizeWhitespace(), 'Line 1 Line 2');
      expect('   \n\t  '.normalizeWhitespace(), '');
      expect(''.normalizeWhitespace(), '');
    });
  });

  group('splitting', () {
    test('words splits on whitespace runs', () {
      expect('Hello World'.words, ['Hello', 'World']);
      expect('  Hello   World  '.words, ['Hello', 'World']);
      expect('Hello\nWorld'.words, ['Hello', 'World']);
    });

    test('words returns empty for blank input', () {
      expect(''.words, isEmpty);
      expect('   '.words, isEmpty);
    });

    test('lines handles both LF and CRLF', () {
      expect('Line 1\nLine 2'.lines, ['Line 1', 'Line 2']);
      expect('Line 1\r\nLine 2'.lines, ['Line 1', 'Line 2']);
    });

    test('lines on empty input yields one empty line', () {
      expect(''.lines, ['']);
    });
  });

  group('toCharArray', () {
    test('splits into code units', () {
      expect('abc'.toCharArray(), ['a', 'b', 'c']);
    });

    test('blank and null yield an empty list', () {
      expect(''.toCharArray(), isEmpty);
      expect('   '.toCharArray(), isEmpty);
      expect((null as String?).toCharArray(), isEmpty);
    });
  });

  group('insert', () {
    test('inserts at an interior index', () {
      expect('abc'.insert(1, 'Z'), 'aZbc');
    });

    test('inserts at both boundaries', () {
      expect('abc'.insert(0, 'Z'), 'Zabc');
      expect('abc'.insert(3, 'Z'), 'abcZ');
    });

    test('treats null as empty', () {
      expect((null as String?).insert(0, 'x'), 'x');
    });

    test('rejects an out-of-range index', () {
      expect(() => 'abc'.insert(4, 'Z'), throwsRangeError);
      expect(() => 'abc'.insert(-1, 'Z'), throwsRangeError);
    });
  });

  group('equalsIgnoreCase', () {
    test('compares case-insensitively', () {
      expect('Hello'.equalsIgnoreCase('hello'), isTrue);
      expect('Hello'.equalsIgnoreCase('world'), isFalse);
    });

    test('two nulls are equal, one null is not', () {
      expect((null as String?).equalsIgnoreCase(null), isTrue);
      expect('A'.equalsIgnoreCase(null), isFalse);
      expect((null as String?).equalsIgnoreCase('A'), isFalse);
    });
  });

  group('removeSurrounding', () {
    test('strips only when present at both ends', () {
      expect('"value"'.removeSurrounding('"'), 'value');
      expect('value'.removeSurrounding('"'), 'value');
      expect('"value'.removeSurrounding('"'), '"value');
    });

    test('null passes through', () {
      expect((null as String?).removeSurrounding('"'), isNull);
    });
  });

  group('replaceAfter / replaceBefore', () {
    test('replaces around the first delimiter', () {
      expect('foo=bar'.replaceAfter('=', 'baz'), 'foo=baz');
      expect('foo=bar'.replaceBefore('=', 'baz'), 'baz=bar');
    });

    test('falls back when the delimiter is missing', () {
      expect('foo'.replaceAfter(':', 'x', 'fallback'), 'fallback');
      expect('foo'.replaceBefore(':', 'x', 'fallback'), 'fallback');
      expect('foo'.replaceAfter(':', 'x'), 'foo');
      expect('foo'.replaceBefore(':', 'x'), 'foo');
    });

    test('null passes through', () {
      expect((null as String?).replaceAfter('=', 'x'), isNull);
      expect((null as String?).replaceBefore('=', 'x'), isNull);
    });
  });

  group('truncate', () {
    test('shortens and appends the suffix', () {
      expect('Hello World'.truncate(5), 'Hello...');
      expect('Hello World'.truncate(5, suffix: '!'), 'Hello!');
    });

    test('leaves short-enough strings alone', () {
      expect('Hello'.truncate(10), 'Hello');
      expect('Hello'.truncate(5), 'Hello');
    });

    test('non-positive length yields empty, null yields null', () {
      expect('abc'.truncate(0), '');
      expect('abc'.truncate(-1), '');
      expect((null as String?).truncate(3), isNull);
    });
  });

  group('mask', () {
    test('keeps the requested edges visible', () {
      expect('1234567890'.mask(visibleStart: 2, visibleEnd: 2), '12******90');
      expect('12345'.mask(visibleStart: 1), '1****');
      expect('12345'.mask(), '*****');
    });

    test('supports a custom mask character', () {
      expect('12345'.mask(visibleStart: 1, char: '#'), '1####');
    });

    test('returns the input when it is too short to mask', () {
      expect('123'.mask(visibleStart: 2, visibleEnd: 2), '123');
      expect('ab'.mask(visibleStart: 5), 'ab');
    });

    test('null yields the empty string', () {
      expect((null as String?).mask(), '');
    });

    test('rejects negative bounds', () {
      expect(() => 'abc'.mask(visibleStart: -1), throwsArgumentError);
      expect(() => 'abc'.mask(visibleEnd: -1), throwsArgumentError);
    });
  });
}
