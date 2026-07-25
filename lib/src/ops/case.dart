/// Case conversion implementations.
///
/// Every conversion here streams words out of [scanWords] straight into a
/// single [StringBuffer]. Nothing builds an intermediate word list, and
/// nothing allocates a per-word substring on the ASCII path.
///
/// ## The ASCII fast path
///
/// Case mapping is done inline on code units when the whole input is ASCII,
/// and delegated to Dart's native [String.toLowerCase] and
/// [String.toUpperCase] otherwise. The fallback is not optional: Dart's casing
/// is full Unicode, so `'ECOLE'` with accents lowercases to `'ecole'` with
/// accents, and an ASCII-only implementation would silently corrupt any text
/// that is not plain English.
library;

import 'package:stringo/src/chars.dart';
import 'package:stringo/src/title_case_exceptions.dart';
import 'package:stringo/src/word_scanner.dart';

/// Sentinel for "join these words with nothing between them".
const int _noSeparator = -1;

const int _underscore = 0x5F;
const int _hyphen = 0x2D;
const int _dot = 0x2E;
const int _space = 0x20;

/// How a single word should be cased when written out.
enum _WordCase {
  /// Every character lowercased.
  lower,

  /// Every character uppercased.
  upper,

  /// First character uppercased, the rest lowercased.
  capitalize,
}

void _writeWordAscii(
  StringBuffer buffer,
  String s,
  int start,
  int end,
  _WordCase mode,
) {
  switch (mode) {
    case _WordCase.lower:
      for (var i = start; i < end; i++) {
        buffer.writeCharCode(toAsciiLower(s.codeUnitAt(i)));
      }
    case _WordCase.upper:
      for (var i = start; i < end; i++) {
        buffer.writeCharCode(toAsciiUpper(s.codeUnitAt(i)));
      }
    case _WordCase.capitalize:
      buffer.writeCharCode(toAsciiUpper(s.codeUnitAt(start)));
      for (var i = start + 1; i < end; i++) {
        buffer.writeCharCode(toAsciiLower(s.codeUnitAt(i)));
      }
  }
}

String _applyCaseUnicode(String word, _WordCase mode) => switch (mode) {
  _WordCase.lower => word.toLowerCase(),
  _WordCase.upper => word.toUpperCase(),
  _WordCase.capitalize => capitalizeFirstLowerRest(word),
};

/// Streams the words of [s] into one buffer, joined by [separator], casing the
/// first word as [firstCase] and every later word as [restCase].
///
/// [separator] is a single code unit, or [_noSeparator] for none. It is not a
/// `String` on purpose: a `StringBuffer` that receives `writeCharCode` calls
/// interleaved with `write(String)` calls runs about 2.6x slower than one
/// receiving only `writeCharCode`, because the two go through different
/// internal paths. Every separator this package emits is a single ASCII
/// character, so keeping the buffer in one mode is free.
String _convert(
  String s,
  int separator,
  _WordCase firstCase,
  _WordCase restCase,
) {
  final buffer = StringBuffer();
  // The ASCII test is hoisted out of the per-word callback: branching once per
  // string rather than once per word, and it keeps each closure monomorphic.
  //
  // "Is this the first word?" is read from the buffer rather than a counter,
  // because a mutable captured variable is boxed onto the heap in Dart and
  // that box costs an allocation on every conversion. Words are never empty,
  // so an empty buffer means nothing has been written yet.
  if (isAsciiString(s)) {
    scanWords(s, (start, end) {
      final isFirst = buffer.isEmpty;
      if (!isFirst && separator != _noSeparator) {
        buffer.writeCharCode(separator);
      }
      _writeWordAscii(buffer, s, start, end, isFirst ? firstCase : restCase);
    });
  } else {
    scanWords(s, (start, end) {
      final isFirst = buffer.isEmpty;
      if (!isFirst && separator != _noSeparator) {
        buffer.writeCharCode(separator);
      }
      buffer.write(
        _applyCaseUnicode(
          s.substring(start, end),
          isFirst ? firstCase : restCase,
        ),
      );
    });
  }
  return buffer.toString();
}

/// Splits [s] into its component words.
///
/// Recognizes camelCase and PascalCase boundaries, acronym boundaries so that
/// `HTTPServer` splits into `HTTP` and `Server`, plus underscores, hyphens,
/// and whitespace. Never returns an empty element.
List<String> words(String s) => scanWordsToList(s);

/// Converts [s] to `PascalCase`, also known as UpperCamelCase.
String pascalCase(String s) =>
    _convert(s, _noSeparator, _WordCase.capitalize, _WordCase.capitalize);

/// Converts [s] to `camelCase`, also known as dromedaryCase.
String camelCase(String s) =>
    _convert(s, _noSeparator, _WordCase.lower, _WordCase.capitalize);

