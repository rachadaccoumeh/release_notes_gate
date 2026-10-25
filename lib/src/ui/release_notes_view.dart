import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/release_notes_controller.dart';
import '../controller/release_notes_state.dart';
import '../model/release_note.dart';
import 'theme/release_notes_strings.dart';
import 'theme/release_notes_theme.dart';
import 'widgets/formatted_text.dart';
import 'widgets/platform_toggle.dart';
import 'widgets/release_card.dart';
import 'widgets/release_notes_error_view.dart';
import 'widgets/release_notes_footer.dart';
import 'widgets/release_notes_header.dart';
import 'widgets/release_notes_loading.dart';
import 'widgets/release_notes_summary_card.dart';
import 'widgets/release_notes_timeline.dart';

/// Builds the footer actions for the current state. Return an empty list
/// for no footer.
typedef ReleaseNotesActionsBuilder =
    List<ReleaseNotesAction> Function(
      BuildContext context,
      ReleaseNotesState state,
      List<ReleaseNotesAction> defaults,
    );

/// The complete notes screen: header, scrolling body with summary and
/// timeline, and footer actions, all driven by a [ReleaseNotesController].
///
/// [ReleaseNotesSheet] and [ReleaseNotesDialog] wrap this. Use it directly
/// to put the notes on a page of your own. Every part has a builder to
/// replace it, and [showHeader], [showFooter], [showSummary] and
/// [showPlatformToggle] switch parts off.
class ReleaseNotesView extends StatefulWidget {
  /// Creates the view.
  const ReleaseNotesView({
    super.key,
    required this.controller,
    this.title,
    this.subtitle,
    this.appName,
    this.icon,
    this.actions,
    this.onUpdate,
    this.onClose,
    this.showHeader = true,
    this.showFooter = true,
    this.showSummary,
    this.showPlatformToggle = true,
    this.showCloseButton = false,
    this.scrollController,
    this.locale,
    this.onLinkTap,
    this.headerBuilder,
    this.footerBuilder,
    this.summaryBuilder,
    this.releaseBuilder,
    this.sectionBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.notifyShown = true,
  });

  /// The controller.
  final ReleaseNotesController controller;

  /// Replaces the title picked from the decision.
  final String? title;

  /// Replaces the subtitle, which is the app name and the target version.
  final String? subtitle;

  /// The app name for the default subtitle.
  final String? appName;

  /// The header icon, normally the app icon.
  final Widget? icon;

  /// Builds the footer actions. Receives the defaults to extend or replace.
  final ReleaseNotesActionsBuilder? actions;

  /// What the Update or Download button does. Defaults to opening the
  /// latest release's download link, else its page.
  final void Function(BuildContext context, ReleaseNote? latest)? onUpdate;

  /// What the Close button does. Defaults to popping the route.
  final VoidCallback? onClose;

  /// Whether the header shows.
  final bool showHeader;

  /// Whether the footer shows.
  final bool showFooter;

  /// Whether the summary card shows. Null shows it for updates and for
  /// "what's new" after an update.
  final bool? showSummary;

  /// Whether the platform toggle shows when the filter hides changes.
  final bool showPlatformToggle;

  /// Whether a close icon sits in the header, for a view without footer.
  final bool showCloseButton;

  /// The body's scroll controller, for a draggable sheet.
  final ScrollController? scrollController;

  /// Locale for translated texts. Defaults to the controller's config, then
  /// the ambient locale.
  final Locale? locale;

  /// Called on a link tap inside a change. Defaults to the controller's
  /// callback, then to opening the browser.
  final LinkTapCallback? onLinkTap;

  /// Replaces the header.
  final Widget Function(
    BuildContext context,
    ReleaseNotesState state,
    String title,
    String? subtitle,
  )?
  headerBuilder;

  /// Replaces the footer.
  final Widget Function(
    BuildContext context,
    ReleaseNotesState state,
    List<ReleaseNotesAction> actions,
  )?
  footerBuilder;

  /// Replaces the summary card.
  final Widget Function(
    BuildContext context,
    ReleaseNotesDecision decision,
    List<ReleaseNote> notes,
  )?
  summaryBuilder;

  /// Replaces each release card.
  final ReleaseCardBuilder? releaseBuilder;

  /// Replaces the section cards.
  final ReleaseSectionBuilder? sectionBuilder;

  /// Replaces the loading state.
  final WidgetBuilder? loadingBuilder;

  /// Replaces the error state.
  final Widget Function(
    BuildContext context,
    Object? error,
    VoidCallback retry,
  )?
  errorBuilder;

