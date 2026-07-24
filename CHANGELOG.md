# CHANGELOG

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
