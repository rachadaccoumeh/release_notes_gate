# release_notes_gate

Release notes and "what's new" for Flutter apps.

Read the notes from **GitHub Releases and `CHANGELOG.md`**, your own **REST API**, a **Markdown file**, or a list in code. Show them **once after an update**, as an **"update available"** summary, or as a **changelog page**. The timeline UI matches the look of a modern update dialog and is themeable piece by piece, or replaceable as a whole.

Runs on Android, iOS, web, Windows, macOS and Linux.

## Features

- **Sources**: GitHub (Releases API + raw `CHANGELOG.md`, with fallback), HTTP JSON, Markdown from a URL, an asset or a string, and a static list. One small interface for anything else.
- **Parser**: understands conventional-changelog (`# [2.2.0](...) (2026-10-25)`, `### Features`, `### Bug Fixes`), Keep a Changelog (`## [1.4.0] - 2024-03-01`, `### Added`) and plain pub.dev changelogs. Strips commit links, images and noise. Reads `**Scope:**` bullets.
- **Triggers**: show after the app was updated (default), when the source has a newer release, or only by hand.
- **Platform filter**: tag a change `[iOS]` or give it `**Android:**` as scope, or set `platforms` in JSON. Users see their platform's changes with a switch to see all.
- **Localized text**: any text can be a map of locale to string, with a fallback.
- **Offline cache**: the last fetched notes stay readable without network. On by default, one flag to turn off.
- **Callbacks**: loaded, error, decision, shown, dismissed, action tap, release toggled, link tap.
- **UI**: summary card (version step, release count, count pills), timeline with rail and nodes, release cards with Latest / Installed / Pre-release badges, section cards with icons and counts, inline code chips, bold and links, shimmer loading, error state with retry, bottom sheet and dialog, adaptive picker, and a gate widget that runs the check after the first frame.
- **Theming**: `ReleaseNotesThemeData.fromTheme` derives everything from your `ThemeData`; override any value with `copyWith`, or use the dark `midnight` preset. All strings in `ReleaseNotesStrings`.
- **Accessibility**: semantic labels and headers, 48 dp tap targets, text scaling, RTL, reduced motion.

