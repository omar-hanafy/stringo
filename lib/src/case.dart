import 'package:stringo/stringo.dart';

/// Words that [StringCaseExtensions.toTitleCase] leaves lowercase when they
/// appear after the first word.
///
/// These are the English articles, conjunctions, and short prepositions that
/// conventional title casing does not capitalize. The first word of a title is
/// always capitalized regardless of this list.
///
/// Exposed so callers can inspect the rule or build their own casing on top of
/// it. Backed by a `Set` for constant-time lookup.
const Set<String> titleCaseExceptions = <String>{
  'a',
  'abaft',
  'about',
  'above',
  'afore',
  'after',
  'along',
  'amid',
  'among',
  'an',
  'and',
  'apud',
  'as',
  'aside',
  'at',
  'atop',
  'below',
  'but',
  'by',
  'circa',
  'down',
  'for',
  'from',
  'given',
  'in',
  'into',
  'lest',
  'like',
  'mid',
  'midst',
  'minus',
  'near',
  'next',
  'nor',
  'of',
  'off',
  'on',
  'onto',
  'or',
  'out',
  'over',
  'pace',
  'past',
  'per',
  'plus',
  'pro',
  'qua',
  'round',
  'sans',
  'save',
  'since',
  'so',
  'than',
  'the',
  'thru',
  'till',
  'times',
  'to',
  'under',
  'until',
  'unto',
  'up',
  'upon',
  'via',
  'vice',
  'with',
  'worth',
  'yet',
};

/// Case conversion for strings.
///
/// Every conversion is built on [toWords], so all of them accept input in any
/// of the supported shapes: `camelCase`, `PascalCase`, `snake_case`,
/// `kebab-case`, or plain spaced text.
extension StringCaseExtensions on String {
  /// Splits this string into its component words.
  ///
  /// Recognizes camelCase and PascalCase boundaries, acronym boundaries
  /// (`HTTPServer` splits into `HTTP` and `Server`), plus underscores,
  /// hyphens, and whitespace.
  ///
  /// This is the tokenizer every other conversion in this extension uses. To
  /// split plain prose on whitespace only, use
  /// [StringTransformExtensions.words].
  List<String> get toWords =>
      split(RegExp(r'(?<=[a-z])(?=[A-Z])|[_\-\s]+|(?<=[A-Z])(?=[A-Z][a-z])'));

  /// Converts to `PascalCase`, also known as UpperCamelCase.
  ///
  /// Example: `"hello_world"` becomes `"HelloWorld"`.
  String get toPascalCase =>
      toWords.map((word) => word.capitalizeFirstLowerRest).join();

  /// Converts to `Title Case`.
  ///
  /// Example: `"hello_world"` becomes `"Hello World"`.
  ///
  /// The first word is always capitalized. Subsequent words listed in
  /// [titleCaseExceptions] (articles, conjunctions, short prepositions) are
  /// left lowercase, so `"the lord of the rings"` becomes
  /// `"The Lord of the Rings"`.
  String get toTitleCase {
    final words = toWords;
    for (var i = 0; i < words.length; i++) {
      words[i] = i > 0 && words[i].shouldIgnoreCapitalization
          ? words[i].toLowerCase()
          : words[i].capitalizeFirstLowerRest;
    }
    return words.join(' ');
  }

  /// Converts to `camelCase`, also known as dromedaryCase.
  ///
  /// Example: `"hello_world"` becomes `"helloWorld"`.
  String get toCamelCase {
    final words = toWords;
    for (var i = 0; i < words.length; i++) {
      words[i] = (i == 0
          ? words[i].toLowerCase()
          : words[i].capitalizeFirstLowerRest);
    }
    return words.join();
  }

  /// Converts to `snake_case`, also known as snail_case or pothole_case.
  ///
  /// Example: `"helloWorld"` becomes `"hello_world"`.
  String get toSnakeCase => toWords.join('_').toLowerCase();

  /// Converts to `kebab-case`, also known as dash-case, lisp-case, or
  /// spinal-case.
  ///
  /// Example: `"helloWorld"` becomes `"hello-world"`.
  String get toKebabCase => toWords.join('-').toLowerCase();

  /// Converts to `SCREAMING_SNAKE_CASE`, also known as MACRO_CASE,
  /// CONSTANT_CASE, or ALL_CAPS.
  ///
  /// Example: `"helloWorld"` becomes `"HELLO_WORLD"`.
  String get toScreamingSnakeCase => toWords.join('_').toUpperCase();

