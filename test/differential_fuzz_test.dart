import 'dart:math';

import 'package:stringo/src/ops/case.dart' as ops;
import 'package:stringo/src/ops/checks.dart' as ck;
import 'package:stringo/src/title_case_exceptions.dart';
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
  '\r', '\r\n', // CR: reaches the \r\n and lone-\r branches
  '\u{0085}', // NEL: trimmed by trim(), NOT matched by \s
  '\u{FEFF}', // BOM: matched by \s AND trimmed
  '\u{00A0}', '\u{3000}', // NBSP, ideographic space
  '\u{00E9}', '\u{00C9}', // e-acute, E-acute
  '\u{00DF}', // sharp s: uppercases to two characters
  '\u{0130}', // dotted capital I: lowercases to two code units
  '\u{212A}', // Kelvin sign: non-ascii whose lowercase IS ascii
  // The only astral character here is an emoji, deliberately: it has no case
  // mapping, so the capitalize helpers still match 1.0.0 on it. A *cased*
  // astral character would make eight oracles diverge for a registered
  // reason rather than a wrong one, so that lives in its own group.
  '\u{1F600}', // surrogate pair
  'HTTP', 'Http', 'xY', 'ABc',
];

String _randomInput(Random rng, int maxPieces) =>
    _randomFrom(_alphabet, rng, maxPieces);

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

/// Asserts [fresh] equals [legacy], building the failure text only on failure.
///
/// The message is a callback rather than an `expect` reason because a reason
/// is evaluated eagerly: at roughly ten million comparisons, running [_escape]
/// on every PASSING iteration costs more than every operation under test
/// combined.
void _same<T>(String op, T fresh, T legacy, String Function() where) {
  if (fresh == legacy) return;
  fail('$op diverged on ${where()}\n  2.0.0: <$fresh>\n  1.0.0: <$legacy>');
}

/// [_same] for list results.
///
/// This has to exist separately: `==` on two `List`s is identity in Dart, so
/// routing a list through [_same] would report success forever.
void _sameList(
  String op,
  List<String> fresh,
  List<String> legacy,
  String Function() where,
) {
  if (fresh.length == legacy.length) {
    var i = 0;
    while (i < fresh.length && fresh[i] == legacy[i]) {
      i++;
    }
    if (i == fresh.length) return;
  }
  fail('$op diverged on ${where()}\n  2.0.0: $fresh\n  1.0.0: $legacy');
}

/// [_randomInput] over an arbitrary alphabet.
String _randomFrom(List<String> alphabet, Random rng, int maxPieces) {
  final pieces = rng.nextInt(maxPieces);
  final b = StringBuffer();
  for (var i = 0; i < pieces; i++) {
    b.write(alphabet[rng.nextInt(alphabet.length)]);
  }
  return b.toString();
}

/// Inputs shaped so an anchored pattern can actually match.
///
/// `^[a-zA-Z0-9]+$` is false for virtually every string the main alphabet
/// produces, so fuzzing the checks there would only prove that both versions
/// agree on `false`. These are short strings over a narrow alphabet, padded
/// with whitespace often enough to drive the `trim()` inside isNumeric and
/// isAlphabet.
String _randomCheckInput(Random rng) {
  const core = <String>['a', 'B', 'z', '0', '9', '\u{00E9}', '_', '-', ' '];
  final b = StringBuffer();
  if (rng.nextBool()) b.write(' ' * rng.nextInt(3));
  b.write(_randomFrom(core, rng, 5));
  if (rng.nextBool()) b.write('\t' * rng.nextInt(3));
  return b.toString();
}

/// Flips the case of ASCII letters at random.
///
/// The result is always case-equal to [s] for ASCII input, which is exactly
/// what drives the equal-length fast path all the way to its `return true`.
String _flipAsciiCase(String s, Random rng) {
  final units = List<int>.of(s.codeUnits);
  for (var i = 0; i < units.length; i++) {
    if (!rng.nextBool()) continue;
    final u = units[i];
    if (u >= 0x41 && u <= 0x5A) {
      units[i] = u + 32;
    } else if (u >= 0x61 && u <= 0x7A) {
      units[i] = u - 32;
    }
  }
  return String.fromCharCodes(units);
}

