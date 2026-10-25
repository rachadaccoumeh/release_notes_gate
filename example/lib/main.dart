import 'package:flutter/material.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

import 'sample_notes.dart';

void main() => runApp(const DemoApp());

/// Which look the demo uses.
enum DemoTheme { light, dark, midnight }

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  DemoTheme _theme = DemoTheme.midnight;
  ReleaseNotesPresentation _presentation = ReleaseNotesPresentation.adaptive;

  // A list in code, so the demo runs offline. Swap for any other source:
  //   GitHubReleaseNotesSource(owner: 'you', repo: 'your-app')
  //   HttpReleaseNotesSource(uri: Uri.parse('https://api.example.com/releases'))
  //   MarkdownChangelogSource.asset('assets/CHANGELOG.md')
  late final ReleaseNotesController _whatsNew = ReleaseNotesController(
    source: StaticReleaseNotesSource(sampleNotes),
    config: const ReleaseNotesConfig(
      // The demo pretends to run 1.2.0 (see pubspec.yaml); the seen version
      // is cleared by the button below so the sheet shows again.
      installedVersion: null,
      showOnFirstInstall: true,
    ),
    callbacks: ReleaseNotesCallbacks(
      onShown: (decision) => debugPrint('shown: $decision'),
      onDismissed: (decision) => debugPrint('dismissed: $decision'),
      onActionTap: (id) => debugPrint('action: $id'),
    ),
  );

  // The same notes as an "update available" flow: the source says 1.4.0 is
  // out, the app runs 1.2.0.
  late final ReleaseNotesController _update = ReleaseNotesController(
    source: _LatestOverride(sampleNotes, sampleNotes.newestFirst.first),
    config: const ReleaseNotesConfig(
      trigger: ReleaseNotesTrigger.onRemoteUpdate,
    ),
    seenStore: MemorySeenVersionStore(),
    cache: MemoryReleaseNotesCache(),
  );

  // Reads the package's own CHANGELOG.md from GitHub.
  late final ReleaseNotesController _github = ReleaseNotesController(
    source: GitHubReleaseNotesSource(
      owner: 'rachadaccoumeh',
      repo: 'release_notes_gate',
    ),
    config: const ReleaseNotesConfig(trigger: ReleaseNotesTrigger.manual),
    seenStore: MemorySeenVersionStore(),
  );

  @override
  void dispose() {
    _whatsNew.dispose();
    _update.dispose();
    _github.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      colorSchemeSeed: const Color(0xFF3B6FD8),
      useMaterial3: true,
    );
    final dark = ThemeData(
      colorSchemeSeed: const Color(0xFF3B6FD8),
      brightness: Brightness.dark,
      useMaterial3: true,
    );
    final midnight = ReleaseNotesThemeData.midnight();
    return MaterialApp(
      title: 'Release notes demo',
      debugShowCheckedModeBanner: false,
      theme: switch (_theme) {
        DemoTheme.light => light,
        DemoTheme.dark => dark,
        DemoTheme.midnight => dark.copyWith(
          scaffoldBackgroundColor: midnight.backgroundColor,
          extensions: [midnight],
        ),
      },
      // The gate runs the trigger after the first frame and shows the notes
      // once per version. It needs a Navigator above it, so it wraps home.
      home: ReleaseNotesGate(
        controller: _whatsNew,
        presentation: _presentation,
        appName: 'Demo',
        child: DemoHome(
          whatsNew: _whatsNew,
          update: _update,
          github: _github,
          theme: _theme,
          presentation: _presentation,
          onTheme: (theme) => setState(() => _theme = theme),
          onPresentation:
              (presentation) => setState(() => _presentation = presentation),
        ),
      ),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({
    super.key,
    required this.whatsNew,
    required this.update,
    required this.github,
    required this.theme,
    required this.presentation,
    required this.onTheme,
    required this.onPresentation,
  });

  final ReleaseNotesController whatsNew;
  final ReleaseNotesController update;
  final ReleaseNotesController github;
  final DemoTheme theme;
  final ReleaseNotesPresentation presentation;
  final ValueChanged<DemoTheme> onTheme;
  final ValueChanged<ReleaseNotesPresentation> onPresentation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Release notes demo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: 'Flows',
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text("What's new after an update"),
                onPressed: () async {
                  await whatsNew.resetSeen();
                  final decision = await whatsNew.check();
                  if (!context.mounted) return;
                  if (decision.shouldShow) {
                    await showReleaseNotes(
                      context,
                      controller: whatsNew,
                      presentation: presentation,
                      appName: 'Demo',
                    );
                  }
                },
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.system_update_alt_rounded),
                label: const Text('An update is available'),
                onPressed: () async {
                  final decision = await update.check();
                  if (!context.mounted) return;
                  if (decision.shouldShow) {
                    await showReleaseNotes(
                      context,
                      controller: update,
                      presentation: presentation,
                      appName: 'Demo',
                      // In a store app, send the user to the store here.
                      onUpdate:
                          (context, latest) => ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Open the store for ${latest?.version.withPrefix}',
                              ),
                            ),
                          ),
                    );
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.history_rounded),
                label: const Text('Full changelog'),
                onPressed: () async {
                  await whatsNew.open();
                  if (!context.mounted) return;
                  await showReleaseNotes(
                    context,
                    controller: whatsNew,
                    presentation: presentation,
                    appName: 'Demo',
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Changelog from GitHub (needs network)'),
                onPressed: () async {
                  await github.open();
                  if (!context.mounted) return;
                  await showReleaseNotes(
                    context,
                    controller: github,
                    presentation: presentation,
                    appName: 'release_notes_gate',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Look',
            children: [
              SegmentedButton<DemoTheme>(
                segments: const [
                  ButtonSegment(value: DemoTheme.light, label: Text('Light')),
                  ButtonSegment(value: DemoTheme.dark, label: Text('Dark')),
                  ButtonSegment(
                    value: DemoTheme.midnight,
                    label: Text('Midnight'),
                  ),
                ],
                selected: {theme},
                onSelectionChanged: (s) => onTheme(s.first),
              ),
              SegmentedButton<ReleaseNotesPresentation>(
                segments: const [
                  ButtonSegment(
                    value: ReleaseNotesPresentation.adaptive,
                    label: Text('Adaptive'),
                  ),
                  ButtonSegment(
                    value: ReleaseNotesPresentation.sheet,
                    label: Text('Sheet'),
                  ),
                  ButtonSegment(
                    value: ReleaseNotesPresentation.dialog,
                    label: Text('Dialog'),
                  ),
                ],
                selected: {presentation},
                onSelectionChanged: (s) => onPresentation(s.first),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'One piece, anywhere',
            children: [
              // Every widget works on its own with plain model data.
              ReleaseNotesSummaryCard(
                notes: sampleNotes.newerThan(ReleaseVersion.parse('1.1.0')),
                from: ReleaseVersion.parse('1.1.0'),
                to: sampleNotes.newestFirst.first.version,
              ),
              const SizedBox(height: 16),
              ReleaseSectionCard(
                section: sampleNotes.newestFirst.first.sections.first,
              ),
              const SizedBox(height: 16),
              ReleaseCard(
                note: sampleNotes.newestFirst[1],
                showRail: false,
                initiallyExpanded: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Headless',
            children: [
              // Or skip the widgets and read the controller.
              ListenableBuilder(
                listenable: whatsNew,
                builder: (context, _) {
                  final state = whatsNew.state;
                  final total = state.notes.fold(
                    0,
                    (sum, note) => sum + note.changeCount,
                  );
                  return Text(
                    '${state.notes.length} releases · $total changes · installed ${state.installedVersion?.withPrefix ?? '?'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }
}

/// A static source that reports a chosen note as the latest release, so the
/// update flow can be tried offline.
class _LatestOverride extends StaticReleaseNotesSource {
  const _LatestOverride(super.notes, this.latestNote);

  final ReleaseNote latestNote;

  @override
  Future<ReleaseNote?> latest() async => latestNote;
}
