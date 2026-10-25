import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:http/http.dart' as http;

import '../model/release_note.dart';
import '../model/release_version.dart';
import '../parser/changelog_parser.dart';
import 'http_fetch.dart';
import 'release_notes_source.dart';

/// Release notes from a changelog in Markdown: a URL, a bundled asset or a
/// string.
///
/// The text is parsed with [ChangelogParser], so conventional-changelog,
/// Keep a Changelog and pub.dev style files all work.
class MarkdownChangelogSource extends ReleaseNotesSource {
  /// Reads the changelog from [uri] with a GET request.
  MarkdownChangelogSource.url(
    Uri uri, {
    Map<String, String> headers = const {},
    this.parser = const ChangelogParser(),
    this.urlBuilder,
    Duration timeout = const Duration(seconds: 15),
    http.Client? client,
  }) : _loader = _UrlLoader(uri, headers, timeout, client),
       _bundle = null;

  /// Reads the changelog from an asset declared in `pubspec.yaml`, for
  /// example `assets/CHANGELOG.md`.
  MarkdownChangelogSource.asset(
    String key, {
    this.parser = const ChangelogParser(),
    this.urlBuilder,
    AssetBundle? bundle,
  }) : _loader = _AssetLoader(key),
       _bundle = bundle;

  /// Parses [markdown] you already have.
  MarkdownChangelogSource.text(
    String markdown, {
    this.parser = const ChangelogParser(),
    this.urlBuilder,
  }) : _loader = _TextLoader(markdown),
       _bundle = null;

  /// The parser for the Markdown.
  final ChangelogParser parser;

  /// Gives each note a release page link, or null for none.
  final Uri? Function(ReleaseVersion version)? urlBuilder;

  final _Loader _loader;
  final AssetBundle? _bundle;

  @override
  Future<List<ReleaseNote>> fetch() async {
    final markdown = await _loader.load(_bundle ?? rootBundle);
    return parser.parse(markdown, urlBuilder: urlBuilder);
  }

  @override
  void dispose() => _loader.dispose();
}

abstract class _Loader {
  Future<String> load(AssetBundle bundle);

  void dispose() {}
}

class _UrlLoader implements _Loader {
  _UrlLoader(this.uri, this.headers, this.timeout, http.Client? client)
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final Uri uri;
  final Map<String, String> headers;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<String> load(AssetBundle bundle) =>
      fetchText(_client, uri, headers: headers, timeout: timeout);

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class _AssetLoader implements _Loader {
  const _AssetLoader(this.key);

  final String key;

  @override
  Future<String> load(AssetBundle bundle) async {
    try {
      return await bundle.loadString(key);
    } catch (error) {
      throw ReleaseNotesException(
        'Asset not found: $key',
        kind: ReleaseNotesErrorKind.format,
        cause: error,
      );
    }
  }

  @override
  void dispose() {}
}

class _TextLoader implements _Loader {
  const _TextLoader(this.markdown);

  final String markdown;

  @override
  Future<String> load(AssetBundle bundle) async => markdown;

  @override
  void dispose() {}
}
