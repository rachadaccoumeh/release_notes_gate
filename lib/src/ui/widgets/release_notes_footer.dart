import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';

/// How prominent a footer action is.
enum ReleaseNotesActionEmphasis {
  /// Filled with the primary colour: the one thing to do.
  primary,

  /// Filled with a soft tint.
  tonal,

  /// Outlined.
  outlined,
}

/// A button in the footer.
class ReleaseNotesAction {
  /// Creates an action. [id] names it in callbacks: `update`, `download`,
  /// `release_page`, `close`, `retry` or your own.
  const ReleaseNotesAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emphasis = ReleaseNotesActionEmphasis.primary,
    this.enabled = true,
  });

  /// Identifier reported to `ReleaseNotesCallbacks.onActionTap`.
  final String id;

  /// The button text.
  final String label;

  /// What happens on tap.
  final void Function(BuildContext context) onPressed;

  /// An optional leading icon.
  final IconData? icon;

  /// How prominent the button is.
  final ReleaseNotesActionEmphasis emphasis;

  /// Whether the button can be pressed.
  final bool enabled;
}

/// Full-width pill buttons stacked under the notes.
class ReleaseNotesFooter extends StatelessWidget {
  /// Creates a footer over [actions], in order from top to bottom.
  const ReleaseNotesFooter({
    super.key,
    required this.actions,
    this.onActionTap,
  });

  /// The buttons.
  final List<ReleaseNotesAction> actions;

  /// Called with the action's id before its handler runs.
  final void Function(String id)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(height: theme.spacing.sm),
            _ActionButton(action: actions[i], onActionTap: onActionTap),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onActionTap});

  final ReleaseNotesAction action;
  final void Function(String id)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(theme.actionStyle),
    );
    void onPressed() {
      onActionTap?.call(action.id);
      action.onPressed(context);
    }

    final icon = action.icon == null ? null : Icon(action.icon, size: 20);
    final label = Text(action.label);
    final enabled = action.enabled ? onPressed : null;
    return switch (action.emphasis) {
      ReleaseNotesActionEmphasis.primary =>
        icon == null
            ? FilledButton(onPressed: enabled, style: style, child: label)
            : FilledButton.icon(
              onPressed: enabled,
              style: style,
              icon: icon,
              label: label,
            ),
      ReleaseNotesActionEmphasis.tonal =>
        icon == null
            ? FilledButton.tonal(onPressed: enabled, style: style, child: label)
            : FilledButton.tonalIcon(
              onPressed: enabled,
              style: style,
              icon: icon,
              label: label,
            ),
      ReleaseNotesActionEmphasis.outlined =>
        icon == null
            ? OutlinedButton(onPressed: enabled, style: style, child: label)
            : OutlinedButton.icon(
              onPressed: enabled,
              style: style,
              icon: icon,
              label: label,
            ),
    };
  }
}
