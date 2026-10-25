import 'package:flutter/material.dart';

import '../controller/release_notes_controller.dart';
import 'release_notes_view.dart';
import 'theme/release_notes_strings.dart';
import 'theme/release_notes_theme.dart';

/// How the notes are presented.
enum ReleaseNotesPresentation {
  /// A bottom sheet on narrow windows, a dialog on wide ones. The default.
  adaptive,

  /// Always a bottom sheet.
  sheet,

  /// Always a dialog.
  dialog,
}

/// Window width from which [ReleaseNotesPresentation.adaptive] picks the
/// dialog.
const double releaseNotesWideBreakpoint = 600;

/// A draggable bottom sheet around a [ReleaseNotesView].
///
/// Use [showReleaseNotesSheet] to present it, or place this widget in your
/// own `showModalBottomSheet` call.
class ReleaseNotesSheet extends StatelessWidget {
  /// Creates the sheet. [viewBuilder] receives the sheet's scroll
  /// controller and must pass it to the view it returns; the default builds
  /// a [ReleaseNotesView] from [controller] and the other arguments.
  const ReleaseNotesSheet({
    super.key,
    required this.controller,
    this.initialSize = 0.92,
    this.minSize = 0.5,
    this.maxSize = 0.96,
    this.title,
    this.subtitle,
    this.appName,
    this.icon,
    this.actions,
    this.onUpdate,
    this.viewBuilder,
  });

  /// The controller.
  final ReleaseNotesController controller;

  /// Starting height as a fraction of the window.
  final double initialSize;

  /// Smallest height before the sheet closes.
  final double minSize;

  /// Largest height.
  final double maxSize;

  /// See [ReleaseNotesView.title].
  final String? title;

  /// See [ReleaseNotesView.subtitle].
  final String? subtitle;

  /// See [ReleaseNotesView.appName].
  final String? appName;

  /// See [ReleaseNotesView.icon].
  final Widget? icon;

  /// See [ReleaseNotesView.actions].
  final ReleaseNotesActionsBuilder? actions;

  /// See [ReleaseNotesView.onUpdate].
  final void Function(BuildContext context, dynamic latest)? onUpdate;

  /// Replaces the view inside the sheet.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
  )?
  viewBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      expand: false,
      builder: (context, scrollController) {
        final view =
            viewBuilder?.call(context, scrollController) ??
            ReleaseNotesView(
              controller: controller,
              title: title,
              subtitle: subtitle,
              appName: appName,
              icon: icon,
              actions: actions,
              onUpdate: onUpdate,
              scrollController: scrollController,
            );
        return Column(
          children: [
            SizedBox(height: theme.spacing.sm),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.mutedColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        theme.contentMaxWidth + theme.contentPadding.horizontal,
                  ),
                  child: view,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A dialog around a [ReleaseNotesView], at most
/// [ReleaseNotesThemeData.contentMaxWidth] wide.
class ReleaseNotesDialog extends StatelessWidget {
  /// Creates the dialog.
  const ReleaseNotesDialog({
    super.key,
    required this.controller,
    this.maxHeightFraction = 0.85,
    this.title,
    this.subtitle,
    this.appName,
    this.icon,
    this.actions,
    this.onUpdate,
    this.view,
  });

  /// The controller.
  final ReleaseNotesController controller;

  /// Largest height as a fraction of the window.
  final double maxHeightFraction;

  /// See [ReleaseNotesView.title].
  final String? title;

  /// See [ReleaseNotesView.subtitle].
  final String? subtitle;

  /// See [ReleaseNotesView.appName].
  final String? appName;

  /// See [ReleaseNotesView.icon].
  final Widget? icon;

  /// See [ReleaseNotesView.actions].
  final ReleaseNotesActionsBuilder? actions;

  /// See [ReleaseNotesView.onUpdate].
  final void Function(BuildContext context, dynamic latest)? onUpdate;

  /// Replaces the view inside the dialog.
  final Widget? view;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final height = MediaQuery.sizeOf(context).height * maxHeightFraction;
    return Dialog(
      backgroundColor: theme.backgroundColor,
      insetPadding: EdgeInsets.all(theme.spacing.xl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: theme.contentMaxWidth,
          maxHeight: height,
        ),
        child: Padding(
          padding: EdgeInsets.only(top: theme.spacing.sm),
          child:
              view ??
              ReleaseNotesView(
                controller: controller,
                title: title,
                subtitle: subtitle,
                appName: appName,
                icon: icon,
                actions: actions,
                onUpdate: onUpdate,
              ),
        ),
      ),
    );
  }
}

