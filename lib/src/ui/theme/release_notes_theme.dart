import 'package:flutter/material.dart';

import '../../model/release_section.dart';
import 'release_notes_strings.dart';

/// A colour role: a filled background, the content on it, and a standalone
/// accent for text, icons and timeline nodes.
@immutable
class ReleaseNotesTone {
  /// Creates a tone.
  const ReleaseNotesTone({
    required this.container,
    required this.content,
    required this.accent,
  });

  /// Background of a filled element in this role.
  final Color container;

  /// Content drawn on top of [container].
  final Color content;

  /// Standalone colour for text or icons that carry the role without a
  /// filled background.
  final Color accent;

  /// Returns a copy with the given fields replaced.
  ReleaseNotesTone copyWith({
    Color? container,
    Color? content,
    Color? accent,
  }) => ReleaseNotesTone(
    container: container ?? this.container,
    content: content ?? this.content,
    accent: accent ?? this.accent,
  );

  /// Blends two tones.
  static ReleaseNotesTone lerp(
    ReleaseNotesTone a,
    ReleaseNotesTone b,
    double t,
  ) => ReleaseNotesTone(
    container: Color.lerp(a.container, b.container, t)!,
    content: Color.lerp(a.content, b.content, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
  );
}

/// How a section kind presents itself: its icon and its tone. The heading
/// comes from [ReleaseNotesStrings], or from the section itself for
/// [ReleaseSectionKind.other].
@immutable
class ReleaseNotesSectionStyle {
  /// Creates a section style.
  const ReleaseNotesSectionStyle({required this.icon, required this.tone});

  /// The icon in the section header and the summary pill.
  final IconData icon;

  /// The colour role of the section.
  final ReleaseNotesTone tone;

  /// Returns a copy with the given fields replaced.
  ReleaseNotesSectionStyle copyWith({IconData? icon, ReleaseNotesTone? tone}) =>
      ReleaseNotesSectionStyle(
        icon: icon ?? this.icon,
        tone: tone ?? this.tone,
      );
}

/// Every colour, size, shape, text style and duration the release notes
/// widgets use.
///
/// [ReleaseNotesThemeData.fromTheme] derives all of it from a [ThemeData],
/// so the widgets match the app with no setup. Override any field with
/// [copyWith], or start from the [ReleaseNotesThemeData.midnight] preset,
/// a dark look with blue, amber and green sections.
@immutable
class ReleaseNotesThemeData extends ThemeExtension<ReleaseNotesThemeData> {
  /// Creates a theme with every value given.
  const ReleaseNotesThemeData({
    required this.primary,
    required this.success,
    required this.warning,
    required this.neutral,
    required this.error,
    required this.sectionStyles,
    required this.cardColor,
    required this.cardBorderColor,
    required this.cardHeaderColor,
    required this.dividerColor,
    required this.railColor,
    required this.mutedColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.codeChipColor,
    required this.linkColor,
    required this.backgroundColor,
    required this.headerIconBackgroundColor,
    required this.shimmerBaseColor,
    required this.shimmerHighlightColor,
    required this.versionStyle,
    required this.releaseSummaryStyle,
    required this.sectionTitleStyle,
    required this.itemStyle,
    required this.noteStyle,
    required this.scopeStyle,
    required this.badgeStyle,
    required this.pillStyle,
    required this.summaryTitleStyle,
    required this.headerTitleStyle,
    required this.headerSubtitleStyle,
    required this.actionStyle,
    this.cardRadius = 20,
    this.cardBorderWidth = 1,
    this.cardElevation = 0,
    this.sectionIconRadius = 8,
    this.sectionIconSize = 28,
    this.headerIconSize = 48,
    this.headerIconRadius = 14,
    this.summaryPadding = 20,
    this.summaryArrowSize = 18,
    this.railSlotWidth = 18,
    this.railContentGap = 14,
    this.railStrokeWidth = 2,
    this.nodeRadius = 6,
    this.nodeHaloRadius = 10,
    this.nodeCenterY = 16,
    this.releaseSpacing = 20,
    this.itemDotSize = 6,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.sectionPreviewLimit = 6,
    this.sectionPreviewSize = 5,
    this.relativeDateDays = 6,
    this.contentMaxWidth = 560,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.spacing = const ReleaseNotesSpacing(),
    this.duration = const Duration(milliseconds: 220),
    this.shortDuration = const Duration(milliseconds: 180),
    this.staggerDelay = const Duration(milliseconds: 40),
    this.curve = Curves.easeOutCubic,
  });

