import '../model/release_note.dart';

/// Where release notes come from.
///
/// Implement [fetch] to return every note you have, newest first. Override
/// [latest] when your backend can answer "what is the newest release" more
/// cheaply than a full fetch, for example from the GitHub Releases API.
abstract class ReleaseNotesSource {
  /// Creates a source.
  const ReleaseNotesSource();

  /// All release notes, newest first.
  ///
  /// Throws a [ReleaseNotesException] when the notes cannot be loaded.
  Future<List<ReleaseNote>> fetch();

  /// The newest release, or null when the source cannot tell.
  ///
  /// The default takes the first note of [fetch].
  Future<ReleaseNote?> latest() async {
    final notes = await fetch();
    return notes.newestFirst.firstOrNull;
  }

  /// Releases resources such as an owned HTTP client.
  void dispose() {}
}

/// Why release notes could not be loaded.
enum ReleaseNotesErrorKind {
  /// No connection, DNS failure or timeout.
  network,

  /// The server answered with an error status.
  http,

  /// The response could not be read.
  format,

  /// Anything else.
  unknown,
}

/// Thrown when a [ReleaseNotesSource] cannot load its notes.
class ReleaseNotesException implements Exception {
  /// Creates an exception.
  const ReleaseNotesException(
    this.message, {
    this.kind = ReleaseNotesErrorKind.unknown,
    this.statusCode,
    this.uri,
    this.cause,
  });

  /// What went wrong, in plain words.
  final String message;

  /// The class of failure.
  final ReleaseNotesErrorKind kind;

  /// The HTTP status, for [ReleaseNotesErrorKind.http].
  final int? statusCode;

  /// The request that failed, when there was one.
  final Uri? uri;

  /// The underlying error, when there was one.
  final Object? cause;

  /// True for a 404, which usually means the file or endpoint does not exist.
  bool get isNotFound => statusCode == 404;

  @override
  String toString() {
    final buffer = StringBuffer('ReleaseNotesException(${kind.name}');
    if (statusCode != null) buffer.write(' $statusCode');
    buffer.write('): $message');
    if (uri != null) buffer.write(' [$uri]');
    return buffer.toString();
  }
}
