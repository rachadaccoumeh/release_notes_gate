import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/release_notes_controller.dart';
import '../controller/release_notes_state.dart';
import 'release_notes_presentation.dart';
import 'release_notes_view.dart';
import 'theme/release_notes_strings.dart';
import 'theme/release_notes_theme.dart';

/// Runs the controller's trigger after the first frame and presents the
/// notes when there is something to show.
///
/// Place it below the app's `Navigator`, for example around the home page:
///
/// ```dart
/// MaterialApp(
///   home: ReleaseNotesGate(controller: controller, child: const HomePage()),
/// )
/// ```
///
/// Or above it with a [navigatorKey]:
///
/// ```dart
/// MaterialApp(
///   navigatorKey: navigatorKey,
///   builder: (context, child) => ReleaseNotesGate(
///     controller: controller,
///     navigatorKey: navigatorKey,
///     child: child!,
///   ),
/// )
/// ```
///
/// [child] renders at once; the check runs in the background. Pass
/// [onDecision] to present the notes your own way instead.
class ReleaseNotesGate extends StatefulWidget {
  /// Creates the gate.
  const ReleaseNotesGate({
    super.key,
    required this.controller,
    required this.child,
    this.navigatorKey,
    this.presentation = ReleaseNotesPresentation.adaptive,
    this.delay = Duration.zero,
    this.autoCheck = true,
    this.onDecision,
    this.appName,
    this.icon,
    this.actions,
    this.onUpdate,
    this.theme,
    this.strings,
  });

  /// The controller.
  final ReleaseNotesController controller;

  /// The app content.
  final Widget child;

  /// The navigator to present on, when the gate sits above the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Sheet, dialog or adaptive.
  final ReleaseNotesPresentation presentation;

  /// Extra wait after the first frame, for a splash to finish.
  final Duration delay;

  /// Whether the check runs on mount. Turn off to call
  /// `controller.check()` yourself.
  final bool autoCheck;

  /// Receives the decision. Return true to let the gate present the notes,
  /// false when you handle it yourself.
  final bool Function(BuildContext context, ReleaseNotesDecision decision)?
  onDecision;

  /// See [ReleaseNotesView.appName].
  final String? appName;

  /// See [ReleaseNotesView.icon].
  final Widget? icon;

  /// See [ReleaseNotesView.actions].
  final ReleaseNotesActionsBuilder? actions;

  /// See [ReleaseNotesView.onUpdate].
  final void Function(BuildContext context, dynamic latest)? onUpdate;

  /// Theme for the presented notes. Defaults to the ambient one.
  final ReleaseNotesThemeData? theme;

  /// Strings for the presented notes. Defaults to the ambient ones.
  final ReleaseNotesStrings? strings;

  @override
  State<ReleaseNotesGate> createState() => _ReleaseNotesGateState();
}

class _ReleaseNotesGateState extends State<ReleaseNotesGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
    }
  }

  Future<void> _run() async {
    if (_checked || !mounted) return;
    _checked = true;
    final decision = await widget.controller.check();
    if (!mounted || !decision.shouldShow) return;
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    final targetContext = widget.navigatorKey?.currentContext ?? context;
    if (!targetContext.mounted) return;
    final present = widget.onDecision?.call(targetContext, decision) ?? true;
    if (!present) return;
    await showReleaseNotes(
      targetContext,
      controller: widget.controller,
      presentation: widget.presentation,
      appName: widget.appName,
      icon: widget.icon,
      actions: widget.actions,
      onUpdate: widget.onUpdate,
      theme: widget.theme,
      strings: widget.strings,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
