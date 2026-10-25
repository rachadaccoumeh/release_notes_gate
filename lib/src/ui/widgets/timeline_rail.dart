import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';

/// Marker a release carries on the timeline, listed from the strongest
/// when several apply.
enum ReleaseBadge {
  /// The version the app runs.
  installed,

  /// A pre-release such as `2.2.0-dev.4`.
  prerelease,

  /// The newest release.
  latest,
}

/// A place on the timeline: the rail and a node at the leading edge, with
/// [child] beside them.
///
/// The node tells the release's badge at a glance: a filled dot with a halo
/// for the latest release, a ring for the installed one, a dashed ring for a
/// pre-release, a small muted dot for the rest.
class TimelineRow extends StatelessWidget {
  /// Creates a row.
  const TimelineRow({
    super.key,
    required this.child,
    this.badge,
    this.isFirst = false,
    this.isLast = false,
    this.hasNode = true,
  });

  /// The content beside the rail.
  final Widget child;

  /// The release's badge, which colours the node.
  final ReleaseBadge? badge;

  /// Whether the rail starts at this row instead of coming down from above.
  final bool isFirst;

  /// Whether the rail ends at this row.
  final bool isLast;

  /// Whether the row is a release with a node, rather than a label along
  /// the rail.
  final bool hasNode;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final tone = switch (badge) {
      ReleaseBadge.installed => theme.success,
      ReleaseBadge.prerelease => theme.warning,
      ReleaseBadge.latest || null => theme.primary,
    };
    return CustomPaint(
      painter: _RailPainter(
        badge: badge,
        isFirst: isFirst,
        isLast: isLast,
        hasNode: hasNode,
        rail: theme.railColor,
        accent: tone.accent,
        halo: tone.container,
        muted: theme.mutedColor,
        slotWidth: theme.railSlotWidth,
        strokeWidth: theme.railStrokeWidth,
        nodeRadius: theme.nodeRadius,
        haloRadius: theme.nodeHaloRadius,
        centerY: theme.nodeCenterY,
        textDirection: Directionality.of(context),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: theme.railSlotWidth + theme.railContentGap,
          bottom: isLast ? 0 : theme.releaseSpacing,
        ),
        child: child,
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.badge,
    required this.isFirst,
    required this.isLast,
    required this.hasNode,
    required this.rail,
    required this.accent,
    required this.halo,
    required this.muted,
    required this.slotWidth,
    required this.strokeWidth,
    required this.nodeRadius,
    required this.haloRadius,
    required this.centerY,
    required this.textDirection,
  });

  final ReleaseBadge? badge;
  final bool isFirst;
  final bool isLast;
  final bool hasNode;
  final Color rail;
  final Color accent;
  final Color halo;
  final Color muted;
  final double slotWidth;
  final double strokeWidth;
  final double nodeRadius;
  final double haloRadius;
  final double centerY;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final x =
        textDirection == TextDirection.rtl
            ? size.width - slotWidth / 2
            : slotWidth / 2;
    final railPaint =
        Paint()
          ..color = rail
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    if (!hasNode) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), railPaint);
      return;
    }

    final center = Offset(x, centerY);
    // The rail stops short of the node, so hollow nodes stay hollow over any
    // background.
    final clearance = haloRadius + strokeWidth;
    if (!isFirst) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, center.dy - clearance),
        railPaint,
      );
    }
    if (!isLast) {
      canvas.drawLine(
        Offset(x, center.dy + clearance),
        Offset(x, size.height),
        railPaint,
      );
    }

    switch (badge) {
      case ReleaseBadge.latest:
        canvas.drawCircle(center, haloRadius, Paint()..color = halo);
        canvas.drawCircle(center, nodeRadius, Paint()..color = accent);
      case ReleaseBadge.installed:
        const ring = 3.0;
        canvas.drawCircle(
          center,
          nodeRadius - ring / 2,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring,
        );
      case ReleaseBadge.prerelease:
        _drawDashedRing(
          canvas,
          center,
          nodeRadius - strokeWidth / 2,
          strokeWidth,
          2.5,
          muted,
        );
      case null:
        canvas.drawCircle(center, nodeRadius * 0.7, Paint()..color = muted);
    }
  }

  void _drawDashedRing(
    Canvas canvas,
    Offset center,
    double radius,
    double width,
    double dash,
    Color color,
  ) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width;
    final circumference = 2 * 3.141592653589793 * radius;
    final count = (circumference / (dash * 2)).floor().clamp(4, 64);
    final sweep = 2 * 3.141592653589793 / count;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * sweep, sweep / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.badge != badge ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.hasNode != hasNode ||
      old.rail != rail ||
      old.accent != accent ||
      old.halo != halo ||
      old.muted != muted ||
      old.slotWidth != slotWidth ||
      old.strokeWidth != strokeWidth ||
      old.nodeRadius != nodeRadius ||
      old.haloRadius != haloRadius ||
      old.centerY != centerY ||
      old.textDirection != textDirection;
}
