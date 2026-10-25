import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

const conventional = '''
# [2.2.0](https://github.com/acme/app/compare/v2.1.0...v2.2.0) (2026-10-25)


### Bug Fixes

* Fail patching that runs out of memory instead of hanging ([76b5477](https://github.com/acme/app/commit/76b5477eca7a97b393a95cc5880d90d1ab47354a))
* **Android:** Remote and D-pad navigation on TV ([2742b26](https://github.com/acme/app/commit/2742b263a4c71f541e361988b309831fcceca958))


### Features

* More apps card on the home screen ([a974389](https://github.com/acme/app/commit/a9743897cf69b5d38bbaa0c48410cb07bf756d02))
* Support export to PDF and CSV ([#1271](https://github.com/acme/app/issues/1271)) ([8017b79](https://github.com/acme/app/commit/8017b792d9ba3e610058d784709cfa54f502094a))
* **Login - Face ID:** Sign in with `FaceID` on supported devices

### Performance Improvements

* Faster startup

# [2.2.0-dev.4](https://github.com/acme/app/compare/v2.2.0-dev.3...v2.2.0-dev.4) (2026-10-25)


### Bug Fixes

* Give the patcher more memory on 64-bit devices ([77af30c](https://github.com/acme/app/commit/77af30c2e2711d6b745ffa435a5a7fa534277449))

# 2.1.0 (2026-09-01)

### Features

* First feature
''';

const keepAChangelog = '''
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Something not yet shipped

## [1.4.0] - 2024-03-01

### Added
- Dark mode
- [iOS] Face ID sign-in

### Fixed
- Crash on start

### Security
- Rotate keys

## [1.3.0] - 2024-01-15

- Flat bullet without a section
Some prose explaining the release.
''';

const pubDev = '''
## 0.3.2

* Fix a typo in the README.

## 0.3.1

* **BREAKING**: Rename `foo` to `bar`.
''';

void main() {
  const parser = ChangelogParser();

  group('ChangelogParser.parse conventional-changelog', () {
    final notes = parser.parse(conventional);

    test('finds every version with its date', () {
      expect(notes.map((n) => n.version.normalized), [
        '2.2.0',
        '2.2.0-dev.4',
        '2.1.0',
      ]);
      expect(notes.first.date, DateTime(2026, 10, 25));
      expect(notes[1].isPrerelease, isTrue);
      expect(notes.last.date, DateTime(2026, 9, 1));
    });

    test('orders sections features first and maps the headings', () {
      final kinds = notes.first.sections.map((s) => s.kind).toList();
      expect(kinds, [
        ReleaseSectionKind.features,
        ReleaseSectionKind.fixes,
        ReleaseSectionKind.performance,
      ]);
      expect(notes.first.counts, {
        ReleaseSectionKind.features: 3,
        ReleaseSectionKind.fixes: 2,
        ReleaseSectionKind.performance: 1,
      });
    });

    test('strips commit links but keeps issue links', () {
      final features = notes.first.sections.first;
      expect(features.items[0].text.text, 'More apps card on the home screen');
      expect(
        features.items[1].text.text,
        'Support export to PDF and CSV ([#1271](https://github.com/acme/app/issues/1271))',
      );
    });

    test('reads scopes and tags platform scopes', () {
      final fixes = notes.first.sections[1];
      expect(fixes.items[1].scope, 'Android');
      expect(fixes.items[1].platforms, {ReleasePlatform.android});
      expect(fixes.items[1].text.text, 'Remote and D-pad navigation on TV');
      final login = notes.first.sections.first.items[2];
      expect(login.scope, 'Login - Face ID');
      expect(login.platforms, isNull);
    });

    test('builds release urls on request', () {
      final withUrls = parser.parse(
        conventional,
        urlBuilder: (v) => Uri.parse('https://example.com/${v.withPrefix}'),
      );
      expect(withUrls.first.url, Uri.parse('https://example.com/v2.2.0'));
    });
  });

  group('ChangelogParser.parse keep-a-changelog', () {
    final notes = parser.parse(keepAChangelog);

    test('skips Unreleased and the file preamble', () {
      expect(notes.map((n) => n.version.normalized), ['1.4.0', '1.3.0']);
      expect(notes.first.date, DateTime(2024, 3, 1));
    });

    test('maps Added and Fixed, keeps Security as other with its title', () {
      final sections = notes.first.sections;
      expect(sections.map((s) => s.kind), [
        ReleaseSectionKind.features,
        ReleaseSectionKind.fixes,
        ReleaseSectionKind.other,
      ]);
      expect(sections.last.title?.text, 'Security');
    });

    test('reads a leading platform tag', () {
      final faceId = notes.first.sections.first.items[1];
      expect(faceId.text.text, 'Face ID sign-in');
      expect(faceId.platforms, {ReleasePlatform.ios});
    });

    test('keeps bullets before any heading and prose as notes', () {
      final section = notes.last.sections.single;
      expect(section.kind, ReleaseSectionKind.other);
      expect(section.title, isNull);
      expect(section.items[0].isChange, isTrue);
      expect(section.items[1].isNote, isTrue);
      expect(section.changeCount, 1);
    });
  });

  group('ChangelogParser.parse pub.dev style', () {
    test('reads versions without dates or links', () {
      final notes = parser.parse(pubDev);
      expect(notes.map((n) => n.version.normalized), ['0.3.2', '0.3.1']);
      expect(notes.first.date, isNull);
      expect(notes.last.sections.single.items.single.scope, 'BREAKING');
    });
  });

  group('ChangelogParser.parseSections', () {
    test('drops noise, images, quotes and code fences', () {
      final sections = parser.parseSections('''
> ### Features
> * One ![shot](https://x/y.png)
---
```
code
```
<details>
* Two
<<<<<<< HEAD
Signed-off-by: someone
''');
      expect(sections.single.items.map((i) => i.text.text), ['One', 'Two']);
    });

    test('accepts a bold scope with the colon outside', () {
      final sections = parser.parseSections('* **Sync**: Faster');
      expect(sections.single.items.single.scope, 'Sync');
      expect(sections.single.items.single.text.text, 'Faster');
    });

    test('strips emoji decorations from headings', () {
      final sections = parser.parseSections('### 🐛 Bug Fixes\n* A');
      expect(sections.single.kind, ReleaseSectionKind.fixes);
      expect(sections.single.title?.text, 'Bug Fixes');
    });

    test('keeps the file order when sorting is off', () {
      const unsorted = ChangelogParser(sortSections: false);
      final sections = unsorted.parseSections(
        '### Bug Fixes\n* A\n### Features\n* B',
      );
      expect(sections.map((s) => s.kind), [
        ReleaseSectionKind.fixes,
        ReleaseSectionKind.features,
      ]);
    });
  });

  group('inline markup', () {
    test('splits code, bold, links and text', () {
      final spans = parseInlineMarkup(
        'Use `foo` and **bar** at [docs](https://d.io) now',
      );
      expect(spans, const [
        InlineMarkupSpan(InlineMarkupKind.text, 'Use '),
        InlineMarkupSpan(InlineMarkupKind.code, 'foo'),
        InlineMarkupSpan(InlineMarkupKind.text, ' and '),
        InlineMarkupSpan(InlineMarkupKind.bold, 'bar'),
        InlineMarkupSpan(InlineMarkupKind.text, ' at '),
        InlineMarkupSpan(InlineMarkupKind.link, 'docs', url: 'https://d.io'),
        InlineMarkupSpan(InlineMarkupKind.text, ' now'),
      ]);
      expect(stripInlineMarkup('Use `foo` and **bar**'), 'Use foo and bar');
    });
  });
}
