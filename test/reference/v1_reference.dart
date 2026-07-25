/// Verbatim stringo 1.0.0 implementations, retained ONLY as differential
/// oracles.
///
/// These are the regex-and-join implementations the package shipped in 1.0.0.
/// They are slow and they emit empty words, which is exactly why they were
/// replaced. They live here so the new engine can be *proven* equivalent to
/// them rather than assumed equivalent.
///
/// Every function here operates on the word list with empty words removed.
/// That is the single registered behavior change between 1.0.0 and 2.0.0
/// (spec defects 2 and 8). Everything else about casing must match exactly,
/// so any fuzz disagreement means the new engine is wrong and the engine gets
/// fixed, never this file.
///
/// Do not import this from `lib/`.
library;

import 'package:stringo/src/title_case_exceptions.dart';

final RegExp _v1Split = RegExp(
  r'(?<=[a-z])(?=[A-Z])|[_\-\s]+|(?<=[A-Z])(?=[A-Z][a-z])',
);

/// Splits [s] exactly as `String.toWords` did in stringo 1.0.0, including the
/// empty words it produced for leading and trailing separators.
List<String> v1Words(String s) => s.split(_v1Split);

/// [v1Words] with the empty entries dropped, which is the 2.0.0 contract.
List<String> v1WordsNonEmpty(String s) =>
    v1Words(s).where((w) => w.isNotEmpty).toList();

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

bool _shouldIgnore(String w) => v1ShouldIgnoreCapitalization(w);

/// 1.0.0 `toPascalCase`.
String v1PascalCase(String s) => v1WordsNonEmpty(s).map(_cap).join();

/// 1.0.0 `toCamelCase`.
String v1CamelCase(String s) {
  final w = v1WordsNonEmpty(s);
  for (var i = 0; i < w.length; i++) {
    w[i] = i == 0 ? w[i].toLowerCase() : _cap(w[i]);
  }
  return w.join();
}

/// 1.0.0 `toSnakeCase`.
String v1SnakeCase(String s) => v1WordsNonEmpty(s).join('_').toLowerCase();

/// 1.0.0 `toKebabCase`.
String v1KebabCase(String s) => v1WordsNonEmpty(s).join('-').toLowerCase();

/// 1.0.0 `toDotCase`.
String v1DotCase(String s) => v1WordsNonEmpty(s).join('.').toLowerCase();

/// 1.0.0 `toFlatCase`.
String v1FlatCase(String s) => v1WordsNonEmpty(s).join().toLowerCase();

/// 1.0.0 `toScreamingCase`.
String v1ScreamingCase(String s) => v1WordsNonEmpty(s).join().toUpperCase();

/// 1.0.0 `toScreamingSnakeCase`.
String v1ScreamingSnakeCase(String s) =>
    v1WordsNonEmpty(s).join('_').toUpperCase();

/// 1.0.0 `toScreamingKebabCase`.
String v1ScreamingKebabCase(String s) =>
    v1WordsNonEmpty(s).join('-').toUpperCase();

/// 1.0.0 `toPascalSnakeCase`.
String v1PascalSnakeCase(String s) => v1WordsNonEmpty(s).map(_cap).join('_');

/// 1.0.0 `toPascalKebabCase`.
String v1PascalKebabCase(String s) => v1WordsNonEmpty(s).map(_cap).join('-');

/// 1.0.0 `toCamelSnakeCase`.
String v1CamelSnakeCase(String s) {
  final w = v1WordsNonEmpty(s);
  for (var i = 0; i < w.length; i++) {
    w[i] = i == 0 ? w[i].toLowerCase() : _cap(w[i]);
  }
  return w.join('_');
}

/// 1.0.0 `toCamelKebabCase`.
String v1CamelKebabCase(String s) {
  final w = v1WordsNonEmpty(s);
  for (var i = 0; i < w.length; i++) {
    w[i] = i == 0 ? w[i].toLowerCase() : _cap(w[i]);
  }
  return w.join('-');
}

/// 1.0.0 `toTitleCase`.
String v1TitleCase(String s) {
  final w = v1WordsNonEmpty(s);
  for (var i = 0; i < w.length; i++) {
    w[i] = i > 0 && _shouldIgnore(w[i]) ? w[i].toLowerCase() : _cap(w[i]);
  }
  return w.join(' ');
}

