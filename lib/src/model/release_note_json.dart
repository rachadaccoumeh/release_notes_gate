import '../parser/changelog_parser.dart';
import 'localized_text.dart';
import 'release_item.dart';
import 'release_note.dart';
import 'release_platform.dart';
import 'release_section.dart';
import 'release_version.dart';

/// Reads and writes [ReleaseNote]s as JSON.
///
/// This is the shape the HTTP source, the cache and the Firestore and
/// Supabase adapters share. One object per release:
///
/// ```json
/// {
///   "version": "2.2.0",
///   "date": "2026-10-25",
///   "title": {"default": "Autumn release", "ar": "إصدار الخريف"},
///   "url": "https://example.com/releases/2.2.0",
///   "download_url": "https://example.com/app-2.2.0.apk",
///   "platforms": ["android", "ios"],
///   "sections": [
///     {
///       "kind": "features",
///       "items": [
///         "Dark mode",
///         {"text": {"default": "Face ID sign-in", "ar": "..."}, "platforms": ["ios"]},
///         {"text": "Faster sync", "scope": "Sync"}
///       ]
///     },
///     {"kind": "fixes", "title": "Fixed", "items": ["Crash on start"]}
///   ]
/// }
/// ```
///
/// Instead of `sections`, a release may carry `markdown` with the body in
/// changelog Markdown, which [ChangelogParser] splits into sections. The
/// `sections` value may also be a map of kind to items:
/// `{"features": ["..."], "fixes": ["..."]}`. Keys are accepted in
/// `snake_case` and `camelCase`.
class ReleaseNoteJson {
  const ReleaseNoteJson._();

  /// Reads one release. Returns null when [json] has no usable version.
  static ReleaseNote? decode(
    Map<String, Object?> json, {
    ChangelogParser parser = const ChangelogParser(),
    String defaultLocale = 'en',
  }) {
    final version = ReleaseVersion.tryParse(
      _string(json, 'version') ?? _string(json, 'tag') ?? _string(json, 'name'),
    );
    if (version == null) return null;

    var sections = <ReleaseSection>[];
    final markdown =
        _string(json, 'markdown') ??
        _string(json, 'body') ??
        _string(json, 'notes');
    final rawSections = json['sections'];
    if (rawSections != null) {
      sections = _sections(rawSections, defaultLocale);
    } else if (markdown != null) {
      sections = parser.parseSections(markdown);
    }

    final title = json['title'];
    return ReleaseNote(
      version: version,
      date: _date(
        _string(json, 'date') ??
            _string(json, 'released_at') ??
            _string(json, 'published_at'),
      ),
      title:
          title == null
              ? null
              : LocalizedText.fromJson(title, defaultLocale: defaultLocale),
      sections: sections,
      url: _uri(_string(json, 'url') ?? _string(json, 'html_url')),
      downloadUrl: _uri(_string(json, 'download_url')),
      platforms: _platforms(json['platforms']),
    );
  }

  /// Reads a list of releases, or an object that wraps one under `releases`,
  /// `notes`, `items` or `data`. Entries without a version are skipped.
  static List<ReleaseNote> decodeList(
    Object? json, {
    ChangelogParser parser = const ChangelogParser(),
    String defaultLocale = 'en',
  }) {
    Object? list = json;
    if (json is Map) {
      list = json['releases'] ?? json['notes'] ?? json['items'] ?? json['data'];
    }
    if (list is! List) return const [];
    return list
        .whereType<Map<Object?, Object?>>()
        .map(
          (entry) => decode(
            entry.cast<String, Object?>(),
            parser: parser,
            defaultLocale: defaultLocale,
          ),
        )
        .whereType<ReleaseNote>()
        .toList(growable: false);
  }

  /// Writes one release in the shape [decode] reads.
  static Map<String, Object?> encode(ReleaseNote note) => <String, Object?>{
    'version': note.version.normalized,
    if (note.date != null) 'date': _formatDate(note.date!),
    if (note.title != null) 'title': note.title!.toJson(),
    if (note.url != null) 'url': note.url.toString(),
    if (note.downloadUrl != null) 'download_url': note.downloadUrl.toString(),
    if (note.platforms != null)
      'platforms': note.platforms!.map((platform) => platform.name).toList(),
    'sections': note.sections.map(_encodeSection).toList(),
  };

