/// Case conversion extensions.
library;

import 'package:stringo/src/core.dart';
import 'package:stringo/src/title_case_exceptions.dart';

/// Case conversion for strings.
///
/// Every conversion is built on [toWords], so all of them accept input in any
/// of the supported shapes: `camelCase`, `PascalCase`, `snake_case`,
/// `kebab-case`, or plain spaced text.
///
/// Each member here delegates to the matching [Stringo] function, so the two
/// surfaces cannot drift apart.
extension StringCaseExtensions on String {
  /// Splits this string into its component words.
  ///
  /// Recognizes camelCase and PascalCase boundaries, acronym boundaries so
  /// `HTTPServer` splits into `HTTP` and `Server`, plus underscores, hyphens,
  /// and whitespace.
  ///
  /// Never returns an empty element: a leading, trailing, or repeated
  /// separator run contributes no word. To split prose on whitespace only, use
  /// [StringTransformExtensions.words].
  List<String> get toWords => Stringo.words(this);

  /// Converts to `PascalCase`, also known as UpperCamelCase.
  ///
  /// Example: `'hello_world'` becomes `'HelloWorld'`.
  String get toPascalCase => Stringo.pascalCase(this);

  /// Converts to `camelCase`, also known as dromedaryCase.
  ///
  /// Example: `'hello_world'` becomes `'helloWorld'`.
  String get toCamelCase => Stringo.camelCase(this);

  /// Converts to `snake_case`, also known as snail_case or pothole_case.
  ///
  /// Example: `'helloWorld'` becomes `'hello_world'`.
  String get toSnakeCase => Stringo.snakeCase(this);

  /// Converts to `kebab-case`, also known as dash-case or spinal-case.
  ///
  /// Example: `'helloWorld'` becomes `'hello-world'`.
  String get toKebabCase => Stringo.kebabCase(this);

  /// Converts to `dot.case`.
  ///
  /// Example: `'helloWorld'` becomes `'hello.world'`.
  String get toDotCase => Stringo.dotCase(this);

  /// Converts to `flatcase`.
  ///
  /// Example: `'HelloWorld'` becomes `'helloworld'`.
  String get toFlatCase => Stringo.flatCase(this);

  /// Converts to `SCREAMINGCASE`.
  ///
  /// Example: `'helloWorld'` becomes `'HELLOWORLD'`.
  String get toScreamingCase => Stringo.screamingCase(this);

  /// Converts to `SCREAMING_SNAKE_CASE`, also known as MACRO_CASE,
  /// CONSTANT_CASE, or ALL_CAPS.
  ///
  /// Example: `'helloWorld'` becomes `'HELLO_WORLD'`.
  String get toScreamingSnakeCase => Stringo.screamingSnakeCase(this);

  /// Converts to `SCREAMING-KEBAB-CASE`, also known as COBOL-CASE.
  ///
  /// Example: `'helloWorld'` becomes `'HELLO-WORLD'`.
  String get toScreamingKebabCase => Stringo.screamingKebabCase(this);

  /// Converts to `Pascal_Snake_Case`.
  ///
  /// Example: `'helloWorld'` becomes `'Hello_World'`.
  String get toPascalSnakeCase => Stringo.pascalSnakeCase(this);

  /// Converts to `Pascal-Kebab-Case`.
  ///
  /// Example: `'helloWorld'` becomes `'Hello-World'`.
  ///
  /// This is the canonical name; [toTrainCase] is an alias for it.
  String get toPascalKebabCase => Stringo.pascalKebabCase(this);

  /// Converts to `Train-Case`, also known as HTTP-Header-Case.
  ///
  /// Example: `'helloWorld'` becomes `'Hello-World'`.
  ///
  /// An alias for [toPascalKebabCase], kept because both names are in common
  /// use. Identical in behavior.
  String get toTrainCase => Stringo.pascalKebabCase(this);

  /// Converts to `camel_Snake_Case`.
  ///
  /// Example: `'helloWorld'` becomes `'hello_World'`.
  String get toCamelSnakeCase => Stringo.camelSnakeCase(this);

  /// Converts to `camel-Kebab-Case`.
  ///
  /// Example: `'helloWorld'` becomes `'hello-World'`.
  String get toCamelKebabCase => Stringo.camelKebabCase(this);

  /// Converts to `Title Case`.
  ///
  /// Example: `'hello_world'` becomes `'Hello World'`.
  ///
  /// The first word is always capitalized. Subsequent words listed in
  /// [titleCaseExceptions] are left lowercase, so `'the lord of the rings'`
  /// becomes `'The Lord of the Rings'`.
  String get toTitleCase => Stringo.titleCase(this);

  /// Title-cases the text while preserving `-` and `_` separators.
  ///
  /// Where [toTitleCase] normalizes every separator to a space, this keeps the
  /// original punctuation and title-cases each segment between separators.
  ///
  /// ```dart
  /// 'example-string_for general use-sample.'.toTitle;
  /// // 'Example-String_For General Use-Sample.'
  /// ```
  String get toTitle => Stringo.title(this);

  /// Uppercases the first character, leaving the rest untouched.
  ///
  /// Example: `'flutter AND DART'` becomes `'Flutter AND DART'`.
  String get capitalizeFirstLetter => Stringo.capitalizeFirst(this);

  /// Lowercases the first character, leaving the rest untouched.
  ///
  /// Example: `'FLUTTER AND DART'` becomes `'fLUTTER AND DART'`.
  String get lowercaseFirstLetter => Stringo.lowercaseFirst(this);

  /// Uppercases the first character and lowercases everything after it.
  ///
  /// Example: `'FLUTTER AND DART'` becomes `'Flutter and dart'`.
  String get capitalizeFirstLowerRest => Stringo.capitalizeFirstLowerRest(this);

  /// Whether this word should stay lowercase inside a title.
  ///
  /// True when the word starts with a digit or appears in
  /// [titleCaseExceptions]. Note that [toTitleCase] ignores this for the first
  /// word, which is always capitalized.
  bool get shouldIgnoreCapitalization =>
      Stringo.shouldIgnoreCapitalization(this);
}

/// Case conversion that tolerates a null receiver.
extension NullableStringCaseExtensions on String? {
  /// Lowercases this string, or returns `null` when it is `null`.
  String? tryToLowerCase() => this?.toLowerCase();

  /// Uppercases this string, or returns `null` when it is `null`.
  String? tryToUpperCase() => this?.toUpperCase();
}
