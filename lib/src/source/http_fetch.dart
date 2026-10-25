import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'release_notes_source.dart';

/// Performs one GET and turns every failure into a [ReleaseNotesException].
///
/// Shared by the HTTP sources so they handle status codes, timeouts and
/// connection errors the same way.
Future<String> fetchText(
  http.Client client,
  Uri uri, {
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 15),
}) async {
  final http.Response response;
  try {
    response = await client.get(uri, headers: headers).timeout(timeout);
  } on TimeoutException catch (error) {
    throw ReleaseNotesException(
      'Timed out after ${timeout.inSeconds}s',
      kind: ReleaseNotesErrorKind.network,
      uri: uri,
      cause: error,
    );
  } on http.ClientException catch (error) {
    throw ReleaseNotesException(
      error.message,
      kind: ReleaseNotesErrorKind.network,
      uri: uri,
      cause: error,
    );
  } catch (error) {
    throw ReleaseNotesException(
      'Request failed',
      kind: ReleaseNotesErrorKind.network,
      uri: uri,
      cause: error,
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ReleaseNotesException(
      'HTTP ${response.statusCode}',
      kind: ReleaseNotesErrorKind.http,
      statusCode: response.statusCode,
      uri: uri,
    );
  }
  return response.body;
}

/// Performs one GET and decodes the body as JSON.
Future<Object?> fetchJson(
  http.Client client,
  Uri uri, {
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 15),
}) async {
  final body = await fetchText(client, uri, headers: headers, timeout: timeout);
  try {
    return jsonDecode(body);
  } on FormatException catch (error) {
    throw ReleaseNotesException(
      'Response is not JSON',
      kind: ReleaseNotesErrorKind.format,
      uri: uri,
      cause: error,
    );
  }
}