  /// Converts to `SCREAMING-KEBAB-CASE`, also known as COBOL-CASE.
  ///
  /// Example: `"helloWorld"` becomes `"HELLO-WORLD"`.
  String get toScreamingKebabCase => toWords.join('-').toUpperCase();

  /// Converts to `Pascal_Snake_Case`.
  ///
  /// Example: `"helloWorld"` becomes `"Hello_World"`.
  String get toPascalSnakeCase =>
      toWords.map((word) => word.capitalizeFirstLowerRest).join('_');

  /// Converts to `Pascal-Kebab-Case`.
  ///
  /// Example: `"helloWorld"` becomes `"Hello-World"`.
  ///
  /// Identical in behavior to [toTrainCase]; both names are kept because both
  /// are in common use.
  String get toPascalKebabCase =>
      toWords.map((word) => word.capitalizeFirstLowerRest).join('-');

  /// Converts to `Train-Case`, also known as HTTP-Header-Case.
  ///
  /// Example: `"helloWorld"` becomes `"Hello-World"`.
  ///
  /// Identical in behavior to [toPascalKebabCase]; both names are kept because
  /// both are in common use.
  String get toTrainCase =>
      toWords.map((word) => word.capitalizeFirstLowerRest).join('-');

  /// Converts to `camel_Snake_Case`.
  ///
  /// Example: `"helloWorld"` becomes `"hello_World"`.
  String get toCamelSnakeCase {
    final words = toWords;
    for (var i = 0; i < words.length; i++) {
      words[i] = (i == 0
          ? words[i].toLowerCase()
          : words[i].capitalizeFirstLowerRest);
    }
    return words.join('_');
  }

  /// Converts to `camel-Kebab-Case`.
  ///
  /// Example: `"helloWorld"` becomes `"hello-World"`.
  String get toCamelKebabCase {
    final words = toWords;
    for (var i = 0; i < words.length; i++) {
      words[i] = (i == 0
          ? words[i].toLowerCase()
          : words[i].capitalizeFirstLowerRest);
    }
    return words.join('-');
  }

  /// Converts to `dot.case`.
  ///
  /// Example: `"helloWorld"` becomes `"hello.world"`.
  String get toDotCase => toWords.join('.').toLowerCase();

  /// Converts to `flatcase`.
  ///
  /// Example: `"HelloWorld"` becomes `"helloworld"`.
  String get toFlatCase => toWords.join().toLowerCase();

  /// Converts to `SCREAMINGCASE`.
  ///
  /// Example: `"helloWorld"` becomes `"HELLOWORLD"`.
  String get toScreamingCase => toWords.join().toUpperCase();

  /// Uppercases the first character, leaving the rest untouched.
  ///
  /// Example: `"flutter AND DART"` becomes `"Flutter AND DART"`.
  String get capitalizeFirstLetter =>
      isBlank ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Lowercases the first character, leaving the rest untouched.
  ///
  /// Example: `"FLUTTER AND DART"` becomes `"fLUTTER AND DART"`.
  String get lowercaseFirstLetter =>
      isBlank ? this : '${this[0].toLowerCase()}${substring(1)}';

  /// Uppercases the first character and lowercases everything after it.
  ///
  /// Example: `"FLUTTER AND DART"` becomes `"Flutter and dart"`.
  String get capitalizeFirstLowerRest =>
      isBlank ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// Title-cases the text while preserving `-` and `_` separators.
  ///
  /// Where [toTitleCase] normalizes every separator to a space, this keeps the
  /// original punctuation and title-cases each segment between separators.
  ///
  /// ```dart
  /// 'example-string_for general use-sample.'.toTitle;
  /// // 'Example-String_For General Use-Sample.'
  /// ```
  String get toTitle => splitMapJoin(
    RegExp('[-_]'),
    onMatch: (match) => match.group(0)!,
    onNonMatch: (subWord) => subWord.isNotEmpty ? subWord.toTitleCase : subWord,
  );

  /// Whether this word should stay lowercase inside a title.
  ///
  /// True when the word starts with a digit or appears in
  /// [titleCaseExceptions]. Note that [toTitleCase] ignores this for the first
  /// word, which is always capitalized.
  bool get shouldIgnoreCapitalization =>
      startsWithNumber || titleCaseExceptions.contains(toLowerCase());
}

/// Case conversion that tolerates a null receiver.
extension NullableStringCaseExtensions on String? {
  /// Lowercases this string, or returns `null` when it is `null`.
  String? tryToLowerCase() => this?.toLowerCase();

  /// Uppercases this string, or returns `null` when it is `null`.
  String? tryToUpperCase() => this?.toUpperCase();
}
