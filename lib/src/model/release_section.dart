import 'package:flutter/foundation.dart' show immutable;

import 'localized_text.dart';
import 'release_item.dart';
import 'release_platform.dart';

/// The kind of changes a section holds. Drives the icon, the colour and the
/// heading of the section, and which sections are counted in summaries.
enum ReleaseSectionKind {
  /// New features. Changelog headings: `Features`, `New features`, `Added`,
  /// `New`.
  features,

  /// Bug fixes. Headings: `Bug fixes`, `Fixes`, `Fixed`.
  fixes,

  /// Improvements. Headings: `Improvements`, `Changed`, `Improved`,
  /// `Enhancements`.
  improvements,

  /// Performance. Headings: `Performance improvements`, `Performance`,
  /// `Optimizations`.
  performance,

  /// Anything else. The section keeps the heading it came with, for example
  /// `Notes`, `Security`, `Deprecated` or `Removed`.
  other;

  /// Maps a changelog heading to a kind. Decorations such as emoji are
  /// removed before matching. Unknown headings are [other].
  static ReleaseSectionKind fromTitle(String? title) {
    if (title == null) return ReleaseSectionKind.other;
    final key = title.replaceAll(_decoration, '').trim().toLowerCase();
    return switch (key) {
      'features' ||
      'new features' ||
      'feature' ||
      'new' ||
      'added' => ReleaseSectionKind.features,
      'bug fixes' ||
      'bugfixes' ||
      'fixes' ||
      'fixed' ||
      'bug fix' => ReleaseSectionKind.fixes,
      'improvements' ||
      'improvement' ||
      'improved' ||
      'changed' ||
      'changes' ||
      'enhancements' => ReleaseSectionKind.improvements,
      'performance improvements' ||
      'performance' ||
      'optimizations' ||
      'optimisations' ||
      'optimization' => ReleaseSectionKind.performance,
      _ => ReleaseSectionKind.other,
    };
  }

  /// Parses the kind as written in JSON (`features`, `fixes`, ...). Falls
  /// back to [fromTitle] so a heading works too, then to [other].
  static ReleaseSectionKind fromName(String? name) {
    if (name == null) return ReleaseSectionKind.other;
    final key = name.trim().toLowerCase();
    for (final kind in ReleaseSectionKind.values) {
      if (kind.name == key) return kind;
    }
    return fromTitle(name);
  }

  static final RegExp _decoration = RegExp(r'^[^\p{L}\p{N}]+', unicode: true);
}

/// The changes of one release under a single heading.
@immutable
class ReleaseSection {
  /// Creates a section.
  const ReleaseSection({required this.kind, required this.items, this.title});

  /// What the section holds.
  final ReleaseSectionKind kind;

  /// The heading as written in the source. The UI shows its own heading for
  /// the known kinds and this one for [ReleaseSectionKind.other].
  final LocalizedText? title;

  /// The changes and notes, in source order.
  final List<ReleaseItem> items;

  /// The changes, without the notes between them.
  Iterable<ReleaseItem> get changes => items.where((item) => item.isChange);

  /// Number of changes in the section, the notes left out.
  int get changeCount => items.where((item) => item.isChange).length;

  /// True when the section has no items at all.
  bool get isEmpty => items.isEmpty;

  /// Returns the section with only the items that apply to [platform], or
  /// null when nothing is left. A null [platform] returns this section.
  ReleaseSection? forPlatform(ReleasePlatform? platform) {
    if (platform == null) return this;
    final kept = items
        .where((item) => item.appliesTo(platform))
        .toList(growable: false);
    if (kept.isEmpty) return null;
    if (kept.length == items.length) return this;
    return ReleaseSection(kind: kind, title: title, items: kept);
  }

  /// Returns a copy with the given fields replaced.
  ReleaseSection copyWith({
    ReleaseSectionKind? kind,
    LocalizedText? title,
    List<ReleaseItem>? items,
  }) => ReleaseSection(
    kind: kind ?? this.kind,
    title: title ?? this.title,
    items: items ?? this.items,
  );

  @override
  bool operator ==(Object other) =>
      other is ReleaseSection &&
      other.kind == kind &&
      other.title == title &&
      other.items.length == items.length &&
      Iterable<int>.generate(
        items.length,
      ).every((i) => other.items[i] == items[i]);

  @override
  int get hashCode => Object.hash(kind, title, Object.hashAll(items));

  @override
  String toString() =>
      'ReleaseSection(${title ?? kind.name}, ${items.length} items)';
}
