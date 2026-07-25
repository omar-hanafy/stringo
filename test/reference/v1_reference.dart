/// Verbatim stringo 1.0.0 tokenizer, retained ONLY as a differential oracle.
///
/// This is the regex the package shipped in 1.0.0. It is slow and it emits
/// empty words, which is exactly why it was replaced. It lives here so the
/// new scanner can be proven equivalent to it rather than assumed equivalent.
///
/// Do not import this from `lib/`. If a fuzz test disagrees with this oracle,
/// the scanner is wrong and the scanner gets fixed, never this file.
library;

final RegExp _v1Split = RegExp(
  r'(?<=[a-z])(?=[A-Z])|[_\-\s]+|(?<=[A-Z])(?=[A-Z][a-z])',
);

/// Splits [s] exactly as `String.toWords` did in stringo 1.0.0.
List<String> v1Words(String s) => s.split(_v1Split);
