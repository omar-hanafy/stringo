/// Benchmark suite for stringo.
///
/// Run with:
///
/// ```
/// dart run benchmark/stringo_benchmark.dart
/// ```
///
/// Reports nanoseconds per operation. This is for humans comparing runs on one
/// machine, not a CI gate: correctness and algorithmic complexity are asserted
/// by `test/performance_contract_test.dart`, which cannot flake on a noisy
/// runner the way a wall-clock threshold would.
///
/// Each case also runs the stringo 1.0.0 implementation of the same operation
/// so the speedup is measured rather than claimed. The 1.0.0 versions live in
/// this file only, and are never imported by `lib/`.
library;

import 'package:stringo/stringo.dart';

// ---------------------------------------------------------------------------
// stringo 1.0.0 implementations, for comparison only.
// ---------------------------------------------------------------------------

final RegExp _v1Split = RegExp(
  r'(?<=[a-z])(?=[A-Z])|[_\-\s]+|(?<=[A-Z])(?=[A-Z][a-z])',
);

List<String> _v1Words(String s) => s.split(_v1Split);

String _v1Cap(String s) =>
    _v1IsBlank(s) ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

/// The 1.0.0 blank check: two whole-string allocations plus a compiled regex.
bool _v1IsBlank(String? s) =>
    s == null || s.replaceAll('\n', '').replaceAll(RegExp(r'\s+'), '').isEmpty;

String _v1SnakeCase(String s) => _v1Words(s).join('_').toLowerCase();

String _v1CamelCase(String s) {
  final w = _v1Words(s);
  for (var i = 0; i < w.length; i++) {
    w[i] = i == 0 ? w[i].toLowerCase() : _v1Cap(w[i]);
  }
  return w.join();
}

String _v1NormalizeWhitespace(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// The 1.0.0 blank-line collapse. This pattern backtracks catastrophically on
/// a run of spaces that is not followed by a line break.
final RegExp _v1BlankLines = RegExp(r'(?:[\t ]*(?:\r?\n|\r))+');

String _v1RemoveEmptyLines(String s) => s.replaceAll(_v1BlankLines, '\n');

String _v1Slugify(String s) {
  final normalized = _v1NormalizeWhitespace(s).toLowerCase();
  if (normalized.isEmpty) return '';
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
      .replaceAll(RegExp(r'[_\s]+'), '-')
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

int _sink = 0;

double _nsPerOp(int iterations, void Function() body) {
  for (var i = 0; i < iterations ~/ 10 + 1; i++) {
    body();
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    body();
  }
  sw.stop();
  return sw.elapsedMicroseconds * 1000 / iterations;
}

void _compare(
  String label,
  int iterations,
  void Function() before,
  void Function() after,
) {
  final v1 = _nsPerOp(iterations, before);
  final v2 = _nsPerOp(iterations, after);
  final speedup = v1 / v2;
  print(
    '  ${label.padRight(34)}'
    '${_fmt(v1).padLeft(14)}${_fmt(v2).padLeft(14)}'
    '${'${speedup.toStringAsFixed(1)}x'.padLeft(10)}',
  );
}

String _fmt(double ns) => ns >= 100000
    ? '${(ns / 1000).toStringAsFixed(0)}us'
    : '${ns.toStringAsFixed(0)}ns';

void _header(String title) {
  print('\n$title');
  print(
    '  ${'operation'.padRight(34)}${'1.0.0'.padLeft(14)}'
    '${'2.0.0'.padLeft(14)}${'gain'.padLeft(10)}',
  );
  print('  ${'-' * 70}');
}

void main() {
  print('stringo benchmark');
  print('Dart ${_dartVersion()}');

  _header('Blank detection (the headline defect)');
  for (final n in [10, 1000, 100000]) {
    final s = 'x' * n;
    final iterations = n > 10000 ? 2000 : 200000;
    _compare(
      'isBlank, $n chars',
      iterations,
      () {
        if (_v1IsBlank(s)) _sink++;
      },
      () {
        if (s.isBlank) _sink++;
      },
    );
  }

  _header('Case conversion');
  const identifier = 'someUserProfileFieldName';
  _compare(
    'toWords',
    200000,
    () {
      _sink += _v1Words(identifier).length;
    },
    () {
      _sink += identifier.toWords.length;
    },
  );
  _compare(
    'toSnakeCase',
    200000,
    () {
      _sink += _v1SnakeCase(identifier).length;
    },
    () {
      _sink += identifier.toSnakeCase.length;
    },
  );
  _compare(
    'toCamelCase',
    200000,
    () {
      _sink += _v1CamelCase(identifier).length;
    },
    () {
      _sink += identifier.toCamelCase.length;
    },
  );

  _header('Transformation');
  const title = 'Hello, World! This is a Blog Post Title (2026 Edition)';
  _compare(
    'slugify, ${title.length} chars',
    50000,
    () {
      _sink += _v1Slugify(title).length;
    },
    () {
      _sink += title.slugify().length;
    },
  );
  const messy = '  Some   messy \n text \t with  spacing  ';
  _compare(
    'normalizeWhitespace',
    200000,
    () {
      _sink += _v1NormalizeWhitespace(messy).length;
    },
    () {
      _sink += messy.normalizeWhitespace().length;
    },
  );

  _header('Blank-line collapse (the other pathological case)');
  final indented = List.filled(400, '${' ' * 40}line').join('\n');
  _compare(
    'removeEmptyLines, 400 indented lines',
    2000,
    () {
      _sink += _v1RemoveEmptyLines(indented).length;
    },
    () {
      _sink += indented.removeEmptyLines.length;
    },
  );
  final spaceRun = ' ' * 8000;
  _compare(
    'removeEmptyLines, 8 KB unbroken run',
    50,
    () {
      _sink += _v1RemoveEmptyLines(spaceRun).length;
    },
    () {
      _sink += spaceRun.removeEmptyLines.length;
    },
  );

  _serverWorkload();

  if (_sink == -1) print('unreachable');
}

/// The shape that actually matters on a server: many short identifiers.
void _serverWorkload() {
  const count = 200000;
  final corpus = List.generate(count, (i) => 'userProfileField$i');

  print('\nServer workload: $count identifiers to snake_case');
  print('  ${'-' * 70}');

  var sw = Stopwatch()..start();
  var total = 0;
  for (final s in corpus) {
    total += _v1SnakeCase(s).length;
  }
  sw.stop();
  final v1Ms = sw.elapsedMilliseconds;

  sw = Stopwatch()..start();
  for (final s in corpus) {
    total += s.toSnakeCase.length;
  }
  sw.stop();
  final v2Ms = sw.elapsedMilliseconds;

  print('  1.0.0: ${v1Ms}ms');
  print('  2.0.0: ${v2Ms}ms');
  if (v2Ms > 0) {
    print('  gain : ${(v1Ms / v2Ms).toStringAsFixed(1)}x');
  }
  _sink += total;
}

String _dartVersion() {
  // Version.toString() is verbose; keep only the leading semver.
  final full = const String.fromEnvironment('dart.version', defaultValue: '');
  return full.isEmpty ? '(current)' : full;
}
