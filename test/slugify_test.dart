import 'package:stringo/stringo.dart';
import 'package:test/test.dart';

void main() {
  group('slugify', () {
    test('converts to a lowercase slug', () {
      expect('Hello, World!'.slugify(), 'hello-world');
    });

    test('collapses underscores and spaces', () {
      expect('Foo__Bar  Baz'.slugify(), 'foo-bar-baz');
    });

    test('collapses repeated separators', () {
      expect('Already--slug'.slugify(), 'already-slug');
    });

    test('trims separators from both ends', () {
      expect('---'.slugify(), '');
      expect('-hello-'.slugify(), 'hello');
    });

    test('retains numbers', () {
      expect('Version 2 Update'.slugify(), 'version-2-update');
    });

    test('supports a custom separator', () {
      expect('Hello World'.slugify(separator: '_'), 'hello_world');
    });

    test('supports a multi-character separator', () {
      expect('Hello World'.slugify(separator: '--'), 'hello--world');
    });

    test('returns empty for blank or symbol-only input', () {
      expect(''.slugify(), '');
      expect('   '.slugify(), '');
      expect('!!!'.slugify(), '');
    });

    test('drops non-ASCII characters rather than transliterating', () {
      // Documented limitation: accented characters are stripped, not folded.
      expect('Café'.slugify(), 'caf');
      expect('naïve'.slugify(), 'nave');
    });

    test('rejects an empty separator', () {
      expect(() => 'Hello'.slugify(separator: ''), throwsArgumentError);
    });
  });
}
