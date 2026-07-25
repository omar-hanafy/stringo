# CHANGELOG

## 2.0.0

A performance rewrite. Every operation is now built on a single tokenizer that
reports word boundaries as index pairs and allocates nothing, and conversions
stream those boundaries straight into one `StringBuffer`. Case mapping runs
inline on code units for ASCII input and falls back to Dart's native Unicode
casing otherwise, so accented text is never ASCII-folded.

The package still has zero dependencies and still runs everywhere Dart does.
Native code through `dart:ffi` was measured and rejected: marshalling UTF-16
across the boundary costs more than the work itself, making it slower than
staying in Dart.

Case-conversion output is unchanged from 1.0.0 apart from the corrections
listed under Fixed. That equivalence is verified by running the 1.0.0
implementations against the new ones over generated input.

### Performance

Measured on one machine with `dart run benchmark/stringo_benchmark.dart`:

| Operation | 1.0.0 | 2.0.0 | |
| --- | --- | --- | --- |
| `isBlank`, 100,000 chars | 3,166,000 ns | 3 ns | ~1,000,000x |
| `isBlank`, 10 chars | 516 ns | 7 ns | 79x |
| `toWords` | 1,880 ns | 148 ns | 12.7x |
| `toCamelCase` | 3,769 ns | 288 ns | 13.1x |
| `toSnakeCase` | 2,111 ns | 307 ns | 6.9x |
| `slugify`, 54 chars | 11,268 ns | 1,108 ns | 10.2x |
| 200,000 identifiers to `snake_case` | 341 ms | 56 ms | 6.1x |
| `removeEmptyLines`, 400 indented lines | 14.6 ms | 0.12 ms | 121x |
| `removeEmptyLines`, 8 KB unbroken run | 1,137 ms | 0.05 ms | ~22,700x |

`isBlank` is the outlier because 1.0.0 answered it by allocating two
whole-string copies and compiling a regex, which made it linear in the length
of the input. It is now a scan that returns at the first non-whitespace
character. If your code guarded `isBlank` with a length check or avoided it on
large strings, you can drop that workaround.

`removeEmptyLines` was the other pathological case. Its pattern
`(?:[\t ]*(?:\r?\n|\r))+` backtracked catastrophically: inside a run of
spaces not followed by a line break, the engine consumed the whole run then
gave characters back one at a time. Cost was quadratic in the length of such a
run, so a document indented 40 spaces cost roughly ten times an unindented one,
and a 20 KB run of spaces took about seven seconds. It is now a linear scanner.
There is no longer any `RegExp` in the transform layer at all.

### Added

- **`Stringo`**, a namespace exposing every operation as a plain static
  function: `Stringo.snakeCase('userProfileField')`. Useful for passing an
  operation as a value, and as an escape hatch when an extension member name
  collides with one your project already defines. Every extension member is a
  one-line delegation to it.
- **Precompiled patterns.** Alongside the existing `String` sources there are
  now `patternAlphanumeric`, `patternStartsWithNumber`,
  `patternContainsDigits`, `patternNumeric`, `patternAlphabet`, and
  `patternHasCapitalLetter`. Prefer them: Dart does not cache compiled
  patterns, so `RegExp(regexNumeric)` recompiles on every call.

### Removed

- **`isEmptyOrNull` and `isNotEmptyOrNull`**, which were exact synonyms of
  `isBlank` and `isNotBlank`. Rename; behavior is identical.

### Changed

- **`mask` and `insert` on a `String?` receiver now return `String?`** and
  yield `null` for a null receiver, instead of `''` and the inserted value.
  Null handling is now uniform across every transforming member on the
  nullable extensions. Append `?? ''` to restore the old result exactly.
  `orEmpty` and `toCharArray()` keep their existing null behavior.
- **`mask` validates its bounds before checking the receiver**, so a negative
  `visibleStart` or `visibleEnd` throws `ArgumentError` even when the receiver
  is null.
- **`slugify` treats `-`, `_`, and whitespace identically.** Any run of them,
  in any mix, collapses to a single separator. Previously a literal hyphen
  passed through untouched, so `'a-b'.slugify(separator: '_')` returned
  `'a-b'`; it now returns `'a_b'`. The default hyphen separator is unaffected.
- **`truncate` counts its suffix against the requested length** instead of
  appending it on top. `'Hello World'.truncate(5)` was `'Hello...'` (8
  characters) and is now `'He...'` (5). Ask for `length + suffix.length` to
  reproduce the old output. A suffix longer than `length` yields exactly the
  suffix.
