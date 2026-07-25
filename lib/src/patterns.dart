/// Character-class regex patterns used by the string checks in this package.
///
/// Each pattern is exposed twice: as the raw `String` source, which is what
/// stringo 1.0.0 exported and what [RegExp] constructors expect, and as a
/// precompiled `RegExp`.
///
/// Prefer the precompiled objects. Dart does not cache compiled patterns, so
/// `RegExp(regexNumeric)` pays the compilation cost on every call, while the
/// `pattern*` objects are compiled exactly once per isolate.
///
/// All patterns are ASCII-only by design: they are cheap, predictable, and
/// have a single correct answer. Patterns that would judge real-world formats
/// such as emails, phone numbers, or URLs are intentionally not part of this
/// package.
library;

/// Matches strings made up solely of ASCII letters and digits.
const String regexAlphanumeric = r'^[a-zA-Z0-9]+$';

/// Matches strings that start with an ASCII digit.
const String regexStartsWithNumber = r'^\d';

/// Matches strings containing at least one ASCII digit.
const String regexContainsDigits = r'\d';

/// Matches strings made up solely of ASCII digits.
const String regexNumeric = r'^\d+$';

/// Matches strings made up solely of ASCII letters.
const String regexAlphabet = r'^[a-zA-Z]+$';

/// Matches strings containing at least one uppercase ASCII letter.
const String regexHasCapitalLetter = '[A-Z]';

/// [regexAlphanumeric], compiled once.
final RegExp patternAlphanumeric = RegExp(regexAlphanumeric);

/// [regexStartsWithNumber], compiled once.
final RegExp patternStartsWithNumber = RegExp(regexStartsWithNumber);

/// [regexContainsDigits], compiled once.
final RegExp patternContainsDigits = RegExp(regexContainsDigits);

/// [regexNumeric], compiled once.
final RegExp patternNumeric = RegExp(regexNumeric);

/// [regexAlphabet], compiled once.
final RegExp patternAlphabet = RegExp(regexAlphabet);

/// [regexHasCapitalLetter], compiled once.
final RegExp patternHasCapitalLetter = RegExp(regexHasCapitalLetter);
