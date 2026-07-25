/// Transformations that produce a new string or a list of parts.
///
/// Everything here is a single linear pass over the input, writing into one
/// [StringBuffer]. There is no [RegExp] in this library: every rule is a hand
/// written scanner, which is both faster and immune to the backtracking
/// blow-ups a pattern can hide.
library;

import 'package:stringo/src/chars.dart';
import 'package:stringo/src/ops/checks.dart';

/// Whether [c] is a space or a tab, the only characters a blank line may hold.
@pragma('vm:prefer-inline')
bool _isSpaceOrTab(int c) => c == 0x20 || c == 0x09;

/// Consumes a line terminator at [i], returning the index after it, or [i]
/// itself when there is none. Accepts `\r\n`, `\r`, and `\n`.
@pragma('vm:prefer-inline')
int _skipLineBreak(String s, int i, int n) {
  if (i >= n) return i;
  final c = s.codeUnitAt(i);
  if (c == 0x0D) {
    return (i + 1 < n && s.codeUnitAt(i + 1) == 0x0A) ? i + 2 : i + 1;
  }
  return c == 0x0A ? i + 1 : i;
}

/// Collapses runs of blank lines into a single newline.
///
/// Example: `'Line1\n\n\nLine2'` becomes `'Line1\nLine2'`.
///
/// A "blank line" is any run of spaces and tabs terminated by `\r\n`, `\r`, or
/// `\n`; one or more consecutive such lines collapse to a single `\n`.
///
/// This was a regex in 1.0.0. The pattern `(?:[\t ]*(?:\r?\n|\r))+` is
/// catastrophically backtracking: at every position inside a run of spaces the
/// engine consumed the whole run, then gave characters back one at a time
/// looking for a line break that was not there. That made it quadratic in the
/// length of any whitespace run NOT ending in a newline, so a 20 KB run of
/// spaces took about 7 seconds. This scanner is linear and never backtracks.
String removeEmptyLines(String s) {
  final n = s.length;
  final buffer = StringBuffer();
  var i = 0;
  while (i < n) {
    // Try to consume one or more blank lines starting here.
    var cursor = i;
    var linesMatched = 0;
    var deadEnd = i;
    while (true) {
      var probe = cursor;
      while (probe < n && _isSpaceOrTab(s.codeUnitAt(probe))) {
        probe++;
      }
      final afterBreak = _skipLineBreak(s, probe, n);
      if (afterBreak == probe) {
        // The spaces from cursor to probe are ordinary content, not a blank
        // line, because nothing terminates them.
        deadEnd = probe;
        break;
      }
      cursor = afterBreak;
      linesMatched++;
    }
    if (linesMatched > 0) {
      buffer.writeCharCode(0x0A);
      i = cursor;
      continue;
    }
    // Emit the whole unterminated run at once and jump past it. Advancing by
    // a single character here would re-probe the same run from every position
    // inside it, which is precisely what made the old regex quadratic. If a
    // run starting at i has no line break after it, no run starting further
    // inside it can have one either, so there is nothing to reconsider.
    if (deadEnd > i) {
      for (var k = i; k < deadEnd; k++) {
        buffer.writeCharCode(s.codeUnitAt(k));
      }
      i = deadEnd;
    } else {
      buffer.writeCharCode(s.codeUnitAt(i));
      i++;
    }
  }
  return buffer.toString();
}

/// Removes every newline character, joining the text onto one line.
///
/// Note that this joins without inserting a separator, so `'Line1\nLine2'`
/// becomes `'Line1Line2'`.
String oneLine(String s) {
  if (!s.contains('\n')) return s;
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c != 0x0A) buffer.writeCharCode(c);
  }
  return buffer.toString();
}

/// Removes every whitespace character, including spaces, tabs, and newlines.
///
/// Example: `'Line 1\tLine 2'` becomes `'Line1Line2'`.
String removeWhitespace(String s) {
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (!isWhitespaceUnit(c)) buffer.writeCharCode(c);
  }
  return buffer.toString();
}

