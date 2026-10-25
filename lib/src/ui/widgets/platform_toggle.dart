import 'package:flutter/material.dart';

import '../../model/release_platform.dart';
import '../theme/release_notes_theme.dart';

/// Two chips that switch between the changes of one platform and all of
/// them.
class PlatformToggle extends StatelessWidget {
  /// Creates the toggle.
  const PlatformToggle({
    super.key,
    required this.platform,
    required this.showAll,
    required this.onChanged,
  });

  /// The platform the filter narrows to.
  final ReleasePlatform platform;

  /// Whether every platform's changes show.
  final bool showAll;

  /// Called with the new value of [showAll].
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final strings = ReleaseNotesTheme.stringsOf(context);
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          label: Text(strings.platformOnly(platform)),
        ),
        ButtonSegment(value: true, label: Text(strings.allPlatforms)),
      ],
      selected: {showAll},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.badgeStyle),
        minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: theme.spacing.md),
        ),
      ),
    );
  }
}
