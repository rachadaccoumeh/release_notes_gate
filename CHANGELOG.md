# Changelog

## Unreleased

### Changes

* A timeline with a single release draws no rail, so its cards take the full width

## 0.1.0

### Features

* Model: `ReleaseNote`, `ReleaseSection`, `ReleaseItem`, `ReleaseVersion`, `LocalizedText`, `ReleasePlatform`
* `ChangelogParser` for conventional-changelog, Keep a Changelog and pub.dev style Markdown
* Sources: `GitHubReleaseNotesSource`, `MarkdownChangelogSource`, `HttpReleaseNotesSource`, `StaticReleaseNotesSource`
* `ReleaseNotesController` with the `onVersionChange`, `onRemoteUpdate` and `manual` triggers
* Last-seen version store and offline cache on `shared_preferences`
* Platform filter with a toggle, localized texts, analytics callbacks
* Timeline UI: summary card, release cards, section cards, badges, pills, shimmer loading, error view
* `ReleaseNotesSheet`, `ReleaseNotesDialog`, adaptive `showReleaseNotes`, `ReleaseNotesGate`
* `ReleaseNotesThemeData` derived from the app theme, with a `midnight` preset, and `ReleaseNotesStrings`
