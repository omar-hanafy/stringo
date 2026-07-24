import 'package:stringo/stringo.dart';

/// Transformations that produce a new string (or a view of it) from an
/// existing one.
extension StringTransformExtensions on String {
  /// Returns `null` when this string is empty, otherwise the string itself.
  ///
  /// Only a zero-length string counts as empty here; use [nullIfBlank] to
  /// treat whitespace-only strings as empty too.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Returns `null` when this string is empty or whitespace-only, otherwise
  /// the string itself.
  String? get nullIfBlank => isBlank ? null : this;

  /// Collapses runs of blank lines into a single newline.
  ///
  /// Example: `"Line1\n\n\nLine2"` becomes `"Line1\nLine2"`.
  String get removeEmptyLines =>
      replaceAll(RegExp(r'(?:[\t ]*(?:\r?\n|\r))+'), '\n');

  /// Removes every newline character, joining the text onto one line.
  ///
  /// Note that this joins without inserting a separator:
  /// `"Line1\nLine2"` becomes `"Line1Line2"`.
  String get toOneLine => replaceAll('\n', '');

  /// Removes every whitespace character (spaces, tabs, newlines).
  ///
  /// Example: `"Line 1\tLine 2"` becomes `"Line1Line2"`.
  String get removeWhiteSpaces => replaceAll(RegExp(r'\s+'), '');

  /// Removes all whitespace and collapses the text onto a single line.
  ///
  /// Equivalent to [toOneLine] followed by [removeWhiteSpaces].
  String get clean => toOneLine.removeWhiteSpaces;

  /// Collapses runs of whitespace into single spaces and trims the result.
  ///
  /// Example: `" Line   1 \n Line 2 "` becomes `"Line 1 Line 2"`.
  String normalizeWhitespace() => trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Splits this string into whitespace-separated words.
  ///
  /// Returns an empty list when the string is empty or whitespace-only. To
  /// split identifiers such as `helloWorld` or `hello_world` into their parts,
  /// use [StringCaseExtensions.toWords] instead.
  List<String> get words {
    final normalized = normalizeWhitespace();
    return normalized.isEmpty ? [] : normalized.split(' ');
  }

  /// Splits this string into lines, accepting both `\n` and `\r\n` endings.
  List<String> get lines => split(RegExp(r'\r?\n'));

  /// Converts this string into a URL- and filename-friendly slug.
  ///
  /// Example: `"Hello, World!"` becomes `"hello-world"`.
  ///
  /// The result is lowercased; whitespace and underscores become [separator];
  /// repeated separators are collapsed and trimmed from both ends.
  ///
  /// This is ASCII-only: characters outside `a-z0-9` are dropped rather than
  /// transliterated, so `"Café"` becomes `"caf"`. Normalize accented text
  /// before calling this if you need those characters preserved.
  ///
  /// Throws an [ArgumentError] when [separator] is empty.
  String slugify({String separator = '-'}) {
    if (separator.isEmpty) {
      throw ArgumentError.value(
        separator,
        'separator',
        'Separator must not be empty',
      );
    }

    final normalized = normalizeWhitespace().toLowerCase();
    if (normalized.isEmpty) return '';

    final escapedSeparator = RegExp.escape(separator);
    final cleaned = normalized
        .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
        .replaceAll(RegExp(r'[_\s]+'), separator)
        .replaceAll(RegExp('$escapedSeparator+'), separator)
        .replaceAll(RegExp('^$escapedSeparator|$escapedSeparator\$'), '');

    return cleaned;
  }
}

/// Transformations that tolerate a null receiver.
extension NullableStringTransformExtensions on String? {
  /// Removes every newline character, or returns `null` when this is `null`.
  String? get toOneLine => this?.replaceAll('\n', '');

  /// Removes every whitespace character, or returns `null` when this is
  /// `null`.
  String? get removeWhiteSpaces => this?.replaceAll(RegExp(r'\s+'), '');

  /// Removes all whitespace and collapses onto one line, or returns `null`
  /// when this is `null`.
  String? get clean => toOneLine?.removeWhiteSpaces;

  /// Returns this string, or the empty string when it is `null`.
  String get orEmpty => this ?? '';

