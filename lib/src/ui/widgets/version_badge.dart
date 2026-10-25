import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';

/// A small filled marker: a version, a count, or a word such as "Latest".
///
/// Sized to its content, with a colour that animates when the tone
/// changes. Use it anywhere you need a compact label in the notes' style.
class VersionBadge extends StatelessWidget {
  /// Creates a badge.
  const VersionBadge({
    super.key,
    required this.text,
    this.tone,
    this.icon,
    this.onTap,
    this.semanticsLabel,
  });

  /// The label.
  final String text;

  /// The colour role. Defaults to the theme's neutral tone.
  final ReleaseNotesTone? tone;

  /// An optional icon before the label.
  final IconData? icon;

  /// Makes the badge act as a button.
  final VoidCallback? onTap;

  /// Label for screen readers, when [text] alone is not enough.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final tone = this.tone ?? theme.neutral;
    final shape = const StadiumBorder();

    Widget badge = AnimatedContainer(
      duration: context.motion(theme.duration),
      curve: theme.curve,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      decoration: ShapeDecoration(color: tone.container, shape: shape),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone.content),
            SizedBox(width: theme.spacing.xs),
          ],
          AnimatedDefaultTextStyle(
            duration: context.motion(theme.duration),
            style: theme.badgeStyle.copyWith(color: tone.content),
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: badge),
      );
    }

    return Semantics(
      label: semanticsLabel ?? text,
      button: onTap != null,
      excludeSemantics: true,
      child: badge,
    );
  }
}

/// A larger pill with an icon, as in the update summary: "8 features".
class CountPill extends StatelessWidget {
  /// Creates a pill.
  const CountPill({
    super.key,
    required this.text,
    required this.icon,
    required this.tone,
  });

  /// The label.
  final String text;

  /// The icon before the label.
  final IconData icon;

  /// The colour role.
  final ReleaseNotesTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.lg,
          vertical: theme.spacing.sm,
        ),
        decoration: ShapeDecoration(
          color: tone.container,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tone.content),
            SizedBox(width: theme.spacing.sm),
            Flexible(
              child: Text(
                text,
                style: theme.pillStyle.copyWith(color: tone.content),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