/// Replaces one code unit, keeping the length identical.
///
/// Length-preserving on purpose: a differing length skips the fast path
/// entirely, so a naive mutation would silently stop testing it.
String _mutateOneUnit(String s, Random rng) {
  if (s.isEmpty) return 'a';
  const swaps = <int>[0x61, 0x41, 0x7A, 0x30, 0x5F, 0x00E9, 0x00C9, 0x212A];
  final units = List<int>.of(s.codeUnits);
  units[rng.nextInt(units.length)] = swaps[rng.nextInt(swaps.length)];
  return String.fromCharCodes(units);
}

/// The second argument of a case-insensitive comparison, generated so the
/// comparison is worth making.
///
/// An unrelated random string is unequal almost always and exits on the length
/// check, exercising neither the ASCII loop nor its `break`. These shapes
/// cover the identity short circuit, an equal-length case variant (the
/// `return true` exit), a one-unit difference (the early `return false`),
/// whole-string folds that can change length, a length near-miss, an
/// unrelated string, and null.
String? _partnerFor(String a, Random rng) => switch (rng.nextInt(8)) {
  0 => a,
  1 => _flipAsciiCase(a, rng),
  2 => a.toUpperCase(),
  3 => a.toLowerCase(),
  4 => _mutateOneUnit(a, rng),
  5 => a.isEmpty ? '' : a.substring(0, a.length - 1),
  6 => _randomInput(rng, 8),
  _ => null,
};

/// A delimiter with a realistic chance of occurring in [s].
///
/// A random string is essentially never a substring of another random string,
/// so a naive generator exercises only the `indexOf == -1` branch of
/// replaceAfter/replaceBefore and only the false branch of removeSurrounding.
/// The empty delimiter is deliberate: `indexOf('')` is 0 and `startsWith('')`
/// is true, which is a boundary both versions must agree on.
String _randomDelimiter(String s, Random rng) {
  switch (rng.nextInt(6)) {
    case 0:
      return '';
    case 1:
      return s;
    case 2:
      return s.isEmpty ? '' : s.substring(0, rng.nextInt(s.length) + 1);
    case 3:
      if (s.isEmpty) return '';
      final start = rng.nextInt(s.length);
      // May slice a surrogate pair in half. That is a legal Dart string and
      // both versions match by code unit, so it is a real case, not a bug.
      return s.substring(start, start + 1 + rng.nextInt(s.length - start));
    case 4:
      return _alphabet[rng.nextInt(_alphabet.length)];
    default:
      return _randomInput(rng, 3);
  }
}

/// The optional `defaultValue`, consulted only when it is NOT blank.
/// Whitespace-only values matter: that is where both versions call isBlank.
String? _randomFallback(Random rng) => switch (rng.nextInt(4)) {
  0 => null,
  1 => '',
  2 => ' \t\u{00A0}',
  _ => _randomInput(rng, 3),
};

