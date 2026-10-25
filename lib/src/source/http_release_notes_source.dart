import 'package:http/http.dart' as http;

import '../model/release_note.dart';
import '../model/release_note_json.dart';
import 'http_fetch.dart';
import 'release_notes_source.dart';

/// Builds the headers of a request, for example with a fresh auth token.
typedef HeadersBuilder = Future<Map<String, String>> Function();

/// Turns a decoded JSON response into notes.
typedef ReleaseNotesMapper = List<ReleaseNote> Function(Object? json);

/// Release notes from your own REST endpoint.
///
/// By default the response is read with [ReleaseNoteJson.decodeList]: a
/// list of releases, or an object that wraps one under `releases`, `notes`,
/// `items` or `data`. Pass a [mapper] to read any other shape.
///
/// ```dart
/// HttpReleaseNotesSource(
///   uri: Uri.parse('https://api.example.com/app/releases'),
///   headersBuilder: () async => {'Authorization': 'Bearer ${await token()}'},
/// )
/// ```
class HttpReleaseNotesSource extends ReleaseNotesSource {
  /// Creates a source that GETs [uri].
  ///
  /// [latestUri], when given, is a cheaper endpoint that returns one release
  /// for [latest]. Without it [latest] takes the first note of [fetch].
  HttpReleaseNotesSource({
    required this.uri,
    this.latestUri,
    this.headers = const {},
    this.headersBuilder,
    ReleaseNotesMapper? mapper,
    this.timeout = const Duration(seconds: 15),
    http.Client? client,
  }) : mapper = mapper ?? ReleaseNoteJson.decodeList,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  /// The endpoint that lists releases.
  final Uri uri;

  /// An endpoint that returns the newest release, or null.
  final Uri? latestUri;

  /// Static headers sent with every request.
  final Map<String, String> headers;

  /// Builds headers per request, merged over [headers].
  final HeadersBuilder? headersBuilder;

  /// Reads the response into notes.
  final ReleaseNotesMapper mapper;

  /// Timeout per request.
  final Duration timeout;

  final http.Client _client;
  final bool _ownsClient;

  Future<Map<String, String>> _headers() async => {
    'Accept': 'application/json',
    ...headers,
    ...?await headersBuilder?.call(),
  };

  @override
  Future<List<ReleaseNote>> fetch() async {
    final json = await fetchJson(
      _client,
      uri,
      headers: await _headers(),
      timeout: timeout,
    );
    return mapper(json).newestFirst;
  }

  @override
  Future<ReleaseNote?> latest() async {
    final target = latestUri;
    if (target == null) return super.latest();
    final json = await fetchJson(
      _client,
      target,
      headers: await _headers(),
      timeout: timeout,
    );
    final notes = mapper(json is Map ? <Object?>[json] : json);
    return notes.newestFirst.firstOrNull;
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
