import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

void main() {
  group('ReleaseNoteJson.decode', () {
    test('reads structured sections with localized items and platforms', () {
      final note =
          ReleaseNoteJson.decode({
            'version': 'v2.2.0',
            'date': '2026-10-25',
            'title': {'default': 'Autumn', 'ar': 'الخريف'},
            'url': 'https://example.com/r/2.2.0',
            'downloadUrl': 'https://example.com/app.apk',
            'platforms': ['android', 'iOS'],
            'sections': [
              {
                'kind': 'features',
                'items': [
                  'Dark mode',
                  {
                    'text': {'default': 'Face ID', 'ar': 'بصمة الوجه'},
                    'platforms': ['ios'],
                  },
                  {'text': 'Faster sync', 'scope': 'Sync'},
                  {'text': 'A note', 'note': true},
                ],
              },
              {
                'title': 'Fixed',
                'items': ['Crash on start'],
              },
            ],
          })!;

      expect(note.version.normalized, '2.2.0');
      expect(note.date, DateTime(2026, 10, 25));
      expect(note.title?.text, 'Autumn');
      expect(note.url, Uri.parse('https://example.com/r/2.2.0'));
      expect(note.downloadUrl, Uri.parse('https://example.com/app.apk'));
      expect(note.platforms, {ReleasePlatform.android, ReleasePlatform.ios});
      expect(note.sections[0].kind, ReleaseSectionKind.features);
      expect(note.sections[0].changeCount, 3);
      expect(note.sections[0].items[1].platforms, {ReleasePlatform.ios});
      expect(note.sections[0].items[2].scope, 'Sync');
      expect(note.sections[0].items[3].isNote, isTrue);
      expect(note.sections[1].kind, ReleaseSectionKind.fixes);
      expect(note.sections[1].title?.text, 'Fixed');
    });

    test('reads a markdown body through the parser', () {
      final note =
          ReleaseNoteJson.decode({
            'version': '1.0.0',
            'markdown': '### Features\n* One\n### Bug Fixes\n* Two',
          })!;
      expect(note.counts, {
        ReleaseSectionKind.features: 1,
        ReleaseSectionKind.fixes: 1,
      });
    });

    test('reads sections as a map of kind to items', () {
      final note =
          ReleaseNoteJson.decode({
            'version': '1.0.0',
            'sections': {
              'fixes': ['Two'],
              'features': ['One'],
              'Notes': ['Read me'],
            },
          })!;
      expect(note.sections.map((s) => s.kind), [
        ReleaseSectionKind.features,
        ReleaseSectionKind.fixes,
        ReleaseSectionKind.other,
      ]);
      expect(note.sections.last.title?.text, 'Notes');
    });

    test('returns null without a version and skips such entries in lists', () {
      expect(ReleaseNoteJson.decode({'date': '2026-01-01'}), isNull);
      final list = ReleaseNoteJson.decodeList({
        'releases': [
          {'version': '1.0.0', 'sections': <Object>[]},
          {'nope': true},
        ],
      });
      expect(list.length, 1);
    });

    test('round-trips through encode', () {
      final note =
          ReleaseNoteJson.decode({
            'version': '2.2.0',
            'date': '2026-10-25',
            'title': 'Autumn',
            'platforms': ['web'],
            'sections': [
              {
                'kind': 'features',
                'title': {'default': 'New', 'ar': 'جديد'},
                'items': [
                  'Dark mode',
                  {
                    'text': 'Face ID',
                    'scope': 'Login',
                    'platforms': ['ios'],
                  },
                ],
              },
            ],
          })!;
      final again = ReleaseNoteJson.decode(ReleaseNoteJson.encode(note))!;
      expect(again, note);
      expect(again.platforms, {ReleasePlatform.web});
    });
  });
}