- **`toCharArray()` splits by Unicode code point** rather than UTF-16 code
  unit, so a surrogate pair such as an emoji is no longer torn in half. It is
  still code points rather than grapheme clusters; use `package:characters`
  for those.

### Fixed

- **`toWords` no longer emits empty elements.** `''.toWords` was `['']` and is
  now `[]`; `'  a  '.toWords` was `['', 'a', '']` and is now `['a']`.
- **A leading separator no longer capitalizes camelCase output.**
  `'_leading'.toCamelCase` returned `'Leading'` because the phantom empty first
  word shifted the real one; it now returns `'leading'`. `toPascalCase` was
  never affected.
- **The first character of supplementary-plane text is now cased.**
  `capitalizeFirstLetter`, `lowercaseFirstLetter`, and
  `capitalizeFirstLowerRest` operated on `s[0]`, which is a lone surrogate for
  any character outside the Basic Multilingual Plane, and casing a lone
  surrogate does nothing. The first letter of Deseret, Osage, or Adlam text was
  silently left alone, which also affected `toPascalCase`, `toCamelCase`,
  `toTitleCase`, `toTitle`, and the four Pascal/camel separator variants.
  Characters without a case mapping, such as emoji, are unchanged as before.

## 1.0.0

Initial release.

`stringo` is the string toolkit extracted from
[`dart_helper_utils`](https://pub.dev/packages/dart_helper_utils) into a
standalone, zero-dependency package. `dart_helper_utils` 6.1.0 and later
re-export it, so existing code keeps working without an import change.

### Included

- **Case conversion:** `toWords` plus 15 case styles (`toCamelCase`,
  `toPascalCase`, `toSnakeCase`, `toKebabCase`, `toDotCase`, `toTitleCase`,
  `toScreamingSnakeCase`, `toScreamingKebabCase`, `toPascalSnakeCase`,
  `toPascalKebabCase`, `toTrainCase`, `toCamelSnakeCase`, `toCamelKebabCase`,
  `toFlatCase`, `toScreamingCase`), `toTitle`, `capitalizeFirstLetter`,
  `lowercaseFirstLetter`, `capitalizeFirstLowerRest`,
  `shouldIgnoreCapitalization`, `tryToLowerCase`, `tryToUpperCase`.
- **Transforms:** `slugify`, `truncate`, `mask`, `normalizeWhitespace`,
  `clean`, `toOneLine`, `removeWhiteSpaces`, `removeEmptyLines`, `words`,
  `lines`, `nullIfEmpty`, `nullIfBlank`, `orEmpty`, `insert`, `toCharArray`,
  `equalsIgnoreCase`, `removeSurrounding`, `replaceBefore`, `replaceAfter`.
- **Checks:** `isBlank` / `isEmptyOrNull` (and negations), `isNumeric`,
  `isAlphabet`, `isAlphanumeric`, `startsWithNumber`, `containsDigits`,
  `hasCapitalLetter`, `hasMatch`, and the six backing regex constants.

### Changes from the `dart_helper_utils` originals

- **`toTitleCase` and `toTitle` now always capitalize the first word.**
  Previously a leading stop word was lowercased, so
  `'the lord of the rings'.toTitleCase` produced `'the Lord of the Rings'`.
  It now produces `'The Lord of the Rings'`, matching conventional title
  casing and the behavior the original documentation already described.
- **`titleCaseExceptions` is now public** and backed by a `Set` for
  constant-time lookup instead of a private `List`.
- **`mask` rejects negative `visibleStart` / `visibleEnd`** with an
  `ArgumentError` instead of failing later with a `RangeError`.
- **`insert` is implemented with `substring`** rather than a `List<String>`
  round-trip. Behavior is unchanged; out-of-range indices still throw a
  `RangeError`.
- Extension type names dropped the `DHU` prefix and are grouped by concern:
  `StringCaseExtensions`, `NullableStringCaseExtensions`,
  `StringTransformExtensions`, `NullableStringTransformExtensions`, and
  `StringChecksExtensions`.

### Deliberately not included

Domain validation (`isValidEmail`, `isValidPhoneNumber`, `isValidUrl`,
`isValidUsername`, `isValidCurrency`, `isUuid`, `isValidIp4`), MIME and file
type checks, `parseDuration`, and base64 helpers all remain in
`dart_helper_utils`. Those judge real-world formats rather than transform
text, and their correct behavior varies by project.
