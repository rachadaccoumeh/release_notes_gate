import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

ReleaseNote note(
  String version, {
  List<String> features = const [],
  List<String> fixes = const [],
}) => ReleaseNote(
  version: ReleaseVersion.parse(version),
  url: Uri.parse('https://example.com/releases/$version'),
  sections: [
    if (features.isNotEmpty)
      ReleaseSection(
        kind: ReleaseSectionKind.features,
        items: features.map(ReleaseItem.plain).toList(),
      ),
    if (fixes.isNotEmpty)
      ReleaseSection(
        kind: ReleaseSectionKind.fixes,
        items: fixes.map(ReleaseItem.plain).toList(),
      ),
  ],
);

final notes = [
  note('1.0.0', features: ['Launch']),
  note('1.1.0', fixes: ['Crash']),
  note('1.2.0', features: ['Dark mode', 'Sync']),
];

class LatestSource extends StaticReleaseNotesSource {
  const LatestSource(super.notes, this.latestNote);

  final ReleaseNote latestNote;

  @override
  Future<ReleaseNote?> latest() async => latestNote;
}

ReleaseNotesController controller({
  ReleaseNotesConfig config = const ReleaseNotesConfig(),
  String installed = '1.2.0',
  ReleaseVersion? seen,
  ReleaseNotesSource? source,
  ReleaseNotesCallbacks callbacks = const ReleaseNotesCallbacks(),
}) => ReleaseNotesController(
  source: source ?? StaticReleaseNotesSource(notes),
  config: config.copyWith(platformFilter: PlatformFilter.none),
  seenStore: MemorySeenVersionStore(seen),
  cache: MemoryReleaseNotesCache(),
  installedVersionLoader: () async => installed,
  callbacks: callbacks,
);

Widget app(Widget home, {double width = 400}) => MediaQuery(
  data: MediaQueryData(size: Size(width, 900), disableAnimations: true),
  child: MaterialApp(home: home),
);

void main() {
  testWidgets(
    'ReleaseNotesView shows What\'s new with a summary after an update and marks seen',
    (tester) async {
      final seenStore = MemorySeenVersionStore(ReleaseVersion.parse('1.0.0'));
      final c = ReleaseNotesController(
        source: StaticReleaseNotesSource(notes),
        config: const ReleaseNotesConfig(platformFilter: PlatformFilter.none),
        seenStore: seenStore,
        cache: MemoryReleaseNotesCache(),
        installedVersionLoader: () async => '1.2.0',
      );
      final decision = await c.check();
      expect(decision.shouldShow, isTrue);

      await tester.pumpWidget(
        app(Scaffold(body: ReleaseNotesView(controller: c, appName: 'Demo'))),
      );
      await tester.pumpAndSettle();

      expect(find.text("What's new"), findsOneWidget);
      expect(find.text('Demo · v1.2.0'), findsOneWidget);
      expect(find.text('2 new releases'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(seenStore.version, ReleaseVersion.parse('1.2.0'));
    },
  );

  testWidgets(
    'ReleaseNotesView shows An update is available with Release page and Update actions',
    (tester) async {
      final c = controller(
        config: const ReleaseNotesConfig(
          trigger: ReleaseNotesTrigger.onRemoteUpdate,
        ),
        installed: '1.0.0',
        source: LatestSource(notes, notes.last),
      );
      await c.check();
      await tester.pumpWidget(
        app(Scaffold(body: ReleaseNotesView(controller: c))),
      );
      await tester.pumpAndSettle();

      expect(find.text('An update is available'), findsOneWidget);
      expect(find.text('Release page'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Latest'), findsOneWidget);
      expect(find.text('Installed'), findsOneWidget);
    },
  );

  testWidgets(
    'showReleaseNotes opens a sheet on narrow and a dialog on wide windows and reports dismissal',
    (tester) async {
      var dismissed = 0;
      final c = controller(
        callbacks: ReleaseNotesCallbacks(onDismissed: (_) => dismissed++),
      );
      await c.open();

      for (final (width, finder) in [
        (400.0, find.byType(ReleaseNotesSheet)),
        (900.0, find.byType(ReleaseNotesDialog)),
      ]) {
        late BuildContext context;
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
            ),
            width: width,
          ),
        );
        final future = showReleaseNotes(context, controller: c);
        await tester.pumpAndSettle();
        expect(finder, findsOneWidget);
        expect(find.text('Changelog'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await future;
        expect(finder, findsNothing);
      }
      expect(dismissed, 2);
    },
  );

  testWidgets('ReleaseNotesGate presents the notes when the check says so', (
    tester,
  ) async {
    final c = controller(seen: ReleaseVersion.parse('1.0.0'));
    await tester.pumpWidget(
      app(
        ReleaseNotesGate(
          controller: c,
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(ReleaseNotesSheet), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
  });

  testWidgets('ReleaseNotesGate stays quiet when nothing is new', (
    tester,
  ) async {
    final c = controller(seen: ReleaseVersion.parse('1.2.0'));
    await tester.pumpWidget(
      app(
        ReleaseNotesGate(
          controller: c,
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReleaseNotesSheet), findsNothing);
  });

  testWidgets(
    'ReleaseNotesView shows the error state with Retry when loading fails',
    (tester) async {
      final c = ReleaseNotesController(
        source: const _FailingSource(),
        config: const ReleaseNotesConfig(
          cacheEnabled: false,
          platformFilter: PlatformFilter.none,
        ),
        seenStore: MemorySeenVersionStore(),
        installedVersionLoader: () async => '1.0.0',
      );
      await tester.pumpWidget(
        app(Scaffold(body: ReleaseNotesView(controller: c))),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('The release notes could not be loaded.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsWidgets);
    },
  );

  testWidgets('custom strings and builders replace the defaults', (
    tester,
  ) async {
    final c = controller();
    await c.open();
    await tester.pumpWidget(
      app(
        ReleaseNotesTheme(
          strings: const ReleaseNotesStrings(
            changelogTitle: 'سجل التغييرات',
            sectionNew: 'جديد',
          ),
          child: Scaffold(
            body: ReleaseNotesView(
              controller: c,
              footerBuilder:
                  (context, state, actions) => const Text('my footer'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('سجل التغييرات'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('my footer'), findsOneWidget);
    expect(find.text('Close'), findsNothing);
  });
}

class _FailingSource extends ReleaseNotesSource {
  const _FailingSource();

  @override
  Future<List<ReleaseNote>> fetch() async =>
      throw const ReleaseNotesException(
        'down',
        kind: ReleaseNotesErrorKind.network,
      );
}
