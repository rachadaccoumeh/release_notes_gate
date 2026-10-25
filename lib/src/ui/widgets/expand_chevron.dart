import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';

/// A chevron that turns upside down when [expanded].
class ExpandChevron extends StatelessWidget {
  /// Creates a chevron.
  const ExpandChevron({
    super.key,
    required this.expanded,
    this.size = 24,
    this.color,
  });

  /// Whether the chevron points up.
  final bool expanded;

  /// Icon size.
  final double size;

  /// Icon colour. Defaults to the theme's secondary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: context.motion(theme.shortDuration),
      curve: theme.curve,
      child: Icon(
        Icons.expand_more_rounded,
        size: size,
        color: color ?? theme.secondaryTextColor,
      ),
    );
  }
}
