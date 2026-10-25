import 'package:flutter/foundation.dart' show immutable;

import '../model/release_note.dart';
import '../model/release_version.dart';

/// Where the controller is in loading the notes.
enum ReleaseNotesStatus {
  /// Nothing loaded yet.
  idle,

  /// A fetch is running.
  loading,

  /// Notes are available, from the source or the cache.
  ready,

  /// The fetch failed and no cached notes could stand in.
  failed,
}

/// Why the notes are being shown.
enum ReleaseNotesReason {
  /// Not shown on their own.
  none,

  /// The app was updated since the user last saw the notes.
  newVersionInstalled,

  /// The source has a newer release than the installed one.
  updateAvailable,

  /// The app opened them.
  manual,
}

/// The outcome of a trigger check: whether to show the notes, and which.
@immutable
class ReleaseNotesDecision {
  /// Creates a decision.
  const ReleaseNotesDecision({
    required this.reason,
    required this.notes,
    this.from,
    this.to,
  });

  /// A decision not to show anything.
  const ReleaseNotesDecision.none()
    : reason = ReleaseNotesReason.none,
      notes = const [],
      from = null,
      to = null;

  /// Why the notes show.
  final ReleaseNotesReason reason;

  /// The notes to present, newest first: the releases between [from] and
  /// [to].
  final List<ReleaseNote> notes;

  /// The version the user comes from: the last seen version, or the
  /// installed one for an available update. Null when unknown.
  final ReleaseVersion? from;

  /// The version the notes lead to: the installed version, or the latest
  /// release for an available update.
  final ReleaseVersion? to;

  /// True when there is something to show.
  bool get shouldShow => reason != ReleaseNotesReason.none && notes.isNotEmpty;

  /// True when the decision is about an available update.
  bool get isUpdate => reason == ReleaseNotesReason.updateAvailable;

  @override
  String toString() =>
      'ReleaseNotesDecision(${reason.name}, ${notes.length} notes, $from -> $to)';
}

/// Everything the UI needs from a controller.
@immutable
class ReleaseNotesState {
  /// Creates a state.
  const ReleaseNotesState({
    this.status = ReleaseNotesStatus.idle,
    this.notes = const [],
    this.installedVersion,
    this.seenVersion,
    this.latest,
    this.fromCache = false,
    this.fetchedAt,
    this.error,
    this.decision = const ReleaseNotesDecision.none(),
  });

  /// Where loading stands.
  final ReleaseNotesStatus status;

  /// Every note known, newest first, after the pre-release filter and
  /// [ReleaseNotesConfig.maxNotes].
  final List<ReleaseNote> notes;

  /// The version of the running app, once read.
  final ReleaseVersion? installedVersion;

  /// The last version the user saw before this launch, or null.
  final ReleaseVersion? seenVersion;

  /// The newest release the source reported, when a remote check ran.
  final ReleaseNote? latest;

  /// True when [notes] came from the cache because the source failed.
  final bool fromCache;

  /// When [notes] were fetched, from the source or as recorded in the cache.
  final DateTime? fetchedAt;

  /// The error of the last failed fetch, or null.
  final Object? error;

  /// The result of the last trigger check.
  final ReleaseNotesDecision decision;

  /// True when the source has a release newer than the installed version.
  bool get updateAvailable {
    final installed = installedVersion;
    final newest = latest?.version;
    return installed != null && newest != null && newest > installed;
  }

  /// True while the first load runs and nothing is there to show yet.
  bool get isLoadingFirst =>
      status == ReleaseNotesStatus.loading && notes.isEmpty;

  /// Returns a copy with the given fields replaced.
  ReleaseNotesState copyWith({
    ReleaseNotesStatus? status,
    List<ReleaseNote>? notes,
    ReleaseVersion? installedVersion,
    ReleaseVersion? seenVersion,
    bool clearSeenVersion = false,
    ReleaseNote? latest,
    bool? fromCache,
    DateTime? fetchedAt,
    Object? error,
    bool clearError = false,
    ReleaseNotesDecision? decision,
  }) => ReleaseNotesState(
    status: status ?? this.status,
    notes: notes ?? this.notes,
    installedVersion: installedVersion ?? this.installedVersion,
    seenVersion: clearSeenVersion ? null : seenVersion ?? this.seenVersion,
    latest: latest ?? this.latest,
    fromCache: fromCache ?? this.fromCache,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    error: clearError ? null : error ?? this.error,
    decision: decision ?? this.decision,
  );
}
