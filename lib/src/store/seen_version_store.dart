import 'package:shared_preferences/shared_preferences.dart';

import '../model/release_version.dart';

/// Remembers the last app version whose notes the user has seen.
///
/// The default is [SharedPreferencesSeenVersionStore]. Implement this to
/// keep the value elsewhere, for example per signed-in user.
abstract class SeenVersionStore {
  /// Creates a store.
  const SeenVersionStore();

  /// The last seen version, or null when nothing was stored yet.
  Future<ReleaseVersion?> read();

  /// Stores [version] as seen.
  Future<void> write(ReleaseVersion version);

  /// Forgets the stored version.
  Future<void> clear();
}

/// Keeps the last seen version in `shared_preferences`. Works on every
/// Flutter platform.
class SharedPreferencesSeenVersionStore extends SeenVersionStore {
  /// Creates a store under [key].
  SharedPreferencesSeenVersionStore({
    this.key = 'release_notes_gate.seen_version',
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// The preference key.
  final String key;

  final SharedPreferencesAsync _preferences;

  @override
  Future<ReleaseVersion?> read() async =>
      ReleaseVersion.tryParse(await _preferences.getString(key));

  @override
  Future<void> write(ReleaseVersion version) =>
      _preferences.setString(key, version.normalized);

  @override
  Future<void> clear() => _preferences.remove(key);
}

/// Keeps the last seen version in memory, for tests and previews.
class MemorySeenVersionStore extends SeenVersionStore {
  /// Creates a store, optionally with a starting [version].
  MemorySeenVersionStore([this.version]);

  /// The stored version.
  ReleaseVersion? version;

  @override
  Future<ReleaseVersion?> read() async => version;

  @override
  Future<void> write(ReleaseVersion version) async => this.version = version;

  @override
  Future<void> clear() async => version = null;
}
