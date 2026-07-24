// ignore_for_file: avoid_print

import 'package:stringo/stringo.dart';

void main() {
  // Case conversion: any input shape works, because every conversion runs
  // through toWords.
  print('helloWorld'.toSnakeCase); // hello_world
  print('hello_world'.toCamelCase); // helloWorld
  print('hello-world'.toPascalCase); // HelloWorld
  print('helloWorld'.toScreamingSnakeCase); // HELLO_WORLD

  // Acronyms survive the round trip.
  print('parseHTTPResponse'.toWords); // [parse, HTTP, Response]
  print('parseHTTPResponse'.toSnakeCase); // parse_http_response

  // Title casing capitalizes the first word, then respects stop words.
  print('the lord of the rings'.toTitleCase); // The Lord of the Rings

  // Slugs for URLs and filenames.
  print('Hello, World!'.slugify()); // hello-world
  print('Release 2 Notes'.slugify(separator: '_')); // release_2_notes

  // Trimming and shaping.
  print('  Line   1 \n Line 2  '.normalizeWhitespace()); // Line 1 Line 2
  print('Hello World'.truncate(5)); // Hello...
  print('"quoted"'.removeSurrounding('"')); // quoted

  // Masking for display of sensitive values.
  print('1234567890'.mask(visibleStart: 2, visibleEnd: 2)); // 12******90

  // Null-tolerant helpers: no bang operator needed.
  const String? missing = null;
  print(missing.orEmpty); // (empty)
  print(missing.isBlank); // true
  print(missing.truncate(5)); // null

  // Character-level checks.
  print('12345'.isNumeric); // true
  print('abcDEF'.isAlphabet); // true
  print('Hello'.hasCapitalLetter); // true
}