  /// Derives a theme from [theme]. Features take the primary colour, fixes
  /// amber, improvements and performance green, the rest the surface.
  factory ReleaseNotesThemeData.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final dark = scheme.brightness == Brightness.dark;

    final primary = ReleaseNotesTone(
      container: scheme.primaryContainer,
      content: scheme.onPrimaryContainer,
      accent: scheme.primary,
    );
    final success =
        dark
            ? const ReleaseNotesTone(
              container: Color(0xFF0D5316),
              content: Color(0xFFABF5A3),
              accent: Color(0xFF90D889),
            )
            : const ReleaseNotesTone(
              container: Color(0xFFABF5A3),
              content: Color(0xFF002204),
              accent: Color(0xFF286C2A),
            );
    final warning =
        dark
            ? const ReleaseNotesTone(
              container: Color(0xFF5F4100),
              content: Color(0xFFFFDEA8),
              accent: Color(0xFFF5BD48),
            )
            : const ReleaseNotesTone(
              container: Color(0xFFFFDEA8),
              content: Color(0xFF271900),
              accent: Color(0xFF7C5800),
            );
    final neutral = ReleaseNotesTone(
      container: scheme.surfaceContainerHighest,
      content: scheme.onSurfaceVariant,
      accent: scheme.onSurfaceVariant,
    );
    final error = ReleaseNotesTone(
      container: scheme.errorContainer,
      content: scheme.onErrorContainer,
      accent: scheme.error,
    );

    return ReleaseNotesThemeData(
      primary: primary,
      success: success,
      warning: warning,
      neutral: neutral,
      error: error,
      sectionStyles: {
        ReleaseSectionKind.features: ReleaseNotesSectionStyle(
          icon: Icons.auto_awesome_rounded,
          tone: primary,
        ),
        ReleaseSectionKind.fixes: ReleaseNotesSectionStyle(
          icon: Icons.bug_report_rounded,
          tone: warning,
        ),
        ReleaseSectionKind.improvements: ReleaseNotesSectionStyle(
          icon: Icons.tune_rounded,
          tone: success,
        ),
        ReleaseSectionKind.performance: ReleaseNotesSectionStyle(
          icon: Icons.speed_rounded,
          tone: success,
        ),
        ReleaseSectionKind.other: ReleaseNotesSectionStyle(
          icon: Icons.notes_rounded,
          tone: neutral,
        ),
      },
      cardColor: scheme.surfaceContainerLow,
      cardBorderColor: scheme.outlineVariant.withValues(
        alpha: dark ? 0.6 : 0.8,
      ),
      cardHeaderColor: scheme.onSurface.withValues(alpha: dark ? 0.04 : 0.03),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      railColor: scheme.outlineVariant,
      mutedColor: scheme.outline,
      textColor: scheme.onSurface,
      secondaryTextColor: scheme.onSurfaceVariant,
      codeChipColor: scheme.surfaceContainerHighest,
      linkColor: scheme.primary,
      backgroundColor: scheme.surface,
      headerIconBackgroundColor: scheme.primary.withValues(alpha: 0.2),
      shimmerBaseColor: scheme.onSurface.withValues(alpha: 0.08),
      shimmerHighlightColor: scheme.onSurface.withValues(alpha: 0.16),
      versionStyle: text.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      releaseSummaryStyle: text.bodySmall!.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      sectionTitleStyle: text.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      itemStyle: text.bodyMedium!.copyWith(color: scheme.onSurface),
      noteStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
      scopeStyle: text.labelMedium!.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      badgeStyle: text.labelMedium!,
      pillStyle: text.labelLarge!,
      summaryTitleStyle: text.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      headerTitleStyle: text.titleLarge!.copyWith(
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      headerSubtitleStyle: text.bodyMedium!.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      actionStyle: text.labelLarge!,
    );
  }

