/// Guards the package's regex policy at the source level.
///
/// Dart does not cache compiled patterns, so a `RegExp(...)` inside a function
/// body recompiles on every call. stringo 1.0.0 had one in almost every getter
/// and paid for it on every invocation. The policy for 2.0.0 is that a
/// `RegExp` may only be constructed in a top-level or static `final`
/// declaration, which compiles it exactly once per isolate.
///
/// This test reads the source rather than the behavior, because the cost is
/// invisible to a correctness test: a recompiling implementation still returns
/// the right answer.
library;

import 'dart:io';

import 'package:test/test.dart';

/// A `RegExp(` occurrence that is a lazily-initialized declaration, and so is
/// compiled once rather than per call.
final RegExp _allowedDeclaration = RegExp(
  r'^(final|static final|const)\s.*=\s*RegExp\(',
);

/// Marker that exempts the following lines, with a stated reason.
///
/// Exemptions must be deliberate and explain themselves in the source. The
/// only legitimate case is an entry point that takes a caller-supplied pattern
/// string, where per-call compilation is inherent rather than accidental.
const String _exemptMarker = 'regex-policy-exempt:';

void main() {
  test('no RegExp is constructed inside a function body in lib/', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      var exemptUntil = -1;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();

        if (trimmed.contains(_exemptMarker)) {
          // An exemption covers the declaration that follows it.
          exemptUntil = i + 30;
          continue;
        }
        if (!line.contains('RegExp(')) continue;

        // Doc comments reference RegExp by name; they compile nothing.
        if (trimmed.startsWith('///') || trimmed.startsWith('//')) continue;
        if (_allowedDeclaration.hasMatch(trimmed)) continue;
        if (i <= exemptUntil) continue;

        offenders.add('${entity.path}:${i + 1}: $trimmed');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'RegExp must be hoisted to a top-level or static final so it '
          'compiles once, not on every call:\n${offenders.join('\n')}',
    );
  });

  test('the guard itself detects a violation', () {
    // Proves the check above is not vacuously passing.
    const violation = 'return RegExp(r\'\\s+\').hasMatch(s);';
    expect(violation.contains('RegExp('), isTrue);
    expect(_allowedDeclaration.hasMatch(violation.trimLeft()), isFalse);

    const allowed = "final RegExp _wsRun = RegExp(r'\\s+');";
    expect(_allowedDeclaration.hasMatch(allowed), isTrue);
  });
}