/// Collapses runs of whitespace into single spaces and trims the result.
///
/// Example: `' Line   1 \n Line 2 '` becomes `'Line 1 Line 2'`.
///
/// The leading and trailing trim uses [String.trim], matching what stringo
/// 1.0.0 did. That set differs very slightly from the interior collapse rule:
/// `U+0085` is trimmed at the edges but is not treated as an interior
/// whitespace run, exactly as before.
String normalizeWhitespace(String s) {
  final trimmed = s.trim();
  final buffer = StringBuffer();
  var pendingSpace = false;
  for (var i = 0; i < trimmed.length; i++) {
    final c = trimmed.codeUnitAt(i);
    if (isWhitespaceUnit(c)) {
      pendingSpace = true;
      continue;
    }
    if (pendingSpace) {
      buffer.writeCharCode(0x20);
      pendingSpace = false;
    }
    buffer.writeCharCode(c);
  }
  return buffer.toString();
}

/// Splits [s] into whitespace-separated words.
///
/// Returns an empty list when [s] is empty or whitespace-only. To split
/// identifiers such as `helloWorld` into their parts, use the word scanner
/// instead.
List<String> splitWhitespace(String s) {
  final trimmed = s.trim();
  if (trimmed.isEmpty) return <String>[];
  final out = <String>[];
  var start = 0;
  var inWord = false;
  for (var i = 0; i < trimmed.length; i++) {
    if (isWhitespaceUnit(trimmed.codeUnitAt(i))) {
      if (inWord) {
        out.add(trimmed.substring(start, i));
        inWord = false;
      }
    } else if (!inWord) {
      start = i;
      inWord = true;
    }
  }
  if (inWord) out.add(trimmed.substring(start));
  return out;
}

/// Splits [s] into lines, accepting both `\n` and `\r\n` endings.
///
/// A lone carriage return is not a line ending, matching stringo 1.0.0.
List<String> lines(String s) {
  final out = <String>[];
  var start = 0;
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) == 0x0A) {
      var end = i;
      if (end > start && s.codeUnitAt(end - 1) == 0x0D) end--;
      out.add(s.substring(start, end));
      start = i + 1;
    }
  }
  out.add(s.substring(start));
  return out;
}

/// Splits [s] into its individual Unicode code points.
///
/// Unlike stringo 1.0.0 this never splits a surrogate pair, so a string
/// holding one emoji yields one element rather than two broken halves.
///
/// This is code points, not grapheme clusters. A flag emoji or a letter
/// followed by a combining mark is still more than one element; use
/// `package:characters` when you need user-perceived characters.
///
/// The returned list is growable, matching every other list this package
/// returns and matching what `split('')` produced in 1.0.0.
List<String> characters(String s) => s.runes.map(String.fromCharCode).toList();

/// Converts [s] into a URL- and filename-friendly slug.
///
/// Example: `'Hello, World!'` becomes `'hello-world'`.
///
/// The text is lowercased. Hyphens, underscores, and whitespace are all
/// separator-producing: any run of them, in any mix, collapses to a single
/// [separator], and separators are trimmed from both ends. Every other
/// character outside `a-z0-9` is dropped.
///
/// This is ASCII-only by design and does not transliterate, so an accented
/// `'Cafe'` becomes `'caf'`. The exception is a character whose Unicode
/// lowercase form is itself ASCII, which survives: the Kelvin sign `U+212A`
/// becomes `'k'`, and a dotted capital I becomes `'i'`. Normalize accented
/// text before calling this if you need the rest preserved.
///
/// [separator] is written verbatim and is NOT itself filtered, so a separator
/// containing characters outside `a-z0-9` produces a result this function
/// would not return to you unchanged if you slugified it again. The operation
/// is idempotent for separators drawn from `a-z0-9`, `-`, and `_`, which
/// covers every conventional slug.
///
/// Throws an [ArgumentError] when [separator] is empty.
String slugify(String s, {String separator = '-'}) {
  if (separator.isEmpty) {
    throw ArgumentError.value(
      separator,
      'separator',
      'Separator must not be empty',
    );
  }
  // Non-ASCII input is lowercased with Dart's full Unicode mapping first, so
  // characters whose lowercase form IS ASCII survive. The Kelvin sign U+212A
  // lowercasing to 'k' is the case that makes this necessary.
  final source = isAsciiString(s) ? s : s.toLowerCase();
  final buffer = StringBuffer();
  var pendingSeparator = false;
  var wroteAny = false;
  for (var i = 0; i < source.length; i++) {
    final c = toAsciiLower(source.codeUnitAt(i));
    if (isAsciiLower(c) || isAsciiDigit(c)) {
      if (pendingSeparator && wroteAny) buffer.write(separator);
      buffer.writeCharCode(c);
      wroteAny = true;
      pendingSeparator = false;
    } else if (isWordSeparator(c)) {
      if (wroteAny) pendingSeparator = true;
    }
    // Everything else is dropped outright.
  }
  return buffer.toString();
}

