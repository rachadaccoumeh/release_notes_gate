import 'package:flutter/material.dart';

import '../../source/release_notes_source.dart';
import '../theme/release_notes_theme.dart';

/// Shown in place of the timeline when the notes could not be loaded.
class ReleaseNotesErrorView extends StatelessWidget {
  /// Creates the error view.
  const ReleaseNotesErrorView({
    super.key,
    this.error,
    this.onRetry,
    this.message,
  });

  /// The error, used to pick an icon.
  final Object? error;

  /// Tries again. Null hides the button.
  final VoidCallback? onRetry;

  /// Replaces the default message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final strings = ReleaseNotesTheme.stringsOf(context);
    final error = this.error;
    final offline =
        error is ReleaseNotesException &&
        error.kind == ReleaseNotesErrorKind.network;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: theme.spacing.xxl,
          horizontal: theme.spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.error.container,
                shape: BoxShape.circle,
              ),
              child: Icon(
                offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                color: theme.error.content,
                size: 28,
              ),
            ),
            SizedBox(height: theme.spacing.lg),
            Text(
              message ?? strings.loadFailed,
              style: theme.itemStyle,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: theme.spacing.lg),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(strings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
