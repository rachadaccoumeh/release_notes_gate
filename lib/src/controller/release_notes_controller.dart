import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/release_note.dart';
import '../model/release_platform.dart';
import '../model/release_version.dart';
import '../source/release_notes_source.dart';
import '../store/release_notes_cache.dart';
import '../store/seen_version_store.dart';
import 'release_notes_callbacks.dart';
import 'release_notes_config.dart';
import 'release_notes_state.dart';

/// Reads the installed app version.
typedef InstalledVersionLoader = Future<String> Function();

/// Loads the notes, runs the trigger and holds the state the UI observes.
///
/// ```dart
/// final controller = ReleaseNotesController(
///   source: GitHubReleaseNotesSource(owner: 'acme', repo: 'app'),
///   config: const ReleaseNotesConfig(trigger: ReleaseNotesTrigger.onVersionChange),
/// );
/// final decision = await controller.check();
/// if (decision.shouldShow) showReleaseNotes(context, controller: controller);
/// ```
///
/// The controller is a [ChangeNotifier]; listen to it or wrap the UI in a
/// [ListenableBuilder]. It is headless: nothing here draws. Use [state] to
/// render anything you like.
class ReleaseNotesController extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// [seenStore] and [cache] default to `shared_preferences`. The cache is
  /// only used when [ReleaseNotesConfig.cacheEnabled] is true.
  /// [installedVersionLoader] defaults to `package_info_plus`; pass one in
  /// tests. With [disposeSource], disposing the controller disposes the
  /// source too.
  ReleaseNotesController({
    required this.source,
    this.config = const ReleaseNotesConfig(),
    this.callbacks = const ReleaseNotesCallbacks(),
    SeenVersionStore? seenStore,
    ReleaseNotesCache? cache,
    InstalledVersionLoader? installedVersionLoader,
    bool disposeSource = true,
  }) : seenStore = seenStore ?? SharedPreferencesSeenVersionStore(),
       cache =
           cache ??
           (config.cacheEnabled ? SharedPreferencesReleaseNotesCache() : null),
       _installedVersionLoader = installedVersionLoader ?? _packageInfoVersion,
       _disposeSource = disposeSource;

  /// Where the notes come from.
  final ReleaseNotesSource source;

  /// How the controller behaves.
  final ReleaseNotesConfig config;

  /// Hooks for analytics and logging.
  final ReleaseNotesCallbacks callbacks;

  /// Remembers the last seen version.
  final SeenVersionStore seenStore;

  /// Keeps the last fetched notes, or null when caching is off.
  final ReleaseNotesCache? cache;

  final InstalledVersionLoader _installedVersionLoader;
  final bool _disposeSource;

  ReleaseNotesState _state = const ReleaseNotesState();
  Future<void>? _loading;
  bool _showAllPlatforms = false;
  bool _disposed = false;

  /// Everything the UI needs.
  ReleaseNotesState get state => _state;

  /// The platform the notes are filtered for, or null for no filter.
  ReleasePlatform? get platform {
    if (config.platformFilter == PlatformFilter.none) return null;
    return config.platform ?? ReleasePlatform.current;
  }

  /// True when the filter is lifted and every platform's changes show.
  bool get showAllPlatforms => _showAllPlatforms;

  /// Lifts or applies the platform filter. Only has an effect with
  /// [PlatformFilter.currentWithToggle].
  set showAllPlatforms(bool value) {
    if (config.platformFilter != PlatformFilter.currentWithToggle) return;
    if (_showAllPlatforms == value) return;
    _showAllPlatforms = value;
    notifyListeners();
  }

  /// True when the user may switch between their platform and all.
  bool get canTogglePlatforms =>
      config.platformFilter == PlatformFilter.currentWithToggle &&
      platform != null;

  /// The platform in effect right now, after the toggle.
  ReleasePlatform? get effectivePlatform => _showAllPlatforms ? null : platform;

  /// [ReleaseNotesState.notes] narrowed to [effectivePlatform].
  List<ReleaseNote> get visibleNotes =>
      _state.notes.forPlatform(effectivePlatform);

  /// The notes of the last decision narrowed to [effectivePlatform].
  List<ReleaseNote> get visibleDecisionNotes =>
      _state.decision.notes.forPlatform(effectivePlatform);

  /// True when the filter hides at least one change.
  bool get filterHidesChanges {
    final platform = this.platform;
    if (platform == null) return false;
    final all = _state.notes.fold(0, (sum, note) => sum + note.changeCount);
    final shown = _state.notes
        .forPlatform(platform)
        .fold(0, (sum, note) => sum + note.changeCount);
    return shown < all;
  }

  /// Runs the configured trigger and returns what to show.
  ///
  /// Loads the notes when the trigger needs them. For
  /// [ReleaseNotesTrigger.manual] the decision is always "none"; call
  /// [open] and present the notes yourself.
  Future<ReleaseNotesDecision> check() async {
    final installed = await _readInstalledVersion();
    final decision = switch (config.trigger) {
      ReleaseNotesTrigger.onVersionChange => await _checkVersionChange(
        installed,
      ),
      ReleaseNotesTrigger.onRemoteUpdate => await _checkRemoteUpdate(installed),
      ReleaseNotesTrigger.manual => const ReleaseNotesDecision.none(),
    };
    _set(_state.copyWith(decision: decision));
    callbacks.onDecision?.call(decision);
    return decision;
  }

  Future<ReleaseNotesDecision> _checkVersionChange(
    ReleaseVersion? installed,
  ) async {
    if (installed == null) return const ReleaseNotesDecision.none();
    final seen = await _readSeenVersion();
    if (seen == null && !config.showOnFirstInstall) {
      await _writeSeen(installed);
      return const ReleaseNotesDecision.none();
    }
    if (seen != null && seen >= installed) {
      return const ReleaseNotesDecision.none();
    }

    await load();
    final notes = _state.notes.between(seen, installed);
    if (notes.isEmpty) {
      // Nothing to tell about this version. Remember it so the check stays
      // quiet until the next update. A failed fetch leaves the store alone,
      // so the next launch tries again.
      if (_state.status == ReleaseNotesStatus.ready && !_state.fromCache) {
        await _writeSeen(installed);
      }
      return const ReleaseNotesDecision.none();
    }
    return ReleaseNotesDecision(
      reason: ReleaseNotesReason.newVersionInstalled,
      notes: notes,
      from: seen,
      to: installed,
    );
  }

  Future<ReleaseNotesDecision> _checkRemoteUpdate(
    ReleaseVersion? installed,
  ) async {
    ReleaseNote? latest;
    try {
      latest = await source.latest();
    } catch (error, stackTrace) {
      callbacks.onError?.call(error, stackTrace);
      _set(_state.copyWith(error: error));
      return const ReleaseNotesDecision.none();
    }
    if (latest != null) _set(_state.copyWith(latest: latest));
    if (latest == null || installed == null || latest.version <= installed) {
      return const ReleaseNotesDecision.none();
    }

    await load();
    var notes = _state.notes.between(installed, latest.version);
    // Right after a release the changelog file can lag behind the release
    // itself; the release body then stands in so the user is not shown an
    // empty update.
    if (notes.find(latest.version) == null && latest.hasContent) {
      notes = [latest, ...notes].newestFirst;
    }
    return ReleaseNotesDecision(
      reason: ReleaseNotesReason.updateAvailable,
      notes: notes,
      from: installed,
      to: latest.version,
    );
  }

  /// Opens the notes by hand: loads them and sets a manual decision over
  /// every note, so the UI shows the full changelog.
  Future<ReleaseNotesDecision> open() async {
    await _readInstalledVersion();
    await load();
    final decision = ReleaseNotesDecision(
      reason: ReleaseNotesReason.manual,
      notes: _state.notes,
      to: _state.installedVersion,
    );
    _set(_state.copyWith(decision: decision));
    return decision;
  }

  /// Loads the notes from the source, once. Concurrent calls share one
  /// fetch. With [force], a fetch runs even when notes are already there.
  ///
  /// Never throws: a failure lands in [ReleaseNotesState.error], and cached
  /// notes stand in when the cache has any.
  Future<void> load({bool force = false}) {
    if (!force && _state.status == ReleaseNotesStatus.ready) {
      return Future.value();
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  /// Fetches again, keeping the current notes on screen meanwhile.
  Future<void> refresh() => load(force: true);

  Future<void> _load() async {
    _set(_state.copyWith(status: ReleaseNotesStatus.loading, clearError: true));
    final installed = await _readInstalledVersion();
    try {
      final notes = _filter(await source.fetch(), installed);
      final now = DateTime.now();
      _set(
        _state.copyWith(
          status: ReleaseNotesStatus.ready,
          notes: notes,
          fromCache: false,
          fetchedAt: now,
        ),
      );
      callbacks.onLoaded?.call(notes, fromCache: false);
      if (config.cacheEnabled) {
        unawaited(
          cache?.write(notes, fetchedAt: now).catchError((Object _) {}),
        );
      }
    } catch (error, stackTrace) {
      callbacks.onError?.call(error, stackTrace);
      final cached = config.cacheEnabled ? await _readCache() : null;
      if (cached != null && cached.notes.isNotEmpty) {
        final notes = _filter(cached.notes, installed);
        _set(
          _state.copyWith(
            status: ReleaseNotesStatus.ready,
            notes: notes,
            fromCache: true,
            fetchedAt: cached.fetchedAt,
            error: error,
          ),
        );
        callbacks.onLoaded?.call(notes, fromCache: true);
      } else {
        _set(
          _state.copyWith(
            status:
                _state.notes.isEmpty
                    ? ReleaseNotesStatus.failed
                    : ReleaseNotesStatus.ready,
            error: error,
          ),
        );
      }
    }
  }

  Future<CachedReleaseNotes?> _readCache() async {
    try {
      return await cache?.read();
    } catch (_) {
      return null;
    }
  }

  List<ReleaseNote> _filter(
    List<ReleaseNote> notes,
    ReleaseVersion? installed,
  ) {
    var result = notes.newestFirst;
    final keepPrereleases =
        config.includePrereleases || (installed?.isPrerelease ?? false);
    if (!keepPrereleases) {
      result = result
          .where((note) => !note.isPrerelease || note.version == installed)
          .toList(growable: false);
    }
    final max = config.maxNotes;
    if (max != null && result.length > max) result = result.sublist(0, max);
    return result;
  }

  /// Stores the installed version as seen, so the next launch stays quiet
  /// until the app is updated again. The UI calls this on show when
  /// [ReleaseNotesConfig.markSeenOnShow] is on.
  Future<void> markSeen() async {
    final installed = await _readInstalledVersion();
    if (installed == null) return;
    await _writeSeen(installed);
  }

  /// Forgets the seen version, so the next [check] shows the notes again.
  /// Useful for a "show what's new again" debug switch.
  Future<void> resetSeen() async {
    await seenStore.clear();
    _set(_state.copyWith(clearSeenVersion: true));
  }

  /// Tells the callbacks the notes were shown and, by config, marks the
  /// installed version as seen. The built-in UI calls this; call it
  /// yourself when you render your own.
  Future<void> notifyShown() async {
    callbacks.onShown?.call(_state.decision);
    if (config.markSeenOnShow &&
        _state.decision.reason == ReleaseNotesReason.newVersionInstalled) {
      await markSeen();
    }
  }

  /// Tells the callbacks the notes were dismissed.
  void notifyDismissed() => callbacks.onDismissed?.call(_state.decision);

  Future<void> _writeSeen(ReleaseVersion version) async {
    try {
      await seenStore.write(version);
      _set(_state.copyWith(seenVersion: version));
    } catch (error, stackTrace) {
      callbacks.onError?.call(error, stackTrace);
    }
  }

  Future<ReleaseVersion?> _readInstalledVersion() async {
    if (_state.installedVersion != null) return _state.installedVersion;
    var installed = config.installedVersion;
    if (installed == null) {
      try {
        installed = ReleaseVersion.tryParse(await _installedVersionLoader());
      } catch (error, stackTrace) {
        callbacks.onError?.call(error, stackTrace);
      }
    }
    if (installed != null) _set(_state.copyWith(installedVersion: installed));
    return installed;
  }

  Future<ReleaseVersion?> _readSeenVersion() async {
    try {
      final seen = await seenStore.read();
      if (seen != null) _set(_state.copyWith(seenVersion: seen));
      return seen;
    } catch (error, stackTrace) {
      callbacks.onError?.call(error, stackTrace);
      return null;
    }
  }

  void _set(ReleaseNotesState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_disposeSource) source.dispose();
    super.dispose();
  }

  static Future<String> _packageInfoVersion() async =>
      (await PackageInfo.fromPlatform()).version;
}
