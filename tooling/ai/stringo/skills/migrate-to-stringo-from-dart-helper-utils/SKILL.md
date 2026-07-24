---
name: migrate-to-stringo-from-dart-helper-utils
description: Use when moving a Dart/Flutter project's string code from dart_helper_utils to the standalone stringo package, when dropping dart_helper_utils because only its string helpers were used, when a build breaks after bumping dart_helper_utils to 6.1.0 with unresolved DHUCaseConversionExtensions or DHUStringExtensions names, or when toTitleCase output changed after an upgrade.
---

# Migrate string code to stringo

`stringo` 1.0.0 is the string toolkit extracted from `dart_helper_utils`
(DHU) 6.1.0. DHU depends on it and re-exports it.

## Step 0: decide whether you need to do anything

Run this decision first - most projects need NO code change.

| Situation | Action |
|---|---|
| Project uses DHU and stays on DHU | **Nothing to do.** stringo is re-exported. Do NOT add a `stringo` dependency; that only risks a version skew. Skip to Step 3. |
| Project uses DHU but ONLY for string helpers | Optional slimming: Step 1 and 2. |
| Project uses DHU for strings AND anything else (maps, dates, intl, conversions, MIME) | Keep DHU. Skip to Step 3. |
| New project, strings only | Depend on `stringo` alone. |

The point of dropping DHU is removing the transitive `convert_object`, `intl`,
`collection`, `mime`, and `equatable` dependencies. If any of those are used
directly, that win disappears.

## Step 1: confirm only string members are used

Check what the project actually calls from DHU. If any hit is outside the
"moved to stringo" list below, DHU must stay.

```bash
grep -rn "dart_helper_utils" lib test
```

**Moved to stringo** (safe to keep after dropping DHU):

- Case: `toWords`, `toCamelCase`, `toPascalCase`, `toSnakeCase`,
  `toKebabCase`, `toDotCase`, `toTitleCase`, `toTitle`,
  `toScreamingSnakeCase`, `toScreamingKebabCase`, `toPascalSnakeCase`,
  `toPascalKebabCase`, `toTrainCase`, `toCamelSnakeCase`, `toCamelKebabCase`,
  `toFlatCase`, `toScreamingCase`, `capitalizeFirstLetter`,
  `lowercaseFirstLetter`, `capitalizeFirstLowerRest`,
  `shouldIgnoreCapitalization`, `tryToLowerCase`, `tryToUpperCase`
- Transform: `slugify`, `truncate`, `mask`, `normalizeWhitespace`, `clean`,
  `toOneLine`, `removeWhiteSpaces`, `removeEmptyLines`, `words`, `lines`,
  `nullIfEmpty`, `nullIfBlank`, `orEmpty`, `insert`, `toCharArray`,
  `equalsIgnoreCase`, `removeSurrounding`, `replaceBefore`, `replaceAfter`
- Checks: `isBlank`, `isEmptyOrNull`, `isNotBlank`, `isNotEmptyOrNull`,
  `isNumeric`, `isAlphabet`, `isAlphanumeric`, `startsWithNumber`,
  **`containsDigits`**, `hasCapitalLetter`, `hasMatch`, and the constants
  `regexNumeric`, `regexAlphabet`, `regexAlphanumeric`,
  `regexStartsWithNumber`, `regexContainsDigits`, `regexHasCapitalLetter`

**STAYED in dart_helper_utils** (any of these means you cannot drop DHU):

`isValidEmail`, `isValidPhoneNumber`, `isValidUrl`, `isValidUsername`,
`isValidCurrency`, `isValidHTML`, `isValidIp4`, `isUuid`, `maskEmail`,
`hasSpecialChars`, `hasNoSpecialChars`, `isBool`, `isPalindrome`,
`parseDuration`, `base64Encode`, `base64Decode`, `wrapString`,
`limitFromStart`, `limitFromEnd`, `lastIndex`, `anyChar`, `ifEmpty`, every
MIME getter (`isPDF`, `isImage`, `isVideo`, ...), and `regexSpecialChars`,
`regexValidEmail`, `regexValidUsername`, `regexValidCurrency`,
`regexValidPhoneNumber`, `regexValidIp4`, `regexValidUrl`.

Common blockers to look for specifically: `maskEmail` (people assume it moved
with `mask` - it did not, it depends on `isValidEmail`), and `limitFromStart`
/ `limitFromEnd` (people assume they moved with `truncate`).

## Step 2: swap the dependency

```yaml
dependencies:
  stringo: ^1.0.0   # replaces dart_helper_utils
```

```dart
// Replace every occurrence of:
import 'package:dart_helper_utils/dart_helper_utils.dart';
// with:
import 'package:stringo/stringo.dart';
```

Then `dart pub get` and `dart analyze`. Any unresolved member is one that
stayed in DHU - revert and keep DHU.

## Step 3: fix the two things that actually changed in 6.1.0

These apply to EVERY project bumping DHU to 6.1.0, including ones that change
nothing else.

### 3a. Explicit extension type names

Only affects code that names an extension type, not `'x'.toSnakeCase` calls.

```bash
grep -rn "DHUCaseConversionExtensions\|DHUNullSafeCaseConversionExtensions\|DHUStringExtensions\|DHUNullSafeStringExtensions" lib test
```

Most projects get zero hits. For any hit:

| Old | New |
|---|---|
| `DHUCaseConversionExtensions` | `StringCaseExtensions` |
| `DHUNullSafeCaseConversionExtensions` | `NullableStringCaseExtensions` |
| `DHUStringExtensions` (moved members) | `StringTransformExtensions` |
| `DHUNullSafeStringExtensions` (moved transforms) | `NullableStringTransformExtensions` |
| `DHUNullSafeStringExtensions` (moved checks) | `StringChecksExtensions` |

`DHUStringExtensions` and `DHUNullSafeStringExtensions` still exist in DHU and
still hold the members that stayed, so a hit is only an error if it referenced
a moved member.

Dart cannot alias or deprecate an extension name, and two extensions declaring
the same members collide, so there is no compatibility shim for this.

### 3b. `toTitleCase` / `toTitle` capitalize the first word

```dart
'the lord of the rings'.toTitleCase;
// 6.0.x: 'the Lord of the Rings'
// 6.1.0: 'The Lord of the Rings'   <- conventional title casing
```

This is a silent output change - it compiles either way. Check golden tests,
snapshot tests, and any UI assertion over title-cased text. If you need the old
behavior, lowercase the first word after the call.

## Verify

```bash
dart pub get
dart analyze
dart test
```

A clean analyze proves 3a is handled; only the test suite catches 3b.
