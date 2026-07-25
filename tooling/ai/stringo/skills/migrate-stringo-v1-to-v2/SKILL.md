---
name: migrate-stringo-v1-to-v2
description: Use when upgrading a Dart/Flutter project from stringo 1.x to 2.x, when a build breaks after a stringo bump with unresolved isEmptyOrNull or isNotEmptyOrNull, when mask or insert stops compiling because it now returns a nullable String, or when truncate, toWords, toCharArray, slugify, or toCamelCase output changed after the upgrade.
---

# Migrate stringo 1.x to 2.x

stringo 2.0.0 is a performance rewrite. The API shape is nearly unchanged, but
two members were removed, two signatures became nullable, and six behaviors
were corrected.

Work through the three sections in order. Sections 1 and 2 are compile errors,
so the analyzer finds them for you. Section 3 is the dangerous part: silent
behavior changes that still compile.

## Step 1: removed members (compile errors)

| Removed | Replacement |
|---|---|
| `isEmptyOrNull` | `isBlank` |
| `isNotEmptyOrNull` | `isNotBlank` |

They were exact synonyms. Behavior is identical, so this is a pure rename:

```bash
grep -rn "isEmptyOrNull\|isNotEmptyOrNull" lib/ test/
```

## Step 2: signatures that became nullable (compile errors)

`mask()` and `insert()` on a `String?` receiver now return `String?` instead of
`String`, and yield `null` for a null receiver instead of `''` and the inserted
value respectively. This makes null handling uniform across every transforming
member on the nullable extension.

```dart
// 1.x
final String masked = maybeNull.mask();          // '' when null

// 2.x
final String masked = maybeNull.mask() ?? '';    // explicit
```

If the old behavior is what the code wants, `?? ''` restores it exactly.

Note that argument validation now happens before the null check, so
`maybeNull.mask(visibleStart: -1)` throws `ArgumentError` rather than silently
returning. That is intentional: a negative bound is a programmer error whether
or not the receiver happened to be null.

## Step 3: silent behavior changes (these still compile)

This is where real bugs hide. Check each one against actual usage.

### toWords no longer emits empty words

```dart
''.toWords          // 1.x: ['']          2.x: []
'_leading'.toWords  // 1.x: ['', 'leading'] 2.x: ['leading']
'  a  '.toWords     // 1.x: ['', 'a', '']   2.x: ['a']
```

Code that indexed `toWords` positionally, or that special-cased an empty first
element, needs review. Code that did `.where((w) => w.isNotEmpty)` afterwards
can drop that filter.

### camelCase no longer capitalizes after a leading separator

This was the bug caused by the empty words above:

```dart
'_leading'.toCamelCase  // 1.x: 'Leading'  2.x: 'leading'
```

If any code depended on the 1.x output, it was almost certainly working around
the bug. `toPascalCase` is unaffected, since it capitalizes every word anyway.

### truncate counts its suffix against the length

```dart
'Hello World'.truncate(5)  // 1.x: 'Hello...' (8 chars)  2.x: 'He...' (5)
```

1.x could exceed the limit it was given. If a column width, database field, or
UI constraint was tuned around the 1.x overshoot, re-tune it. To reproduce the
old output exactly, ask for `length + suffix.length`.

### slugify treats every separator kind uniformly

```dart
'a-b'.slugify(separator: '_')  // 1.x: 'a-b'  2.x: 'a_b'
```

1.x collapsed underscores and whitespace into the requested separator but let a
literal hyphen through untouched, so the result depended on which separator you
asked for. Default `slugify()` with the `-` separator is unchanged.

### toCharArray splits by code point, not code unit

```dart
'😀'.toCharArray()  // 1.x: two broken halves  2.x: ['😀']
```

Anything that reassembled the list with `join()` is unaffected. Anything that
counted elements to measure length will now get a different, more correct
number. Still not grapheme clusters: use `package:characters` for those.

### Case conversion output is unchanged otherwise

Every other conversion is byte-identical to 1.x, including all Unicode
handling. This is verified by a differential fuzz suite that runs the 1.0.0
implementations against the 2.0.0 ones over hundreds of thousands of generated
inputs. If you find a difference not listed above, it is a bug worth reporting.

## Step 4: optional adoption

Nothing below is required, but 2.x adds these.

**The `Stringo` functional core.** Every operation as a plain static function:

```dart
Stringo.snakeCase('userProfileField');
fields.map(Stringo.snakeCase).toList();
```

Useful for passing operations as values, and as an escape hatch when an
extension name collides with one the project defines.

**Precompiled patterns.** Alongside `regexNumeric` and friends there are now
`patternNumeric`, `patternAlphabet`, `patternAlphanumeric`,
`patternStartsWithNumber`, `patternContainsDigits`, `patternHasCapitalLetter`.
Prefer them: Dart does not cache compiled patterns, so `RegExp(regexNumeric)`
recompiles on every call.

**Remove blank-check workarounds.** In 1.x, `isBlank` allocated two
whole-string copies and compiled a regex, making it linear in input length. Any
code that guarded it with a length check, cached its result, or avoided it on
large strings can drop that workaround. It is now a scan that returns at the
first non-whitespace character.

## Step 5: verify

```bash
dart pub upgrade stringo
dart analyze
dart test
```

The analyzer catches steps 1 and 2 completely. Step 3 needs the test suite and
a review of the specific call sites listed above.

## If the project uses dart_helper_utils

DHU re-exports stringo, and DHU 6.1.x pins stringo `^1.0.0`, so such a project
cannot resolve 2.x until DHU itself upgrades. Do not force it with a dependency
override: DHU's own source calls stringo members that changed, so an override
can break DHU internally rather than only in project code.
