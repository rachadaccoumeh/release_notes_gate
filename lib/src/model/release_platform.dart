import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// A platform a release note or a single change applies to.
enum ReleasePlatform {
  /// Android phones, tablets and TV.
  android,

  /// iPhone and iPad.
  ios,

  /// Flutter web.
  web,

  /// Windows desktop.
  windows,

  /// macOS desktop.
  macos,

  /// Linux desktop.
  linux;

  /// The platform the app runs on now, or null when it is not one of the
  /// six (for example Fuchsia).
  static ReleasePlatform? get current {
    if (kIsWeb) return ReleasePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ReleasePlatform.android,
      TargetPlatform.iOS => ReleasePlatform.ios,
      TargetPlatform.windows => ReleasePlatform.windows,
      TargetPlatform.macOS => ReleasePlatform.macos,
      TargetPlatform.linux => ReleasePlatform.linux,
      TargetPlatform.fuchsia => null,
    };
  }

  /// Parses a platform name as written in JSON, a changelog scope or a tag:
  /// `android`, `iOS`, `Web`, `Windows`, `macOS`, `osx`, `Linux`.
  static ReleasePlatform? tryParse(String? name) {
    if (name == null) return null;
    return switch (name.trim().toLowerCase()) {
      'android' => ReleasePlatform.android,
      'ios' || 'iphone' || 'ipad' => ReleasePlatform.ios,
      'web' || 'browser' => ReleasePlatform.web,
      'windows' || 'win' => ReleasePlatform.windows,
      'macos' || 'mac' || 'osx' => ReleasePlatform.macos,
      'linux' => ReleasePlatform.linux,
      _ => null,
    };
  }

  /// Parses a comma or slash separated list: `Android, iOS`. Returns null
  /// when no part is a platform.
  static Set<ReleasePlatform>? tryParseList(String? text) {
    if (text == null) return null;
    final platforms =
        text
            .split(RegExp(r'[,/&+]|\band\b'))
            .map(tryParse)
            .whereType<ReleasePlatform>()
            .toSet();
    return platforms.isEmpty ? null : platforms;
  }

  /// The display name: `Android`, `iOS`, `Web`, `Windows`, `macOS`, `Linux`.
  String get label => switch (this) {
    ReleasePlatform.android => 'Android',
    ReleasePlatform.ios => 'iOS',
    ReleasePlatform.web => 'Web',
    ReleasePlatform.windows => 'Windows',
    ReleasePlatform.macos => 'macOS',
    ReleasePlatform.linux => 'Linux',
  };
}
