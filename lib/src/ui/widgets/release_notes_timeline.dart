import 'package:flutter/material.dart';

import '../../model/release_note.dart';
import '../../model/release_version.dart';
import '../theme/release_notes_theme.dart';
import 'formatted_text.dart';
import 'release_card.dart';
import 'timeline_rail.dart';

/// Builds one release on the timeline.
typedef ReleaseCardBuilder =
    Widget Function(
      BuildContext context,
      ReleaseNote note,
      ReleaseBadge? badge, {
      required bool isFirst,
      required bool isLast,
      required bool initiallyExpanded,
    });

/// The releases, newest first, on a rail with a node per release.
///
/// Not scrollable itself: place it in a `ListView` or a
/// `SingleChildScrollView`. Works alone with any list of notes.
class ReleaseNotesTimeline extends StatelessWidget {
  /// Creates a timeline over [notes].
  ///
  /// [installedVersion] gets the Installed badge. [latestVersion] gets the
  /// Latest badge; it defaults to the newest note. Releases in
  /// [expandedNotes] start open; by default every note in [highlighted]
  /// does, or the newest one when [highlighted] is empty.
  const ReleaseNotesTimeline({
    super.key,
    required this.notes,
    this.installedVersion,
    this.latestVersion,
    this.highlighted = const [],
    this.expandedNotes,
    this.locale,
    this.onLinkTap,
    this.onReleaseToggled,
    this.showPlatforms = false,
    this.animateEntrance = true,
    this.releaseBuilder,
    this.sectionBuilder,
  });

  /// The releases, in any order; shown newest first.
  final List<ReleaseNote> notes;

  /// The version the app runs.
  final ReleaseVersion? installedVersion;

  /// The newest release. Defaults to the first note.
  final ReleaseVersion? latestVersion;

  /// The releases the user has not seen: they start expanded.
  final List<ReleaseNote> highlighted;

  /// Which releases start expanded. Overrides [highlighted].
  final Set<ReleaseVersion>? expandedNotes;

  /// Locale for translated texts.
  final Locale? locale;

  /// Called on a link tap inside a change.
  final LinkTapCallback? onLinkTap;

  /// Called when the user opens or closes a release.
  final void Function(ReleaseNote note, {required bool expanded})?
  onReleaseToggled;

  /// Whether platform-specific changes show their platforms.
  final bool showPlatforms;

  /// Whether releases slide in one after the other on first build.
  final bool animateEntrance;

  /// Replaces each release card.
  final ReleaseCardBuilder? releaseBuilder;

  /// Replaces the section cards inside the default release card.
  final ReleaseSectionBuilder? sectionBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final sorted = notes.newestFirst;
    if (sorted.isEmpty) return const SizedBox.shrink();
    final latest = latestVersion ?? sorted.first.version;
    final expanded =
        expandedNotes ??
        (highlighted.isEmpty
            ? {sorted.first.version}
            : highlighted.map((n) => n.version).toSet());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sorted.length; i++)
          _Entrance(
            index: i,
            enabled: animateEntrance,
            delay: theme.staggerDelay,
            duration: theme.duration,
            curve: theme.curve,
            child: _build(
              context,
              sorted[i],
              badgeFor(sorted[i], installedVersion, latest),
              i == 0,
              i == sorted.length - 1,
              expanded.contains(sorted[i].version),
            ),
          ),
      ],
    );
  }

  Widget _build(
    BuildContext context,
    ReleaseNote note,
    ReleaseBadge? badge,
    bool isFirst,
    bool isLast,
    bool initiallyExpanded,
  ) {
    final builder = releaseBuilder;
    if (builder != null) {
      return builder(
        context,
        note,
        badge,
        isFirst: isFirst,
        isLast: isLast,
        initiallyExpanded: initiallyExpanded,
      );
    }
    return ReleaseCard(
      key: ValueKey(note.version.normalized),
      note: note,
      badge: badge,
      isFirst: isFirst,
      isLast: isLast,
      initiallyExpanded: initiallyExpanded,
      onToggle:
          onReleaseToggled == null
              ? null
              : (expanded) => onReleaseToggled!(note, expanded: expanded),
      locale: locale,
      onLinkTap: onLinkTap,
      showPlatforms: showPlatforms,
      sectionBuilder: sectionBuilder,
    );
  }

  /// The badge of [note]: Installed beats Latest beats Pre-release.
  static ReleaseBadge? badgeFor(
    ReleaseNote note,
    ReleaseVersion? installed,
    ReleaseVersion? latest,
  ) {
    if (installed != null && note.version == installed) {
      return ReleaseBadge.installed;
    }
    if (latest != null && note.version == latest) return ReleaseBadge.latest;
    if (note.isPrerelease) return ReleaseBadge.prerelease;
    return null;
  }
}

/// Fades and slides [child] up into place after a delay that grows with
/// [index]. Only the first few rows wait, so a long list does not trickle in.
class _Entrance extends StatefulWidget {
  const _Entrance({
    required this.index,
    required this.enabled,
    required this.delay,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final int index;
  final bool enabled;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget child;

  static const int staggeredRows = 6;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
        return;
      }
      final steps = widget.index.clamp(0, _Entrance.staggeredRows);
      Future<void>.delayed(widget.delay * steps, () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(_curve),
      child: widget.child,
    ),
  );
}
