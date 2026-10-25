import '../model/localized_text.dart';
import '../model/release_item.dart';
import '../model/release_note.dart';
import '../model/release_platform.dart';
import '../model/release_section.dart';
import '../model/release_version.dart';

/// Parses `CHANGELOG.md` files and release bodies into [ReleaseNote]s.
///
/// Understands the headings of conventional-changelog, Keep a Changelog and
/// plain pub.dev changelogs:
///
/// ```markdown
/// # [2.2.0](https://.../compare/v2.1.0...v2.2.0) (2026-10-25)
/// ## [1.4.0] - 2024-03-01
/// ## 1.4.0
/// ```
///
/// Inside a release, `### Features`, `### Bug Fixes` and the other headings
/// split the bullets into sections. A bullet may start with a bold scope,
/// `* **Login:** text`, and a scope or a leading `[android]` tag that names
/// a platform tags the change for that platform. Commit links, images,
/// rules, code fences and merge markers are removed. Lines of prose between
/// bullets become notes.
class ChangelogParser {
  /// Creates a parser.
  ///
  /// With [platformScopes] on, a scope such as `**Android:**` or
  /// `**iOS, Web:**` tags the change for those platforms. With
  /// [sortSections] on, sections come in [ReleaseSectionKind] order, features
  /// first, whatever order the file wrote them in.
  const ChangelogParser({this.platformScopes = true, this.sortSections = true});

  /// Whether a scope that names a platform tags the change for it.
  final bool platformScopes;

  /// Whether sections are ordered features first.
  final bool sortSections;

  static final RegExp _heading = RegExp(r'^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$');
  static final RegExp _linkedToken = RegExp(r'\[([^\]]+)\](?:\([^)]*\))?');
  static final RegExp _date = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
  static final RegExp _bareVersion = RegExp(r'^[vV]?\d+\.\d+[\w.\-+]*$');
  static final RegExp _commitLink = RegExp(
    r'\s*\(\[[0-9a-f]{7,}\]\([^)]+/commit/[^)]+\)\)',
  );
  static final RegExp _image = RegExp(r'!\[[^\]]*\]\([^)]*\)');
  static final RegExp _quotePrefix = RegExp(r'^\s*>\s?');
  static final RegExp _noiseLine = RegExp(
    r'^\s*(?:[-=_*~]{3,}|[<=>]{7}.*|```.*|<[^>]+>|(?:signed-off-by|co-authored-by):.*)\s*$',
    caseSensitive: false,
  );
  static final RegExp _fence = RegExp(r'^\s*(?:```|~~~)');
  static final RegExp _listItem = RegExp(r'^\s*(?:[*+-]|\d+[.)])\s+(.+?)\s*$');
  static final RegExp _scopedBody = RegExp(
    r'^\*\*(.+?)(?::\*\*|\*\*:)\s*(.*)$',
  );
  static final RegExp _platformTag = RegExp(r'^\[([^\]]+)\]\s*:?\s*(.+)$');
  static final RegExp _platformSplit = RegExp(r'[,/&+]|\band\b');
  static final RegExp _onlySuffix = RegExp(r'\s*only$', caseSensitive: false);
  static final RegExp _unreleased = RegExp(
    r'\bunreleased\b',
    caseSensitive: false,
  );
  static final RegExp _decoration = RegExp(r'^[^\p{L}\p{N}]+', unicode: true);

  /// Parses a whole changelog into notes, newest first as the file lists
  /// them. Headings that carry no version, such as `Unreleased`, are
  /// skipped with their content.
  ///
  /// [urlBuilder] can give each note a release page, for example the GitHub
  /// release of its tag.
  List<ReleaseNote> parse(
    String markdown, {
    Uri? Function(ReleaseVersion version)? urlBuilder,
  }) {
    final notes = <ReleaseNote>[];
    _VersionHeading? current;
    final content = StringBuffer();

    void flush() {
      final heading = current;
      if (heading == null) return;
      notes.add(
        ReleaseNote(
          version: heading.version,
          date: heading.date,
          sections: parseSections(content.toString()),
          url: urlBuilder?.call(heading.version),
        ),
      );
    }

    var skipping = false;
    for (final line in markdown.split('\n')) {
      final heading = _heading.firstMatch(line);
      if (heading != null && heading.group(1)!.length <= 3) {
        final parsed = _parseVersionHeading(heading.group(2)!);
        if (parsed != null) {
          flush();
          current = parsed;
          content.clear();
          skipping = false;
          continue;
        }
        if (_unreleased.hasMatch(heading.group(2)!)) {
          flush();
          current = null;
          skipping = true;
          continue;
        }
      }
      if (!skipping && current != null) content.writeln(line);
    }
    flush();
    return notes;
  }

