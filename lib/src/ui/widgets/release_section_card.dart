import 'package:flutter/material.dart';

import '../../model/release_section.dart';
import '../theme/release_notes_theme.dart';
import 'expand_chevron.dart';
import 'formatted_text.dart';
import 'release_item_row.dart';
import 'version_badge.dart';

/// A card of changes headed by the section's icon, title and count.
///
/// Long sections show a preview and a "Show all" row until opened. Manage
/// [expanded] yourself, or leave [onToggle] null to let the card keep its
/// own state.
class ReleaseSectionCard extends StatefulWidget {
  /// Creates a section card.
  const ReleaseSectionCard({
    super.key,
    required this.section,
    this.expanded,
    this.onToggle,
    this.locale,
    this.onLinkTap,
    this.showPlatforms = false,
    this.headerBuilder,
    this.itemBuilder,
  });

  /// The section.
  final ReleaseSection section;

  /// Whether a long section is fully open. Null lets the card keep its own
  /// state, starting folded.
  final bool? expanded;

  /// Called when the user taps "Show all" or "Show less".
  final ValueChanged<bool>? onToggle;

  /// Locale for translated texts.
  final Locale? locale;

  /// Called on a link tap inside a change.
  final LinkTapCallback? onLinkTap;

  /// Whether platform-specific changes show their platforms.
  final bool showPlatforms;

  /// Replaces the header row. Receives the resolved title and the count.
  final Widget Function(
    BuildContext context,
    ReleaseSection section,
    String title,
    int count,
  )?
  headerBuilder;

  /// Replaces one change row.
  final Widget Function(
    BuildContext context,
    ReleaseSection section,
    int index,
  )?
  itemBuilder;

  @override
  State<ReleaseSectionCard> createState() => _ReleaseSectionCardState();
}

class _ReleaseSectionCardState extends State<ReleaseSectionCard> {
  bool _expanded = false;

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onToggle?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final strings = ReleaseNotesTheme.stringsOf(context);
    final locale = widget.locale ?? Localizations.maybeLocaleOf(context);
    final section = widget.section;
    final style = theme.sectionStyle(section.kind);
    final title =
        section.kind == ReleaseSectionKind.other && section.title != null
            ? section.title!.resolve(locale)
            : strings.sectionTitle(section.kind);
    final count = section.changeCount;
    final collapsible = section.items.length > theme.sectionPreviewLimit;
    final shown =
        collapsible && !_isExpanded
            ? section.items.take(theme.sectionPreviewSize).toList()
            : section.items;

    return Material(
      color: theme.cardColor,
      elevation: theme.cardElevation,
      shape: theme.cardShape,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: context.motion(theme.duration),
        curve: theme.curve,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.headerBuilder?.call(context, section, title, count) ??
                _Header(title: title, count: count, style: style),
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: theme.dividerColor),
              widget.itemBuilder?.call(context, section, i) ??
                  ReleaseItemRow(
                    item: shown[i],
                    dotColor: style.tone.accent,
                    locale: locale,
                    onLinkTap: widget.onLinkTap,
                    showPlatforms: widget.showPlatforms,
                  ),
            ],
            if (collapsible) ...[
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              _Expander(expanded: _isExpanded, total: count, onToggle: _toggle),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.count,
    required this.style,
  });

  final String title;
  final int count;
  final ReleaseNotesSectionStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Semantics(
      header: true,
      child: Container(
        color: theme.cardHeaderColor,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.lg,
          vertical: theme.spacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: theme.sectionIconSize,
              height: theme.sectionIconSize,
              decoration: BoxDecoration(
                color: style.tone.container,
                borderRadius: BorderRadius.circular(theme.sectionIconRadius),
              ),
              child: Icon(style.icon, size: 16, color: style.tone.content),
            ),
            SizedBox(width: theme.spacing.sm),
            Expanded(child: Text(title, style: theme.sectionTitleStyle)),
            if (count > 0) VersionBadge(text: '$count'),
          ],
        ),
      ),
    );
  }
}

class _Expander extends StatelessWidget {
  const _Expander({
    required this.expanded,
    required this.total,
    required this.onToggle,
  });

  final bool expanded;
  final int total;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final strings = ReleaseNotesTheme.stringsOf(context);
    final label = expanded ? strings.showLess : strings.showAll(total);
    return InkWell(
      onTap: onToggle,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.lg,
              vertical: theme.spacing.md,
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: theme.pillStyle.copyWith(color: theme.primary.accent),
                ),
                SizedBox(width: theme.spacing.sm),
                ExpandChevron(
                  expanded: expanded,
                  size: 18,
                  color: theme.primary.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
