import 'dart:math';

import 'package:stringo/src/ops/case.dart' as ops;
import 'package:stringo/src/ops/transform.dart' as tx;
import 'package:stringo/src/word_scanner.dart';
import 'package:test/test.dart';

import 'reference/v1_reference.dart';

/// Alphabet chosen to exercise every boundary rule plus the known quirks:
/// case humps, acronym tails, digit boundaries, every separator kind,
/// unicode whitespace, accented letters, and a surrogate pair.
const List<String> _alphabet = <String>[
  'a', 'b', 'z', 'A', 'B', 'Z', '0', '9', //
  '_', '-', ' ', '\t', '\n',
  '\u{00A0}', '\u{3000}', // NBSP, ideographic space
  '\u{00E9}', '\u{00C9}', // e-acute, E-acute
  '\u{1F600}', // surrogate pair
  'HTTP', 'Http', 'xY', 'ABc',
];

String _randomInput(Random rng, int maxPieces) {
  final pieces = rng.nextInt(maxPieces);
  final b = StringBuffer();
  for (var i = 0; i < pieces; i++) {
    b.write(_alphabet[rng.nextInt(_alphabet.length)]);
  }
  return b.toString();
}

/// The single registered difference between the oracle and the scanner:
/// 1.0.0 emitted empty words for leading, trailing, and repeated separator
/// runs (spec defects 2 and 8); the scanner never does. Any OTHER divergence
/// is a bug and fails the test.
List<String> _v1Normalized(String s) =>
    v1Words(s).where((w) => w.isNotEmpty).toList();

String _escape(String s) {
  final b = StringBuffer();
  for (final unit in s.codeUnits) {
    if (unit == 0x0A) {
      b.write(r'\n');
    } else if (unit == 0x09) {
      b.write(r'\t');
    } else if (unit < 0x20 || unit > 0x7E) {
      b.write('\\u{${unit.toRadixString(16).toUpperCase()}}');
    } else {
      b.writeCharCode(unit);
    }
  }
  return b.toString();
}

void main() {
  test('scanner matches the v1 tokenizer over 200k random inputs', () {
    // Fixed seed so a failure is reproducible rather than a one-off.
    final rng = Random(20260725);
    for (var iter = 0; iter < 200000; iter++) {
      final input = _randomInput(rng, 12);
      expect(
        scanWordsToList(input),
        _v1Normalized(input),
        reason: 'iteration $iter, input: "${_escape(input)}"',
      );
    }
  });

  test('scanner matches the v1 tokenizer on pathological inputs', () {
    final inputs = <String>[
      '', ' ', '_', '-', '---', '___', '_ - \t\n', //
      'a', 'A', '0', 'aB', 'Ab', 'ABc', 'ABC', 'aBc',
      'aaaaBBBBcccc', 'HTTPServer', 'XMLHttpRequest',
      'abc123Def', 'a1B', '1a', 'a1',
      '\u{1F600}\u{1F600}', 'a\u{1F600}B',
      '\u{00C9}COLE', 'caf\u{00E9}Au',
      'a' * 10000,
      '${'_' * 5000}x${'_' * 5000}',
      'aB' * 2000,
      ' \u{00A0}\u{3000}a\u{2028}b\u{FEFF} ',
    ];
    for (final input in inputs) {
      expect(
        scanWordsToList(input),
        _v1Normalized(input),
        reason: 'input: "${_escape(input)}"',
      );
    }
  });

  test('every case conversion matches its v1 implementation', () {
    // This is the test that proves the ASCII fast path never diverges from
    // Dart's native Unicode casing. Each entry pairs the new op with the
    // 1.0.0 map-and-join implementation of the same conversion.
    final conversions =
        <String, (String Function(String), String Function(String))>{
          'pascalCase': (ops.pascalCase, v1PascalCase),
          'camelCase': (ops.camelCase, v1CamelCase),
          'snakeCase': (ops.snakeCase, v1SnakeCase),
          'kebabCase': (ops.kebabCase, v1KebabCase),
          'dotCase': (ops.dotCase, v1DotCase),
          'flatCase': (ops.flatCase, v1FlatCase),
          'screamingCase': (ops.screamingCase, v1ScreamingCase),
          'screamingSnakeCase': (ops.screamingSnakeCase, v1ScreamingSnakeCase),
          'screamingKebabCase': (ops.screamingKebabCase, v1ScreamingKebabCase),
          'pascalSnakeCase': (ops.pascalSnakeCase, v1PascalSnakeCase),
          'pascalKebabCase': (ops.pascalKebabCase, v1PascalKebabCase),
          'camelSnakeCase': (ops.camelSnakeCase, v1CamelSnakeCase),
          'camelKebabCase': (ops.camelKebabCase, v1CamelKebabCase),
          'titleCase': (ops.titleCase, v1TitleCase),
          'capitalizeFirst': (ops.capitalizeFirst, v1CapitalizeFirst),
          'lowercaseFirst': (ops.lowercaseFirst, v1LowercaseFirst),
          'capitalizeFirstLowerRest': (
            ops.capitalizeFirstLowerRest,
            v1CapitalizeFirstLowerRest,
          ),
        };

    final rng = Random(1177);
    for (var iter = 0; iter < 40000; iter++) {
      final input = _randomInput(rng, 10);
      for (final entry in conversions.entries) {
        final (fresh, legacy) = entry.value;
        expect(
          fresh(input),
          legacy(input),
          reason: '${entry.key} diverged on "${_escape(input)}"',
        );
      }
    }
  });

  test('transform operations match their v1 implementations', () {
    final stringOps =
        <String, (String Function(String), String Function(String))>{
          'normalizeWhitespace': (
            tx.normalizeWhitespace,
            v1NormalizeWhitespace,
          ),
          'removeWhitespace': (tx.removeWhitespace, v1RemoveWhitespace),
          'oneLine': (tx.oneLine, v1OneLine),
          'removeEmptyLines': (tx.removeEmptyLines, v1RemoveEmptyLines),
          // Valid only for the hyphen separator; defect 3 changes the others.
          'slugify': (tx.slugify, v1SlugifyHyphen),
        };
    final listOps =
        <
          String,
          (List<String> Function(String), List<String> Function(String))
        >{
          'splitWhitespace': (tx.splitWhitespace, v1SplitWhitespace),
          'lines': (tx.lines, v1Lines),
        };

    final rng = Random(90210);
    for (var iter = 0; iter < 40000; iter++) {
      final input = _randomInput(rng, 10);
      for (final entry in stringOps.entries) {
        final (fresh, legacy) = entry.value;
        expect(
          fresh(input),
          legacy(input),
          reason: '${entry.key} diverged on "${_escape(input)}"',
        );
      }
      for (final entry in listOps.entries) {
        final (fresh, legacy) = entry.value;
        expect(
          fresh(input),
          legacy(input),
          reason: '${entry.key} diverged on "${_escape(input)}"',
        );
      }
    }
  });

  test('exhaustive over every 1-3 char string from a focused alphabet', () {
    // Small enough to brute force, dense enough to hit every boundary rule.
    const units = <String>['a', 'B', 'c', 'D', '_', '-', ' ', '1'];
    for (final x in units) {
      expect(scanWordsToList(x), _v1Normalized(x), reason: 'input: "$x"');
      for (final y in units) {
        final xy = '$x$y';
        expect(scanWordsToList(xy), _v1Normalized(xy), reason: 'input: "$xy"');
        for (final z in units) {
          final xyz = '$x$y$z';
          expect(
            scanWordsToList(xyz),
            _v1Normalized(xyz),
            reason: 'input: "$xyz"',
          );
        }
      }
    }
  });
}