  /// Splits the body of one release into sections. Changes ahead of the
  /// first heading form a section without a title.
  List<ReleaseSection> parseSections(String body) {
    final sections = <ReleaseSection>[];
    String? title;
    var items = <ReleaseItem>[];

    void flush() {
      if (items.isEmpty) return;
      sections.add(
        ReleaseSection(
          kind: ReleaseSectionKind.fromTitle(title),
          title: title == null ? null : LocalizedText(title),
          items: items,
        ),
      );
      items = <ReleaseItem>[];
    }

    final cleaned = body.replaceAll(_commitLink, '').replaceAll(_image, '');
    var inFence = false;
    for (final rawLine in cleaned.split('\n')) {
      final line = rawLine.replaceFirst(_quotePrefix, '');
      if (_fence.hasMatch(line)) {
        inFence = !inFence;
        continue;
      }
      if (inFence || line.trim().isEmpty || _noiseLine.hasMatch(line)) continue;

      final heading = _heading.firstMatch(line);
      if (heading != null) {
        flush();
        title = _stripDecoration(heading.group(2)!);
        continue;
      }

      final item = _listItem.firstMatch(line);
      if (item == null) {
        items.add(ReleaseItem.plain(line.trim(), isNote: true));
        continue;
      }
      items.add(_parseItem(item.group(1)!));
    }
    flush();

    if (!sortSections) return sections;
    final indexed = sections.indexed.toList();
    indexed.sort((a, b) {
      final byKind = a.$2.kind.index.compareTo(b.$2.kind.index);
      return byKind != 0 ? byKind : a.$1.compareTo(b.$1);
    });
    return indexed.map((entry) => entry.$2).toList(growable: false);
  }

  ReleaseItem _parseItem(String body) {
    String? scope;
    var text = body;
    Set<ReleasePlatform>? platforms;

    final scoped = _scopedBody.firstMatch(body);
    if (scoped != null) {
      scope = scoped.group(1)!.trim();
      text = scoped.group(2)!.trim();
      if (platformScopes) platforms = _platformsOf(scope);
    }

    final tagged = _platformTag.firstMatch(text);
    if (tagged != null && platformScopes) {
      final tagPlatforms = _platformsOf(tagged.group(1)!);
      if (tagPlatforms != null) {
        platforms = {...?platforms, ...tagPlatforms};
        text = tagged.group(2)!.trim();
      }
    }

    return ReleaseItem.plain(text, scope: scope, platforms: platforms);
  }

  /// The platforms a scope names, when every part of it is a platform.
  /// `Android` and `iOS, Web` qualify; `YouTube - Hide ads` does not.
  static Set<ReleasePlatform>? _platformsOf(String scope) {
    final parts = scope
        .split(_platformSplit)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    final platforms = <ReleasePlatform>{};
    for (final part in parts) {
      final platform = ReleasePlatform.tryParse(
        part.replaceAll(_onlySuffix, ''),
      );
      if (platform == null) return null;
      platforms.add(platform);
    }
    return platforms.isEmpty ? null : platforms;
  }

  static String _stripDecoration(String title) {
    final stripped = title.replaceFirst(_decoration, '').trim();
    return stripped.isEmpty ? title.trim() : stripped;
  }

  _VersionHeading? _parseVersionHeading(String heading) {
    ReleaseVersion? version;
    for (final match in _linkedToken.allMatches(heading)) {
      version = _versionToken(match.group(1)!);
      if (version != null) break;
    }
    if (version == null) {
      final plain = heading.replaceAll(_linkedToken, ' ');
      for (final token in plain.split(RegExp(r'\s+'))) {
        version = _versionToken(token);
        if (version != null) break;
      }
    }
    if (version == null) return null;

    DateTime? date;
    final dateMatch = _date.firstMatch(heading);
    if (dateMatch != null) {
      date = DateTime(
        int.parse(dateMatch.group(1)!),
        int.parse(dateMatch.group(2)!),
        int.parse(dateMatch.group(3)!),
      );
    }
    return _VersionHeading(version, date);
  }

  static ReleaseVersion? _versionToken(String token) {
    final trimmed = token.trim();
    if (!_bareVersion.hasMatch(trimmed)) return null;
    return ReleaseVersion.tryParse(trimmed);
  }
}

class _VersionHeading {
  const _VersionHeading(this.version, this.date);

  final ReleaseVersion version;
  final DateTime? date;
}
