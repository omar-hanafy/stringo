# stringo - agent guide (maintainers)

Zero-dependency pure-Dart string package. Public API is `lib/stringo.dart`.

Layers, depending strictly downward:

```
lib/src/chars.dart            code-unit classification, imports nothing
lib/src/word_scanner.dart     the engine: allocation-free tokenizer
lib/src/patterns.dart         String sources + precompiled RegExp
lib/src/ops/{case,transform,checks}.dart    the implementations
lib/src/core.dart             `Stringo` namespace, pure delegation
lib/src/extensions/{case,transform,checks}.dart   extensions, pure delegation
```

`core.dart` and `extensions/` are PEERS over `ops/`, not layered on each other.
Neither contains logic: every member is a one-line delegation, so the two
public surfaces cannot drift. Put behavior in `ops/`, never in a facade.

Extracted from `dart_helper_utils` in 2026; DHU 6.1.0+ depends on this package
and re-exports it, so every change here is also a change to DHU's public API.

## Validation gates (run before claiming any change done)

```bash
dart format --output=none --set-exit-if-changed .
dart analyze .                             # public_member_api_docs is enforced
dart test
dart run tool/validate_agent_plugin.dart   # AI plugin/marketplace consistency
dart pub publish --dry-run                 # must stay at 0 warnings
dart run benchmark/stringo_benchmark.dart  # optional, measures against 1.0.0
```

CI requires a PERFECT pana score on PRs ("CI / Pana" is a required check).
The 1.0.0 baseline was 160/160; avoid changes that cost points (missing doc
comments, dependency additions, format drift).

## Scope rule (the reason this package exists)

**stringo transforms text. It does NOT judge whether text is a valid instance
of a real-world concept.**

- IN: splitting, casing, trimming, slicing, masking, joining, character-class
  predicates. One correct answer, decidable from the characters alone.
- OUT: `isValidEmail`, `isValidPhoneNumber`, `isValidUrl`, `isValidUsername`,
  `isValidCurrency`, `isUuid`, `isValidIp4`, MIME checks. These live in
  `dart_helper_utils`. They have no single correct answer and generate
  unbounded maintenance.
- OUT: parsing text into typed values (`convert_object`), similarity and
  search (`string_search_algorithms`).

Reject feature requests that cross this line; point them at the right package.

## FFI was measured and rejected - do not revisit without new data

"Move the hot loops to Rust/C++ and call them through `dart:ffi`" comes up
periodically. It was measured for 2.0.0, with a real C dylib, not reasoned
about:

| 24-char identifier | ns/op |
| --- | --- |
| FFI round trip (alloc, encode, call, decode, free) | 164 |
| FFI with a pre-allocated reused buffer | 130 |
| Dart's built-in `toLowerCase()` | 20 |

FFI is 6.5x SLOWER at that size and still 4.8x slower at 100,000 characters.
Bare call overhead with no string work is 9.3 ns, which alone exceeds several
whole stringo operations. Dart strings are UTF-16, so crossing the boundary
forces an encode and a copy each way, while Dart's own string primitives are
already native code that never pays it.

It would also cost web support (`dart:ffi` does not exist on dart2js or
dart2wasm), require prebuilt binaries for roughly nine platform/arch
combinations, break the zero-dependency guarantee, and drop pana platform
points. Reject it unless someone brings a benchmark showing otherwise for a
workload with high compute per byte, which is not what this package does.

## ⚠️ The partition constraint

`dart_helper_utils` exports BOTH this package and its own string extensions.
**A member name must exist in exactly one of the two packages.** Adding a
member here that DHU already defines (or vice versa) produces
`The property 'x' is defined in multiple extensions` - a compile error for
every DHU user, not just the one who upgrades.

Before adding any public member, grep the DHU repo for the name.

## Zero dependencies is a hard constraint

`pubspec.yaml` has no `dependencies:` block and must not gain one. Only
`dart:core` and `dart:convert` are available. This is the package's entire
value proposition against `dart_helper_utils`. If a feature needs a
dependency, it belongs in DHU instead.