  /// Writes a list of releases.
  static List<Map<String, Object?>> encodeList(Iterable<ReleaseNote> notes) =>
      notes.map(encode).toList();

  static Map<String, Object?> _encodeSection(ReleaseSection section) =>
      <String, Object?>{
        'kind': section.kind.name,
        if (section.title != null) 'title': section.title!.toJson(),
        'items': section.items.map(_encodeItem).toList(),
      };

  static Object _encodeItem(ReleaseItem item) {
    if (item.scope == null &&
        !item.isNote &&
        item.platforms == null &&
        item.text.translations.isEmpty) {
      return item.text.text;
    }
    return <String, Object?>{
      'text': item.text.toJson(),
      if (item.scope != null) 'scope': item.scope,
      if (item.isNote) 'note': true,
      if (item.platforms != null)
        'platforms': item.platforms!.map((platform) => platform.name).toList(),
    };
  }

  static List<ReleaseSection> _sections(Object raw, String defaultLocale) {
    if (raw is List) {
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(
            (entry) => _section(entry.cast<String, Object?>(), defaultLocale),
          )
          .whereType<ReleaseSection>()
          .toList(growable: false);
    }
    if (raw is Map) {
      final sections = <ReleaseSection>[];
      raw.forEach((key, value) {
        if (key is! String) return;
        final kind = ReleaseSectionKind.fromName(key);
        final items = _items(value, defaultLocale);
        if (items.isEmpty) return;
        sections.add(
          ReleaseSection(
            kind: kind,
            title: kind == ReleaseSectionKind.other ? LocalizedText(key) : null,
            items: items,
          ),
        );
      });
      sections.sort((a, b) => a.kind.index.compareTo(b.kind.index));
      return sections;
    }
    return const [];
  }

  static ReleaseSection? _section(
    Map<String, Object?> json,
    String defaultLocale,
  ) {
    final items = _items(json['items'] ?? json['changes'], defaultLocale);
    if (items.isEmpty) return null;
    final title = json['title'];
    final kind = ReleaseSectionKind.fromName(
      _string(json, 'kind') ??
          _string(json, 'type') ??
          (title is String ? title : null),
    );
    return ReleaseSection(
      kind: kind,
      title:
          title == null
              ? null
              : LocalizedText.fromJson(title, defaultLocale: defaultLocale),
      items: items,
    );
  }

  static List<ReleaseItem> _items(Object? raw, String defaultLocale) {
    if (raw is! List) return const [];
    final items = <ReleaseItem>[];
    for (final entry in raw) {
      if (entry is String) {
        if (entry.trim().isNotEmpty) items.add(ReleaseItem.plain(entry));
      } else if (entry is Map) {
        final json = entry.cast<String, Object?>();
        final text = LocalizedText.fromJson(
          json['text'] ?? json['title'],
          defaultLocale: defaultLocale,
        );
        if (text.isEmpty) continue;
        items.add(
          ReleaseItem(
            text: text,
            scope: _string(json, 'scope'),
            isNote:
                json['note'] == true ||
                json['is_note'] == true ||
                json['isNote'] == true,
            platforms: _platforms(json['platforms']),
          ),
        );
      }
    }
    return items;
  }

  static Set<ReleasePlatform>? _platforms(Object? raw) {
    if (raw is String) return ReleasePlatform.tryParseList(raw);
    if (raw is! List) return null;
    final platforms =
        raw
            .whereType<String>()
            .map(ReleasePlatform.tryParse)
            .whereType<ReleasePlatform>()
            .toSet();
    return platforms.isEmpty ? null : platforms;
  }

  static String? _string(Map<String, Object?> json, String snakeKey) {
    final value = json[snakeKey] ?? json[_camel(snakeKey)];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static String _camel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join();
  }

  static DateTime? _date(String? text) {
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    // A date-only value is a calendar day; keep it local so it formats as
    // the day it names in every time zone.
    if (text.length <= 10) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return parsed.toLocal();
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static Uri? _uri(String? text) => text == null ? null : Uri.tryParse(text);
}
