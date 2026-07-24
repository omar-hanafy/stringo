/// Common character-class regex patterns used by the string checks in this
/// package.
///
/// These are exposed so callers can reuse the exact same patterns (for
/// example with [RegExp] directly, or in form-validation layers) instead of
/// re-deriving them.
///
/// All patterns are ASCII-only by design: they are cheap, predictable, and
/// have a single correct answer. Patterns that would need to judge real-world
/// formats (emails, phone numbers, URLs) are intentionally not part of this
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
