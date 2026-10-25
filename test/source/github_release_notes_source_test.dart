import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

const changelog = '''
# [2.2.0](https://github.com/acme/app/compare/v2.1.0...v2.2.0) (2026-10-25)

### Features

* Dark mode

# [2.1.0](https://github.com/acme/app/compare/v2.0.0...v2.1.0) (2026-09-01)

### Bug Fixes

* Crash on start
''';

Map<String, Object?> release(
  String tag, {
  bool prerelease = false,
  bool draft = false,
}) => {
  'tag_name': tag,
  'html_url': 'https://github.com/acme/app/releases/tag/$tag',
  'published_at': '2026-10-25T12:49:15Z',
  'prerelease': prerelease,
  'draft': draft,
  'body': '### Features\n\n* From release body\n',
  'assets': [
    {
      'browser_download_url':
          'https://github.com/acme/app/releases/download/$tag/app.apk',
    },
  ],
};

void main() {
  late List<Uri> requests;

  MockClient client({bool changelogMissing = false}) =>
      MockClient((request) async {
        requests.add(request.url);
        final path = request.url.path;
        if (request.url.host == 'raw.githubusercontent.com') {
          if (changelogMissing) return http.Response('Not Found', 404);
          expect(path, '/acme/app/main/CHANGELOG.md');
          return http.Response(changelog, 200);
        }
        expect(request.headers['Accept'], 'application/vnd.github+json');
        if (path == '/repos/acme/app/releases/latest') {
          return http.Response(jsonEncode(release('v2.2.0')), 200);
        }
        if (path == '/repos/acme/app/releases') {
          return http.Response(
            jsonEncode([
              release('v2.3.0-dev.1', prerelease: true),
              release('v2.3.0-draft', draft: true),
              release('v2.2.0'),
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

  setUp(() => requests = []);

  test(
    'fetch reads CHANGELOG.md and links each note to its tag page',
    () async {
      final source = GitHubReleaseNotesSource(
        owner: 'acme',
        repo: 'app',
        client: client(),
      );
      final notes = await source.fetch();
      expect(notes.map((n) => n.version.normalized), ['2.2.0', '2.1.0']);
      expect(
        notes.first.url,
        Uri.parse('https://github.com/acme/app/releases/tag/v2.2.0'),
      );
      expect(requests.single.host, 'raw.githubusercontent.com');
    },
  );

  test(
    'fetch falls back to the releases when the changelog is missing',
    () async {
      final source = GitHubReleaseNotesSource(
        owner: 'acme',
        repo: 'app',
        client: client(changelogMissing: true),
      );
      final notes = await source.fetch();
      expect(notes.map((n) => n.version.normalized), ['2.3.0-dev.1', '2.2.0']);
      expect(
        notes.last.downloadUrl,
        Uri.parse(
          'https://github.com/acme/app/releases/download/v2.2.0/app.apk',
        ),
      );
      expect(
        notes.last.sections.single.items.single.text.text,
        'From release body',
      );
      expect(requests.map((u) => u.path), [
        '/acme/app/main/CHANGELOG.md',
        '/repos/acme/app/releases',
      ]);
    },
  );

  test('latest asks the latest endpoint and parses the body', () async {
    final source = GitHubReleaseNotesSource(
      owner: 'acme',
      repo: 'app',
      client: client(),
    );
    final latest = await source.latest();
    expect(latest!.version.normalized, '2.2.0');
    expect(latest.date, isNotNull);
    expect(latest.counts, {ReleaseSectionKind.features: 1});
    expect(requests.single.path, '/repos/acme/app/releases/latest');
  });

  test('latest with pre-releases reads the list and skips drafts', () async {
    final source = GitHubReleaseNotesSource(
      owner: 'acme',
      repo: 'app',
      includePrereleases: true,
      client: client(),
    );
    final latest = await source.latest();
    expect(latest!.version.normalized, '2.3.0-dev.1');
    expect(requests.single.queryParameters['per_page'], '5');
  });

  test('sends the token and custom branch and path', () async {
    final source = GitHubReleaseNotesSource(
      owner: 'acme',
      repo: 'app',
      branch: 'dev',
      changelogPath: 'docs/CHANGES.md',
      token: 'secret',
      client: MockClient((request) async {
        expect(request.url.path, '/acme/app/dev/docs/CHANGES.md');
        expect(request.headers['Authorization'], 'Bearer secret');
        return http.Response(changelog, 200);
      }),
    );
    expect((await source.fetch()).length, 2);
  });

  test('turns server errors into ReleaseNotesException', () async {
    final source = GitHubReleaseNotesSource(
      owner: 'acme',
      repo: 'app',
      client: MockClient((_) async => http.Response('nope', 500)),
    );
    await expectLater(
      source.fetch(),
      throwsA(
        isA<ReleaseNotesException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
  });

  test('turns connection failures into ReleaseNotesException', () async {
    final source = GitHubReleaseNotesSource(
      owner: 'acme',
      repo: 'app',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      source.fetch(),
      throwsA(
        isA<ReleaseNotesException>().having(
          (e) => e.kind,
          'kind',
          ReleaseNotesErrorKind.network,
        ),
      ),
    );
  });
}
