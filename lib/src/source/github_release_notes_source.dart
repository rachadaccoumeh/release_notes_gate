import 'package:http/http.dart' as http;

import '../model/release_note.dart';
import '../model/release_version.dart';
import '../parser/changelog_parser.dart';
import 'http_fetch.dart';
import 'release_notes_source.dart';

/// Where a [GitHubReleaseNotesSource] reads the notes from.
enum GitHubNotesOrigin {
  /// The repository's `CHANGELOG.md` on a branch, read as a raw file. Falls
  /// back to [releases] when the file does not exist.
  changelogFile,

  /// The bodies of the GitHub Releases, newest first.
  releases,
}

/// Release notes from a GitHub repository.
///
/// [fetch] reads `CHANGELOG.md` from [branch] through
/// `raw.githubusercontent.com` and parses it with [ChangelogParser]. When the
/// file is missing it reads the GitHub Releases instead. [latest] asks the
/// Releases API for the newest release and parses its body, so an update
/// check costs one small request.
///
/// Public repositories need no token. Unauthenticated calls to the API are
/// limited to 60 per hour per IP address; pass a [token] for private
/// repositories or a higher limit. Works on every Flutter platform,
/// including web, since GitHub sends CORS headers for both hosts.
class GitHubReleaseNotesSource extends ReleaseNotesSource {
  /// Creates a source for `github.com/[owner]/[repo]`.
  ///
  /// [tagPrefix] is what the repository puts before the version in its tags,
  /// `v` for `v2.2.0`. It builds the release page link of each note.
  /// [includePrereleases] lets [latest] return a pre-release.
  GitHubReleaseNotesSource({
    required this.owner,
    required this.repo,
    this.branch = 'main',
    this.changelogPath = 'CHANGELOG.md',
    this.origin = GitHubNotesOrigin.changelogFile,
    this.tagPrefix = 'v',
    this.includePrereleases = false,
    this.token,
    this.releasesPerPage = 30,
    this.parser = const ChangelogParser(),
    this.timeout = const Duration(seconds: 15),
    Uri? apiBaseUrl,
    Uri? rawBaseUrl,
    Uri? webBaseUrl,
    http.Client? client,
  }) : apiBaseUrl = apiBaseUrl ?? Uri.parse('https://api.github.com'),
       rawBaseUrl =
           rawBaseUrl ?? Uri.parse('https://raw.githubusercontent.com'),
       webBaseUrl = webBaseUrl ?? Uri.parse('https://github.com'),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  /// The repository owner, user or organisation.
  final String owner;

  /// The repository name.
  final String repo;

  /// The branch the changelog is read from.
  final String branch;

  /// Path of the changelog inside the repository.
  final String changelogPath;

  /// Where the notes come from.
  final GitHubNotesOrigin origin;

  /// The prefix before the version in tags.
  final String tagPrefix;

  /// Whether [latest] may return a pre-release.
  final bool includePrereleases;

  /// A personal access token, or null for anonymous requests.
  final String? token;

  /// How many releases to read in [GitHubNotesOrigin.releases] mode.
  final int releasesPerPage;

  /// The parser for changelog Markdown and release bodies.
  final ChangelogParser parser;

  /// Timeout per request.
  final Duration timeout;

  /// The API host. Change it for GitHub Enterprise.
  final Uri apiBaseUrl;

  /// The raw file host. Change it for GitHub Enterprise.
  final Uri rawBaseUrl;

  /// The web host, for release page links.
  final Uri webBaseUrl;

  final http.Client _client;
  final bool _ownsClient;

  /// The raw URL of the changelog file.
  Uri get changelogUrl => rawBaseUrl.replace(
    pathSegments: [owner, repo, branch, ...changelogPath.split('/')],
  );

  /// The release page of [version].
  Uri releaseUrl(ReleaseVersion version) =>
      tagUrl('$tagPrefix${version.normalized}');

  /// The release page of a tag.
  Uri tagUrl(String tag) =>
      webBaseUrl.replace(pathSegments: [owner, repo, 'releases', 'tag', tag]);

  Map<String, String> get _apiHeaders => {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, String> get _rawHeaders => {
    if (token != null) 'Authorization': 'Bearer $token',
  };

  @override
  Future<List<ReleaseNote>> fetch() async {
    if (origin == GitHubNotesOrigin.releases) return fetchReleases();
    try {
      final markdown = await fetchText(
        _client,
        changelogUrl,
        headers: _rawHeaders,
        timeout: timeout,
      );
      return parser.parse(markdown, urlBuilder: releaseUrl);
    } on ReleaseNotesException catch (error) {
      if (!error.isNotFound) rethrow;
      return fetchReleases();
    }
  }

  /// Reads up to [releasesPerPage] releases from the Releases API and parses
  /// their bodies. Drafts are skipped.
  Future<List<ReleaseNote>> fetchReleases() async {
    final uri = apiBaseUrl.replace(
      pathSegments: ['repos', owner, repo, 'releases'],
      queryParameters: {'per_page': '$releasesPerPage'},
    );
    final json = await fetchJson(
      _client,
      uri,
      headers: _apiHeaders,
      timeout: timeout,
    );
    if (json is! List) {
      throw ReleaseNotesException(
        'Expected a list of releases',
        kind: ReleaseNotesErrorKind.format,
        uri: uri,
      );
    }
    return json
        .whereType<Map<String, Object?>>()
        .where((release) => release['draft'] != true)
        .map(_noteFromRelease)
        .whereType<ReleaseNote>()
        .toList(growable: false)
        .newestFirst;
  }

  @override
  Future<ReleaseNote?> latest() async {
    if (!includePrereleases) {
      final uri = apiBaseUrl.replace(
        pathSegments: ['repos', owner, repo, 'releases', 'latest'],
      );
      try {
        final json = await fetchJson(
          _client,
          uri,
          headers: _apiHeaders,
          timeout: timeout,
        );
        return json is Map<String, Object?> ? _noteFromRelease(json) : null;
      } on ReleaseNotesException catch (error) {
        // A repository without a stable release answers 404.
        if (error.isNotFound) return null;
        rethrow;
      }
    }
    final uri = apiBaseUrl.replace(
      pathSegments: ['repos', owner, repo, 'releases'],
      queryParameters: {'per_page': '5'},
    );
    final json = await fetchJson(
      _client,
      uri,
      headers: _apiHeaders,
      timeout: timeout,
    );
    if (json is! List) return null;
    for (final release in json.whereType<Map<String, Object?>>()) {
      if (release['draft'] == true) continue;
      final note = _noteFromRelease(release);
      if (note != null) return note;
    }
    return null;
  }

  ReleaseNote? _noteFromRelease(Map<String, Object?> release) {
    final tag = release['tag_name'];
    if (tag is! String) return null;
    final version = ReleaseVersion.tryParse(
      tag.startsWith(tagPrefix) ? tag.substring(tagPrefix.length) : tag,
    );
    if (version == null) return null;

    final body = release['body'];
    final published = release['published_at'] ?? release['created_at'];
    final htmlUrl = release['html_url'];
    final assets = release['assets'];
    Uri? download;
    if (assets is List) {
      for (final asset in assets.whereType<Map<String, Object?>>()) {
        final url = asset['browser_download_url'];
        if (url is String) {
          download = Uri.tryParse(url);
          break;
        }
      }
    }
    return ReleaseNote(
      version: version,
      date:
          published is String ? DateTime.tryParse(published)?.toLocal() : null,
      sections: body is String ? parser.parseSections(body) : const [],
      url: htmlUrl is String ? Uri.tryParse(htmlUrl) : tagUrl(tag),
      downloadUrl: download,
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
