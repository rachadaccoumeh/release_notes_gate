import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

void main() {
  ReleaseVersion v(String text) => ReleaseVersion.parse(text);

  group('ReleaseVersion.parse', () {
    test('reads plain, prefixed and pre-release versions', () {
      expect(v('2.2.0').numbers, [2, 2, 0]);
      expect(v('v2.2.0').normalized, '2.2.0');
      expect(v('2.2.0-dev.4').preRelease, ['dev', '4']);
      expect(v('2.2.0-dev.4').isPrerelease, isTrue);
      expect(v('1.0.0-rc1+12').build, '12');
      expect(v('1.0.0-rc1+12').normalized, '1.0.0-rc1');
      expect(v('2.2').numbers, [2, 2]);
    });

    test('rejects text that is not a version', () {
      expect(ReleaseVersion.tryParse('Unreleased'), isNull);
      expect(ReleaseVersion.tryParse(''), isNull);
      expect(ReleaseVersion.tryParse(null), isNull);
      expect(() => ReleaseVersion.parse('abc'), throwsFormatException);
    });

    test('shows the v prefix on request', () {
      expect(v('2.2.0').withPrefix, 'v2.2.0');
      expect(v('v2.2.0').withPrefix, 'v2.2.0');
    });
  });

  group('ReleaseVersion compare', () {
    test('compares numbers and pads missing parts', () {
      expect(v('2.2.0') == v('2.2'), isTrue);
      expect(v('2.10.0') > v('2.9.9'), isTrue);
      expect(v('1.0.0') < v('1.0.1'), isTrue);
      expect(v('3') > v('2.99.99'), isTrue);
    });

    test('ranks a stable release above its pre-releases', () {
      expect(v('2.2.0') > v('2.2.0-dev.4'), isTrue);
      expect(v('2.2.0-dev.4') > v('2.2.0-dev.3'), isTrue);
      expect(v('2.2.0-dev.10') > v('2.2.0-dev.9'), isTrue);
      expect(v('2.2.0-beta.1') > v('2.2.0-alpha.9'), isTrue);
      expect(v('2.2.0-rc.1') > v('2.1.9'), isTrue);
      expect(v('1.0.0-alpha') < v('1.0.0-alpha.1'), isTrue);
    });

    test('ignores build metadata', () {
      expect(v('1.0.0+1') == v('1.0.0+2'), isTrue);
      expect(v('1.0.0+1').hashCode, v('1.0.0').hashCode);
    });

    test('sorts a list', () {
      final sorted =
          ['2.0.0', '2.2.0-dev.1', '1.9.0', '2.2.0', 'v2.1.0'].map(v).toList()
            ..sort();
      expect(sorted.map((e) => e.normalized), [
        '1.9.0',
        '2.0.0',
        '2.1.0',
        '2.2.0-dev.1',
        '2.2.0',
      ]);
    });
  });
}
