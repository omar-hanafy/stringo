# stringo

[![pub package](https://img.shields.io/pub/v/stringo.svg)](https://pub.dev/packages/stringo)
[![pub points](https://img.shields.io/pub/points/stringo)](https://pub.dev/packages/stringo/score)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

A zero-dependency Dart string toolkit. Case conversion, word splitting, slugs,
truncation, masking, and whitespace normalization, all built on a single
allocation-free tokenizer.

```dart
import 'package:stringo/stringo.dart';

'hello_world'.toCamelCase;   // 'helloWorld'
'helloWorld'.toSnakeCase;    // 'hello_world'
'Hello, World!'.slugify();   // 'hello-world'
'HTTPServer'.toWords;        // ['HTTP', 'Server']
'   '.isBlank;               // true
```

## Install

```yaml
dependencies:
  stringo: ^2.0.0
```

No transitive dependencies. Only `dart:core` and `dart:convert`, so it runs
everywhere Dart does: VM, Flutter, web, and WASM.

## What it does, and what it deliberately does not

**stringo transforms text.** Splitting, casing, trimming, slicing, masking,
joining, character-class predicates. Every one of these has a single correct
answer, decidable from the characters alone.

**It does not judge whether text is a valid instance of a real-world concept.**
There is no `isValidEmail`, `isValidPhoneNumber`, `isValidUrl`, or MIME
checking here. Those have no single correct answer, they differ per project,
and they generate unbounded maintenance. They belong in the layer that owns the
rule, or in [`dart_helper_utils`](https://pub.dev/packages/dart_helper_utils),
which re-exports this package alongside them.

Parsing text into typed values belongs in
[`convert_object`](https://pub.dev/packages/convert_object).

## Two ways to call it

Extensions read naturally in application code:

```dart
'userProfileField'.toSnakeCase;   // 'user_profile_field'
```

The `Stringo` namespace exposes the same operations as plain functions. Use it
to pass an operation as a value, or as an escape hatch when an extension name
collides with one you already define:

```dart
import 'package:stringo/stringo.dart' show Stringo;

Stringo.snakeCase('userProfileField');    // 'user_profile_field'
fields.map(Stringo.snakeCase).toList();   // as a function value
```

Every extension member is a one-line delegation to the matching `Stringo`
function, so the two surfaces cannot drift apart.

## API

### Case conversion

All conversions accept input in any shape: `camelCase`, `PascalCase`,
`snake_case`, `kebab-case`, or spaced text.

| Extension | `Stringo` | `'helloWorld'` becomes |
| --- | --- | --- |
| `.toPascalCase` | `pascalCase` | `HelloWorld` |
| `.toCamelCase` | `camelCase` | `helloWorld` |
| `.toSnakeCase` | `snakeCase` | `hello_world` |
| `.toKebabCase` | `kebabCase` | `hello-world` |
| `.toDotCase` | `dotCase` | `hello.world` |
| `.toFlatCase` | `flatCase` | `helloworld` |
| `.toScreamingCase` | `screamingCase` | `HELLOWORLD` |
| `.toScreamingSnakeCase` | `screamingSnakeCase` | `HELLO_WORLD` |
| `.toScreamingKebabCase` | `screamingKebabCase` | `HELLO-WORLD` |
| `.toPascalSnakeCase` | `pascalSnakeCase` | `Hello_World` |
| `.toPascalKebabCase` | `pascalKebabCase` | `Hello-World` |
| `.toTrainCase` | `pascalKebabCase` | `Hello-World` (alias) |
| `.toCamelSnakeCase` | `camelSnakeCase` | `hello_World` |
| `.toCamelKebabCase` | `camelKebabCase` | `hello-World` |
| `.toTitleCase` | `titleCase` | `Hello World` |

Plus `.toWords`, `.toTitle` (title-cases while preserving `-` and `_`),
`.capitalizeFirstLetter`, `.lowercaseFirstLetter`, `.capitalizeFirstLowerRest`,
and the null-tolerant `.tryToLowerCase()` / `.tryToUpperCase()`.

`toTitleCase` always capitalizes the first word, then leaves the articles,
conjunctions, and short prepositions in the public `titleCaseExceptions` set
lowercase:

```dart
'the lord of the rings'.toTitleCase;  // 'The Lord of the Rings'
```

### Transformation

| Member | Effect |
| --- | --- |
| `.slugify({separator})` | `'Hello, World!'` to `'hello-world'` |
| `.truncate(n, {suffix})` | shortens to at most `n` characters |
| `.mask({visibleStart, visibleEnd, char})` | `'1234567890'` to `'12******90'` |
| `.normalizeWhitespace()` | collapses whitespace runs, then trims |
| `.removeWhiteSpaces` | drops every whitespace character |
| `.removeEmptyLines` | collapses blank-line runs to one newline |
| `.toOneLine` | drops newlines, inserting no separator |
| `.clean` | removes all whitespace |
| `.words` | splits on whitespace only |
| `.lines` | splits on `\n` and `\r\n` |
| `.toCharArray()` | splits into Unicode code points |
| `.insert(i, s)` | inserts at an index |
| `.removeSurrounding(d)` | strips a delimiter present at both ends |
| `.replaceAfter(d, r, [fallback])` | replaces past the first delimiter |
| `.replaceBefore(d, r, [fallback])` | replaces before the first delimiter |
| `.nullIfEmpty`, `.nullIfBlank`, `.orEmpty` | null plumbing |

Note that `.words` and `.toWords` are different splitters on purpose:
`.words` splits prose on whitespace, `.toWords` splits identifiers.

```dart
'helloWorld'.words;    // ['helloWorld']
'helloWorld'.toWords;  // ['hello', 'World']
```

### Checks

`.isBlank`, `.isNotBlank`, `.isAlphanumeric`, `.isNumeric`, `.isAlphabet`,
`.startsWithNumber`, `.containsDigits`, `.hasCapitalLetter`,
`.equalsIgnoreCase(other)`, and `.hasMatch(pattern, {flags})`. All accept a
`String?` receiver.

The underlying patterns are exported both as `String` sources (`regexNumeric`,
and so on) and as precompiled `RegExp` objects (`patternNumeric`, and so on).
Prefer the precompiled ones: Dart does not cache compiled patterns, so
`RegExp(regexNumeric)` pays the compilation cost on every call.

## Performance

Everything is built on one tokenizer that reports word boundaries as index
pairs and allocates nothing. Conversions stream those boundaries straight into
a single `StringBuffer`, so `toSnakeCase` performs exactly one allocation
instead of a word list, a substring per word, a joined string, and a recased
copy.

Case mapping runs inline on code units when the input is entirely ASCII, and
falls back to Dart's native Unicode casing otherwise. That fallback is not
optional, and correctness is never traded for speed:

```dart
'ÉCOLE'.toSnakeCase;  // 'école'
```

Measured against 1.0.0 on the same machine with
`dart run benchmark/stringo_benchmark.dart`:

| Operation | 1.0.0 | 2.0.0 | |
| --- | --- | --- | --- |
| `isBlank`, 10 chars | 516 ns | 7 ns | 79x |
| `isBlank`, 1,000 chars | 31,182 ns | 3 ns | 10,660x |
| `isBlank`, 100,000 chars | 3,166,000 ns | 3 ns | ~1,000,000x |
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
character, so it costs the same on a ten-character string and a ten-megabyte
one.

`removeEmptyLines` was the other pathological case. Its pattern backtracked
catastrophically inside a run of spaces not followed by a line break, making it
quadratic in the length of such a run: a document indented 40 spaces cost about
a hundred times an unindented one. It is now a linear scanner, and there is no
`RegExp` left in the transform layer at all.

Both are asserted as complexity contracts rather than wall-clock thresholds, so
they cannot flake on a slow CI runner.

### Why not Rust or C++ through FFI

This was measured rather than assumed. A C shared library was built and
benchmarked against staying in Dart:

| 24-char identifier | ns/op |
| --- | --- |
| FFI round trip (allocate, encode, call, decode, free) | 164 |
| FFI with a pre-allocated, reused buffer | 130 |
| Dart's built-in `toLowerCase()` | 20 |

FFI is 6.5x slower than staying in Dart at that size, and still 4.8x slower at
100,000 characters. The cause is structural: Dart strings are UTF-16, so
crossing the boundary forces an encode and a copy in each direction, while
Dart's own string primitives are already native code that never pays it. Bare
FFI call overhead with no string work at all is 9.3 ns, which alone exceeds the
total cost of several stringo operations.

FFI wins when compute per byte is high, as in compression or crypto. stringo
does single-pass character work, which is precisely the profile where
marshalling dominates. Leaving pure Dart would also cost web support, require
prebuilt binaries for roughly nine platform and architecture combinations, and
break the zero-dependency guarantee.

## Documented limitations

These follow from having no dependencies. They are tested rather than hidden:

- **`slugify` does not transliterate.** Characters outside `a-z0-9` are
  dropped, so `'Café'` becomes `'caf'`. Normalize accented text first if you
  need it preserved.
- **`toCharArray()` returns code points, not grapheme clusters.** A surrogate
  pair such as an emoji stays whole, but a flag emoji or a letter with a
  combining mark is still more than one element. Use
  [`package:characters`](https://pub.dev/packages/characters) when you need
  user-perceived characters.
- **`camelCase` and `pascalCase` are not reversible.** Dropping separators
  loses information: `'a_b'` becomes `'aB'`, which re-tokenizes as the single
  acronym `AB`. Use a separator-preserving case when you need a round trip.
- **Word splitting does not break on digits.** `'abc123Def'` is one word.
- **Character predicates are ASCII-only** by design, including
  `hasCapitalLetter` and `isAlphabet`.

## Upgrading from 1.0.0

2.0.0 is a rewrite. [CHANGELOG.md](CHANGELOG.md) has the full migration table;
the short version:

| | 1.0.0 | 2.0.0 |
| --- | --- | --- |
| `'_leading'.toCamelCase` | `'Leading'` | `'leading'` |
| `'  a  '.toWords` | `['', 'a', '']` | `['a']` |
| `''.toWords` | `['']` | `[]` |
| `'a-b'.slugify(separator: '_')` | `'a-b'` | `'a_b'` |
| `'Hello World'.truncate(5)` | `'Hello...'` | `'He...'` |
| `'😀'.toCharArray()` | two broken halves | one element |
| `null.mask()` | `''` | `null` |
| `null.insert(0, 'x')` | `'x'` | `null` |
| `isEmptyOrNull` | present | removed, use `isBlank` |
| `isNotEmptyOrNull` | present | removed, use `isNotBlank` |

## License

BSD-3-Clause. See [LICENSE](LICENSE).
