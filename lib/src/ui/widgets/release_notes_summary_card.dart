import 'package:flutter/material.dart';

import '../../model/release_note.dart';
import '../../model/release_section.dart';
import '../../model/release_version.dart';
import '../theme/release_notes_theme.dart';
import 'version_badge.dart';

/// Head of an update: the step from one version to another, how many
/// releases lie between, and what they bring together as count pills.
///
/// Works alone. Pass the installed and the latest version for an update, or
/// the last seen and the installed version for "what's new".
class ReleaseNotesSummaryCard extends StatelessWidget {
  /// Creates a summary card over [notes], the releases between [from] and
  /// [to].
  const ReleaseNotesSummaryCard({
    super.key,
    required this.notes,
    this.from,
    this.to,
    this.title,
    this.animate = true,
  });

  /// The releases summed up.
  final List<ReleaseNote> notes;

  /// The version the user comes from, or null to show only [to].
  final ReleaseVersion? from;

  /// The version the notes lead to. Defaults to the newest note.
  final ReleaseVersion? to;

  /// Replaces the "N new releases" line.
  final String? title;

  /// Whether the pills pop in one after the other on first build.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final strings = ReleaseNotesTheme.stringsOf(context);
    final to = this.to ?? notes.newestFirst.firstOrNull?.version;
    final counts = notes.counts;
    final pills = <(ReleaseSectionKind, String)>[
      for (final entry in counts.entries)
        if (strings.countLabel(entry.key, entry.value) case final label?)
          (entry.key, label),
    ];

    return Material(
      color: theme.cardColor,
      elevation: theme.cardElevation,
      shape: theme.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(theme.summaryPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (from != null) ...[
                  Flexible(child: VersionBadge(text: from!.withPrefix)),
                  SizedBox(width: theme.spacing.md),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: theme.summaryArrowSize,
                    color: theme.secondaryTextColor,
                    textDirection: Directionality.of(context),
                  ),
                  SizedBox(width: theme.spacing.md),
                ],
                if (to != null)
                  Flexible(
                    child: VersionBadge(
                      text: to.withPrefix,
                      tone: theme.primary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: theme.spacing.lg),
            Text(
              title ?? strings.newReleases(notes.length),
              style: theme.summaryTitleStyle,
              textAlign: TextAlign.center,
            ),
            if (pills.isNotEmpty) ...[
              SizedBox(height: theme.spacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  for (var i = 0; i < pills.length; i++)
                    _PopIn(
                      delay:
                          animate
                              ? theme.staggerDelay * (i + 1)
                              : Duration.zero,
                      duration: animate ? theme.duration : Duration.zero,
                      child: CountPill(
                        text: pills[i].$2,
                        icon: theme.sectionStyle(pills[i].$1).icon,
                        tone: theme.sectionStyle(pills[i].$1).tone,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Scales and fades [child] in after [delay], once.
class _PopIn extends StatefulWidget {
  const _PopIn({
    required this.child,
    required this.delay,
    required this.duration,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context) ||
          widget.duration == Duration.zero) {
        _controller.value = 1;
        return;
      }
      Future<void>.delayed(widget.delay, () {
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
    opacity: _fade,
    child: ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(_scale),
      child: widget.child,
    ),
  );
}
