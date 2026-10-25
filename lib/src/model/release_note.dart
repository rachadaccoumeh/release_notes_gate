import 'package:flutter/foundation.dart' show immutable;

import 'localized_text.dart';
import 'release_platform.dart';
import 'release_section.dart';
import 'release_version.dart';

/// The notes of one release: its version, date and changes grouped by
/// section.
@immutable
class ReleaseNote {
  /// Creates a release note.
  const ReleaseNote({
    required this.version,
    required this.sections,
    this.date,
    this.title,
    this.url,
    this.downloadUrl,
    this.platforms,
  });

  /// The version the note describes.
  final ReleaseVersion version;

  /// When the version was released, or null when unknown.
  final DateTime? date;

  /// An optional headline for the release.
  final LocalizedText? title;

  /// The changes, grouped by section and ordered features first.
  final List<ReleaseSection> sections;

  /// The release page, for example on GitHub, or null.
  final Uri? url;

  /// A direct download link for the release, or null.
  final Uri? downloadUrl;

  /// The platforms the release exists for, or null for all.
  final Set<ReleasePlatform>? platforms;

  /// True for a pre-release such as `2.2.0-dev.4`.
  bool get isPrerelease => version.isPrerelease;

  /// Number of changes across all sections.
  int get changeCount =>
      sections.fold(0, (sum, section) => sum + section.changeCount);

  /// True when the release has at least one change or note.
  bool get hasContent => sections.any((section) => section.items.isNotEmpty);

  /// Number of changes of [kind].
  int countOf(ReleaseSectionKind kind) => sections
      .where((section) => section.kind == kind)
      .fold(0, (sum, section) => sum + section.changeCount);

  /// Number of changes per kind, kinds with zero left out, in enum order.
  Map<ReleaseSectionKind, int> get counts => {
    for (final kind in ReleaseSectionKind.values)
      if (countOf(kind) > 0) kind: countOf(kind),
  };

  /// True when the release applies to [platform]. A null [platform] or a
  /// null [platforms] set always applies.
  bool appliesTo(ReleasePlatform? platform) =>
      platform == null || platforms == null || platforms!.contains(platform);

  /// Returns the note with only the sections and items for [platform], or
  /// null when the release does not apply to it or nothing is left. A null
  /// [platform] returns this note.
  ReleaseNote? forPlatform(ReleasePlatform? platform) {
    if (platform == null) return this;
    if (!appliesTo(platform)) return null;
    final kept = sections
        .map((section) => section.forPlatform(platform))
        .whereType<ReleaseSection>()
        .toList(growable: false);
    if (kept.isEmpty && sections.isNotEmpty) return null;
    if (kept.length == sections.length &&
        Iterable<int>.generate(
          kept.length,
        ).every((i) => identical(kept[i], sections[i]))) {
      return this;
    }
    return copyWith(sections: kept);
  }

  /// Returns a copy with the given fields replaced.
  ReleaseNote copyWith({
    ReleaseVersion? version,
    DateTime? date,
    LocalizedText? title,
    List<ReleaseSection>? sections,
    Uri? url,
    Uri? downloadUrl,
    Set<ReleasePlatform>? platforms,
  }) => ReleaseNote(
    version: version ?? this.version,
    date: date ?? this.date,
    title: title ?? this.title,
    sections: sections ?? this.sections,
    url: url ?? this.url,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    platforms: platforms ?? this.platforms,
  );

  @override
  bool operator ==(Object other) =>
      other is ReleaseNote &&
      other.version == version &&
      other.date == date &&
      other.title == title &&
      other.url == url &&
      other.downloadUrl == downloadUrl &&
      other.sections.length == sections.length &&
      Iterable<int>.generate(
        sections.length,
      ).every((i) => other.sections[i] == sections[i]);

  @override
  int get hashCode => Object.hash(
    version,
    date,
    title,
    url,
    downloadUrl,
    Object.hashAll(sections),
  );

  @override
  String toString() =>
      'ReleaseNote(${version.withPrefix}, $changeCount changes)';
}

/// Queries over a list of release notes.
extension ReleaseNoteListX on List<ReleaseNote> {
  /// The notes sorted newest first.
  List<ReleaseNote> get newestFirst {
    final sorted = List<ReleaseNote>.of(this);
    sorted.sort((a, b) => b.version.compareTo(a.version));
    return sorted;
  }

  /// The note for exactly [version], or null.
  ReleaseNote? find(ReleaseVersion? version) {
    if (version == null) return null;
    for (final note in this) {
      if (note.version == version) return note;
    }
    return null;
  }

  /// Notes strictly newer than [version], newest first. A null [version]
  /// returns all notes.
  List<ReleaseNote> newerThan(ReleaseVersion? version) {
    if (version == null) return newestFirst;
    return newestFirst
        .where((note) => note.version > version)
        .toList(growable: false);
  }

  /// Notes newer than [from] and up to and including [to], newest first.
  /// A null [from] starts at the oldest note; a null [to] ends at the newest.
  List<ReleaseNote> between(ReleaseVersion? from, ReleaseVersion? to) =>
      newestFirst
          .where(
            (note) =>
                (from == null || note.version > from) &&
                (to == null || note.version <= to),
          )
          .toList(growable: false);

  /// Notes without a pre-release version.
  List<ReleaseNote> get stableOnly =>
      where((note) => !note.isPrerelease).toList(growable: false);

  /// Number of changes of [kind] across all notes.
  int countOf(ReleaseSectionKind kind) =>
      fold(0, (sum, note) => sum + note.countOf(kind));

  /// Number of changes per kind across all notes, zeros left out.
  Map<ReleaseSectionKind, int> get counts => {
    for (final kind in ReleaseSectionKind.values)
      if (countOf(kind) > 0) kind: countOf(kind),
  };

  /// Each note narrowed to [platform]; notes with nothing left are dropped.
  List<ReleaseNote> forPlatform(ReleasePlatform? platform) => map(
    (note) => note.forPlatform(platform),
  ).whereType<ReleaseNote>().toList(growable: false);
}