  /// Replaces the empty state.
  final WidgetBuilder? emptyBuilder;

  /// Whether the view reports itself shown to the controller on first
  /// build, which marks the version as seen by config.
  final bool notifyShown;

  @override
  State<ReleaseNotesView> createState() => _ReleaseNotesViewState();
}

class _ReleaseNotesViewState extends State<ReleaseNotesView> {
  @override
  void initState() {
    super.initState();
    if (widget.notifyShown) widget.controller.notifyShown();
    if (widget.controller.state.status == ReleaseNotesStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = ReleaseNotesTheme.of(context);
        final strings = ReleaseNotesTheme.stringsOf(context);
        final controller = widget.controller;
        final state = controller.state;
        final decision = state.decision;
        final title = widget.title ?? _titleFor(decision, strings);
        final subtitle = widget.subtitle ?? _subtitleFor(state);
        final actions = _actions(context, state, strings);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader)
              Padding(
                padding: theme.contentPadding,
                child:
                    widget.headerBuilder?.call(
                      context,
                      state,
                      title,
                      subtitle,
                    ) ??
                    ReleaseNotesHeader(
                      title: title,
                      subtitle: subtitle,
                      icon: widget.icon,
                      trailing:
                          widget.showCloseButton
                              ? IconButton(
                                tooltip: strings.close,
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => _close(context),
                              )
                              : null,
                    ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.motion(theme.duration),
                switchInCurve: theme.curve,
                switchOutCurve: theme.curve,
                child: KeyedSubtree(
                  key: ValueKey(_bodyKey(state)),
                  child: _body(context, state, theme, strings),
                ),
              ),
            ),
            if (widget.showFooter && actions.isNotEmpty)
              Padding(
                padding: theme.contentPadding,
                child:
                    widget.footerBuilder?.call(context, state, actions) ??
                    ReleaseNotesFooter(
                      actions: actions,
                      onActionTap: controller.callbacks.onActionTap,
                    ),
              ),
          ],
        );
      },
    );
  }

  String _bodyKey(ReleaseNotesState state) {
    if (state.isLoadingFirst) return 'loading';
    if (state.status == ReleaseNotesStatus.failed) return 'error';
    return 'content';
  }

  Widget _body(
    BuildContext context,
    ReleaseNotesState state,
    ReleaseNotesThemeData theme,
    ReleaseNotesStrings strings,
  ) {
    final controller = widget.controller;
    final decision = state.decision;
    final showSummary =
        widget.showSummary ??
        (decision.isUpdate ||
            (decision.reason == ReleaseNotesReason.newVersionInstalled &&
                decision.from != null));

    if (state.isLoadingFirst) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        padding: theme.contentPadding.copyWith(
          top: theme.spacing.sm,
          bottom: theme.spacing.lg,
        ),
        child:
            widget.loadingBuilder?.call(context) ??
            ReleaseNotesLoading(withSummary: showSummary),
      );
    }
    if (state.status == ReleaseNotesStatus.failed) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        padding: theme.contentPadding,
        child:
            widget.errorBuilder?.call(
              context,
              state.error,
              controller.refresh,
            ) ??
            ReleaseNotesErrorView(
              error: state.error,
              onRetry: controller.refresh,
            ),
      );
    }

    final locale = widget.locale ?? controller.config.locale;
    final onLinkTap = widget.onLinkTap ?? controller.callbacks.onLinkTap;
    // A changelog opened by hand highlights nothing: the newest release
    // starts open and the rest folded. After an update, the new releases
    // lead and start open; the installed version and the history follow.
    final highlighted =
        decision.reason == ReleaseNotesReason.manual
            ? const <ReleaseNote>[]
            : controller.visibleDecisionNotes;
    final all = controller.visibleNotes;
    final notes =
        highlighted.isEmpty
            ? all
            : [
              ...highlighted,
              ...all.where((note) => highlighted.find(note.version) == null),
            ].newestFirst;

    if (notes.isEmpty) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        padding: theme.contentPadding,
        child:
            widget.emptyBuilder?.call(context) ??
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.spacing.xxl),
              child: Text(
                strings.noNotes,
                style: theme.noteStyle,
                textAlign: TextAlign.center,
              ),
            ),
      );
    }

    final platform = controller.platform;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        controller: widget.scrollController,
        padding: theme.contentPadding.copyWith(
          top: theme.spacing.sm,
          bottom: theme.spacing.lg,
        ),
        children: [
          if (state.fromCache)
            Padding(
              padding: EdgeInsets.only(bottom: theme.spacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: theme.secondaryTextColor,
                  ),
                  SizedBox(width: theme.spacing.sm),
                  Expanded(
                    child: Text(
                      strings.offlineNotice,
                      style: theme.releaseSummaryStyle,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.showPlatformToggle &&
              platform != null &&
              controller.canTogglePlatforms &&
              controller.filterHidesChanges)
            Padding(
              padding: EdgeInsets.only(bottom: theme.spacing.lg),
              child: Center(
                child: PlatformToggle(
                  platform: platform,
                  showAll: controller.showAllPlatforms,
                  onChanged: (value) => controller.showAllPlatforms = value,
                ),
              ),
            ),
          if (showSummary && highlighted.isNotEmpty) ...[
            widget.summaryBuilder?.call(context, decision, highlighted) ??
                ReleaseNotesSummaryCard(
                  notes: highlighted,
                  from: decision.from,
                  to: decision.to,
                ),
            SizedBox(height: theme.spacing.xl),
          ],
          ReleaseNotesTimeline(
            notes: notes,
            installedVersion: state.installedVersion,
            latestVersion: decision.isUpdate ? decision.to : null,
            highlighted: highlighted,
            locale: locale,
            onLinkTap: onLinkTap,
            onReleaseToggled: controller.callbacks.onReleaseToggled,
            showPlatforms: controller.showAllPlatforms,
            releaseBuilder: widget.releaseBuilder,
            sectionBuilder: widget.sectionBuilder,
          ),
        ],
      ),
    );
  }

  String _titleFor(
    ReleaseNotesDecision decision,
    ReleaseNotesStrings strings,
  ) => switch (decision.reason) {
    ReleaseNotesReason.updateAvailable => strings.updateAvailableTitle,
    ReleaseNotesReason.newVersionInstalled => strings.whatsNewTitle,
    ReleaseNotesReason.manual ||
    ReleaseNotesReason.none => strings.changelogTitle,
  };

  String? _subtitleFor(ReleaseNotesState state) {
    final version = state.decision.to ?? state.installedVersion;
    final parts = [
      if (widget.appName != null) widget.appName!,
      if (version != null) version.withPrefix,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  List<ReleaseNotesAction> _actions(
    BuildContext context,
    ReleaseNotesState state,
    ReleaseNotesStrings strings,
  ) {
    final defaults = <ReleaseNotesAction>[];
    final decision = state.decision;
    if (state.status == ReleaseNotesStatus.failed) {
      defaults.add(
        ReleaseNotesAction(
          id: 'retry',
          label: strings.retry,
          icon: Icons.refresh_rounded,
          emphasis: ReleaseNotesActionEmphasis.tonal,
          onPressed: (_) => widget.controller.refresh(),
        ),
      );
    }
    if (decision.isUpdate) {
      final latest = state.latest ?? decision.notes.newestFirst.firstOrNull;
      final page = latest?.url;
      if (page != null) {
        defaults.add(
          ReleaseNotesAction(
            id: 'release_page',
            label: strings.releasePage,
            icon: Icons.open_in_new_rounded,
            emphasis: ReleaseNotesActionEmphasis.outlined,
            onPressed:
                (_) => launchUrl(page, mode: LaunchMode.externalApplication),
          ),
        );
      }
      final hasDownload = latest?.downloadUrl != null;
      defaults.add(
        ReleaseNotesAction(
          id: hasDownload ? 'download' : 'update',
          label: hasDownload ? strings.download : strings.update,
          icon:
              hasDownload
                  ? Icons.download_rounded
                  : Icons.system_update_alt_rounded,
          enabled: widget.onUpdate != null || hasDownload || page != null,
          onPressed: (context) {
            final onUpdate = widget.onUpdate;
            if (onUpdate != null) return onUpdate(context, latest);
            final target = latest?.downloadUrl ?? page;
            if (target != null) {
              launchUrl(target, mode: LaunchMode.externalApplication);
            }
          },
        ),
      );
    } else {
      defaults.add(
        ReleaseNotesAction(
          id: 'close',
          label: strings.close,
          emphasis: ReleaseNotesActionEmphasis.tonal,
          onPressed: _close,
        ),
      );
    }
    return widget.actions?.call(context, state, defaults) ?? defaults;
  }

  void _close(BuildContext context) {
    final onClose = widget.onClose;
    if (onClose != null) return onClose();
    Navigator.of(context).maybePop();
  }
}