/// Whether [s] contains a well-formed surrogate pair.
///
/// 1.0.0 split by code unit, so it tore these in half. That is one of the two
/// registered differences for `characters`.
bool _hasSurrogatePair(String s) {
  for (var i = 0; i + 1 < s.length; i++) {
    final hi = s.codeUnitAt(i);
    final lo = s.codeUnitAt(i + 1);
    if (hi >= 0xD800 && hi <= 0xDBFF && lo >= 0xDC00 && lo <= 0xDFFF) {
      return true;
    }
  }
  return false;
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

  test('no divergence anywhere in the BMP, in four contexts', () {
    // The random fuzz above draws from a fixed alphabet, so it can only find
    // bugs involving characters someone thought to include. This sweeps every
    // code point in the Basic Multilingual Plane instead, which is what
    // actually pins the ASCII fast path: a character whose Unicode case
    // mapping differs from its ASCII one, or that the scanner misclassifies,
    // shows up here even though nobody predicted it.
    var divergences = 0;
    for (var c = 0; c <= 0xFFFF; c++) {
      if (c >= 0xD800 && c <= 0xDFFF) continue; // lone surrogates below
      final ch = String.fromCharCode(c);
      for (final probe in ['a${ch}B', '${ch}ab', 'ab$ch', 'A${ch}a']) {
        if (scanWordsToList(probe).join('|') !=
                _v1Normalized(probe).join('|') ||
            ops.snakeCase(probe) != v1SnakeCase(probe) ||
            ops.pascalCase(probe) != v1PascalCase(probe) ||
            ops.screamingCase(probe) != v1ScreamingCase(probe) ||
            ops.camelCase(probe) != v1CamelCase(probe)) {
          divergences++;
          if (divergences <= 5) {
            printOnFailure(
              'diverged at U+${c.toRadixString(16)} '
              'in "${_escape(probe)}"',
            );
          }
        }
      }
    }
    expect(divergences, 0, reason: 'see printed code points above');
  });

  test('lone surrogates do not break the scanner', () {
    // Malformed UTF-16 that a code-unit scanner could mishandle.
    for (final lone in [0xD800, 0xDBFF, 0xDC00, 0xDFFF]) {
      final ch = String.fromCharCode(lone);
      for (final probe in ['a${ch}B', ch, '$ch$ch', '_$ch', '$ch$ch$ch']) {
        expect(
          scanWordsToList(probe),
          _v1Normalized(probe),
          reason: 'lone U+${lone.toRadixString(16)}',
        );
        expect(ops.snakeCase(probe), v1SnakeCase(probe));
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

  // -------------------------------------------------------------------------
  // Checks. 1.0.0 answered these with regexes; 2.0.0 answers most with scans.
  // -------------------------------------------------------------------------

  test('every check matches its v1 implementation', () {
    final checks = <String, (bool Function(String?), bool Function(String?))>{
      'isBlank': (ck.isBlank, v1IsBlank),
      'isNotBlank': (ck.isNotBlank, v1IsNotBlank),
      'isAlphanumeric': (ck.isAlphanumeric, v1IsAlphanumeric),
      'isNumeric': (ck.isNumeric, v1IsNumeric),
      'isAlphabet': (ck.isAlphabet, v1IsAlphabet),
      'startsWithNumber': (ck.startsWithNumber, v1StartsWithNumber),
      'containsDigits': (ck.containsDigits, v1ContainsDigits),
      'hasCapitalLetter': (ck.hasCapitalLetter, v1HasCapitalLetter),
    };

    final rng = Random(60613);
    for (var iter = 0; iter < 30000; iter++) {
      final String? input = switch (iter % 20) {
        0 => null,
        1 => '',
        _ => iter.isEven ? _randomInput(rng, 8) : _randomCheckInput(rng),
      };
      String where() => 'input "${input == null ? '<null>' : _escape(input)}"';
      for (final e in checks.entries) {
        final (fresh, legacy) = e.value;
        _same(e.key, fresh(input), legacy(input), where);
      }
    }
  });

  test('every check agrees with its v1 regex across the whole BMP', () {
    // This is what actually pins isBlank's reimplementation: it proves
    // isWhitespaceUnit equals ECMAScript \s character by character, rather
    // than only through whatever the generator happened to produce.
    var divergences = 0;
    for (var c = 0; c <= 0xFFFF; c++) {
      if (c >= 0xD800 && c <= 0xDFFF) continue;
      final ch = String.fromCharCode(c);
      for (final probe in [ch, ' $ch ', 'a$ch', '$ch\n']) {
        if (ck.isBlank(probe) != v1IsBlank(probe) ||
            ck.isNumeric(probe) != v1IsNumeric(probe) ||
            ck.isAlphabet(probe) != v1IsAlphabet(probe) ||
            ck.isAlphanumeric(probe) != v1IsAlphanumeric(probe) ||
            ck.startsWithNumber(probe) != v1StartsWithNumber(probe) ||
            ck.containsDigits(probe) != v1ContainsDigits(probe) ||
            ck.hasCapitalLetter(probe) != v1HasCapitalLetter(probe)) {
          divergences++;
          if (divergences <= 5) {
            printOnFailure('diverged at U+${c.toRadixString(16)}');
          }
        }
      }
    }
    expect(divergences, 0, reason: 'see printed code points above');
  });

  // -------------------------------------------------------------------------
  // equalsIgnoreCase. The riskiest rewrite: 2.0.0 added a hand-rolled ASCII
  // fast path with an early break that 1.0.0 had no equivalent of.
  // -------------------------------------------------------------------------

  test('equalsIgnoreCase matches v1 over related and unrelated pairs', () {
    final rng = Random(1071);
    for (var iter = 0; iter < 40000; iter++) {
      final a = _randomInput(rng, 8);
      final b = _partnerFor(a, rng);
      String where() =>
          'a "${_escape(a)}" b "${b == null ? '<null>' : _escape(b)}"';
      _same(
        'equalsIgnoreCase',
        ck.equalsIgnoreCase(a, b),
        v1EqualsIgnoreCase(a, b),
        where,
      );
      // The contract is symmetric. The fast path is not obviously so: it
      // reads a.length, and it breaks when EITHER side is non-ascii.
      _same(
        'equalsIgnoreCase/swapped',
        ck.equalsIgnoreCase(b, a),
        v1EqualsIgnoreCase(b, a),
        where,
      );
    }
  });

  test('equalsIgnoreCase matches v1 on fast-path pathologies', () {
    // The shape that would actually break the early `break` is one a random
    // generator will not reliably produce: a long matching ASCII run followed
    // by a non-ascii unit at the very end.
    final pairs = <(String?, String?)>[
      ('', ''), ('', 'a'), (null, ''), ('a', null), (null, null),
      ('ABC', 'abc'), ('ABC', 'abd'), ('ABC', 'ABCD'),
      ('\u{212A}x', 'kX'), // non-ascii at index 0: break before any compare
      ('x\u{212A}', 'xk'), // non-ascii after a match: break mid-loop
      ('y\u{212A}', 'xk'), // ascii mismatch BEFORE it: must return false
      ('stra\u{00DF}e', 'STRASSE'),
      ('stra\u{00DF}e', 'STRA\u{00DF}E'),
      ('\u{0130}', 'i\u{0307}'),
      ('\u{D800}A', '\u{D800}a'), // lone surrogate
      ('\u{1F600}', '\u{1F600}'),
      ('a' * 10000, 'A' * 10000),
      ('${'a' * 9999}b', '${'A' * 9999}C'),
      // 9,999 matching ascii units, then a non-ascii pair that must fall
      // through to the unicode path and still answer true.
      ('${'a' * 9999}\u{00E9}', '${'A' * 9999}\u{00C9}'),
    ];
    for (final (a, b) in pairs) {
      _same(
        'equalsIgnoreCase',
        ck.equalsIgnoreCase(a, b),
        v1EqualsIgnoreCase(a, b),
        () => 'a=<$a> b=<$b>',
      );
      _same(
        'equalsIgnoreCase/swapped',
        ck.equalsIgnoreCase(b, a),
        v1EqualsIgnoreCase(b, a),
        () => 'a=<$b> b=<$a>',
      );
    }
  });

  test('hasMatch matches v1 across a pattern and flag battery', () {
    // Both versions compile per call by contract, so this loop is two orders
    // of magnitude shorter than the others. It is a regression guard for the
    // day someone tries to cache or rewrite them, not proof of anything
    // subtle.
    const patterns = <String>[
      '',
      'a',
      'A',
      r'^\d',
      r'\d',
      '[A-Z]',
      r'^[a-zA-Z0-9]+$',
      r'^\d+$',
      r'\s+',
      'a.b',
      r'^b',
      '(a|b)+',
      '[-_]',
    ];
    const flags = <(bool, bool, bool, bool)>[
      (false, true, false, false),
      (true, true, false, false),
      (false, false, false, false),
      (false, true, false, true),
      (false, true, true, false),
    ];
    final rng = Random(8080);
    for (var iter = 0; iter < 500; iter++) {
      final String? input = iter == 0 ? null : _randomInput(rng, 8);
      for (final p in patterns) {
        for (final (multiLine, caseSensitive, unicode, dotAll) in flags) {
          _same(
            'hasMatch',
            ck.hasMatch(
              input,
              p,
              multiLine: multiLine,
              caseSensitive: caseSensitive,
              unicode: unicode,
              dotAll: dotAll,
            ),
            v1HasMatch(
              input,
              p,
              multiLine: multiLine,
              caseSensitive: caseSensitive,
              unicode: unicode,
              dotAll: dotAll,
            ),
            () =>
                'pattern "$p" input '
                '"${input == null ? '<null>' : _escape(input)}"',
          );
        }
      }
    }
  });

  // -------------------------------------------------------------------------
  // Transforms that take arguments.
  // -------------------------------------------------------------------------

  test('argument-taking transforms match their v1 implementations', () {
    const maskChars = <String>['*', '#', '', 'xy', '\u{1F600}'];
    final rng = Random(5150);
    for (var iter = 0; iter < 20000; iter++) {
      final s = _randomInput(rng, 8);
      final index = rng.nextInt(s.length + 1);
      final value = _randomInput(rng, 3);
      final d = _randomDelimiter(s, rng);
      final replacement = _randomInput(rng, 3);
      final fallback = _randomFallback(rng);
      final vs = rng.nextInt(4);
      final ve = rng.nextInt(4);
      final ch = maskChars[rng.nextInt(maskChars.length)];
      String where() => 's="${_escape(s)}" d="${_escape(d)}"';

      _same(
        'insert',
        tx.insert(s, index, value),
        v1Insert(s, index, value),
        () => '${where()} index=$index',
      );
      _same(
        'mask',
        tx.mask(s, visibleStart: vs, visibleEnd: ve, char: ch),
        v1Mask(s, visibleStart: vs, visibleEnd: ve, char: ch),
        () => '${where()} start=$vs end=$ve char="$ch"',
      );
      _same(
        'removeSurrounding',
        tx.removeSurrounding(s, d),
        v1RemoveSurrounding(s, d),
        where,
      );
      // A random delimiter almost never surrounds a random string, so the
      // strip branch needs a subject built to trigger it.
      final wrapped = '$d$s$d';
      _same(
        'removeSurrounding/wrapped',
        tx.removeSurrounding(wrapped, d),
        v1RemoveSurrounding(wrapped, d),
        () => 'wrapped "${_escape(wrapped)}"',
      );
      _same(
        'replaceAfter',
        tx.replaceAfter(s, d, replacement, fallback),
        v1ReplaceAfter(s, d, replacement, fallback),
        () => '${where()} default=<$fallback>',
      );
      _same(
        'replaceBefore',
        tx.replaceBefore(s, d, replacement, fallback),
        v1ReplaceBefore(s, d, replacement, fallback),
        () => '${where()} default=<$fallback>',
      );
    }

    // Argument validation is part of the contract; both versions throw.
    expect(() => tx.mask('abc', visibleStart: -1), throwsArgumentError);
    expect(() => v1Mask('abc', visibleStart: -1), throwsArgumentError);
    expect(() => tx.insert('abc', 4, 'x'), throwsRangeError);
    expect(() => v1Insert('abc', 4, 'x'), throwsRangeError);
  });

  // -------------------------------------------------------------------------
  // title and shouldIgnoreCapitalization, previously unfuzzed entirely.
  // -------------------------------------------------------------------------

  test('title and shouldIgnoreCapitalization match their v1 versions', () {
    final rng = Random(19937);
    for (var iter = 0; iter < 40000; iter++) {
      final input = _randomInput(rng, 10);
      _same(
        'title',
        ops.title(input),
        v1Title(input),
        () => 'input "${_escape(input)}"',
      );
      _sameList(
        'words',
        ops.words(input),
        v1WordsNonEmpty(input),
        () => 'input "${_escape(input)}"',
      );
      for (final w in ops.words(input)) {
        _same(
          'shouldIgnoreCapitalization',
          ops.shouldIgnoreCapitalization(w),
          v1ShouldIgnoreCapitalization(w),
          () => 'word "${_escape(w)}"',
        );
      }
    }
    // A random string is essentially never in titleCaseExceptions, so the
    // true branch needs the set itself.
    for (final w in titleCaseExceptions) {
      for (final variant in [w, w.toUpperCase(), ops.capitalizeFirst(w)]) {
        _same(
          'shouldIgnoreCapitalization',
          ops.shouldIgnoreCapitalization(variant),
          v1ShouldIgnoreCapitalization(variant),
          () => 'word "$variant"',
        );
      }
    }
    for (final w in ['', '1', '1a', 'a1', '\u{00E9}']) {
      _same(
        'shouldIgnoreCapitalization',
        ops.shouldIgnoreCapitalization(w),
        v1ShouldIgnoreCapitalization(w),
        () => 'word "${_escape(w)}"',
      );
    }
  });

  // -------------------------------------------------------------------------
  // Registered behavior changes.
  //
  // These ops deliberately differ from 1.0.0, so they cannot be compared for
  // equality. Each change is instead stated as "identical to 1.0.0 EXCEPT
  // here", which is stronger than a property test alone: it also catches a
  // second, unregistered change riding along with the intended one.
  // -------------------------------------------------------------------------

  test('truncate differs from v1 only by counting its suffix', () {
    final rng = Random(2468);
    for (var iter = 0; iter < 20000; iter++) {
      final s = _randomInput(rng, 8);
      final n = rng.nextInt(s.length + 4) - 1; // -1 .. length + 2
      // With no suffix there is nothing to account for, so the two must agree
      // EXACTLY. A divergence here is a bug, not the registered change.
      _same(
        'truncate/no-suffix',
        tx.truncate(s, n, suffix: ''),
        v1Truncate(s, n, suffix: ''),
        () => 's="${_escape(s)}" n=$n',
      );
      // The CHANGELOG migration note, made executable: asking for
      // length + suffix.length reproduces the 1.0.0 output exactly.
      if (n > 0 && s.length > n + 3) {
        _same(
          'truncate/migration',
          tx.truncate(s, n + 3),
          v1Truncate(s, n),
          () => 's="${_escape(s)}" n=$n',
        );
      }
    }
    // And the change itself, both sides asserted so it is visible in a diff.
    expect(tx.truncate('Hello World', 5), 'He...');
    expect(v1Truncate('Hello World', 5), 'Hello...');
  });

  test('characters differs from v1 only by code point and the blank gate', () {
    final rng = Random(1357);
    var compared = 0;
    for (var iter = 0; iter < 20000; iter++) {
      final s = _randomInput(rng, 8);
      // The two registered differences, stated as the only exclusions.
      if (v1IsBlank(s) || _hasSurrogatePair(s)) continue;
      _sameList(
        'characters',
        tx.characters(s),
        v1ToCharArray(s),
        () => 's="${_escape(s)}"',
      );
      compared++;
    }
    expect(compared, greaterThan(1000), reason: 'exclusions ate the sample');
    // Difference 1: code points, not code units.
    expect(tx.characters('\u{1F600}'), ['\u{1F600}']);
    expect(v1ToCharArray('\u{1F600}').length, 2, reason: '1.0.0 tore the pair');
    // Difference 2: the op has no blank gate; the extension still does.
    expect(tx.characters('  '), [' ', ' ']);
    expect(v1ToCharArray('  '), isEmpty);
  });

  test('slugify differs from v1 only in how a literal hyphen is treated', () {
    for (final sep in ['_', '.', '::']) {
      expect(tx.slugify('a-b', separator: sep), 'a${sep}b');
      expect(v1SlugifyGeneral('a-b', separator: sep), 'a-b');
    }
    // With no literal hyphen in the input the two still agree, for separators
    // whose 1.0.0 regex round trip was sound. See v1SlugifyGeneral for why
    // this cannot be claimed generally.
    final rng = Random(31415);
    for (var iter = 0; iter < 10000; iter++) {
      final s = _randomInput(rng, 8).replaceAll('-', '');
      for (final sep in ['_', '.']) {
        _same(
          'slugify/$sep',
          tx.slugify(s, separator: sep),
          v1SlugifyGeneral(s, separator: sep),
          () => 's="${_escape(s)}"',
        );
      }
    }
  });
}
