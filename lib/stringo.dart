/// A zero-dependency string toolkit for Dart.
///
/// `stringo` operates on the text itself: case conversion, word splitting,
/// slugs, truncation, masking, and whitespace normalization. It deliberately
/// does not judge whether a string is a valid instance of some real-world
/// concept (an email address, a phone number, a URL) - those rules vary by
/// project and belong in the layer that owns them.
///
/// ```dart
/// import 'package:stringo/stringo.dart';
///
/// 'hello_world'.toCamelCase;      // 'helloWorld'
/// 'Hello, World!'.slugify();      // 'hello-world'
/// 'helloWorld'.toWords;           // ['hello', 'World']
/// ```
library;

export 'src/case.dart';
export 'src/checks.dart';
export 'src/regex_patterns.dart';
export 'src/transform.dart';
