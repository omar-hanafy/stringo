# stringo agent plugin

Package-specific AI coding-assistant support for the
[stringo](https://pub.dev/packages/stringo) Dart package, installable in Claude
Code and OpenAI Codex from this repository. It ships skills only - no hooks, no
MCP servers, no telemetry, no network access.

## Capabilities

| Skill | Use it for |
|---|---|
| `use-stringo` | Exact member names and semantics across the string surface (case conversion, `toWords`, slugify, truncate, mask, whitespace, blank and character checks), plus the documented ASCII/Unicode limits and the scope rule that keeps domain validation out of this package |
| `migrate-to-stringo-from-dart-helper-utils` | Moving string code off `dart_helper_utils`, deciding whether the move is worth it, and the two things that changed in DHU 6.1.0 (extension type names, first-word title casing) |

## Install in Claude Code

```
/plugin marketplace add omar-hanafy/stringo
/plugin install stringo@stringo-tools
```

Skills auto-trigger on relevant work; invoke one explicitly with
`/stringo:use-stringo` (same pattern for the other).

## Install in Codex

```
codex plugin marketplace add omar-hanafy/stringo
codex plugin install stringo@stringo-tools
```

## Related plugins

- [`dart-helper-utils`](https://github.com/omar-hanafy/dart_helper_utils) -
  the wider utility belt that re-exports this package.
- [`convert-object`](https://github.com/omar-hanafy/convert_object) - typed
  conversion and JSON parsing.

## Maintenance

The plugin `version` in both manifests must equal the `version` in
`pubspec.yaml`. `dart run tool/validate_agent_plugin.dart` enforces this in CI,
along with catalog syntax, kebab-case identifiers, skill frontmatter, and pub
archive exclusions.