/// Presents the notes as a bottom sheet. Completes when it closes.
Future<void> showReleaseNotesSheet(
  BuildContext context, {
  required ReleaseNotesController controller,
  String? title,
  String? subtitle,
  String? appName,
  Widget? icon,
  ReleaseNotesActionsBuilder? actions,
  void Function(BuildContext context, dynamic latest)? onUpdate,
  bool isDismissible = true,
  ReleaseNotesThemeData? theme,
  ReleaseNotesStrings? strings,
}) async {
  final data = theme ?? ReleaseNotesTheme.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: data.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder:
        (context) => ReleaseNotesTheme(
          data: data,
          strings: strings ?? ReleaseNotesTheme.stringsOf(context),
          child: ReleaseNotesSheet(
            controller: controller,
            title: title,
            subtitle: subtitle,
            appName: appName,
            icon: icon,
            actions: actions,
            onUpdate: onUpdate,
          ),
        ),
  );
  controller.notifyDismissed();
}

/// Presents the notes as a dialog that fades and scales in. Completes when
/// it closes.
Future<void> showReleaseNotesDialog(
  BuildContext context, {
  required ReleaseNotesController controller,
  String? title,
  String? subtitle,
  String? appName,
  Widget? icon,
  ReleaseNotesActionsBuilder? actions,
  void Function(BuildContext context, dynamic latest)? onUpdate,
  bool isDismissible = true,
  ReleaseNotesThemeData? theme,
  ReleaseNotesStrings? strings,
}) async {
  final data = theme ?? ReleaseNotesTheme.of(context);
  final resolvedStrings = strings ?? ReleaseNotesTheme.stringsOf(context);
  final duration = context.motion(data.duration);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: duration,
    pageBuilder:
        (context, animation, secondaryAnimation) => ReleaseNotesTheme(
          data: data,
          strings: resolvedStrings,
          child: PopScope(
            canPop: isDismissible,
            child: ReleaseNotesDialog(
              controller: controller,
              title: title,
              subtitle: subtitle,
              appName: appName,
              icon: icon,
              actions: actions,
              onUpdate: onUpdate,
            ),
          ),
        ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: data.curve,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
  controller.notifyDismissed();
}

/// Presents the notes: a sheet on narrow windows, a dialog on wide ones, or
/// whichever [presentation] asks for. Completes when the notes close.
Future<void> showReleaseNotes(
  BuildContext context, {
  required ReleaseNotesController controller,
  ReleaseNotesPresentation presentation = ReleaseNotesPresentation.adaptive,
  String? title,
  String? subtitle,
  String? appName,
  Widget? icon,
  ReleaseNotesActionsBuilder? actions,
  void Function(BuildContext context, dynamic latest)? onUpdate,
  bool isDismissible = true,
  ReleaseNotesThemeData? theme,
  ReleaseNotesStrings? strings,
}) {
  final useDialog = switch (presentation) {
    ReleaseNotesPresentation.dialog => true,
    ReleaseNotesPresentation.sheet => false,
    ReleaseNotesPresentation.adaptive =>
      MediaQuery.sizeOf(context).width >= releaseNotesWideBreakpoint,
  };
  if (useDialog) {
    return showReleaseNotesDialog(
      context,
      controller: controller,
      title: title,
      subtitle: subtitle,
      appName: appName,
      icon: icon,
      actions: actions,
      onUpdate: onUpdate,
      isDismissible: isDismissible,
      theme: theme,
      strings: strings,
    );
  }
  return showReleaseNotesSheet(
    context,
    controller: controller,
    title: title,
    subtitle: subtitle,
    appName: appName,
    icon: icon,
    actions: actions,
    onUpdate: onUpdate,
    isDismissible: isDismissible,
    theme: theme,
    strings: strings,
  );
}
