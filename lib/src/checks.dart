import 'package:stringo/stringo.dart';

/// Predicates that inspect the characters of a string.
///
/// These answer questions about the text itself (is it blank, is it all
/// digits, does it contain a capital letter). They deliberately do not answer
/// questions about real-world formats such as "is this a valid email
/// address" - those have no single correct answer and belong in the layer
/// that owns the rule.
extension StringChecksExtensions on String? {
  /// Whether the string is null, empty, or made up solely of whitespace.
  ///
  /// Alias: [isBlank].
  bool get isEmptyOrNull => this == null || this!.clean.isEmpty;

  /// Whether the string is null, empty, or made up solely of whitespace.
  ///
  /// Alias for [isEmptyOrNull].
  bool get isBlank => isEmptyOrNull;

  /// Whether the string is non-null and holds at least one non-whitespace
  /// character.
  ///
  /// Alias: [isNotBlank].
  bool get isNotEmptyOrNull => !isEmptyOrNull;

  /// Whether the string is non-null and holds at least one non-whitespace
  /// character.
  ///
  /// Alias for [isNotEmptyOrNull].
  bool get isNotBlank => isNotEmptyOrNull;

  /// Whether the string contains only ASCII letters and digits.
  ///
  /// Returns `false` for null and for the empty string.
  bool get isAlphanumeric => hasMatch(regexAlphanumeric);

  /// Whether the string starts with an ASCII digit.
  bool get startsWithNumber => hasMatch(regexStartsWithNumber);

  /// Whether the string contains at least one ASCII digit.
  bool get containsDigits => hasMatch(regexContainsDigits);

  /// Whether the string contains at least one uppercase ASCII letter.
  bool get hasCapitalLetter => hasMatch(regexHasCapitalLetter);

  /// Whether the string consists only of ASCII digits (no sign, no decimal
  /// point).
  ///
  /// Surrounding whitespace is ignored. This is a character check, not a
  /// parser: use a conversion package if you need the numeric value.
  bool get isNumeric => this != null && this!.trim().hasMatch(regexNumeric);

  /// Whether the string consists only of ASCII letters (`A-Z`, `a-z`).
  ///
  /// Surrounding whitespace is ignored.
  bool get isAlphabet => this != null && this!.trim().hasMatch(regexAlphabet);

  /// Whether [pattern] matches anywhere in this string.
  ///
  /// Returns `false` when the string is null. The optional flags map directly
  /// onto the matching [RegExp] constructor arguments.
  bool hasMatch(
    String pattern, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) =>
      this != null &&
      RegExp(
        pattern,
        caseSensitive: caseSensitive,
        multiLine: multiLine,
        unicode: unicode,
        dotAll: dotAll,
      ).hasMatch(this!);
}
