/// Release notes and "what's new" for Flutter.
///
/// Read notes from GitHub Releases and `CHANGELOG.md`, any REST API, a
/// Markdown file or a list in code. Show them once after an update, as an
/// "update available" summary, or as a changelog page, with a timeline UI
/// that is themeable piece by piece and replaceable as a whole.
library;

export 'src/controller/release_notes_callbacks.dart';
export 'src/controller/release_notes_config.dart';
export 'src/controller/release_notes_controller.dart';
export 'src/controller/release_notes_state.dart';
export 'src/model/localized_text.dart';
export 'src/model/release_item.dart';
export 'src/model/release_note.dart';
export 'src/model/release_note_json.dart';
export 'src/model/release_platform.dart';
export 'src/model/release_section.dart';
export 'src/model/release_version.dart';
export 'src/parser/changelog_parser.dart';
export 'src/parser/inline_markup.dart';
export 'src/source/github_release_notes_source.dart';
export 'src/source/http_release_notes_source.dart';
export 'src/source/markdown_changelog_source.dart';
export 'src/source/release_notes_source.dart';
export 'src/source/static_release_notes_source.dart';
export 'src/store/release_notes_cache.dart';
export 'src/store/seen_version_store.dart';
export 'src/ui/release_notes_gate.dart';
export 'src/ui/release_notes_presentation.dart';
export 'src/ui/release_notes_view.dart';
export 'src/ui/theme/release_notes_strings.dart';
export 'src/ui/theme/release_notes_theme.dart';
export 'src/ui/widgets/expand_chevron.dart';
export 'src/ui/widgets/formatted_text.dart';
export 'src/ui/widgets/platform_toggle.dart';
export 'src/ui/widgets/release_card.dart';
export 'src/ui/widgets/release_date.dart';
export 'src/ui/widgets/release_item_row.dart';
export 'src/ui/widgets/release_notes_error_view.dart';
export 'src/ui/widgets/release_notes_footer.dart';
export 'src/ui/widgets/release_notes_header.dart';
export 'src/ui/widgets/release_notes_loading.dart';
export 'src/ui/widgets/release_notes_summary_card.dart';
export 'src/ui/widgets/release_notes_timeline.dart';
export 'src/ui/widgets/release_section_card.dart';
export 'src/ui/widgets/timeline_rail.dart';
export 'src/ui/widgets/version_badge.dart';
