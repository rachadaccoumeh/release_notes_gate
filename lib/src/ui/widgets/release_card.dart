import 'package:flutter/material.dart';

import '../../model/release_note.dart';
import '../../model/release_section.dart';
import '../theme/release_notes_theme.dart';
import 'expand_chevron.dart';
import 'formatted_text.dart';
import 'release_date.dart';
import 'release_section_card.dart';
import 'timeline_rail.dart';
import 'version_badge.dart';

/// Builds a section card inside a release.
typedef ReleaseSectionBuilder =
    Widget Function(
      BuildContext context,
      ReleaseNote note,
      ReleaseSection section,
    );

/// One release on the timeline: its node on the rail, a header that folds
/// the release open and shut, and its changes grouped by section.
///
/// Manage [expanded] yourself or leave [onToggle] null to let the card keep
/// its own state, starting from [initiallyExpanded].
class ReleaseCard extends StatefulWidget {
  /// Creates a release card.
  const ReleaseCard({
    super.key,
    required this.note,
    this.badge,
    this.isFirst = false,
    this.isLast = false,
    this.expanded,
    this.initiallyExpanded = true,
    this.onToggle,
    this.locale,
    this.onLinkTap,
    this.showPlatforms = false,
    this.showRail = true,
    this.sectionBuilder,
    this.headerBuilder,
  });

  /// The release.
  final ReleaseNote note;

  /// The badge beside the version, which also colours the node.
  final ReleaseBadge? badge;

  /// Whether the rail starts here.
  final bool isFirst;

  /// Whether the rail ends here.
  final bool isLast;

  /// Whether the body shows. Null lets the card keep its own state.
  final bool? expanded;

  /// The starting state when the card keeps its own.
  final bool initiallyExpanded;

  /// Called when the header is tapped.
  final ValueChanged<bool>? onToggle;

  /// Locale for translated texts.
  final Locale? locale;

  /// Called on a link tap inside a change.
  final LinkTapCallback? onLinkTap;

  /// Whether platform-specific changes show their platforms.
  final bool showPlatforms;

  /// Whether the rail and node are drawn. Turn off to place the card in a
  /// plain list.
  final bool showRail;

  /// Replaces the section cards.
  final ReleaseSectionBuilder? sectionBuilder;

  /// Replaces the header row. Receives the date-and-counts line.
  final Widget Function(
    BuildContext context,
    ReleaseNote note,
    String? summary,
    bool expanded,
  )?
  headerBuilder;

  @override
  State<ReleaseCard> createState() => _ReleaseCardState();
}

class _ReleaseCardState extends State<ReleaseCard> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onToggle?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final locale = widget.locale ?? Localizations.maybeLocaleOf(context);
    final note = widget.note;
    final hasBody = note.hasContent;
    final expanded = _isExpanded && hasBody;
    final summary = _summary(context, note, locale);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.headerBuilder?.call(context, note, summary, expanded) ??
            _Header(
              note: note,
              badge: widget.badge,
              summary: summary,
              expanded: expanded,
              onToggle: hasBody ? _toggle : null,
            ),
        ClipRect(
          child: AnimatedSize(
            duration: context.motion(theme.duration),
            curve: theme.curve,
            alignment: Alignment.topCenter,
            child:
                expanded
                    ? AnimatedOpacity(
                      opacity: 1,
                      duration: context.motion(theme.duration),
                      child: Padding(
                        padding: EdgeInsets.only(top: theme.spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < note.sections.length; i++) ...[
                              if (i > 0) SizedBox(height: theme.spacing.lg),
                              widget.sectionBuilder?.call(
                                    context,
                                    note,
                                    note.sections[i],
                                  ) ??
                                  ReleaseSectionCard(
                                    section: note.sections[i],
                                    locale: locale,
                                    onLinkTap: widget.onLinkTap,
                                    showPlatforms: widget.showPlatforms,
                                  ),
                            ],
                          ],
                        ),
                      ),
                    )
                    : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );

    if (!widget.showRail) return content;
    return TimelineRow(
      badge: widget.badge,
      isFirst: widget.isFirst,
      isLast: widget.isLast,
      child: content,
    );
  }

  String? _summary(BuildContext context, ReleaseNote note, Locale? locale) {
    final strings = ReleaseNotesTheme.stringsOf(context);
    final parts = <String>[
      if (note.title != null && note.title!.isNotEmpty)
        note.title!.resolve(locale),
      if (note.date != null) formatReleaseDate(context, note.date!),
    ];
    final counts = note.counts;
    var counted = false;
    for (final entry in counts.entries) {
      final label = strings.countLabel(entry.key, entry.value);
      if (label != null) {
        parts.add(label);
        counted = true;
      }
    }
    if (!counted && note.changeCount > 0) {
      parts.add(strings.changeCount(note.changeCount));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.note,
    required this.badge,
    required this.summary,
    required this.expanded,
    required this.onToggle,
  });

  final ReleaseNote note;
  final ReleaseBadge? badge;
  final String? summary;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final strings = ReleaseNotesTheme.stringsOf(context);
    final badgeText = switch (badge) {
      ReleaseBadge.installed => strings.badgeInstalled,
      ReleaseBadge.prerelease => strings.badgePrerelease,
      ReleaseBadge.latest => strings.badgeLatest,
      null => null,
    };
    final badgeTone = switch (badge) {
      ReleaseBadge.installed => theme.success,
      ReleaseBadge.prerelease => theme.warning,
      ReleaseBadge.latest => theme.primary,
      null => theme.neutral,
    };

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        note.version.withPrefix,
                        style: theme.versionStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeText != null) ...[
                      SizedBox(width: theme.spacing.sm),
                      VersionBadge(text: badgeText, tone: badgeTone),
                    ],
                  ],
                ),
                if (summary != null) ...[
                  const SizedBox(height: 2),
                  Text(summary!, style: theme.releaseSummaryStyle),
                ],
              ],
            ),
          ),
          if (onToggle != null) ...[
            SizedBox(width: theme.spacing.md),
            ExpandChevron(expanded: expanded),
          ],
        ],
      ),
    );

    if (onToggle == null) return Semantics(header: true, child: row);
    return Semantics(
      button: true,
      header: true,
      expanded: expanded,
      label: [
        note.version.withPrefix,
        if (badgeText != null) badgeText,
        if (summary != null) summary,
      ].join(', '),
      hint: expanded ? strings.collapse : strings.expand,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: row,
          ),
        ),
      ),
    );
  }
}
