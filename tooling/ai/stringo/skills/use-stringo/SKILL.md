---
name: use-stringo
description: Use when writing or reviewing Dart/Flutter code that uses the stringo package - case conversion (toCamelCase, toSnakeCase, toPascalCase, toTitleCase, toWords), the Stringo functional core, slugify, truncate, mask, whitespace cleanup (clean, normalizeWhitespace, words, lines), blank checks (isBlank), character predicates (isNumeric, isAlphabet, hasMatch), precompiled regex patterns, or deciding whether a string helper belongs in stringo, dart_helper_utils, or convert_object.
---

# Use stringo correctly

`stringo` is a zero-dependency string toolkit. Everything is reachable from one
import:

```dart
import 'package:stringo/stringo.dart';
```

**This skill documents stringo 2.0.0.** Several behaviors changed from 1.0.0.
If the project is on 1.x, use the `migrate-stringo-v1-to-v2` skill instead of
assuming the semantics below.

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
there** - DHU re-exports it. Do NOT add a second import or a `stringo`
dependency to such a project. Note that DHU 6.1.x pins stringo `^1.0.0`, so a
DHU project gets 1.x semantics until DHU itself upgrades.

## Two surfaces

Extensions are the normal way to call it. The `Stringo` class exposes the same
operations as plain static functions:

```dart
'userProfileField'.toSnakeCase;              // extension
Stringo.snakeCase('userProfileField');        // identical result
fields.map(Stringo.snakeCase).toList();       // as a function value
```

Reach for `Stringo` when passing an operation as a value, or when an extension
member name collides with one the project already defines. Every extension
member is a one-line delegation to the matching `Stringo` function, so they can
never disagree.

## Case conversion

All casing members are GETTERS, not methods. They all run through the same
tokenizer, so input can be any shape (`camelCase`, `PascalCase`, `snake_case`,
`kebab-case`, spaced).

| Getter | `Stringo` | `'helloWorld'` gives |
|---|---|---|
| `toWords` | `words` | `['hello', 'World']` |
| `toCamelCase` | `camelCase` | `helloWorld` |
| `toPascalCase` | `pascalCase` | `HelloWorld` |
| `toSnakeCase` | `snakeCase` | `hello_world` |
| `toKebabCase` | `kebabCase` | `hello-world` |
| `toDotCase` | `dotCase` | `hello.world` |
| `toTitleCase` | `titleCase` | `Hello World` |
| `toScreamingSnakeCase` | `screamingSnakeCase` | `HELLO_WORLD` |
| `toScreamingKebabCase` | `screamingKebabCase` | `HELLO-WORLD` |
| `toPascalSnakeCase` | `pascalSnakeCase` | `Hello_World` |
| `toPascalKebabCase`, `toTrainCase` | `pascalKebabCase` | `Hello-World` |
| `toCamelSnakeCase` | `camelSnakeCase` | `hello_World` |
| `toCamelKebabCase` | `camelKebabCase` | `hello-World` |
| `toFlatCase` | `flatCase` | `helloworld` |
| `toScreamingCase` | `screamingCase` | `HELLOWORLD` |

`toTrainCase` is an alias of `toPascalKebabCase`; both remain available.

Also `capitalizeFirstLetter`, `lowercaseFirstLetter`,
`capitalizeFirstLowerRest`, `toTitle`, `shouldIgnoreCapitalization`, and on
`String?`: `tryToLowerCase()`, `tryToUpperCase()` (these two ARE methods).

Key semantics agents get wrong:

- **`toTitleCase` ALWAYS capitalizes the first word**, then leaves later stop
  words lowercase: `'the lord of the rings'.toTitleCase` is
  `'The Lord of the Rings'`.
- The stop-word set is public: `titleCaseExceptions` (a `const Set<String>`).
- **`toTitle` is not `toTitleCase`.** `toTitle` preserves `-` and `_`
  delimiters and title-cases each segment between them:
  `'example-string_for general use'.toTitle` is
  `'Example-String_For General Use'`. `toTitleCase` normalizes every separator
  to a space.
- `capitalizeFirstLowerRest` LOWERCASES the remainder
  (`'FLUTTER AND DART'` becomes `'Flutter and dart'`);
  `capitalizeFirstLetter` preserves it (`'Flutter AND DART'`).
- **`toWords` never returns an empty element.** `''.toWords` is `[]`, and
  `'  a  '.toWords` is `['a']`.
- Casing is full Unicode, not ASCII-folded: `'ÉCOLE'.toSnakeCase` is
  `'école'`.

## Transforms

