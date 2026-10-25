import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show immutable;

import '../model/release_platform.dart';
import '../model/release_version.dart';

/// When the notes show up on their own.
enum ReleaseNotesTrigger {
  /// After the app was updated: the installed version differs from the last
  /// version the user saw. Shows the notes of the versions in between, once.
  /// This is the default.
  onVersionChange,

  /// When the source has a newer release than the installed version. Shows
  /// an "update available" summary with the notes of the releases in
  /// between.
  onRemoteUpdate,

  /// Never on its own. The app opens the notes from a menu or a button.
  manual,
}

/// Which changes to show on the current platform.
enum PlatformFilter {
  /// Show the changes of the current platform, with a switch to show all.
  /// This is the default.
  currentWithToggle,

  /// Show only the changes of the current platform.
  currentOnly,

  /// Show every change, no filter.
  none,
}

/// How a [ReleaseNotesController] behaves.
@immutable
class ReleaseNotesConfig {
  /// Creates a config. Every value has a default that suits a store app.
  const ReleaseNotesConfig({
    this.trigger = ReleaseNotesTrigger.onVersionChange,
    this.platformFilter = PlatformFilter.currentWithToggle,
    this.platform,
    this.cacheEnabled = true,
    this.includePrereleases = false,
    this.showOnFirstInstall = false,
    this.markSeenOnShow = true,
    this.installedVersion,
    this.locale,
    this.defaultLocale = 'en',
    this.maxNotes,
  });

  /// When the notes show up on their own.
  final ReleaseNotesTrigger trigger;

  /// Which changes to show on the current platform.
  final PlatformFilter platformFilter;

  /// The platform to filter for. Null means the platform the app runs on.
  final ReleasePlatform? platform;

  /// Whether fetched notes are cached and shown when the source is
  /// unreachable.
  final bool cacheEnabled;

  /// Whether pre-release notes are listed. Off by default; on when the
  /// installed version is itself a pre-release.
  final bool includePrereleases;

  /// Whether the notes show on the very first launch, when no version was
  /// seen before. Off by default: a new user has nothing to catch up on.
  final bool showOnFirstInstall;

  /// Whether the installed version is stored as seen when the notes are
  /// shown. Turn off to call `markSeen` yourself, for example on dismiss.
  final bool markSeenOnShow;

  /// The installed version. Null reads it from the app's package info.
  final ReleaseVersion? installedVersion;

  /// The locale for translated texts. Null uses the locale of the widget
  /// tree where the notes are shown.
  final Locale? locale;

  /// The locale a JSON text map falls back to when it has no `default` key.
  final String defaultLocale;

  /// At most this many notes are kept, newest first. Null keeps all.
  final int? maxNotes;

  /// Returns a copy with the given fields replaced.
  ReleaseNotesConfig copyWith({
    ReleaseNotesTrigger? trigger,
    PlatformFilter? platformFilter,
    ReleasePlatform? platform,
    bool? cacheEnabled,
    bool? includePrereleases,
    bool? showOnFirstInstall,
    bool? markSeenOnShow,
    ReleaseVersion? installedVersion,
    Locale? locale,
    String? defaultLocale,
    int? maxNotes,
  }) => ReleaseNotesConfig(
    trigger: trigger ?? this.trigger,
    platformFilter: platformFilter ?? this.platformFilter,
    platform: platform ?? this.platform,
    cacheEnabled: cacheEnabled ?? this.cacheEnabled,
    includePrereleases: includePrereleases ?? this.includePrereleases,
    showOnFirstInstall: showOnFirstInstall ?? this.showOnFirstInstall,
    markSeenOnShow: markSeenOnShow ?? this.markSeenOnShow,
    installedVersion: installedVersion ?? this.installedVersion,
    locale: locale ?? this.locale,
    defaultLocale: defaultLocale ?? this.defaultLocale,
    maxNotes: maxNotes ?? this.maxNotes,
  );
}
