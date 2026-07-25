/// A zero-dependency string toolkit for Dart.
///
/// `stringo` operates on the text itself: case conversion, word splitting,
/// slugs, truncation, masking, and whitespace normalization. It deliberately
/// does not judge whether a string is a valid instance of some real-world
/// concept (an email address, a phone number, a URL) - those rules vary by
/// project and belong in the layer that owns them.
///
/// Two equivalent surfaces are provided. Extensions read naturally in
/// application code:
///
/// ```dart
/// import 'package:stringo/stringo.dart';
///
/// 'hello_world'.toCamelCase;      // 'helloWorld'
/// 'Hello, World!'.slugify();      // 'hello-world'
/// 'helloWorld'.toWords;           // ['hello', 'World']
/// ```
///
/// The [Stringo] namespace exposes the same operations as plain functions,
/// which is useful for passing them as values, and gives you an escape hatch
/// if an extension member name collides with one you already define:
///
/// ```dart
/// import 'package:stringo/stringo.dart' show Stringo;
///
/// Stringo.camelCase('hello_world');       // 'helloWorld'
/// names.map(Stringo.snakeCase).toList();  // as a function value
/// ```
///
/// Every extension member is a one-line delegation to the matching [Stringo]
/// function, so the two surfaces cannot drift apart.
library;

export 'src/core.dart';
export 'src/extensions/case.dart';
export 'src/extensions/checks.dart';
export 'src/extensions/transform.dart';
export 'src/patterns.dart';
export 'src/title_case_exceptions.dart';