  /// A dark preset: near-black surfaces, blue features, amber fixes and
  /// green improvements, the look of a modern update dialog. Pass your own
  /// [seed] to tint it.
  factory ReleaseNotesThemeData.midnight({
    Color seed = const Color(0xFF4F8EF7),
    TextTheme? textTheme,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF0B0E14),
      onSurface: const Color(0xFFE6E9EF),
      primaryContainer: const Color(0xFF274569),
      onPrimaryContainer: const Color(0xFFD6E4FF),
      outlineVariant: const Color(0xFF262B36),
      outline: const Color(0xFF59606E),
      surfaceContainerLow: const Color(0xFF10141C),
      surfaceContainerHighest: const Color(0xFF1F2530),
    );
    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: textTheme,
    );
    return ReleaseNotesThemeData.fromTheme(theme).copyWith(
      warning: const ReleaseNotesTone(
        container: Color(0xFF5A4200),
        content: Color(0xFFFFDEA8),
        accent: Color(0xFFF2B944),
      ),
      success: const ReleaseNotesTone(
        container: Color(0xFF1B5E20),
        content: Color(0xFFB9F6CA),
        accent: Color(0xFF7BD389),
      ),
      cardBorderColor: const Color(0xFF262B36),
    );
  }

  /// The features and "latest" role.
  final ReleaseNotesTone primary;

  /// The improvements, performance and "installed" role.
  final ReleaseNotesTone success;

  /// The fixes and "pre-release" role.
  final ReleaseNotesTone warning;

  /// The role of untyped sections and plain badges.
  final ReleaseNotesTone neutral;

  /// The error role.
  final ReleaseNotesTone error;

  /// Icon and tone per section kind. Missing kinds fall back to
  /// [ReleaseSectionKind.other].
  final Map<ReleaseSectionKind, ReleaseNotesSectionStyle> sectionStyles;

  /// Background of the summary and section cards.
  final Color cardColor;

  /// Border of the cards.
  final Color cardBorderColor;

  /// Band behind a section card's header.
  final Color cardHeaderColor;

  /// Divider between the items of a section.
  final Color dividerColor;

  /// The timeline rail.
  final Color railColor;

  /// Nodes of releases without a badge.
  final Color mutedColor;

  /// Primary text.
  final Color textColor;

  /// Secondary text: dates, counts, scopes.
  final Color secondaryTextColor;

  /// Background of inline code.
  final Color codeChipColor;

  /// Links inside a change.
  final Color linkColor;

  /// Background of the sheet and the dialog.
  final Color backgroundColor;

  /// Background of the default header icon.
  final Color headerIconBackgroundColor;

  /// Loading placeholders.
  final Color shimmerBaseColor;

  /// The moving highlight of loading placeholders.
  final Color shimmerHighlightColor;

  /// The version in a release header.
  final TextStyle versionStyle;

  /// The date and counts line under a version.
  final TextStyle releaseSummaryStyle;

  /// A section heading.
  final TextStyle sectionTitleStyle;

  /// A change.
  final TextStyle itemStyle;

  /// A note between the changes.
  final TextStyle noteStyle;

  /// The scope label above a change.
  final TextStyle scopeStyle;

  /// Badges such as Latest and Installed.
  final TextStyle badgeStyle;

  /// Count pills in the summary.
  final TextStyle pillStyle;

  /// The "N new releases" line in the summary.
  final TextStyle summaryTitleStyle;

  /// The sheet or dialog title.
  final TextStyle headerTitleStyle;

  /// The line under the title.
  final TextStyle headerSubtitleStyle;

  /// Footer action labels.
  final TextStyle actionStyle;

  /// Corner radius of the cards.
  final double cardRadius;

  /// Border width of the cards.
  final double cardBorderWidth;

  /// Elevation of the cards.
  final double cardElevation;

  /// Corner radius of the section icon box.
  final double sectionIconRadius;

  /// Size of the section icon box.
  final double sectionIconSize;

  /// Size of the header icon.
  final double headerIconSize;

  /// Corner radius of the header icon.
  final double headerIconRadius;

  /// Padding inside the summary card.
  final double summaryPadding;

  /// Size of the arrow between the versions in the summary.
  final double summaryArrowSize;

  /// Width of the column the rail runs through.
  final double railSlotWidth;

  /// Gap between the rail column and the content.
  final double railContentGap;

  /// Stroke width of the rail.
  final double railStrokeWidth;

  /// Radius of a release node.
  final double nodeRadius;

  /// Radius of the halo around the latest release's node.
  final double nodeHaloRadius;

  /// Vertical centre of the node, level with the first line of the header.
  final double nodeCenterY;

  /// Space between releases on the timeline.
  final double releaseSpacing;

  /// Size of the dot before a change.
  final double itemDotSize;

  /// Padding of one change row.
  final EdgeInsets itemPadding;

  /// Sections longer than this show [sectionPreviewSize] changes until
  /// opened.
  final int sectionPreviewLimit;

  /// How many changes a folded long section shows.
  final int sectionPreviewSize;

  /// Releases this many days old or newer read as "2 days ago" rather than
  /// as a date.
  final int relativeDateDays;

  /// Widest the content grows in the dialog and on wide sheets.
  final double contentMaxWidth;

  /// Horizontal padding of the content.
  final EdgeInsets contentPadding;

  /// The spacing scale.
  final ReleaseNotesSpacing spacing;

  /// Duration of expand, fade and colour animations.
  final Duration duration;

  /// Duration of small animations such as the chevron turn.
  final Duration shortDuration;

  /// Delay between the staggered entrance of consecutive releases.
  final Duration staggerDelay;

  /// Curve of the animations.
  final Curve curve;

  /// The style of [kind], falling back to [ReleaseSectionKind.other].
  ReleaseNotesSectionStyle sectionStyle(ReleaseSectionKind kind) =>
      sectionStyles[kind] ??
      sectionStyles[ReleaseSectionKind.other] ??
      ReleaseNotesSectionStyle(icon: Icons.notes_rounded, tone: neutral);

  /// The shape of the cards.
  ShapeBorder get cardShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(cardRadius),
    side:
        cardBorderWidth > 0
            ? BorderSide(color: cardBorderColor, width: cardBorderWidth)
            : BorderSide.none,
  );

  @override
  ReleaseNotesThemeData copyWith({
    ReleaseNotesTone? primary,
    ReleaseNotesTone? success,
    ReleaseNotesTone? warning,
    ReleaseNotesTone? neutral,
    ReleaseNotesTone? error,
    Map<ReleaseSectionKind, ReleaseNotesSectionStyle>? sectionStyles,
    Color? cardColor,
    Color? cardBorderColor,
    Color? cardHeaderColor,
    Color? dividerColor,
    Color? railColor,
    Color? mutedColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? codeChipColor,
    Color? linkColor,
    Color? backgroundColor,
    Color? headerIconBackgroundColor,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    TextStyle? versionStyle,
    TextStyle? releaseSummaryStyle,
    TextStyle? sectionTitleStyle,
    TextStyle? itemStyle,
    TextStyle? noteStyle,
    TextStyle? scopeStyle,
    TextStyle? badgeStyle,
    TextStyle? pillStyle,
    TextStyle? summaryTitleStyle,
    TextStyle? headerTitleStyle,
    TextStyle? headerSubtitleStyle,
    TextStyle? actionStyle,
    double? cardRadius,
    double? cardBorderWidth,
    double? cardElevation,
    double? sectionIconRadius,
    double? sectionIconSize,
    double? headerIconSize,
    double? headerIconRadius,
    double? summaryPadding,
    double? summaryArrowSize,
    double? railSlotWidth,
    double? railContentGap,
    double? railStrokeWidth,
    double? nodeRadius,
    double? nodeHaloRadius,
    double? nodeCenterY,
    double? releaseSpacing,
    double? itemDotSize,
    EdgeInsets? itemPadding,
    int? sectionPreviewLimit,
    int? sectionPreviewSize,
    int? relativeDateDays,
    double? contentMaxWidth,
    EdgeInsets? contentPadding,
    ReleaseNotesSpacing? spacing,
    Duration? duration,
    Duration? shortDuration,
    Duration? staggerDelay,
    Curve? curve,
  }) => ReleaseNotesThemeData(
    primary: primary ?? this.primary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    neutral: neutral ?? this.neutral,
    error: error ?? this.error,
    sectionStyles:
        sectionStyles ?? _restyle(primary, success, warning, neutral),
    cardColor: cardColor ?? this.cardColor,
    cardBorderColor: cardBorderColor ?? this.cardBorderColor,
    cardHeaderColor: cardHeaderColor ?? this.cardHeaderColor,
    dividerColor: dividerColor ?? this.dividerColor,
    railColor: railColor ?? this.railColor,
    mutedColor: mutedColor ?? this.mutedColor,
    textColor: textColor ?? this.textColor,
    secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
    codeChipColor: codeChipColor ?? this.codeChipColor,
    linkColor: linkColor ?? this.linkColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    headerIconBackgroundColor:
        headerIconBackgroundColor ?? this.headerIconBackgroundColor,
    shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
    shimmerHighlightColor: shimmerHighlightColor ?? this.shimmerHighlightColor,
    versionStyle: versionStyle ?? this.versionStyle,
    releaseSummaryStyle: releaseSummaryStyle ?? this.releaseSummaryStyle,
    sectionTitleStyle: sectionTitleStyle ?? this.sectionTitleStyle,
    itemStyle: itemStyle ?? this.itemStyle,
    noteStyle: noteStyle ?? this.noteStyle,
    scopeStyle: scopeStyle ?? this.scopeStyle,
    badgeStyle: badgeStyle ?? this.badgeStyle,
    pillStyle: pillStyle ?? this.pillStyle,
    summaryTitleStyle: summaryTitleStyle ?? this.summaryTitleStyle,
    headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
    headerSubtitleStyle: headerSubtitleStyle ?? this.headerSubtitleStyle,
    actionStyle: actionStyle ?? this.actionStyle,
    cardRadius: cardRadius ?? this.cardRadius,
    cardBorderWidth: cardBorderWidth ?? this.cardBorderWidth,
    cardElevation: cardElevation ?? this.cardElevation,
    sectionIconRadius: sectionIconRadius ?? this.sectionIconRadius,
    sectionIconSize: sectionIconSize ?? this.sectionIconSize,
    headerIconSize: headerIconSize ?? this.headerIconSize,
    headerIconRadius: headerIconRadius ?? this.headerIconRadius,
    summaryPadding: summaryPadding ?? this.summaryPadding,
    summaryArrowSize: summaryArrowSize ?? this.summaryArrowSize,
    railSlotWidth: railSlotWidth ?? this.railSlotWidth,
    railContentGap: railContentGap ?? this.railContentGap,
    railStrokeWidth: railStrokeWidth ?? this.railStrokeWidth,
    nodeRadius: nodeRadius ?? this.nodeRadius,
    nodeHaloRadius: nodeHaloRadius ?? this.nodeHaloRadius,
    nodeCenterY: nodeCenterY ?? this.nodeCenterY,
    releaseSpacing: releaseSpacing ?? this.releaseSpacing,
    itemDotSize: itemDotSize ?? this.itemDotSize,
    itemPadding: itemPadding ?? this.itemPadding,
    sectionPreviewLimit: sectionPreviewLimit ?? this.sectionPreviewLimit,
    sectionPreviewSize: sectionPreviewSize ?? this.sectionPreviewSize,
    relativeDateDays: relativeDateDays ?? this.relativeDateDays,
    contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
    contentPadding: contentPadding ?? this.contentPadding,
    spacing: spacing ?? this.spacing,
    duration: duration ?? this.duration,
    shortDuration: shortDuration ?? this.shortDuration,
    staggerDelay: staggerDelay ?? this.staggerDelay,
    curve: curve ?? this.curve,
  );

  /// When a tone is replaced, the section styles that used the old tone
  /// follow it, so `copyWith(warning: ...)` recolours the fixes section.
  Map<ReleaseSectionKind, ReleaseNotesSectionStyle> _restyle(
    ReleaseNotesTone? primary,
    ReleaseNotesTone? success,
    ReleaseNotesTone? warning,
    ReleaseNotesTone? neutral,
  ) {
    if (primary == null &&
        success == null &&
        warning == null &&
        neutral == null) {
      return sectionStyles;
    }
    ReleaseNotesTone swap(ReleaseNotesTone tone) {
      if (identical(tone, this.primary) && primary != null) return primary;
      if (identical(tone, this.success) && success != null) return success;
      if (identical(tone, this.warning) && warning != null) return warning;
      if (identical(tone, this.neutral) && neutral != null) return neutral;
      return tone;
    }

    return sectionStyles.map(
      (kind, style) => MapEntry(kind, style.copyWith(tone: swap(style.tone))),
    );
  }

  @override
  ReleaseNotesThemeData lerp(
    ThemeExtension<ReleaseNotesThemeData>? other,
    double t,
  ) {
    if (other is! ReleaseNotesThemeData) return this;
    return t < 0.5 ? this : other;
  }
}

