import 'package:flutter/foundation.dart' show immutable;

import '../../model/release_platform.dart';
import '../../model/release_section.dart';

/// Every text the release notes widgets show. English by default; pass
/// your own instance through [ReleaseNotesTheme] to localise.
///
/// Counts are functions so languages with more than one plural form can
/// handle them.
@immutable
class ReleaseNotesStrings {
  /// Creates the strings. Every argument has an English default.
  const ReleaseNotesStrings({
    this.whatsNewTitle = "What's new",
    this.updateAvailableTitle = 'An update is available',
    this.changelogTitle = 'Changelog',
    this.sectionNew = 'New',
    this.sectionFixes = 'Fixes',
    this.sectionImprovements = 'Improvements',
    this.sectionPerformance = 'Performance',
    this.sectionOther = 'Changes',
    this.badgeLatest = 'Latest',
    this.badgeInstalled = 'Installed',
    this.badgePrerelease = 'Pre-release',
    this.today = 'Today',
    this.yesterday = 'Yesterday',
    this.showLess = 'Show less',
    this.close = 'Close',
    this.update = 'Update',
    this.download = 'Download',
    this.releasePage = 'Release page',
    this.retry = 'Retry',
    this.loadFailed = 'The release notes could not be loaded.',
    this.offlineNotice =
        'Showing saved notes. Pull to refresh when you are back online.',
    this.noNotes = 'No release notes yet.',
    this.allPlatforms = 'All platforms',
    this.collapse = 'Collapse',
    this.expand = 'Expand',
    this.newReleases = _newReleases,
    this.featureCount = _featureCount,
    this.fixCount = _fixCount,
    this.performanceCount = _performanceCount,
    this.improvementCount = _improvementCount,
    this.changeCount = _changeCount,
    this.daysAgo = _daysAgo,
    this.showAll = _showAll,
    this.platformOnly = _platformOnly,
  });

  /// Title when the notes show after an update.
  final String whatsNewTitle;

  /// Title when a newer release is available.
  final String updateAvailableTitle;

  /// Title when the notes are opened from a menu.
  final String changelogTitle;

  /// Heading of [ReleaseSectionKind.features].
  final String sectionNew;

  /// Heading of [ReleaseSectionKind.fixes].
  final String sectionFixes;

  /// Heading of [ReleaseSectionKind.improvements].
  final String sectionImprovements;

  /// Heading of [ReleaseSectionKind.performance].
  final String sectionPerformance;

  /// Heading of an untitled [ReleaseSectionKind.other] section.
  final String sectionOther;

  /// Badge on the newest release.
  final String badgeLatest;

  /// Badge on the installed release.
  final String badgeInstalled;

  /// Badge on a pre-release.
  final String badgePrerelease;

  /// A release from today.
  final String today;

  /// A release from yesterday.
  final String yesterday;

  /// Folds a long section back.
  final String showLess;

  /// Closes the notes.
  final String close;

  /// Starts an update, when no download link is known.
  final String update;

  /// Downloads a release asset.
  final String download;

  /// Opens the release page.
  final String releasePage;

  /// Tries a failed load again.
  final String retry;

  /// Shown when loading failed and there is no cache.
  final String loadFailed;

  /// Shown above cached notes.
  final String offlineNotice;

  /// Shown when the source returned nothing.
  final String noNotes;

  /// Platform filter option that shows everything.
  final String allPlatforms;

  /// Semantics hint on an expanded release.
  final String collapse;

  /// Semantics hint on a folded release.
  final String expand;

  /// "2 new releases".
  final String Function(int count) newReleases;

  /// "8 features".
  final String Function(int count) featureCount;

  /// "12 fixes".
  final String Function(int count) fixCount;

  /// "1 optimization".
  final String Function(int count) performanceCount;

  /// "3 improvements".
  final String Function(int count) improvementCount;

  /// "5 changes".
  final String Function(int count) changeCount;

  /// "3 days ago".
  final String Function(int days) daysAgo;

  /// "Show all 9".
  final String Function(int total) showAll;

  /// "iOS only".
  final String Function(ReleasePlatform platform) platformOnly;

  /// The heading of a section kind.
  String sectionTitle(ReleaseSectionKind kind) => switch (kind) {
    ReleaseSectionKind.features => sectionNew,
    ReleaseSectionKind.fixes => sectionFixes,
    ReleaseSectionKind.improvements => sectionImprovements,
    ReleaseSectionKind.performance => sectionPerformance,
    ReleaseSectionKind.other => sectionOther,
  };

  /// The count label of a section kind, or null for kinds that are not
  /// counted in summaries.
  String? countLabel(ReleaseSectionKind kind, int count) => switch (kind) {
    ReleaseSectionKind.features => featureCount(count),
    ReleaseSectionKind.fixes => fixCount(count),
    ReleaseSectionKind.improvements => improvementCount(count),
    ReleaseSectionKind.performance => performanceCount(count),
    ReleaseSectionKind.other => null,
  };

  static String _newReleases(int n) =>
      n == 1 ? '1 new release' : '$n new releases';
  static String _featureCount(int n) => n == 1 ? '1 feature' : '$n features';
  static String _fixCount(int n) => n == 1 ? '1 fix' : '$n fixes';
  static String _performanceCount(int n) =>
      n == 1 ? '1 optimization' : '$n optimizations';
  static String _improvementCount(int n) =>
      n == 1 ? '1 improvement' : '$n improvements';
  static String _changeCount(int n) => n == 1 ? '1 change' : '$n changes';
  static String _daysAgo(int n) => '$n days ago';
  static String _showAll(int n) => 'Show all $n';
  static String _platformOnly(ReleasePlatform p) => '${p.label} only';
}