/// 1.0.0 `capitalizeFirstLetter`.
String v1CapitalizeFirst(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// 1.0.0 `lowercaseFirstLetter`.
String v1LowercaseFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

/// 1.0.0 `capitalizeFirstLowerRest`.
String v1CapitalizeFirstLowerRest(String s) => _cap(s);

// ---------------------------------------------------------------------------
// Transform oracles. These are the 1.0.0 regex pipelines, verbatim.
// ---------------------------------------------------------------------------

final RegExp _wsRun = RegExp(r'\s+');
final RegExp _lineBreak = RegExp(r'\r?\n');
final RegExp _blankLines = RegExp(r'(?:[\t ]*(?:\r?\n|\r))+');

/// 1.0.0 `normalizeWhitespace`.
String v1NormalizeWhitespace(String s) => s.trim().replaceAll(_wsRun, ' ');

/// 1.0.0 `removeWhiteSpaces`.
String v1RemoveWhitespace(String s) => s.replaceAll(_wsRun, '');

/// 1.0.0 `toOneLine`.
String v1OneLine(String s) => s.replaceAll('\n', '');

/// 1.0.0 `removeEmptyLines`.
String v1RemoveEmptyLines(String s) => s.replaceAll(_blankLines, '\n');

/// 1.0.0 `lines`.
List<String> v1Lines(String s) => s.split(_lineBreak);

/// 1.0.0 `words` (the whitespace splitter, not the identifier tokenizer).
List<String> v1SplitWhitespace(String s) {
  final normalized = v1NormalizeWhitespace(s);
  return normalized.isEmpty ? <String>[] : normalized.split(' ');
}

/// 1.0.0 `slugify`, valid as an oracle only for a single-hyphen separator,
/// since defect 3 changes how other separators treat a literal hyphen.
String v1SlugifyHyphen(String s) {
  final normalized = v1NormalizeWhitespace(s).toLowerCase();
  if (normalized.isEmpty) return '';
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
      .replaceAll(RegExp(r'[_\s]+'), '-')
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

// ---------------------------------------------------------------------------
// Check oracles.
//
// 1.0.0 answered every one of these with a RegExp; 2.0.0 answers most of them
// with a scan. The patterns are hoisted to top-level finals rather than built
// per call as 1.0.0 did: `RegExp(source)` with the same flags produces the
// same matcher, and a per-call compile inside a 30,000 iteration loop would
// dominate the suite. Nothing about the matching is changed.
// ---------------------------------------------------------------------------

final RegExp _v1Alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
final RegExp _v1StartsWithNumber = RegExp(r'^\d');
final RegExp _v1ContainsDigits = RegExp(r'\d');
final RegExp _v1Numeric = RegExp(r'^\d+$');
final RegExp _v1Alphabet = RegExp(r'^[a-zA-Z]+$');
final RegExp _v1HasCapital = RegExp('[A-Z]');

/// 1.0.0 `clean`, which was `toOneLine.removeWhiteSpaces`: two whole-string
/// copies plus a compiled regex. This is the allocation `isBlank` used to pay
/// on every call.
String v1Clean(String s) => s.replaceAll('\n', '').replaceAll(_wsRun, '');

/// 1.0.0 `isBlank` / `isEmptyOrNull`: `this == null || this!.clean.isEmpty`.
bool v1IsBlank(String? s) => s == null || v1Clean(s).isEmpty;

/// 1.0.0 `isNotBlank` / `isNotEmptyOrNull`.
bool v1IsNotBlank(String? s) => !v1IsBlank(s);

/// 1.0.0 `isAlphanumeric`. Note there is no `trim()` here, unlike
/// [v1IsNumeric] and [v1IsAlphabet].
bool v1IsAlphanumeric(String? s) => s != null && _v1Alphanumeric.hasMatch(s);

/// 1.0.0 `startsWithNumber`.
bool v1StartsWithNumber(String? s) =>
    s != null && _v1StartsWithNumber.hasMatch(s);

/// 1.0.0 `containsDigits`.
bool v1ContainsDigits(String? s) => s != null && _v1ContainsDigits.hasMatch(s);

/// 1.0.0 `hasCapitalLetter`.
bool v1HasCapitalLetter(String? s) => s != null && _v1HasCapital.hasMatch(s);

/// 1.0.0 `isNumeric`, which trimmed first.
bool v1IsNumeric(String? s) => s != null && _v1Numeric.hasMatch(s.trim());

/// 1.0.0 `isAlphabet`, which trimmed first.
bool v1IsAlphabet(String? s) => s != null && _v1Alphabet.hasMatch(s.trim());

/// 1.0.0 `equalsIgnoreCase`.
///
/// No fast path, no length check, no ASCII branch: two whole-string lowercase
/// copies and one comparison. 2.0.0 added a hand-rolled ASCII fast path, which
/// is why this oracle matters more than most.
bool v1EqualsIgnoreCase(String? a, String? b) =>
    (a == null && b == null) ||
    (a != null && b != null && a.toLowerCase() == b.toLowerCase());

/// 1.0.0 `hasMatch`. Compiles per call, exactly as 2.0.0 still does, because
/// the pattern is supplied by the caller.
bool v1HasMatch(
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

/// 1.0.0 `shouldIgnoreCapitalization`.
bool v1ShouldIgnoreCapitalization(String w) =>
    v1StartsWithNumber(w) || titleCaseExceptions.contains(w.toLowerCase());

final RegExp _v1TitleSeparator = RegExp('[-_]');

/// 1.0.0 `toTitle`.
///
/// Built on [v1TitleCase], the empty-word-normalized title caser, so the one
/// registered difference does not leak in twice. `splitMapJoin` invokes
/// `onNonMatch` for the empty regions at the ends and between adjacent
/// separators; returning those unchanged is what the 1.0.0 body did, and is
/// what makes this equal to the 2.0.0 scanner, which simply skips them.
String v1Title(String s) => s.splitMapJoin(
  _v1TitleSeparator,
  onMatch: (m) => m.group(0)!,
  onNonMatch: (sub) => sub.isNotEmpty ? v1TitleCase(sub) : sub,
);

// ---------------------------------------------------------------------------
// Transform oracles that take arguments.
//
// 1.0.0 declared these on `String?`; the 2.0.0 ops layer is non-nullable
// because null handling moved up into the extensions. These take non-null and
// return non-null; the null contract is covered by extensions_test.dart.
// ---------------------------------------------------------------------------

/// 1.0.0 `mask`, minus the null-receiver branch.
String v1Mask(
  String s, {
  int visibleStart = 0,
  int visibleEnd = 0,
  String char = '*',
}) {
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
  if (s.length <= visibleStart + visibleEnd) return s;
  return s.substring(0, visibleStart) +
      (char * (s.length - visibleStart - visibleEnd)) +
      s.substring(s.length - visibleEnd);
}

/// 1.0.0 `insert`, minus the null-receiver branch.
String v1Insert(String s, int index, String value) {
  RangeError.checkValueInInterval(index, 0, s.length, 'index');
  return s.substring(0, index) + value + s.substring(index);
}

/// 1.0.0 `removeSurrounding`.
String v1RemoveSurrounding(String s, String delimiter) {
  if (s.length >= delimiter.length + delimiter.length &&
      s.startsWith(delimiter) &&
      s.endsWith(delimiter)) {
    return s.substring(delimiter.length, s.length - delimiter.length);
  }
  return s;
}

/// 1.0.0 `replaceAfter`.
///
/// The `defaultValue` gate was `isEmptyOrNull`, that is [v1IsBlank], so this
/// oracle also pins 2.0.0's `isBlank` in situ rather than only in isolation.
String v1ReplaceAfter(
  String s,
  String delimiter,
  String replacement, [
  String? defaultValue,
]) {
  final index = s.indexOf(delimiter);
  return (index == -1)
      ? (v1IsBlank(defaultValue) ? s : defaultValue!)
      : s.replaceRange(index + delimiter.length, s.length, replacement);
}

/// 1.0.0 `replaceBefore`.
String v1ReplaceBefore(
  String s,
  String delimiter,
  String replacement, [
  String? defaultValue,
]) {
  final index = s.indexOf(delimiter);
  return (index == -1)
      ? (v1IsBlank(defaultValue) ? s : defaultValue!)
      : s.replaceRange(0, index, replacement);
}

// ---------------------------------------------------------------------------
// Oracles for the INTENTIONALLY changed operations.
//
// These must never appear in the main fuzz loops. They exist so each
// registered change can be stated as "equal to 1.0.0 everywhere except HERE",
// which is a stronger claim than a property test alone: it also catches a
// second, unregistered change riding along with the intended one.
// ---------------------------------------------------------------------------

/// 1.0.0 `truncate`: the suffix was appended on top of [length], so the result
/// could overshoot the limit the caller asked for.
String v1Truncate(String s, int length, {String suffix = '...'}) {
  if (length <= 0) return '';
  if (s.length <= length) return s;
  return '${s.substring(0, length)}$suffix';
}

/// 1.0.0 `toCharArray`: split by UTF-16 code unit and gated on `isNotBlank`,
/// so it tore surrogate pairs in half and returned `[]` for whitespace.
List<String> v1ToCharArray(String? s) =>
    v1IsNotBlank(s) ? s!.split('') : <String>[];

/// 1.0.0 `slugify` for an arbitrary separator.
///
/// NOT generally fuzzable. 1.0.0 built regexes *from* the separator and
/// applied them to the finished slug, so a separator drawn from `a-z0-9` eats
/// content: `'x a y'.slugify(separator: 'aa')` returned `'xaay'`, one
/// character short. This exists only so the hyphen-rule change can be
/// contrasted against real 1.0.0 code rather than a remembered constant.
String v1SlugifyGeneral(String s, {String separator = '-'}) {
  if (separator.isEmpty) {
    throw ArgumentError.value(
      separator,
      'separator',
      'Separator must not be empty',
    );
  }
  final normalized = v1NormalizeWhitespace(s).toLowerCase();
  if (normalized.isEmpty) return '';
  final escapedSeparator = RegExp.escape(separator);
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
      .replaceAll(RegExp(r'[_\s]+'), separator)
      .replaceAll(RegExp('$escapedSeparator+'), separator)
      .replaceAll(RegExp('^$escapedSeparator|$escapedSeparator\$'), '');
}
