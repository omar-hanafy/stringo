---
name: use-stringo
description: Use when writing or reviewing Dart/Flutter code that uses the stringo package - case conversion (toCamelCase, toSnakeCase, toPascalCase, toTitleCase, toWords), slugify, truncate, mask, whitespace cleanup (clean, normalizeWhitespace, words, lines), blank checks (isBlank, isEmptyOrNull), character predicates (isNumeric, isAlphabet, hasMatch), or deciding whether a string helper belongs in stringo, dart_helper_utils, or convert_object.
---

# Use stringo correctly

`stringo` is a zero-dependency string toolkit. Every member is an extension on
`String` or `String?`, reachable from one import:

```dart
import 'package:stringo/stringo.dart';
```

## The scope rule (decides where a helper belongs)

**stringo transforms text. It does NOT judge whether text is a valid instance
of a real-world concept.**

There is no `isValidEmail`, `isValidPhoneNumber`, `isValidUrl`,
`isValidUsername`, `isValidCurrency`, `isUuid`, `isValidIp4`, or MIME check in
this package. Do not invent them and do not tell a user they exist here.

| Need | Package |
|---|---|
| Casing, slugs, trimming, truncation, masking | `stringo` |
| Domain validators, MIME checks, `parseDuration`, base64 | `dart_helper_utils` |
| Parsing text into typed values | `convert_object` |
| Fuzzy matching, similarity, substring search | `string_search_algorithms` |

**If the project already depends on `dart_helper_utils`, stringo is already
there** - it is re-exported since DHU 6.1.0. Do NOT add a second import or a
`stringo` dependency to such a project.

## Case conversion

All casing members are GETTERS, not methods. They all run through `toWords`,
so input can be any shape (`camelCase`, `PascalCase`, `snake_case`,
`kebab-case`, spaced).

| Getter | `'helloWorld'` gives |
|---|---|
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
| `toPascalKebabCase`, `toTrainCase` | `Hello-World` (identical behavior) |
| `toCamelSnakeCase` | `hello_World` |
| `toCamelKebabCase` | `hello-World` |
| `toFlatCase` | `helloworld` |
| `toScreamingCase` | `HELLOWORLD` |

Also `capitalizeFirstLetter`, `lowercaseFirstLetter`,
`capitalizeFirstLowerRest`, `toTitle`, `shouldIgnoreCapitalization`, and on
`String?`: `tryToLowerCase()`, `tryToUpperCase()` (these two ARE methods).

Key semantics agents get wrong:

- **`toTitleCase` ALWAYS capitalizes the first word**, then leaves later stop
  words lowercase: `'the lord of the rings'.toTitleCase` is
  `'The Lord of the Rings'`, not `'the Lord of the Rings'`.
- The stop-word set is public: `titleCaseExceptions` (a `const Set<String>`).
- **`toTitle` is not `toTitleCase`.** `toTitle` preserves `-` and `_`
  delimiters and title-cases each segment between them:
  `'example-string_for general use'.toTitle` is
  `'Example-String_For General Use'`. `toTitleCase` normalizes every separator
  to a space.
- `capitalizeFirstLowerRest` LOWERCASES the remainder
  (`'FLUTTER AND DART'` becomes `'Flutter and dart'`);
  `capitalizeFirstLetter` preserves it (`'Flutter AND DART'`).

## Transforms

```dart
'  Line   1 \n Line 2  '.normalizeWhitespace(); // 'Line 1 Line 2'
'Line1\n\n\nLine2'.removeEmptyLines;            // 'Line1\nLine2'
'a b\nc'.clean;                                 // 'abc'
'Hello World'.words;                            // ['Hello', 'World']
'a\r\nb'.lines;                                 // ['a', 'b']
'Hello, World!'.slugify();                      // 'hello-world'
'Hello World'.truncate(5);                      // 'Hello...'
'1234567890'.mask(visibleStart: 2, visibleEnd: 2); // '12******90'
'"quoted"'.removeSurrounding('"');              // 'quoted'
'foo=bar'.replaceAfter('=', 'baz');             // 'foo=baz'
'abc'.insert(1, 'Z');                           // 'aZbc'
```

Plus `nullIfEmpty`, `nullIfBlank`, `orEmpty`, `toOneLine`, `removeWhiteSpaces`,
`toCharArray()`, `equalsIgnoreCase()`.

Traps:

- **`clean` and `toOneLine` join WITHOUT a separator.** `'Line1\nLine2'.clean`
  is `'Line1Line2'`, not `'Line1 Line2'`. Use `normalizeWhitespace()` when you
  want words kept apart.
- **`words` (whitespace split) is not `toWords` (identifier split).**
  `'helloWorld'.words` is `['helloWorld']`; `'helloWorld'.toWords` is
  `['hello', 'World']`.
- **`truncate` appends the suffix ON TOP of the length.** `truncate(5)` can
  return 8 characters. It only truncates when the string is longer than
  `length`; `truncate(0)` or a negative length gives `''`.
- **`nullIfEmpty` is not `nullIfBlank`.** `'   '.nullIfEmpty` is `'   '`;
  `'   '.nullIfBlank` is `null`.
- `mask` returns the input unchanged when it is too short to mask, and throws
  `ArgumentError` on negative `visibleStart`/`visibleEnd`.

## Checks

On `String?`, so they are null-safe without a bang operator:

- Blank: `isBlank` / `isEmptyOrNull` (aliases), `isNotBlank` /
  `isNotEmptyOrNull`. All treat whitespace-only as blank.
- Characters: `isNumeric`, `isAlphabet`, `isAlphanumeric`, `startsWithNumber`,
  `containsDigits`, `hasCapitalLetter`.
- Generic: `hasMatch(pattern, {multiLine, caseSensitive, unicode, dotAll})`.

Exported patterns for reuse: `regexNumeric`, `regexAlphabet`,
`regexAlphanumeric`, `regexStartsWithNumber`, `regexContainsDigits`,
`regexHasCapitalLetter`.

Traps:

- `isNumeric` is ASCII DIGITS ONLY - no sign, no decimal point. `'12.34'` and
  `'-12'` are both `false`. It trims surrounding whitespace first. It is a
  character check, not a parser: use `convert_object` to get the value.
- `isAlphanumeric` rejects spaces: `'a b'` is `false`.
- Empty string is `false` for `isNumeric`, `isAlphabet`, `isAlphanumeric`.

## Documented limitations (do not report these as bugs)

- **`slugify` is ASCII-only.** Non-ASCII characters are DROPPED, not
  transliterated: `'Café'.slugify()` is `'caf'`. Never use it for i18n slugs
  without normalizing first. It throws `ArgumentError` on an empty separator.
- **`toCharArray()` splits by UTF-16 code unit**, so emoji are split
  mid-character. Use `package:characters` for grapheme clusters.
- **`toWords` does not split on digit boundaries**: `'user2Name'` stays one
  word.
- **Character checks are ASCII-only**: `isAlphabet` is `A-Z` / `a-z`.
- A leading separator produces an empty first word, so `'_leading'.toCamelCase`
  is `'Leading'` (capital L), not `'leading'`.

## Extension names

`StringCaseExtensions`, `NullableStringCaseExtensions`,
`StringTransformExtensions`, `NullableStringTransformExtensions`,
`StringChecksExtensions`. You only need these when disambiguating explicitly;
normal `'x'.member` calls resolve by member name.
