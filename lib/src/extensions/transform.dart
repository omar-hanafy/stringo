/// Transformation extensions.
library;

import 'package:stringo/src/core.dart';
import 'package:stringo/src/ops/transform.dart' show validateMaskBounds;

/// Transformations that produce a new string from an existing one.
///
/// Each member delegates to the matching [Stringo] function.
extension StringTransformExtensions on String {
  /// Returns `null` when this string is empty, otherwise the string itself.
  ///
  /// Only a zero-length string counts as empty here; use [nullIfBlank] to
  /// treat whitespace-only strings as empty too.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Returns `null` when this string is empty or whitespace-only, otherwise
  /// the string itself.
  String? get nullIfBlank => Stringo.isBlank(this) ? null : this;

  /// Collapses runs of blank lines into a single newline.
  ///
  /// Example: `'Line1\n\n\nLine2'` becomes `'Line1\nLine2'`.
  String get removeEmptyLines => Stringo.removeEmptyLines(this);

  /// Removes every newline character, joining the text onto one line.
  ///
  /// Note that this joins without inserting a separator:
  /// `'Line1\nLine2'` becomes `'Line1Line2'`.
  String get toOneLine => Stringo.oneLine(this);

  /// Removes every whitespace character, including spaces, tabs, and newlines.
  ///
  /// Example: `'Line 1\tLine 2'` becomes `'Line1Line2'`.
  String get removeWhiteSpaces => Stringo.removeWhitespace(this);

  /// Removes all whitespace and collapses the text onto a single line.
  ///
  /// Equivalent to [toOneLine] followed by [removeWhiteSpaces].
  String get clean => Stringo.removeWhitespace(this);

  /// Collapses runs of whitespace into single spaces and trims the result.
  ///
  /// Example: `' Line   1 \n Line 2 '` becomes `'Line 1 Line 2'`.
  String normalizeWhitespace() => Stringo.normalizeWhitespace(this);

  /// Splits this string into whitespace-separated words.
  ///
  /// Returns an empty list when the string is empty or whitespace-only. To
  /// split identifiers such as `helloWorld` or `hello_world` into their parts,
  /// use [StringCaseExtensions.toWords] instead.
  List<String> get words => Stringo.splitWhitespace(this);

  /// Splits this string into lines, accepting both `\n` and `\r\n` endings.
  List<String> get lines => Stringo.lines(this);

  /// Converts this string into a URL- and filename-friendly slug.
  ///
  /// Example: `'Hello, World!'` becomes `'hello-world'`.
  ///
  /// The result is lowercased. Hyphens, underscores, and whitespace are all
  /// separator-producing: any run of them collapses to a single [separator],
  /// and separators are trimmed from both ends.
  ///
  /// This is ASCII-only: characters outside `a-z0-9` are dropped rather than
  /// transliterated, so an accented `'Cafe'` becomes `'caf'`. Normalize
  /// accented text before calling this if you need those characters preserved.
  ///
  /// Throws an [ArgumentError] when [separator] is empty.
  String slugify({String separator = '-'}) =>
      Stringo.slugify(this, separator: separator);
}

/// Transformations that tolerate a null receiver.
///
/// Members that transform text follow one rule: a `null` receiver yields
/// `null`. The two exceptions are deliberate and named in their own docs:
/// [orEmpty], whose entire purpose is to remove null, and [toCharArray], which
/// returns an empty list.
extension NullableStringTransformExtensions on String? {
  /// Removes every newline character, or returns `null` when this is `null`.
  String? get toOneLine => this == null ? null : Stringo.oneLine(this!);

  /// Removes every whitespace character, or returns `null` when this is
  /// `null`.
  String? get removeWhiteSpaces =>
      this == null ? null : Stringo.removeWhitespace(this!);

  /// Removes all whitespace and collapses onto one line, or returns `null`
  /// when this is `null`.
  String? get clean => this == null ? null : Stringo.removeWhitespace(this!);

  /// Returns this string, or the empty string when it is `null`.
  String get orEmpty => this ?? '';

  /// Splits this string into its individual Unicode code points.
  ///
  /// Returns an empty list when the string is null or blank.
  ///
  /// Unlike stringo 1.0.0 this never splits a surrogate pair, so a string
  /// holding one emoji yields one element rather than two broken halves. It is
  /// still code points rather than grapheme clusters: a flag emoji or a letter
  /// followed by a combining mark is more than one element. Use
  /// `package:characters` when you need user-perceived characters.
  List<String> toCharArray() =>
      Stringo.isNotBlank(this) ? Stringo.characters(this!) : <String>[];

  /// Returns a new string with [str] inserted at [index], or `null` when this
  /// is `null`.
  ///
  /// Throws a [RangeError] when [index] is outside `0..length`.
  String? insert(int index, String str) =>
      this == null ? null : Stringo.insert(this!, index, str);

  /// Compares this string with [other], ignoring case.
  ///
  /// Two `null` values are considered equal.
  bool equalsIgnoreCase(String? other) => Stringo.equalsIgnoreCase(this, other);

  /// Strips [delimiter] from both ends, but only when it is present at both.
  ///
  /// Returns the string unchanged otherwise, and `null` when this is `null`.
  String? removeSurrounding(String delimiter) =>
      this == null ? null : Stringo.removeSurrounding(this!, delimiter);

  /// Replaces everything after the first [delimiter] with [replacement].
  ///
  /// When [delimiter] is absent, returns [defaultValue] if it is non-blank,
  /// otherwise the original string. Returns `null` when this is `null`.
  String? replaceAfter(
    String delimiter,
    String replacement, [
    String? defaultValue,
  ]) => this == null
      ? null
      : Stringo.replaceAfter(this!, delimiter, replacement, defaultValue);

  /// Replaces everything before the first [delimiter] with [replacement].
  ///
  /// When [delimiter] is absent, returns [defaultValue] if it is non-blank,
  /// otherwise the original string. Returns `null` when this is `null`.
  String? replaceBefore(
    String delimiter,
    String replacement, [
    String? defaultValue,
  ]) => this == null
      ? null
      : Stringo.replaceBefore(this!, delimiter, replacement, defaultValue);

  /// Shortens this string so the result is at most [length] characters,
  /// ending with [suffix].
  ///
  /// Returns the string unchanged when it already fits within [length], the
  /// empty string when [length] is zero or negative, and `null` when this is
  /// `null`.
  ///
  /// The suffix counts against [length] rather than being appended on top of
  /// it, so the result never overshoots. The one exception is a [suffix]
  /// longer than [length], where the result is exactly [suffix].
  String? truncate(int length, {String suffix = '...'}) =>
      this == null ? null : Stringo.truncate(this!, length, suffix: suffix);

  /// Replaces the middle of this string with [char], keeping [visibleStart]
  /// leading and [visibleEnd] trailing characters visible.
  ///
  /// Example: `'1234567890'.mask(visibleStart: 2, visibleEnd: 2)` yields
  /// `'12******90'`.
  ///
  /// Returns the string unchanged when it is too short to mask, and `null`
  /// when this is `null`.
  ///
  /// Throws an [ArgumentError] when [visibleStart] or [visibleEnd] is
  /// negative.
  String? mask({int visibleStart = 0, int visibleEnd = 0, String char = '*'}) {
    // Validated before the null check: a negative bound is a programmer error
    // regardless of whether the receiver happened to be null.
    validateMaskBounds(visibleStart, visibleEnd);
    if (this == null) return null;
    return Stringo.mask(
      this!,
      visibleStart: visibleStart,
      visibleEnd: visibleEnd,
      char: char,
    );
  }
}
