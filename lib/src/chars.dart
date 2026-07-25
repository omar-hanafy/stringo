/// Code-unit classification primitives shared by the scanner and the ops.
///
/// Every predicate here operates on a single UTF-16 code unit, never on a
/// character or grapheme cluster, and none of them allocate. They exist so the
/// rest of the package can classify text without constructing a [RegExp].
library;

/// Whether [codeUnit] is whitespace under the ECMAScript `\s` definition.
///
/// This is deliberately the exact set that stringo 1.0.0 matched through
/// `RegExp(r'\s')`: the ASCII controls `\t \n \v \f \r`, the space, and the
/// Unicode space separators including NBSP, the `U+2000` block, the line and
/// paragraph separators, and the byte order mark.
///
/// Keeping this set identical is load-bearing. Narrowing it to ASCII would
/// silently change how blank detection and word splitting behave on text that
/// uses non-breaking or ideographic spaces.
@pragma('vm:prefer-inline')
bool isWhitespaceUnit(int codeUnit) {
  if (codeUnit == 0x20) return true;
  if (codeUnit < 0x09) return false;
  if (codeUnit <= 0x0D) return true;
  if (codeUnit < 0xA0) return false;
  if (codeUnit == 0xA0 || codeUnit == 0x1680) return true;
  if (codeUnit >= 0x2000 && codeUnit <= 0x200A) return true;
  return codeUnit == 0x2028 ||
      codeUnit == 0x2029 ||
      codeUnit == 0x202F ||
      codeUnit == 0x205F ||
      codeUnit == 0x3000 ||
      codeUnit == 0xFEFF;
}

/// Whether [codeUnit] is an ASCII lowercase letter, `a` through `z`.
@pragma('vm:prefer-inline')
bool isAsciiLower(int codeUnit) => codeUnit >= 0x61 && codeUnit <= 0x7A;

/// Whether [codeUnit] is an ASCII uppercase letter, `A` through `Z`.
@pragma('vm:prefer-inline')
bool isAsciiUpper(int codeUnit) => codeUnit >= 0x41 && codeUnit <= 0x5A;

/// Whether [codeUnit] is an ASCII digit, `0` through `9`.
@pragma('vm:prefer-inline')
bool isAsciiDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

/// Whether [codeUnit] is an ASCII letter in either case.
@pragma('vm:prefer-inline')
bool isAsciiLetter(int codeUnit) =>
    isAsciiLower(codeUnit) || isAsciiUpper(codeUnit);

/// Whether [codeUnit] separates words: an underscore, a hyphen, or whitespace.
@pragma('vm:prefer-inline')
bool isWordSeparator(int codeUnit) =>
    codeUnit == 0x5F || codeUnit == 0x2D || isWhitespaceUnit(codeUnit);

/// The ASCII lowercase form of [codeUnit], or [codeUnit] itself.
@pragma('vm:prefer-inline')
int toAsciiLower(int codeUnit) =>
    isAsciiUpper(codeUnit) ? codeUnit + 32 : codeUnit;

/// The ASCII uppercase form of [codeUnit], or [codeUnit] itself.
@pragma('vm:prefer-inline')
int toAsciiUpper(int codeUnit) =>
    isAsciiLower(codeUnit) ? codeUnit - 32 : codeUnit;

/// Whether every code unit in [s] is ASCII, meaning below `U+0080`.
///
/// Callers use this to choose between inline ASCII case mapping and Dart's
/// native Unicode casing. It is a linear scan with no allocation, and it short
/// circuits on the first non-ASCII unit.
bool isAsciiString(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) >= 0x80) return false;
  }
  return true;
}
