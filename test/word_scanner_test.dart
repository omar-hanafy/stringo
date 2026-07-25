import 'package:stringo/src/word_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('scanWordsToList', () {
    test('splits camelCase and PascalCase', () {
      expect(scanWordsToList('helloWorld'), ['hello', 'World']);
      expect(scanWordsToList('HelloWorld'), ['Hello', 'World']);
      expect(scanWordsToList('someUserProfileFieldName'), [
        'some',
        'User',
        'Profile',
        'Field',
        'Name',
      ]);
    });

    test('keeps leading acronyms intact', () {
      expect(scanWordsToList('HTTPServer'), ['HTTP', 'Server']);
      expect(scanWordsToList('XMLHttpRequest'), ['XML', 'Http', 'Request']);
      expect(scanWordsToList('ABC'), ['ABC']);
    });

    test('splits on underscores, hyphens, whitespace, and mixed runs', () {
      expect(scanWordsToList('hello_world'), ['hello', 'world']);
      expect(scanWordsToList('hello-world'), ['hello', 'world']);
      expect(scanWordsToList('hello world'), ['hello', 'world']);
      expect(scanWordsToList('a_-  b'), ['a', 'b']);
      expect(scanWordsToList('a\tb\nc'), ['a', 'b', 'c']);
    });

    test('does not split on digit boundaries (preserved 1.0.0 quirk)', () {
      expect(scanWordsToList('abc123Def'), ['abc123Def']);
      expect(scanWordsToList('a1B'), ['a1B']);
      expect(scanWordsToList('version2Point0'), ['version2Point0']);
    });

    test('never emits an empty word (fixes defects 2 and 8)', () {
      expect(scanWordsToList(''), isEmpty);
      expect(scanWordsToList('_leading'), ['leading']);
      expect(scanWordsToList('trailing_'), ['trailing']);
      expect(scanWordsToList('  spaced  out  '), ['spaced', 'out']);
      expect(scanWordsToList('___'), isEmpty);
      expect(scanWordsToList('   '), isEmpty);
    });

    test('never splits inside a surrogate pair', () {
      expect(scanWordsToList('a\u{1F600}B'), ['a\u{1F600}B']);
      expect(scanWordsToList('\u{1F600}'), ['\u{1F600}']);
    });

    test('treats non-ASCII letters as word content, not boundaries', () {
      expect(scanWordsToList('Ünïcode Wörd'), ['Ünïcode', 'Wörd']);
      // An accented capital is not an ASCII upper, so it starts no new word.
      expect(scanWordsToList('cafÉau'), ['cafÉau']);
    });

    test('splits on unicode whitespace, matching the v1 regex', () {
      expect(scanWordsToList('a b'), ['a', 'b']); // NBSP
      expect(scanWordsToList('a　b'), ['a', 'b']); // ideographic space
    });

    test('single characters and single words are returned whole', () {
      expect(scanWordsToList('a'), ['a']);
      expect(scanWordsToList('A'), ['A']);
      expect(scanWordsToList('hello'), ['hello']);
    });
  });

  group('scanWords', () {
    test('emits index pairs without materializing substrings', () {
      final pairs = <List<int>>[];
      scanWords('helloWorld', (a, b) => pairs.add([a, b]));
      expect(pairs, [
        [0, 5],
        [5, 10],
      ]);
    });

    test('emits nothing for input that contains no word', () {
      var calls = 0;
      scanWords('', (_, _) => calls++);
      scanWords('___   ', (_, _) => calls++);
      expect(calls, 0);
    });

    test('every emitted range is non-empty and in bounds', () {
      const input = '  _someUserProfile-FIELD_name\t\t';
      scanWords(input, (start, end) {
        expect(end, greaterThan(start));
        expect(start, greaterThanOrEqualTo(0));
        expect(end, lessThanOrEqualTo(input.length));
      });
    });
  });
}