Adapters: [`firestore_release_notes`](https://pub.dev/packages/firestore_release_notes) and [`supabase_release_notes`](https://pub.dev/packages/supabase_release_notes) add one source class each on top of this package.

## Quick start

```dart
import 'package:release_notes_gate/release_notes_gate.dart';

final controller = ReleaseNotesController(
  source: GitHubReleaseNotesSource(owner: 'your-user', repo: 'your-app'),
);

MaterialApp(
  home: ReleaseNotesGate(
    controller: controller,
    appName: 'Your app',
    child: const HomePage(),
  ),
);
```

That is the whole "what's new" flow: on the first launch after an update, a bottom sheet (or a dialog on wide windows) shows the notes of the versions the user skipped, once.

### Pick a source

```dart
// GitHub: CHANGELOG.md on main, Releases API for the latest version.
GitHubReleaseNotesSource(owner: 'acme', repo: 'app', branch: 'main', tagPrefix: 'v');

// GitHub release bodies instead of the file:
GitHubReleaseNotesSource(owner: 'acme', repo: 'app', origin: GitHubNotesOrigin.releases);

// Your API, in the JSON shape below (or pass a `mapper`):
HttpReleaseNotesSource(
  uri: Uri.parse('https://api.example.com/releases'),
  headersBuilder: () async => {'Authorization': 'Bearer ${await token()}'},
);

// A Markdown changelog from anywhere:
MarkdownChangelogSource.url(Uri.parse('https://example.com/CHANGELOG.md'));
MarkdownChangelogSource.asset('assets/CHANGELOG.md');

// A list in code:
StaticReleaseNotesSource.json([{ 'version': '1.0.0', 'sections': {'features': ['Hello']} }]);
```

Anything else: extend `ReleaseNotesSource` and implement `fetch()`.

### Pick a trigger

```dart
ReleaseNotesConfig(
  trigger: ReleaseNotesTrigger.onVersionChange, // default: after an app update
  // trigger: ReleaseNotesTrigger.onRemoteUpdate, // when a newer release exists
  // trigger: ReleaseNotesTrigger.manual,          // only when you call open()
  platformFilter: PlatformFilter.currentWithToggle,
  cacheEnabled: true,
  showOnFirstInstall: false,
)
```

### Open the changelog from a menu

```dart
await controller.open();
await showReleaseNotes(context, controller: controller, appName: 'Your app');
```

`showReleaseNotes` picks a sheet under 600 dp and a dialog above. Force one with `presentation: ReleaseNotesPresentation.sheet` or `.dialog`.

### "Update available" like a self-updating app

```dart
final controller = ReleaseNotesController(
  source: GitHubReleaseNotesSource(owner: 'acme', repo: 'app'),
  config: const ReleaseNotesConfig(trigger: ReleaseNotesTrigger.onRemoteUpdate),
);

ReleaseNotesGate(
  controller: controller,
  onUpdate: (context, latest) => openStore(), // or let the default open the download link
  child: const HomePage(),
);
```

The summary card shows installed → latest, the number of new releases and the counts of features, fixes and optimizations. The footer offers the release page and Download (or Update).

## JSON shape

Used by `HttpReleaseNotesSource`, the cache and the Firestore and Supabase adapters. One object per release:

```json
{
  "version": "2.2.0",
  "date": "2026-10-25",
  "title": {"default": "Autumn release", "ar": "إصدار الخريف"},
  "url": "https://example.com/releases/2.2.0",
  "download_url": "https://example.com/app-2.2.0.apk",
  "platforms": ["android", "ios"],
  "sections": {
    "features": [
      "Dark mode",
      {"text": {"default": "Face ID sign-in", "ar": "..."}, "platforms": ["ios"]},
      {"text": "Faster sync", "scope": "Sync"}
    ],
    "fixes": ["Crash on start"],
    "Notes": [{"text": "Android 7 is no longer supported.", "note": true}]
  }
}
```

- `sections` may be a map of kind to items (above) or a list of `{kind, title, items}`.
- Kinds: `features`, `fixes`, `improvements`, `performance`. Any other key is a custom section that keeps its name.
- Instead of `sections`, `markdown` may hold the body in changelog Markdown.
- Any text may be a string or a map of locale to string.
- Keys are accepted in `snake_case` and `camelCase`.

## Theming

Nothing to do for the default: colours, text styles, radii and spacing come from your `ThemeData`.

```dart
// Tweak:
ReleaseNotesTheme(
  data: ReleaseNotesTheme.of(context).copyWith(cardRadius: 12, warning: myOrangeTone),
  strings: const ReleaseNotesStrings(whatsNewTitle: 'Neu in dieser Version'),
  child: ...,
);

// Or register once as a ThemeExtension:
ThemeData(extensions: [ReleaseNotesThemeData.midnight()]);
```

Every geometry value is a field: rail width, node radius, card radius, item padding, preview size, durations, curve. Replacing a tone (`primary`, `success`, `warning`, `neutral`) recolours the sections that use it.

## Use the pieces, or none of them

Each widget works on its own with plain model data:

```dart
ReleaseNotesSummaryCard(notes: newNotes, from: oldVersion, to: newVersion);
ReleaseNotesTimeline(notes: notes, installedVersion: installed);
ReleaseCard(note: note, showRail: false);
ReleaseSectionCard(section: note.sections.first);
ReleaseItemRow(item: item, dotColor: Colors.blue);
VersionBadge(text: 'v2.2.0');
CountPill(text: '8 features', icon: Icons.auto_awesome, tone: tone);
```

`ReleaseNotesView` takes builders for the header, footer, summary, releases, sections, loading, error and empty states. Or ignore the widgets and read `controller.state` in a `ListenableBuilder`:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => Text('${controller.state.notes.length} releases'),
);
```

## Changelog conventions the parser reads

```markdown
# [2.2.0](https://github.com/acme/app/compare/v2.1.0...v2.2.0) (2026-10-25)

### Features

* **Login:** Sign in with `FaceID`
* [iOS] Haptics on success

### Bug Fixes

* **Android:** Back button on TV

## [2.1.0] - 2026-09-01

### Added
- First feature
```

- Version headings: `# [x.y.z](url) (date)`, `## [x.y.z] - date`, `## x.y.z`. `Unreleased` is skipped.
- Sections: `Features`, `New`, `Added` → features. `Bug Fixes`, `Fixes`, `Fixed` → fixes. `Improvements`, `Changed` → improvements. `Performance` → performance. Anything else keeps its heading.
- `**Scope:** text` gives a scope. A scope or a leading `[tag]` that names a platform (`Android`, `iOS`, `Web`, `Windows`, `macOS`, `Linux`) tags the change for it.
- Commit links `([abc1234](.../commit/...))`, images, rules, code fences and merge markers are removed. Issue links stay.

## Example

The `example/` app shows the three flows, the three looks, sheet versus dialog, single pieces on a page, and the headless controller.

## License

MIT
