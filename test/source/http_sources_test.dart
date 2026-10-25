import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

void main() {
  group('HttpReleaseNotesSource', () {
    test('reads the default JSON shape and sends built headers', () async {
      final source = HttpReleaseNotesSource(
        uri: Uri.parse('https://api.example.com/releases'),
        headersBuilder: () async => {'Authorization': 'Bearer t'},
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer t');
          expect(request.headers['Accept'], 'application/json');
          return http.Response(
            jsonEncode({
              'releases': [
                {
                  'version': '1.0.0',
                  'sections': {
                    'features': ['One'],
                  },
                },
                {'version': '1.1.0', 'markdown': '### Bug Fixes\n* Two'},
              ],
            }),
            200,
          );
        }),
      );
      final notes = await source.fetch();
      expect(notes.map((n) => n.version.normalized), ['1.1.0', '1.0.0']);
      expect(notes.first.counts, {ReleaseSectionKind.fixes: 1});
    });

    test('uses a custom mapper and a latest endpoint', () async {
      final source = HttpReleaseNotesSource(
        uri: Uri.parse('https://api.example.com/releases'),
        latestUri: Uri.parse('https://api.example.com/releases/latest'),
        mapper:
            (json) => [
              for (final entry in (json as List).cast<Map<String, Object?>>())
                ReleaseNote(
                  version: ReleaseVersion.parse(entry['v']! as String),
                  sections: [
                    ReleaseSection(
                      kind: ReleaseSectionKind.features,
                      items: [ReleaseItem.plain(entry['what']! as String)],
                    ),
                  ],
                ),
            ],
        client: MockClient((request) async {
          if (request.url.path.endsWith('/latest')) {
            return http.Response(
              jsonEncode({'v': '3.0.0', 'what': 'Newest'}),
              200,
            );
          }
          return http.Response(
            jsonEncode([
              {'v': '2.0.0', 'what': 'Two'},
            ]),
            200,
          );
        }),
      );
      expect((await source.latest())!.version.normalized, '3.0.0');
      expect((await source.fetch()).single.version.normalized, '2.0.0');
    });

    test('reports non-JSON bodies as format errors', () async {
      final source = HttpReleaseNotesSource(
        uri: Uri.parse('https://api.example.com/releases'),
        client: MockClient((_) async => http.Response('<html>', 200)),
      );
      await expectLater(
        source.fetch(),
        throwsA(
          isA<ReleaseNotesException>().having(
            (e) => e.kind,
            'kind',
            ReleaseNotesErrorKind.format,
          ),
        ),
      );
    });
  });

  group('MarkdownChangelogSource', () {
    const markdown = '## 1.2.0\n* A\n## 1.1.0\n* B';

    test('parses text', () async {
      final notes = await MarkdownChangelogSource.text(markdown).fetch();
      expect(notes.map((n) => n.version.normalized), ['1.2.0', '1.1.0']);
    });

    test('fetches a url', () async {
      final source = MarkdownChangelogSource.url(
        Uri.parse('https://example.com/CHANGELOG.md'),
        client: MockClient((_) async => http.Response(markdown, 200)),
        urlBuilder: (v) => Uri.parse('https://example.com/$v'),
      );
      final notes = await source.fetch();
      expect(notes.first.url, Uri.parse('https://example.com/1.2.0'));
    });
  });

  group('StaticReleaseNotesSource', () {
    test('sorts newest first and reads JSON', () async {
      final source = StaticReleaseNotesSource.json([
        {
          'version': '1.0.0',
          'sections': {
            'features': ['A'],
          },
        },
        {
          'version': '2.0.0',
          'sections': {
            'fixes': ['B'],
          },
        },
      ]);
      final notes = await source.fetch();
      expect(notes.first.version.normalized, '2.0.0');
      expect((await source.latest())!.version.normalized, '2.0.0');
    });
  });
}
