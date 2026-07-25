// ignore_for_file: avoid_print

import 'package:stringo/stringo.dart';

void main() {
  // Case conversion: any input shape works, because every conversion runs
  // through the same tokenizer.
  print('helloWorld'.toSnakeCase); // hello_world
  print('hello_world'.toCamelCase); // helloWorld
  print('hello-world'.toPascalCase); // HelloWorld
  print('helloWorld'.toScreamingSnakeCase); // HELLO_WORLD

  // Acronyms survive the round trip.
  print('parseHTTPResponse'.toWords); // [parse, HTTP, Response]
  print('parseHTTPResponse'.toSnakeCase); // parse_http_response

  // Title casing capitalizes the first word, then respects stop words.
  print('the lord of the rings'.toTitleCase); // The Lord of the Rings

  // Slugs for URLs and filenames. Hyphens, underscores, and whitespace are
  // all treated as separators, whichever separator you ask for.
  print('Hello, World!'.slugify()); // hello-world
  print('Release 2 Notes'.slugify(separator: '_')); // release_2_notes
  print('a-b c'.slugify(separator: '_')); // a_b_c

  // Trimming and shaping. truncate counts its suffix against the limit, so
  // the result never exceeds the length you asked for.
  print('  Line   1 \n Line 2  '.normalizeWhitespace()); // Line 1 Line 2
  print('Hello World'.truncate(5)); // He...
  print('Hello World'.truncate(8)); // Hello...
  print('"quoted"'.removeSurrounding('"')); // quoted

  // Masking for display of sensitive values.
  print('1234567890'.mask(visibleStart: 2, visibleEnd: 2)); // 12******90

  // Null-tolerant helpers: no bang operator needed. Transforming members
  // return null for a null receiver.
  const String? missing = null;
  print(missing.orEmpty); // (empty)
  print(missing.isBlank); // true
  print(missing.truncate(5)); // null
  print(missing.mask()); // null

  // Character-level checks.
  print('12345'.isNumeric); // true
  print('abcDEF'.isAlphabet); // true
  print('Hello'.hasCapitalLetter); // true

  // Unicode is preserved rather than ascii-folded.
  print('ÉCOLE'.toSnakeCase); // école

  // The same operations without extensions, for passing as function values
  // or avoiding a name collision.
  const fields = ['userName', 'emailAddress', 'phoneNumber'];
  print(fields.map(Stringo.snakeCase).toList());
  // [user_name, email_address, phone_number]

  // Precompiled patterns avoid recompiling a RegExp on every call.
  print(patternNumeric.hasMatch('12345')); // true
}
