import 'package:flutter/foundation.dart' show immutable;

import 'localized_text.dart';
import 'release_platform.dart';

/// One change in a release, or a line of prose between the changes.
@immutable
class ReleaseItem {
  /// Creates a change.
  const ReleaseItem({
    required this.text,
    this.scope,
    this.isNote = false,
    this.platforms,
  });

  /// Creates a change from plain text.
  ReleaseItem.plain(
    String text, {
    this.scope,
    this.isNote = false,
    this.platforms,
  }) : text = LocalizedText(text);

  /// What changed. Inline Markdown is allowed: `` `code` ``, `**bold**` and
  /// `[label](url)`.
  final LocalizedText text;

  /// The part of the app the change belongs to, written as `**Scope:**` in a
  /// changelog bullet. Null for an unscoped change.
  final String? scope;

  /// True for a line of prose between the bullets, which reads as a note on
  /// the release rather than as a change of its own. Notes are not counted.
  final bool isNote;

  /// The platforms this change applies to, or null for all.
  final Set<ReleasePlatform>? platforms;

  /// True when the change counts: a bullet, not a note.
  bool get isChange => !isNote;

  /// True when this change applies to [platform]. A null [platform] or a
  /// null [platforms] set always applies.
  bool appliesTo(ReleasePlatform? platform) =>
      platform == null || platforms == null || platforms!.contains(platform);

  /// Returns a copy with the given fields replaced.
  ReleaseItem copyWith({
    LocalizedText? text,
    String? scope,
    bool? isNote,
    Set<ReleasePlatform>? platforms,
    bool clearScope = false,
    bool clearPlatforms = false,
  }) => ReleaseItem(
    text: text ?? this.text,
    scope: clearScope ? null : scope ?? this.scope,
    isNote: isNote ?? this.isNote,
    platforms: clearPlatforms ? null : platforms ?? this.platforms,
  );

  @override
  bool operator ==(Object other) =>
      other is ReleaseItem &&
      other.text == text &&
      other.scope == scope &&
      other.isNote == isNote &&
      _sameSet(other.platforms, platforms);

  static bool _sameSet(Set<ReleasePlatform>? a, Set<ReleasePlatform>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }

  @override
  int get hashCode => Object.hash(
    text,
    scope,
    isNote,
    platforms == null ? null : Object.hashAllUnordered(platforms!),
  );

  @override
  String toString() => 'ReleaseItem(${scope == null ? '' : '$scope: '}$text)';
}
