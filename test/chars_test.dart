import 'package:stringo/src/chars.dart';
import 'package:test/test.dart';

void main() {
  group('isWhitespaceUnit', () {
    test('matches exactly the ECMAScript \\s set', () {
      const expected = <int>{
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0xA0, 0x1680, //
        0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006,
        0x2007, 0x2008, 0x2009, 0x200A,
        0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF,
      };
      for (var c = 0; c <= 0xFFFF; c++) {
        expect(
          isWhitespaceUnit(c),
          expected.contains(c),
          reason: 'U+${c.toRadixString(16).toUpperCase()}',
        );
      }
    });

    test('agrees with the v1 regex across the whole BMP', () {
      // The guarantee that matters: the hand-written predicate must be
      // indistinguishable from the RegExp(r'\s') that 1.0.0 relied on.
      final re = RegExp(r'^\s$');
      for (var c = 0; c <= 0xFFFF; c++) {
        expect(
          isWhitespaceUnit(c),
          re.hasMatch(String.fromCharCode(c)),
          reason: 'U+${c.toRadixString(16).toUpperCase()}',
        );
      }
    });
  });

  group('ascii classes', () {
    test('isAsciiLower covers a-z and nothing adjacent', () {
      expect(isAsciiLower(0x61), isTrue);
      expect(isAsciiLower(0x7A), isTrue);
      expect(isAsciiLower(0x60), isFalse);
      expect(isAsciiLower(0x7B), isFalse);
    });

    test('isAsciiUpper covers A-Z and nothing adjacent', () {
      expect(isAsciiUpper(0x41), isTrue);
      expect(isAsciiUpper(0x5A), isTrue);
      expect(isAsciiUpper(0x40), isFalse);
      expect(isAsciiUpper(0x5B), isFalse);
    });

    test('isAsciiDigit covers 0-9 and nothing adjacent', () {
      expect(isAsciiDigit(0x30), isTrue);
      expect(isAsciiDigit(0x39), isTrue);
      expect(isAsciiDigit(0x2F), isFalse);
      expect(isAsciiDigit(0x3A), isFalse);
    });

    test('isAsciiLetter covers both cases only', () {
      expect(isAsciiLetter(0x41), isTrue);
      expect(isAsciiLetter(0x61), isTrue);
      expect(isAsciiLetter(0x30), isFalse);
    });

    test('isWordSeparator covers underscore, hyphen, and whitespace', () {
      expect(isWordSeparator(0x5F), isTrue);
      expect(isWordSeparator(0x2D), isTrue);
      expect(isWordSeparator(0x20), isTrue);
      expect(isWordSeparator(0x09), isTrue);
      expect(isWordSeparator(0xA0), isTrue);
      expect(isWordSeparator(0x61), isFalse);
      expect(isWordSeparator(0x30), isFalse);
    });
  });

  group('ascii case mapping', () {
    test('toAsciiLower and toAsciiUpper only touch ASCII letters', () {
      expect(toAsciiLower(0x41), 0x61);
      expect(toAsciiLower(0x61), 0x61);
      expect(toAsciiLower(0x30), 0x30);
      expect(toAsciiLower(0xC9), 0xC9); // E-acute must stay untouched
      expect(toAsciiUpper(0x61), 0x41);
      expect(toAsciiUpper(0x41), 0x41);
      expect(toAsciiUpper(0xE9), 0xE9); // e-acute must stay untouched
    });
  });

  group('isAsciiString', () {
    test('true for pure ascii including the empty string', () {
      expect(isAsciiString(''), isTrue);
      expect(isAsciiString('hello_world-123'), isTrue);
      expect(
        isAsciiString(String.fromCharCode(0x7F)),
        isTrue,
        reason: '0x7F is still ASCII',
      );
    });

    test('false as soon as any unit reaches 0x80', () {
      expect(
        isAsciiString(String.fromCharCode(0x80)),
        isFalse,
        reason: '0x80 is the boundary',
      );
      expect(isAsciiString('café'), isFalse, reason: 'e-acute');
      expect(isAsciiString('a\u{1F600}b'), isFalse, reason: 'surrogate pair');
      expect(isAsciiString('a\u{00A0}b'), isFalse, reason: 'NBSP');
    });
  });
}
