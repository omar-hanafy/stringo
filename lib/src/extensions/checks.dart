/// Character-inspection extensions.
library;

import 'package:stringo/src/core.dart';

/// Predicates that inspect the characters of a string.
///
/// These answer questions about the text itself: is it blank, is it all
/// digits, does it contain a capital letter. They deliberately do not answer
/// questions about real-world formats such as "is this a valid email
/// address" - those have no single correct answer and belong in the layer
/// that owns the rule.
///
/// Each member delegates to the matching [Stringo] function.
extension StringChecksExtensions on String? {
  /// Whether the string is null, empty, or made up solely of whitespace.
  ///
  /// This returns at the first non-whitespace character, so it costs the same
  /// on a short string and on a very long one.
  bool get isBlank => Stringo.isBlank(this);

  /// Whether the string is non-null and holds at least one non-whitespace
  /// character.
  bool get isNotBlank => Stringo.isNotBlank(this);

  /// Whether the string contains only ASCII letters and digits.
  ///
  /// Returns `false` for null and for the empty string.
  bool get isAlphanumeric => Stringo.isAlphanumeric(this);

  /// Whether the string starts with an ASCII digit.
  bool get startsWithNumber => Stringo.startsWithNumber(this);

  /// Whether the string contains at least one ASCII digit.
  bool get containsDigits => Stringo.containsDigits(this);

  /// Whether the string contains at least one uppercase ASCII letter.
  bool get hasCapitalLetter => Stringo.hasCapitalLetter(this);

  /// Whether the string consists only of ASCII digits, with no sign and no
  /// decimal point.
  ///
  /// Surrounding whitespace is ignored. This is a character check, not a
  /// parser: use a conversion package if you need the numeric value.
  bool get isNumeric => Stringo.isNumeric(this);

  /// Whether the string consists only of ASCII letters, `A-Z` and `a-z`.
  ///
  /// Surrounding whitespace is ignored.
  bool get isAlphabet => Stringo.isAlphabet(this);

  /// Whether [pattern] matches anywhere in this string.
  ///
  /// Returns `false` when the string is null. The optional flags map directly
  /// onto the matching [RegExp] constructor arguments.
  ///
  /// This compiles [pattern] on every call. In a hot loop, hoist a [RegExp]
  /// yourself, or use one of this package's precompiled `pattern*` objects.
  bool hasMatch(
    String pattern, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) => Stringo.hasMatch(
    this,
    pattern,
    multiLine: multiLine,
    caseSensitive: caseSensitive,
    unicode: unicode,
    dotAll: dotAll,
  );
}
