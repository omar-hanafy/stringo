/// The functional core of the package.
library;

import 'package:stringo/src/ops/case.dart' as case_ops;
import 'package:stringo/src/ops/checks.dart' as check_ops;
import 'package:stringo/src/ops/transform.dart' as transform_ops;

/// Every stringo operation as a plain static function.
///
/// This is the same behavior the extensions provide, reachable without them.
/// Use it when you want explicit calls rather than extension sugar, when you
/// are passing an operation as a function value, or when an extension member
/// name collides with one your project or another package already defines:
///
/// ```dart
/// import 'package:stringo/stringo.dart' show Stringo;
///
/// Stringo.snakeCase('userProfileField'); // 'user_profile_field'
/// ['aB', 'cD'].map(Stringo.snakeCase);   // works as a function value
/// ```
///
/// The extensions are thin delegations to these functions, so the two surfaces
/// can never drift apart.
///
/// This class is a namespace. It cannot be instantiated or extended.
abstract final class Stringo {
  // -------------------------------------------------------------------------
  // Splitting
  // -------------------------------------------------------------------------

  /// Splits [input] into its component words.
  ///
  /// Recognizes camelCase and PascalCase boundaries, acronym boundaries so
  /// `HTTPServer` splits into `HTTP` and `Server`, plus underscores, hyphens,
  /// and whitespace. Never returns an empty element.
  ///
  /// To split prose on whitespace only, use [splitWhitespace].
  static List<String> words(String input) => case_ops.words(input);

  /// Splits [input] into whitespace-separated words.
  ///
  /// Returns an empty list when [input] is empty or whitespace-only. To split
  /// identifiers such as `helloWorld`, use [words].
  static List<String> splitWhitespace(String input) =>
      transform_ops.splitWhitespace(input);

  /// Splits [input] into lines, accepting both `\n` and `\r\n` endings.
  static List<String> lines(String input) => transform_ops.lines(input);

  /// Splits [input] into its individual Unicode code points.
  ///
  /// Never splits a surrogate pair. This is code points, not grapheme
  /// clusters; use `package:characters` when you need user-perceived
  /// characters.
  static List<String> characters(String input) =>
      transform_ops.characters(input);

  // -------------------------------------------------------------------------
  // Case conversion
  // -------------------------------------------------------------------------

  /// Converts [input] to `PascalCase`.
  static String pascalCase(String input) => case_ops.pascalCase(input);

  /// Converts [input] to `camelCase`.
  static String camelCase(String input) => case_ops.camelCase(input);

  /// Converts [input] to `snake_case`.
  static String snakeCase(String input) => case_ops.snakeCase(input);

  /// Converts [input] to `kebab-case`.
  static String kebabCase(String input) => case_ops.kebabCase(input);

  /// Converts [input] to `dot.case`.
  static String dotCase(String input) => case_ops.dotCase(input);

  /// Converts [input] to `flatcase`.
  static String flatCase(String input) => case_ops.flatCase(input);

  /// Converts [input] to `SCREAMINGCASE`.
  static String screamingCase(String input) => case_ops.screamingCase(input);

  /// Converts [input] to `SCREAMING_SNAKE_CASE`.
  static String screamingSnakeCase(String input) =>
      case_ops.screamingSnakeCase(input);

  /// Converts [input] to `SCREAMING-KEBAB-CASE`.
  static String screamingKebabCase(String input) =>
      case_ops.screamingKebabCase(input);

  /// Converts [input] to `Pascal_Snake_Case`.
  static String pascalSnakeCase(String input) =>
      case_ops.pascalSnakeCase(input);

  /// Converts [input] to `Pascal-Kebab-Case`, also known as Train-Case.
  static String pascalKebabCase(String input) =>
      case_ops.pascalKebabCase(input);

  /// Converts [input] to `camel_Snake_Case`.
  static String camelSnakeCase(String input) => case_ops.camelSnakeCase(input);

  /// Converts [input] to `camel-Kebab-Case`.
  static String camelKebabCase(String input) => case_ops.camelKebabCase(input);

  /// Converts [input] to `Title Case`.
  ///
  /// The first word is always capitalized; later words in
  /// `titleCaseExceptions` stay lowercase.
  static String titleCase(String input) => case_ops.titleCase(input);

  /// Title-cases [input] while preserving `-` and `_` separators.
  static String title(String input) => case_ops.title(input);

  /// Uppercases the first character of [input], leaving the rest untouched.
  static String capitalizeFirst(String input) =>
      case_ops.capitalizeFirst(input);

  /// Lowercases the first character of [input], leaving the rest untouched.
  static String lowercaseFirst(String input) => case_ops.lowercaseFirst(input);

  /// Uppercases the first character of [input] and lowercases the rest.
  static String capitalizeFirstLowerRest(String input) =>
      case_ops.capitalizeFirstLowerRest(input);

