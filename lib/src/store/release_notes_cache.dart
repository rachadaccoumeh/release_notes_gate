import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/release_note.dart';
import '../model/release_note_json.dart';

/// Notes read from a cache, with the time they were fetched.
@immutable
class CachedReleaseNotes {
  /// Creates a cache entry.
  const CachedReleaseNotes(this.notes, this.fetchedAt);

  /// The cached notes, newest first.
  final List<ReleaseNote> notes;

  /// When the notes were fetched from the source.
  final DateTime fetchedAt;

  /// How long ago the notes were fetched.
  Duration get age => DateTime.now().difference(fetchedAt);
}

/// Keeps the last fetched notes so the app can show them offline.
///
/// The default is [SharedPreferencesReleaseNotesCache].
abstract class ReleaseNotesCache {
  /// Creates a cache.
  const ReleaseNotesCache();

  /// The cached notes, or null when the cache is empty or unreadable.
  Future<CachedReleaseNotes?> read();

  /// Replaces the cache with [notes].
  Future<void> write(List<ReleaseNote> notes, {DateTime? fetchedAt});

  /// Empties the cache.
  Future<void> clear();
}

/// Keeps the notes as JSON in `shared_preferences`.
class SharedPreferencesReleaseNotesCache extends ReleaseNotesCache {
  /// Creates a cache under [key].
  SharedPreferencesReleaseNotesCache({
    this.key = 'release_notes_gate.cache',
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// The preference key.
  final String key;

  final SharedPreferencesAsync _preferences;

  @override
  Future<CachedReleaseNotes?> read() async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      final fetchedAt = DateTime.tryParse(json['fetched_at'] as String? ?? '');
      if (fetchedAt == null) return null;
      return CachedReleaseNotes(
        ReleaseNoteJson.decodeList(json['notes']),
        fetchedAt,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(List<ReleaseNote> notes, {DateTime? fetchedAt}) =>
      _preferences.setString(
        key,
        jsonEncode(<String, Object?>{
          'fetched_at': (fetchedAt ?? DateTime.now()).toUtc().toIso8601String(),
          'notes': ReleaseNoteJson.encodeList(notes),
        }),
      );

  @override
  Future<void> clear() => _preferences.remove(key);
}

/// Keeps the notes in memory, for tests and previews.
class MemoryReleaseNotesCache extends ReleaseNotesCache {
  /// Creates an empty cache.
  MemoryReleaseNotesCache();

  CachedReleaseNotes? _entry;

  @override
  Future<CachedReleaseNotes?> read() async => _entry;

  @override
  Future<void> write(List<ReleaseNote> notes, {DateTime? fetchedAt}) async =>
      _entry = CachedReleaseNotes(
        List.unmodifiable(notes),
        fetchedAt ?? DateTime.now(),
      );

  @override
  Future<void> clear() async => _entry = null;
}
