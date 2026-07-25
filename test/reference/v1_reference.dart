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

bool _shouldIgnore(String w) =>
    RegExp(r'^\d').hasMatch(w) || titleCaseExceptions.contains(w.toLowerCase());

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
