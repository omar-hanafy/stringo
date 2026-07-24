# stringo

[![pub package](https://img.shields.io/pub/v/stringo.svg)](https://pub.dev/packages/stringo)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

A zero-dependency string toolkit for Dart: case conversion, word splitting,
slugs, truncation, masking, and whitespace normalization.

```dart
import 'package:stringo/stringo.dart';

'hello_world'.toCamelCase;        // 'helloWorld'
'parseHTTPResponse'.toSnakeCase;  // 'parse_http_response'
'Hello, World!'.slugify();        // 'hello-world'
'the lord of the rings'.toTitleCase; // 'The Lord of the Rings'
'1234567890'.mask(visibleStart: 2, visibleEnd: 2); // '12******90'
```

## Install

```yaml
dependencies:
  stringo: ^1.0.0
```

## What it does

**stringo operates on the text.** Splitting, casing, trimming, slicing,
masking, joining.

**It does not adjudicate whether text is a valid instance of a real-world
concept.** There is no `isValidEmail`, no `isValidPhoneNumber`, no
`isValidUrl`. Those rules differ per project and change over time; a package
that ships one opinion about them is a package you end up fighting. Keep those
in the layer that owns the rule.

## API

### Case conversion

Every conversion runs through `toWords`, so any input shape works -
`camelCase`, `PascalCase`, `snake_case`, `kebab-case`, or plain spaced text.

| Getter | `'helloWorld'` becomes |
| --- | --- |
| `toWords` | `['hello', 'World']` |
| `toCamelCase` | `helloWorld` |
| `toPascalCase` | `HelloWorld` |
| `toSnakeCase` | `hello_world` |
| `toKebabCase` | `hello-world` |
| `toDotCase` | `hello.world` |
| `toTitleCase` | `Hello World` |
| `toScreamingSnakeCase` | `HELLO_WORLD` |
| `toScreamingKebabCase` | `HELLO-WORLD` |
| `toPascalSnakeCase` | `Hello_World` |
| `toPascalKebabCase` / `toTrainCase` | `Hello-World` |
| `toCamelSnakeCase` | `hello_World` |
| `toCamelKebabCase` | `hello-World` |
| `toFlatCase` | `helloworld` |
| `toScreamingCase` | `HELLOWORLD` |

`toWords` understands acronym boundaries: `'parseHTTPResponse'.toWords` gives
`['parse', 'HTTP', 'Response']`.

Also: `capitalizeFirstLetter`, `lowercaseFirstLetter`,
`capitalizeFirstLowerRest`, `toTitle` (title-cases while preserving `-` and
`_`), and `tryToLowerCase()` / `tryToUpperCase()` for nullable strings.

`toTitleCase` always capitalizes the first word, then leaves the articles,
conjunctions, and short prepositions in `titleCaseExceptions` lowercase. That
list is public, so you can inspect it or build your own rule on top.

### Transforms

```dart
'  Line   1 \n Line 2  '.normalizeWhitespace(); // 'Line 1 Line 2'
'Line1\n\n\nLine2'.removeEmptyLines;            // 'Line1\nLine2'
'a b\nc'.clean;                                 // 'abc'
'Hello World'.words;                            // ['Hello', 'World']
'a\r\nb'.lines;                                 // ['a', 'b']
'Hello World'.truncate(5);                      // 'Hello...'
'"quoted"'.removeSurrounding('"');              // 'quoted'
'foo=bar'.replaceAfter('=', 'baz');             // 'foo=baz'
'abc'.insert(1, 'Z');                           // 'aZbc'
```

Plus `nullIfEmpty`, `nullIfBlank`, `orEmpty`, `toOneLine`, `removeWhiteSpaces`,
`toCharArray()`, `equalsIgnoreCase`, and `mask()`.

Most of these are defined on `String?` and handle null without a bang
operator.

### Checks

Character-level predicates only: `isBlank` / `isEmptyOrNull` (and their
negations), `isNumeric`, `isAlphabet`, `isAlphanumeric`, `startsWithNumber`,
`containsDigits`, `hasCapitalLetter`, and `hasMatch(pattern)`.

The underlying patterns are exported too (`regexNumeric`, `regexAlphabet`,
`regexAlphanumeric`, `regexStartsWithNumber`, `regexContainsDigits`,
`regexHasCapitalLetter`) so you can reuse the exact same rule elsewhere.

## Known limitations

These are deliberate, documented behaviors rather than bugs:

- **`slugify` is ASCII-only.** Characters outside `a-z0-9` are dropped, not
  transliterated, so `'Café'.slugify()` gives `'caf'`. Normalize accented text
  first if you need it preserved.
- **`toCharArray()` splits by UTF-16 code unit,** so text containing emoji is
  split mid-character. Use `package:characters` when you need grapheme
  clusters.
- **`toWords` does not split on digit boundaries:** `'user2Name'` stays one
  word.
- **Character checks are ASCII-only.** `isAlphabet` is `A-Z` and `a-z`.

## Related packages

| Need | Package |
| --- | --- |
| Type conversion and JSON parsing | [`convert_object`](https://pub.dev/packages/convert_object) |
| Fuzzy matching, similarity, substring search | [`string_search_algorithms`](https://pub.dev/packages/string_search_algorithms) |
| The wider Dart utility belt (this package re-exported, plus collections, dates, intl) | [`dart_helper_utils`](https://pub.dev/packages/dart_helper_utils) |

If you already depend on `dart_helper_utils`, you have `stringo` - it is
re-exported there, and no import change is needed.

## AI coding-assistant support

This repository ships an installable plugin with package-specific skills for
Claude Code and OpenAI Codex.

```bash
# Claude Code
/plugin marketplace add omar-hanafy/stringo

# Codex CLI
codex plugin marketplace add omar-hanafy/stringo
```

## License

BSD 3-Clause. See [LICENSE](LICENSE).
