import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';

/// The head of the sheet or dialog: an icon, a title and a line under it.
class ReleaseNotesHeader extends StatelessWidget {
  /// Creates a header.
  const ReleaseNotesHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  /// The title: "What's new", "An update is available" or "Changelog".
  final String title;

  /// The line under the title, for example the app name and version.
  final String? subtitle;

  /// A widget drawn at the header icon size, normally the app icon. Null
  /// draws a default badge icon.
  final Widget? icon;

  /// Widgets after the title, for example a close button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
        child: Row(
          children: [
            SizedBox(
              width: theme.headerIconSize,
              height: theme.headerIconSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(theme.headerIconRadius),
                child:
                    icon ??
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.headerIconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.new_releases_rounded,
                        color: theme.primary.accent,
                        size: 26,
                      ),
                    ),
              ),
            ),
            SizedBox(width: theme.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.headerTitleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.headerSubtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: theme.spacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