/// The spacing scale: 4, 8, 12, 16, 24, 32.
@immutable
class ReleaseNotesSpacing {
  /// Creates a spacing scale.
  const ReleaseNotesSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
  });

  /// 4 by default.
  final double xs;

  /// 8 by default.
  final double sm;

  /// 12 by default.
  final double md;

  /// 16 by default.
  final double lg;

  /// 24 by default.
  final double xl;

  /// 32 by default.
  final double xxl;
}

/// Provides a [ReleaseNotesThemeData] and [ReleaseNotesStrings] to the
/// release notes widgets below it.
///
/// Without one, the widgets derive the theme from [Theme.of] and use the
/// English strings. A [ReleaseNotesThemeData] registered as a
/// [ThemeExtension] on the app theme is honoured too.
class ReleaseNotesTheme extends InheritedWidget {
  /// Creates a theme scope.
  const ReleaseNotesTheme({
    super.key,
    this.data,
    this.strings,
    required super.child,
  });

  /// The theme, or null to derive it from the app theme.
  final ReleaseNotesThemeData? data;

  /// The strings, or null for English.
  final ReleaseNotesStrings? strings;

  /// The theme for [context]: the nearest [ReleaseNotesTheme], then the
  /// app theme's extension, then one derived from the app theme.
  static ReleaseNotesThemeData of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ReleaseNotesTheme>();
    if (scope?.data != null) return scope!.data!;
    final theme = Theme.of(context);
    return theme.extension<ReleaseNotesThemeData>() ??
        ReleaseNotesThemeData.fromTheme(theme);
  }

  /// The strings for [context]: the nearest [ReleaseNotesTheme]'s, else
  /// English.
  static ReleaseNotesStrings stringsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ReleaseNotesTheme>()
          ?.strings ??
      const ReleaseNotesStrings();

  @override
  bool updateShouldNotify(ReleaseNotesTheme oldWidget) =>
      data != oldWidget.data || strings != oldWidget.strings;
}

/// Motion helpers shared by the widgets.
extension ReleaseNotesMotion on BuildContext {
  /// [duration], or one millisecond when the user asked for reduced motion.
  ///
  /// Not zero: `AnimatedSize` and friends assert on a zero duration.
  Duration motion(Duration duration) =>
      MediaQuery.disableAnimationsOf(this)
          ? const Duration(milliseconds: 1)
          : duration;
}
