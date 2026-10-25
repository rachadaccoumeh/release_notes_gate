import 'package:flutter/material.dart';

import '../../model/release_item.dart';
import '../theme/release_notes_theme.dart';
import 'formatted_text.dart';

/// One change: a coloured dot, an optional scope label and the text. A
/// note between the changes has no dot and reads in the secondary colour.
class ReleaseItemRow extends StatelessWidget {
  /// Creates a row.
  const ReleaseItemRow({
    super.key,
    required this.item,
    required this.dotColor,
    this.locale,
    this.onLinkTap,
    this.showPlatforms = false,
  });

  /// The change.
  final ReleaseItem item;

  /// Colour of the dot, normally the section's accent.
  final Color dotColor;

  /// Locale for the translated text. Null uses the ambient locale.
  final Locale? locale;

  /// Called on a link tap inside the text.
  final LinkTapCallback? onLinkTap;

  /// Whether to show the platforms of a platform-specific change as a
  /// small label, useful when the filter is lifted.
  final bool showPlatforms;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final locale = this.locale ?? Localizations.maybeLocaleOf(context);
    final text = item.text.resolve(locale);
    final scope = item.scope;
    final platforms = item.platforms;
    final showScope = scope != null;
    final showPlatformLabel =
        showPlatforms &&
        platforms != null &&
        platforms.isNotEmpty &&
        !_scopeNamesPlatforms(scope, platforms);

    return Padding(
      padding: theme.itemPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: theme.itemDotSize,
            child:
                item.isNote
                    ? null
                    : Padding(
                      // Level with the middle of the first line: the scope's
                      // when there is one, else the text's.
                      padding: EdgeInsets.only(top: showScope ? 5 : 7),
                      child: Container(
                        width: theme.itemDotSize,
                        height: theme.itemDotSize,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showScope || showPlatformLabel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      [
                        if (showScope) scope,
                        if (showPlatformLabel)
                          platforms.map((p) => p.label).join(', '),
                      ].join(' · '),
                      style: theme.scopeStyle,
                    ),
                  ),
                FormattedText(
                  text,
                  style: item.isNote ? theme.noteStyle : theme.itemStyle,
                  onLinkTap: onLinkTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _scopeNamesPlatforms(String? scope, Set<Object> platforms) {
    if (scope == null) return false;
    final lower = scope.toLowerCase();
    return platforms.every(
      (platform) => lower.contains(platform.toString().split('.').last),
    );
  }
}