/// Shortens [s] so the result is at most [length] characters, ending with
/// [suffix].
///
/// Returns [s] unchanged when it already fits, and the empty string when
/// [length] is zero or negative.
///
/// Unlike stringo 1.0.0 the suffix is counted against [length] rather than
/// appended on top of it, so the result never overshoots the limit the caller
/// asked for. The one exception is a [suffix] longer than [length], where no
/// shorter answer keeps the suffix intact and the result is exactly [suffix].
String truncate(String s, int length, {String suffix = '...'}) {
  if (length <= 0) return '';
  if (s.length <= length) return s;
  final keep = length - suffix.length;
  if (keep <= 0) return suffix;
  return '${s.substring(0, keep)}$suffix';
}

/// Validates the visibility bounds shared by every `mask` entry point.
///
/// This is separate from [mask] itself so the nullable extension can reject a
/// negative bound before it decides what to do about a null receiver. Argument
/// validation is a programmer-error check and must not depend on whether the
/// receiver happened to be null.
///
/// Throws an [ArgumentError] when either bound is negative.
void validateMaskBounds(int visibleStart, int visibleEnd) {
  if (visibleStart < 0) {
    throw ArgumentError.value(
      visibleStart,
      'visibleStart',
      'Must not be negative',
    );
  }
  if (visibleEnd < 0) {
    throw ArgumentError.value(visibleEnd, 'visibleEnd', 'Must not be negative');
  }
}

/// Replaces the middle of [s] with [char], keeping [visibleStart] leading and
/// [visibleEnd] trailing characters visible.
///
/// Example: `mask('1234567890', visibleStart: 2, visibleEnd: 2)` yields
/// `'12******90'`.
///
/// Returns [s] unchanged when it is too short to mask.
///
/// Throws an [ArgumentError] when [visibleStart] or [visibleEnd] is negative.
String mask(
  String s, {
  int visibleStart = 0,
  int visibleEnd = 0,
  String char = '*',
}) {
  validateMaskBounds(visibleStart, visibleEnd);
  if (s.length <= visibleStart + visibleEnd) return s;
  return s.substring(0, visibleStart) +
      char * (s.length - visibleStart - visibleEnd) +
      s.substring(s.length - visibleEnd);
}

/// Returns a new string with [value] inserted at [index].
///
/// Throws a [RangeError] when [index] is outside `0..s.length`.
String insert(String s, int index, String value) {
  RangeError.checkValueInInterval(index, 0, s.length, 'index');
  return s.substring(0, index) + value + s.substring(index);
}

/// Strips [delimiter] from both ends of [s], but only when it is present at
/// both.
///
/// Returns [s] unchanged otherwise.
String removeSurrounding(String s, String delimiter) {
  if (s.length >= delimiter.length * 2 &&
      s.startsWith(delimiter) &&
      s.endsWith(delimiter)) {
    return s.substring(delimiter.length, s.length - delimiter.length);
  }
  return s;
}

/// Replaces everything after the first [delimiter] in [s] with [replacement].
///
/// When [delimiter] is absent, returns [defaultValue] if it is non-blank,
/// otherwise [s].
String replaceAfter(
  String s,
  String delimiter,
  String replacement, [
  String? defaultValue,
]) {
  final index = s.indexOf(delimiter);
  if (index == -1) return isBlank(defaultValue) ? s : defaultValue!;
  return s.replaceRange(index + delimiter.length, s.length, replacement);
}

/// Replaces everything before the first [delimiter] in [s] with [replacement].
///
/// When [delimiter] is absent, returns [defaultValue] if it is non-blank,
/// otherwise [s].
String replaceBefore(
  String s,
  String delimiter,
  String replacement, [
  String? defaultValue,
]) {
  final index = s.indexOf(delimiter);
  if (index == -1) return isBlank(defaultValue) ? s : defaultValue!;
  return s.replaceRange(0, index, replacement);
}
