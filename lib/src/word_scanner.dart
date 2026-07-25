/// The tokenizer every case conversion in this package is built on.
///
/// [scanWords] walks [s] once and reports each word as a pair of indices into
/// the original string. It allocates nothing: no list, no substrings, no
/// [RegExp]. Callers that need actual strings materialize them themselves,
/// and callers that are writing into a buffer never materialize them at all.
///
/// Word boundaries reproduce the regex stringo 1.0.0 used,
/// `(?<=[a-z])(?=[A-Z])|[_\-\s]+|(?<=[A-Z])(?=[A-Z][a-z])`:
///
/// 1. a zero-width split between an ASCII lowercase and an ASCII uppercase,
///    so `helloWorld` splits into `hello` and `World`
/// 2. a consumed run of underscores, hyphens, or whitespace
/// 3. a zero-width split between an ASCII uppercase and an uppercase followed
///    by a lowercase, so `HTTPServer` splits into `HTTP` and `Server`
///
/// Because every rule is driven by ASCII character classes, non-ASCII letters
/// are never boundaries and a surrogate pair is never split in half.
///
/// Two consequences are worth stating explicitly. Digits never create a
/// boundary, so `abc123Def` stays a single word, matching 1.0.0. And unlike
/// 1.0.0, an empty word is never emitted: a leading, trailing, or repeated
/// separator run produces no word rather than an empty one.
library;

import 'package:stringo/src/chars.dart';

/// Walks the word boundaries of [s], calling [emit] with the `[start, end)`
/// range of each word.
///
/// [emit] is never called with an empty range. For an empty or
/// separator-only [s] it is never called at all.
void scanWords(String s, void Function(int start, int end) emit) {
  final n = s.length;
  var start = 0;
  var i = 0;
  while (i < n) {
    final c = s.codeUnitAt(i);
    if (isWordSeparator(c)) {
      if (i > start) emit(start, i);
      var j = i + 1;
      while (j < n && isWordSeparator(s.codeUnitAt(j))) {
        j++;
      }
      start = j;
      i = j;
      continue;
    }
    if (i > 0) {
      final p = s.codeUnitAt(i - 1);
      final splitsOnCamelHump = isAsciiLower(p) && isAsciiUpper(c);
      final splitsOnAcronymTail =
          isAsciiUpper(p) &&
          isAsciiUpper(c) &&
          i + 1 < n &&
          isAsciiLower(s.codeUnitAt(i + 1));
      if (splitsOnCamelHump || splitsOnAcronymTail) {
        if (i > start) emit(start, i);
        start = i;
      }
    }
    i++;
  }
  if (n > start) emit(start, n);
}

/// Materializes the words of [s] into a list.
///
/// This is [scanWords] with the substrings actually created, for callers that
/// need the words themselves rather than to stream them into a buffer.
/// Returns an empty list for an empty or separator-only [s].
List<String> scanWordsToList(String s) {
  final out = <String>[];
  scanWords(s, (start, end) => out.add(s.substring(start, end)));
  return out;
}
