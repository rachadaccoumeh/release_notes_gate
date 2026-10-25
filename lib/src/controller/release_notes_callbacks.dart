import 'package:flutter/foundation.dart' show immutable;

import '../model/release_note.dart';
import 'release_notes_state.dart';

/// Hooks for analytics and logging. Every callback is optional.
@immutable
class ReleaseNotesCallbacks {
  /// Creates callbacks.
  const ReleaseNotesCallbacks({
    this.onLoaded,
    this.onError,
    this.onDecision,
    this.onShown,
    this.onDismissed,
    this.onActionTap,
    this.onReleaseToggled,
    this.onLinkTap,
  });

  /// Notes were loaded, from the source or, with [fromCache], the cache.
  final void Function(List<ReleaseNote> notes, {required bool fromCache})?
  onLoaded;

  /// A fetch failed. Called before any cache fallback.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// A trigger check finished.
  final void Function(ReleaseNotesDecision decision)? onDecision;

  /// The notes were presented to the user.
  final void Function(ReleaseNotesDecision decision)? onShown;

  /// The user closed the notes.
  final void Function(ReleaseNotesDecision decision)? onDismissed;

  /// The user tapped a footer action, identified by its [id].
  final void Function(String id)? onActionTap;

  /// The user opened or closed a release on the timeline.
  final void Function(ReleaseNote note, {required bool expanded})?
  onReleaseToggled;

  /// The user tapped a link inside a change.
  final void Function(Uri url)? onLinkTap;
}