Consequence: `slugify` cannot transliterate (no `characters`/ICU), and
`toCharArray` cannot do grapheme clusters. These limits are documented in the
README and tested; do not "fix" them by adding a dependency.

## Conventions

- Extension names carry no vendor prefix and are grouped by concern:
  `StringCaseExtensions`, `NullableStringCaseExtensions`,
  `StringTransformExtensions`, `NullableStringTransformExtensions`,
  `StringChecksExtensions`. Renaming any of them is breaking with NO
  deprecation path (Dart cannot alias or deprecate an extension name), so get
  it right the first time.
- Any public API change needs matching tests in `test/` (one file per concern)
  and a doc comment on every public member.
- Behavior quirks are load-bearing and tested: `toWords` does not split on
  digit boundaries, `clean`/`toOneLine` join without a separator, and
  `toTrainCase`/`toPascalKebabCase` are intentional aliases with
  `toPascalKebabCase` as the canonical implementation. Do not "fix" these
  without a major release and a migration entry.
- Three invariants the engine depends on. Breaking any of them is silent:
  1. **The scanner never emits an empty word.** Leading, trailing, and
     repeated separator runs contribute nothing. `''.toWords` is `[]`.
  2. **The ASCII fast path must have a Unicode fallback.** Dart's casing is
     full Unicode, so an ASCII-only implementation corrupts non-English text.
     `'ÉCOLE'.toSnakeCase` must stay `'école'`.
  3. **`isBlank` is a scan, never an allocation.** It returns at the first
     non-whitespace code unit. It must not call `clean`, build a copy, or
     construct a `RegExp`. This is guarded by
     `test/performance_contract_test.dart`.
  4. **A scanner must never re-probe ground it already rejected.** When a
     forward probe fails, emit everything it walked and jump past it. Advancing
     one character and probing again is how `removeEmptyLines` stayed quadratic
     even after its regex was replaced: the first hand-written version
     reproduced the exact backtracking bug it was meant to remove. Guarded by a
     linearity contract, since the output was correct either way.
- **No `RegExp` inside a function body.** Dart does not cache compiled
  patterns, so that recompiles per call. Hoist to a top-level `final`.
  `test/regex_policy_test.dart` reads `lib/` and fails on violations; a
  genuine exception needs a `regex-policy-exempt:` comment stating why.
- The whitespace set in `chars.dart` is ECMAScript `\s`, proven equal to the
  1.0.0 regex across the whole BMP by test. Narrowing it to ASCII silently
  changes blank detection and word splitting for non-English text.
- Correctness is proven by differential fuzzing against the 1.0.0
  implementations in `test/reference/v1_reference.dart`, not by hand-written
  examples. When you change behavior deliberately, register the exception in
  `test/differential_fuzz_test.dart`; never edit the oracle to match new code.
- README claims are executable: `test/readme_examples_test.dart` mirrors every
  example and table row. Update it with the README.
- `toTitleCase` always capitalizes the first word, then honors
  `titleCaseExceptions`. That set is public API.

## Release process

1. Version bump lands via PR to `main`; `CHANGELOG.md` entry and
   `pubspec.yaml` version in the same PR.
2. Both plugin manifests' `version` must equal the `pubspec.yaml` version -
   bump them together (CI enforces via `tool/validate_agent_plugin.dart`).
3. Merge -> auto-release workflow creates tag `stringo-vX.Y.Z` + GitHub
   release; the tag triggers trusted publishing to pub.dev (OIDC, no manual
   credentials). Never re-use or overwrite an existing tag.
4. Any change to a member DHU re-exports needs a matching note in DHU's
   CHANGELOG, since DHU users see it without touching their own code.

## AI assistant plugin

- Canonical tree: `tooling/ai/stringo/` (one shared `skills/` set; manifests
  `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json`). Catalogs:
  `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json` at
  the repo root.
- Skill facts must match the source; when changing behavior in `lib/`, update
  the affected skill files in the same PR.
- The plugin tree, catalogs, `tool/`, and this file are excluded from the
  pub.dev archive via `.pubignore` - keep the archive free of partial plugin
  content.
- The sibling `dart_helper_utils` repository hosts its own plugin covering the
  wider utility surface; keep cross-references between the two consistent.