```dart
'  Line   1 \n Line 2  '.normalizeWhitespace(); // 'Line 1 Line 2'
'Line1\n\n\nLine2'.removeEmptyLines;            // 'Line1\nLine2'
'a b\nc'.clean;                                 // 'abc'
'Hello World'.words;                            // ['Hello', 'World']
'a\r\nb'.lines;                                 // ['a', 'b']
'Hello, World!'.slugify();                      // 'hello-world'
'Hello World'.truncate(5);                      // 'He...'
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
- **`truncate` counts the suffix AGAINST the length.** `'Hello World'
  .truncate(5)` is `'He...'`, exactly 5 characters. It only truncates when the
  string is longer than `length`; `truncate(0)` or a negative length gives
  `''`. A suffix longer than `length` yields exactly the suffix.
- **`nullIfEmpty` is not `nullIfBlank`.** `'   '.nullIfEmpty` is `'   '`;
  `'   '.nullIfBlank` is `null`.
- `mask` returns the input unchanged when it is too short to mask, and throws
  `ArgumentError` on a negative `visibleStart`/`visibleEnd` even when the
  receiver is null.
- **On a null receiver, transforming members return `null`.** That includes
  `mask()` and `insert()`, which return `String?`. `orEmpty` (returns `''`) and
  `toCharArray()` (returns `[]`) are the deliberate exceptions.
- **`slugify` treats `-`, `_`, and whitespace identically.** Any run of them
  collapses to one separator, whichever separator you asked for:
  `'a-b'.slugify(separator: '_')` is `'a_b'`.

## Checks

On `String?`, so they are null-safe without a bang operator:

- Blank: `isBlank`, `isNotBlank`. Whitespace-only counts as blank.
- Characters: `isNumeric`, `isAlphabet`, `isAlphanumeric`, `startsWithNumber`,
  `containsDigits`, `hasCapitalLetter`.
- Generic: `hasMatch(pattern, {multiLine, caseSensitive, unicode, dotAll})`.

`isEmptyOrNull` and `isNotEmptyOrNull` were REMOVED in 2.0.0 as exact synonyms.
Use `isBlank` and `isNotBlank`.

Patterns are exported twice: as `String` sources (`regexNumeric`,
`regexAlphabet`, `regexAlphanumeric`, `regexStartsWithNumber`,
`regexContainsDigits`, `regexHasCapitalLetter`) and as precompiled `RegExp`
objects (`patternNumeric`, `patternAlphabet`, `patternAlphanumeric`,
`patternStartsWithNumber`, `patternContainsDigits`, `patternHasCapitalLetter`).

**Prefer the precompiled objects.** Dart does not cache compiled patterns, so
`RegExp(regexNumeric)` recompiles on every call. The same applies to
`hasMatch(pattern)`, which takes a source string and therefore compiles per
call - hoist a `RegExp` yourself inside a hot loop.

Traps:

- `isNumeric` is ASCII DIGITS ONLY - no sign, no decimal point. `'12.34'` and
  `'-12'` are both `false`. It trims surrounding whitespace first. It is a
  character check, not a parser: use `convert_object` to get the value.
- `isAlphanumeric` rejects spaces: `'a b'` is `false`.
- Empty string is `false` for `isNumeric`, `isAlphabet`, `isAlphanumeric`.
- `isBlank` is a scan that returns at the first non-whitespace character, so it
  is cheap on very long strings. Do not "optimize" it by adding a length guard.

## Documented limitations (do not report these as bugs)

- **`slugify` is ASCII-only.** Non-ASCII characters are DROPPED, not
  transliterated: `'Café'.slugify()` is `'caf'`. Never use it for i18n slugs
  without normalizing first. It throws `ArgumentError` on an empty separator.
- **`toCharArray()` splits by Unicode CODE POINT.** A surrogate pair such as an
  emoji stays whole, but a flag emoji or a letter with a combining mark is
  still more than one element. Use `package:characters` for grapheme clusters.
- **`toWords` does not split on digit boundaries**: `'user2Name'` stays one
  word.
- **Character checks are ASCII-only**: `isAlphabet` is `A-Z` / `a-z`, and
  `hasCapitalLetter` does not see an accented capital.
- **`camelCase` and `pascalCase` are not reversible.** `'a_b'.toCamelCase` is
  `'aB'`, which re-tokenizes as the single acronym `AB`. Use a
  separator-preserving case when a round trip matters.

## Extension names

`StringCaseExtensions`, `NullableStringCaseExtensions`,
`StringTransformExtensions`, `NullableStringTransformExtensions`,
`StringChecksExtensions`. You only need these when disambiguating explicitly;
normal `'x'.member` calls resolve by member name. When a name genuinely
collides with another package, prefer `import 'package:stringo/stringo.dart'
show Stringo;` and call the functional core.