  /// Whether [word] should stay lowercase inside a title.
  static bool shouldIgnoreCapitalization(String word) =>
      case_ops.shouldIgnoreCapitalization(word);

  // -------------------------------------------------------------------------
  // Transformation
  // -------------------------------------------------------------------------

  /// Converts [input] into a URL- and filename-friendly slug.
  ///
  /// Throws an [ArgumentError] when [separator] is empty.
  static String slugify(String input, {String separator = '-'}) =>
      transform_ops.slugify(input, separator: separator);

  /// Shortens [input] so the result is at most [length] characters, ending
  /// with [suffix].
  static String truncate(String input, int length, {String suffix = '...'}) =>
      transform_ops.truncate(input, length, suffix: suffix);

  /// Replaces the middle of [input] with [char], keeping [visibleStart]
  /// leading and [visibleEnd] trailing characters visible.
  ///
  /// Throws an [ArgumentError] when either bound is negative.
  static String mask(
    String input, {
    int visibleStart = 0,
    int visibleEnd = 0,
    String char = '*',
  }) => transform_ops.mask(
    input,
    visibleStart: visibleStart,
    visibleEnd: visibleEnd,
    char: char,
  );

  /// Collapses runs of whitespace into single spaces and trims the result.
  static String normalizeWhitespace(String input) =>
      transform_ops.normalizeWhitespace(input);

  /// Removes every whitespace character from [input].
  static String removeWhitespace(String input) =>
      transform_ops.removeWhitespace(input);

  /// Collapses runs of blank lines in [input] into a single newline.
  static String removeEmptyLines(String input) =>
      transform_ops.removeEmptyLines(input);

  /// Removes every newline character from [input], without a separator.
  static String oneLine(String input) => transform_ops.oneLine(input);

  /// Returns [input] with [value] inserted at [index].
  ///
  /// Throws a [RangeError] when [index] is outside `0..input.length`.
  static String insert(String input, int index, String value) =>
      transform_ops.insert(input, index, value);

  /// Strips [delimiter] from both ends of [input], only when present at both.
  static String removeSurrounding(String input, String delimiter) =>
      transform_ops.removeSurrounding(input, delimiter);

  /// Replaces everything after the first [delimiter] with [replacement].
  static String replaceAfter(
    String input,
    String delimiter,
    String replacement, [
    String? defaultValue,
  ]) => transform_ops.replaceAfter(input, delimiter, replacement, defaultValue);

  /// Replaces everything before the first [delimiter] with [replacement].
  static String replaceBefore(
    String input,
    String delimiter,
    String replacement, [
    String? defaultValue,
  ]) =>
      transform_ops.replaceBefore(input, delimiter, replacement, defaultValue);

  // -------------------------------------------------------------------------
  // Checks
  // -------------------------------------------------------------------------

  /// Whether [input] is null, empty, or made up solely of whitespace.
  ///
  /// Returns at the first non-whitespace code unit, so this costs the same on
  /// a short string and a very long one.
  static bool isBlank(String? input) => check_ops.isBlank(input);

  /// Whether [input] is non-null and holds a non-whitespace character.
  static bool isNotBlank(String? input) => check_ops.isNotBlank(input);

  /// Whether [input] contains only ASCII letters and digits.
  static bool isAlphanumeric(String? input) => check_ops.isAlphanumeric(input);

  /// Whether [input] consists only of ASCII digits, ignoring outer whitespace.
  static bool isNumeric(String? input) => check_ops.isNumeric(input);

  /// Whether [input] consists only of ASCII letters, ignoring outer
  /// whitespace.
  static bool isAlphabet(String? input) => check_ops.isAlphabet(input);

  /// Whether [input] starts with an ASCII digit.
  static bool startsWithNumber(String? input) =>
      check_ops.startsWithNumber(input);

  /// Whether [input] contains at least one ASCII digit.
  static bool containsDigits(String? input) => check_ops.containsDigits(input);

  /// Whether [input] contains at least one uppercase ASCII letter.
  static bool hasCapitalLetter(String? input) =>
      check_ops.hasCapitalLetter(input);

  /// Compares [a] and [b] ignoring case. Two nulls are equal.
  static bool equalsIgnoreCase(String? a, String? b) =>
      check_ops.equalsIgnoreCase(a, b);

  /// Whether [pattern] matches anywhere in [input].
  ///
  /// Compiles [pattern] on every call. In a hot loop, hoist a [RegExp]
  /// yourself or use one of this package's precompiled `pattern*` objects.
  static bool hasMatch(
    String? input,
    String pattern, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) => check_ops.hasMatch(
    input,
    pattern,
    multiLine: multiLine,
    caseSensitive: caseSensitive,
    unicode: unicode,
    dotAll: dotAll,
  );
}
