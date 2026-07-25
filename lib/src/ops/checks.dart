/// Predicates that inspect the characters of a string.
///
/// These answer questions about the text itself: is it blank, is it all
/// digits, does it contain a capital letter. They deliberately do not answer
/// questions about real-world formats such as "is this a valid email
/// address", which have no single correct answer and belong in the layer that
/// owns the rule.
///
/// Every predicate here is either a direct scan or a lookup against a
/// precompiled pattern. None of them allocate a copy of the input, and none
/// construct a [RegExp].
library;

import 'package:stringo/src/chars.dart';
import 'package:stringo/src/patterns.dart';

/// Whether [s] is null, empty, or made up solely of whitespace.
///
/// This is a scan that returns at the first non-whitespace code unit, so it
/// costs the same on a ten character string and a ten megabyte one.
///
/// stringo 1.0.0 answered this by allocating two whole-string copies and
/// compiling a regex, which made a blank check on a 100 KB payload cost
/// milliseconds. Keep this a scan.
bool isBlank(String? s) {
  if (s == null) return true;
  for (var i = 0; i < s.length; i++) {
    if (!isWhitespaceUnit(s.codeUnitAt(i))) return false;
  }
  return true;
}

/// Whether [s] is non-null and holds at least one non-whitespace character.
bool isNotBlank(String? s) => !isBlank(s);

/// Whether [s] contains only ASCII letters and digits.
///
/// Returns `false` for null and for the empty string.
bool isAlphanumeric(String? s) => s != null && patternAlphanumeric.hasMatch(s);

/// Whether [s] starts with an ASCII digit.
bool startsWithNumber(String? s) =>
    s != null && s.isNotEmpty && isAsciiDigit(s.codeUnitAt(0));

/// Whether [s] contains at least one ASCII digit.
bool containsDigits(String? s) {
  if (s == null) return false;
  for (var i = 0; i < s.length; i++) {
    if (isAsciiDigit(s.codeUnitAt(i))) return true;
  }
  return false;
}

/// Whether [s] contains at least one uppercase ASCII letter.
bool hasCapitalLetter(String? s) {
  if (s == null) return false;
  for (var i = 0; i < s.length; i++) {
    if (isAsciiUpper(s.codeUnitAt(i))) return true;
  }
  return false;
}

/// Whether [s] consists only of ASCII digits, with no sign and no decimal
/// point.
///
/// Surrounding whitespace is ignored. This is a character check, not a parser:
/// use a conversion package if you need the numeric value.
bool isNumeric(String? s) => s != null && patternNumeric.hasMatch(s.trim());

/// Whether [s] consists only of ASCII letters, `A-Z` and `a-z`.
///
/// Surrounding whitespace is ignored.
bool isAlphabet(String? s) => s != null && patternAlphabet.hasMatch(s.trim());

/// Compares [a] and [b] ignoring case.
///
/// Two `null` values are considered equal.
bool equalsIgnoreCase(String? a, String? b) {
  if (a == null || b == null) return a == null && b == null;
  if (identical(a, b)) return true;
  if (a.length == b.length) {
    // Fast path: for equal-length ASCII the comparison needs no allocation.
    var asciiOnly = true;
    for (var i = 0; i < a.length; i++) {
      final ca = a.codeUnitAt(i);
      final cb = b.codeUnitAt(i);
      if (ca >= 0x80 || cb >= 0x80) {
        asciiOnly = false;
        break;
      }
      if (toAsciiLower(ca) != toAsciiLower(cb)) return false;
    }
    if (asciiOnly) return true;
  }
  return a.toLowerCase() == b.toLowerCase();
}

/// Whether [pattern] matches anywhere in [s].
///
/// Returns `false` when [s] is null. The optional flags map directly onto the
/// matching [RegExp] constructor arguments.
///
/// This compiles [pattern] on every call, because it accepts arbitrary
/// caller-supplied source. In a hot loop, hoist a `RegExp` yourself and call
/// [RegExp.hasMatch] directly, or use one of the precompiled `pattern*`
/// objects this package exports.
///
// regex-policy-exempt: the pattern is supplied by the caller at call time, so
// per-call compilation is inherent to the signature rather than an oversight.
// Every pattern this package owns is precompiled in patterns.dart instead.
bool hasMatch(
  String? s,
  String pattern, {
  bool multiLine = false,
  bool caseSensitive = true,
  bool unicode = false,
  bool dotAll = false,
}) =>
    s != null &&
    RegExp(
      pattern,
      caseSensitive: caseSensitive,
      multiLine: multiLine,
      unicode: unicode,
      dotAll: dotAll,
    ).hasMatch(s);
