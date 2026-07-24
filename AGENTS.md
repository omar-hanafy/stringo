# stringo - agent guide (maintainers)

Zero-dependency pure-Dart string package. Public API is `lib/stringo.dart`,
which exports `lib/src/{case,transform,checks,regex_patterns}.dart`.

Extracted from `dart_helper_utils` in 2026; DHU 6.1.0+ depends on this package
and re-exports it, so every change here is also a change to DHU's public API.

## Validation gates (run before claiming any change done)

```bash
dart format --output=none --set-exit-if-changed .
dart analyze .                             # public_member_api_docs is enforced
dart test
dart run tool/validate_agent_plugin.dart   # AI plugin/marketplace consistency
dart pub publish --dry-run                 # must stay at 0 warnings
```

CI requires a PERFECT pana score on PRs ("CI / Pana" is a required check).
The 1.0.0 baseline is 160/160; avoid changes that cost points (missing doc
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
  digit boundaries, a leading separator yields an empty first word
  (`'_leading'.toCamelCase` is `'Leading'`), `clean`/`toOneLine` join without a
  separator, `truncate` appends the suffix on top of the length, and
  `toTrainCase`/`toPascalKebabCase` are intentional aliases. Do not "fix"
  these without a major release and a migration entry.
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