  /// Splits this string into its individual UTF-16 code units as strings.
  ///
  /// Returns an empty list when the string is null or blank.
  ///
  /// This splits by code unit, not by user-perceived character, so text
  /// containing emoji or other characters outside the Basic Multilingual
  /// Plane will be split mid-character. Use `package:characters` when you
  /// need grapheme-cluster correctness.
  List<String> toCharArray() => isNotBlank ? this!.split('') : [];

  /// Returns a new string with [str] inserted at [index].
  ///
  /// A `null` receiver is treated as the empty string, so inserting at index
  /// `0` yields [str].
  ///
  /// Throws a [RangeError] when [index] is outside `0..length`.
  String insert(int index, String str) {
    final value = this ?? '';
    RangeError.checkValueInInterval(index, 0, value.length, 'index');
    return value.substring(0, index) + str + value.substring(index);
  }

  /// Compares this string with [other], ignoring case.
  ///
  /// Two `null` values are considered equal.
  bool equalsIgnoreCase(String? other) =>
      (this == null && other == null) ||
      (this != null &&
          other != null &&
          this!.toLowerCase() == other.toLowerCase());

  /// Strips [delimiter] from both ends, but only when it is present at both.
  ///
  /// Returns the string unchanged otherwise, and `null` when this is `null`.
  String? removeSurrounding(String delimiter) {
    if (this == null) return null;
    final prefix = delimiter;
    final suffix = delimiter;

    if ((this!.length >= prefix.length + suffix.length) &&
        this!.startsWith(prefix) &&
        this!.endsWith(suffix)) {
      return this!.substring(prefix.length, this!.length - suffix.length);
    }
    return this;
  }

  /// Replaces everything after the first [delimiter] with [replacement].
  ///
  /// When [delimiter] is absent, returns [defaultValue] if it is non-blank,
  /// otherwise the original string. Returns `null` when this is `null`.
  String? replaceAfter(
    String delimiter,
    String replacement, [
    String? defaultValue,
  ]) {
    if (this == null) return null;
    final index = this!.indexOf(delimiter);
    return (index == -1)
        ? defaultValue.isEmptyOrNull
              ? this
              : defaultValue
        : this!.replaceRange(
            index + delimiter.length,
            this!.length,
            replacement,
          );
  }

  /// Replaces everything before the first [delimiter] with [replacement].
  ///
  /// When [delimiter] is absent, returns [defaultValue] if it is non-blank,
  /// otherwise the original string. Returns `null` when this is `null`.
  String? replaceBefore(
    String delimiter,
    String replacement, [
    String? defaultValue,
  ]) {
    if (this == null) return null;
    final index = this!.indexOf(delimiter);
    return (index == -1)
        ? defaultValue.isEmptyOrNull
              ? this
              : defaultValue
        : this!.replaceRange(0, index, replacement);
  }

  /// Shortens this string to [length] characters and appends [suffix].
  ///
  /// Returns the string unchanged when it already fits within [length], the
  /// empty string when [length] is zero or negative, and `null` when this is
  /// `null`.
  ///
  /// Note that the result can be longer than [length] because [suffix] is
  /// appended after truncating.
  String? truncate(int length, {String suffix = '...'}) {
    if (this == null) return null;
    if (length <= 0) return '';
    if (this!.length <= length) return this;
    return '${this!.substring(0, length)}$suffix';
  }

  /// Replaces the middle of this string with [char], keeping [visibleStart]
  /// leading and [visibleEnd] trailing characters visible.
  ///
  /// Example: `'1234567890'.mask(visibleStart: 2, visibleEnd: 2)` yields
  /// `'12******90'`.
  ///
  /// Returns the string unchanged when it is too short to mask, and the empty
  /// string when this is `null`.
  ///
  /// Throws an [ArgumentError] when [visibleStart] or [visibleEnd] is
  /// negative.
  String mask({int visibleStart = 0, int visibleEnd = 0, String char = '*'}) {
    if (visibleStart < 0) {
      throw ArgumentError.value(
        visibleStart,
        'visibleStart',
        'Must not be negative',
      );
    }
    if (visibleEnd < 0) {
      throw ArgumentError.value(
        visibleEnd,
        'visibleEnd',
        'Must not be negative',
      );
    }
    if (this == null) return '';
    if (this!.length <= visibleStart + visibleEnd) return this!;
    return this!.substring(0, visibleStart) +
        (char * (this!.length - visibleStart - visibleEnd)) +
        this!.substring(this!.length - visibleEnd);
  }
}
