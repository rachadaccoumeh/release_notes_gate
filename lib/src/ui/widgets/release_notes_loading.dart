import 'package:flutter/material.dart';

import '../theme/release_notes_theme.dart';
import 'timeline_rail.dart';

/// Loading state of the timeline, laid out like the list it stands in for:
/// an optional summary, the newest release open on a section of changes,
/// older ones folded below, so nothing moves once the notes arrive.
class ReleaseNotesLoading extends StatelessWidget {
  /// Creates the loading state.
  const ReleaseNotesLoading({
    super.key,
    this.withSummary = false,
    this.foldedReleases = 2,
  });

  /// Whether a summary card placeholder leads the list.
  final bool withSummary;

  /// How many folded release placeholders follow the open one.
  final int foldedReleases;

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (withSummary) ...[
              _SummaryPlaceholder(),
              SizedBox(height: theme.spacing.xl),
            ],
            TimelineRow(
              isFirst: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeaderPlaceholder(),
                  SizedBox(height: theme.spacing.md),
                  const _SectionPlaceholder(),
                ],
              ),
            ),
            for (var i = 0; i < foldedReleases; i++)
              TimelineRow(
                isLast: i == foldedReleases - 1,
                child: const _HeaderPlaceholder(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Material(
      color: theme.cardColor,
      shape: theme.cardShape,
      child: Padding(
        padding: EdgeInsets.all(theme.summaryPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShimmerBox(width: 96, height: 24, shape: StadiumBorder()),
                SizedBox(width: theme.spacing.md),
                ShimmerBox(
                  width: theme.summaryArrowSize,
                  height: theme.summaryArrowSize,
                  shape: const CircleBorder(),
                ),
                SizedBox(width: theme.spacing.md),
                const ShimmerBox(width: 96, height: 24, shape: StadiumBorder()),
              ],
            ),
            SizedBox(height: theme.spacing.lg),
            const ShimmerBox(widthFraction: 0.5, height: 20),
            SizedBox(height: theme.spacing.lg),
            const ShimmerBox(width: 110, height: 36, shape: StadiumBorder()),
          ],
        ),
      ),
    );
  }
}

class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(widthFraction: 0.45, height: 22),
          SizedBox(height: theme.spacing.xs),
          const ShimmerBox(widthFraction: 0.6, height: 14),
        ],
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    return Material(
      color: theme.cardColor,
      shape: theme.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.cardHeaderColor,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.lg,
              vertical: theme.spacing.sm,
            ),
            child: Row(
              children: [
                ShimmerBox(
                  width: theme.sectionIconSize,
                  height: theme.sectionIconSize,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      theme.sectionIconRadius,
                    ),
                  ),
                ),
                SizedBox(width: theme.spacing.sm),
                const Expanded(
                  child: ShimmerBox(widthFraction: 0.3, height: 16),
                ),
              ],
            ),
          ),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
            Padding(
              padding: theme.itemPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: ShimmerBox(
                      width: theme.itemDotSize,
                      height: theme.itemDotSize,
                      shape: const CircleBorder(),
                    ),
                  ),
                  SizedBox(width: theme.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          widthFraction: i.isEven ? 0.9 : 0.75,
                          height: 14,
                        ),
                        SizedBox(height: theme.spacing.xs),
                        const ShimmerBox(widthFraction: 0.5, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A placeholder block with a moving highlight. Give it a [width] or a
/// [widthFraction] of the available width.
class ShimmerBox extends StatefulWidget {
  /// Creates a placeholder.
  const ShimmerBox({
    super.key,
    this.width,
    this.widthFraction,
    required this.height,
    this.shape,
  });

  /// Fixed width, or null to use [widthFraction].
  final double? width;

  /// Fraction of the available width, when [width] is null.
  final double? widthFraction;

  /// Height.
  final double height;

  /// Shape. Defaults to rounded corners of 8.
  final ShapeBorder? shape;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ReleaseNotesTheme.of(context);
    final shape =
        widget.shape ??
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final box = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          decoration: ShapeDecoration(
            shape: shape,
            gradient: LinearGradient(
              begin: Alignment(-1 + 3 * t - 1.5, 0),
              end: Alignment(1 + 3 * t - 1.5, 0),
              colors: [
                theme.shimmerBaseColor,
                theme.shimmerHighlightColor,
                theme.shimmerBaseColor,
              ],
            ),
          ),
        );
      },
    );
    if (widget.width != null) return SizedBox(width: widget.width, child: box);
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widget.widthFraction ?? 1,
      child: box,
    );
  }
}