/// Converts [s] to `snake_case`, also known as snail_case or pothole_case.
String snakeCase(String s) =>
    _convert(s, _underscore, _WordCase.lower, _WordCase.lower);

/// Converts [s] to `kebab-case`, also known as dash-case or spinal-case.
String kebabCase(String s) =>
    _convert(s, _hyphen, _WordCase.lower, _WordCase.lower);

/// Converts [s] to `dot.case`.
String dotCase(String s) => _convert(s, _dot, _WordCase.lower, _WordCase.lower);

/// Converts [s] to `flatcase`.
String flatCase(String s) =>
    _convert(s, _noSeparator, _WordCase.lower, _WordCase.lower);

/// Converts [s] to `SCREAMINGCASE`.
String screamingCase(String s) =>
    _convert(s, _noSeparator, _WordCase.upper, _WordCase.upper);

/// Converts [s] to `SCREAMING_SNAKE_CASE`, also known as CONSTANT_CASE.
String screamingSnakeCase(String s) =>
    _convert(s, _underscore, _WordCase.upper, _WordCase.upper);

/// Converts [s] to `SCREAMING-KEBAB-CASE`, also known as COBOL-CASE.
String screamingKebabCase(String s) =>
    _convert(s, _hyphen, _WordCase.upper, _WordCase.upper);

/// Converts [s] to `Pascal_Snake_Case`.
String pascalSnakeCase(String s) =>
    _convert(s, _underscore, _WordCase.capitalize, _WordCase.capitalize);

/// Converts [s] to `Pascal-Kebab-Case`, also known as Train-Case or
/// HTTP-Header-Case.
String pascalKebabCase(String s) =>
    _convert(s, _hyphen, _WordCase.capitalize, _WordCase.capitalize);

/// Converts [s] to `camel_Snake_Case`.
String camelSnakeCase(String s) =>
    _convert(s, _underscore, _WordCase.lower, _WordCase.capitalize);

/// Converts [s] to `camel-Kebab-Case`.
String camelKebabCase(String s) =>
    _convert(s, _hyphen, _WordCase.lower, _WordCase.capitalize);

/// Converts [s] to `Title Case`.
///
/// The first word is always capitalized. Later words that appear in
/// [titleCaseExceptions], or that start with a digit, are left lowercase, so
/// `'the lord of the rings'` becomes `'The Lord of the Rings'`.
String titleCase(String s) {
  final buffer = StringBuffer();
  final ascii = isAsciiString(s);
  scanWords(s, (start, end) {
    final isFirst = buffer.isEmpty;
    if (!isFirst) buffer.writeCharCode(_space);
    // The exception lookup needs the word itself, so unlike the other
    // conversions this one does materialize a substring per word.
    final word = s.substring(start, end);
    final mode = !isFirst && shouldIgnoreCapitalization(word)
        ? _WordCase.lower
        : _WordCase.capitalize;
    if (ascii) {
      _writeWordAscii(buffer, s, start, end, mode);
    } else {
      buffer.write(_applyCaseUnicode(word, mode));
    }
  });
  return buffer.toString();
}

/// Title-cases [s] while preserving `-` and `_` separators.
///
/// Where [titleCase] normalizes every separator to a space, this keeps the
/// original punctuation and title-cases each segment between separators:
/// `'example-string_for general use'` becomes
/// `'Example-String_For General Use'`.
String title(String s) {
  final buffer = StringBuffer();
  var segmentStart = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x2D || c == 0x5F) {
      if (i > segmentStart) {
        buffer.write(titleCase(s.substring(segmentStart, i)));
      }
      buffer.writeCharCode(c);
      segmentStart = i + 1;
    }
  }
  if (s.length > segmentStart) {
    buffer.write(titleCase(s.substring(segmentStart)));
  }
  return buffer.toString();
}

/// Uppercases the first character of [s], leaving the rest untouched.
///
/// Example: `'flutter AND DART'` becomes `'Flutter AND DART'`.
String capitalizeFirst(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Lowercases the first character of [s], leaving the rest untouched.
///
/// Example: `'FLUTTER AND DART'` becomes `'fLUTTER AND DART'`.
String lowercaseFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

/// Uppercases the first character of [s] and lowercases everything after it.
///
/// Example: `'FLUTTER AND DART'` becomes `'Flutter and dart'`.
String capitalizeFirstLowerRest(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

/// Whether [word] should stay lowercase inside a title.
///
/// True when the word starts with an ASCII digit or appears in
/// [titleCaseExceptions]. Note that [titleCase] ignores this for the first
/// word, which is always capitalized.
bool shouldIgnoreCapitalization(String word) {
  if (word.isEmpty) return false;
  if (isAsciiDigit(word.codeUnitAt(0))) return true;
  return titleCaseExceptions.contains(word.toLowerCase());
}
