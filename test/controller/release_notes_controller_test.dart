import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

ReleaseNote note(
  String version, {
  List<String> features = const [],
  List<String> fixes = const [],
}) => ReleaseNote(
  version: ReleaseVersion.parse(version),
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
  note('1.2.0-beta.1', features: ['Beta thing']),
  note('1.2.0', features: ['Dark mode', 'Sync'], fixes: ['Login']),
  note('1.3.0', features: ['Search']),
];

class FailingSource extends ReleaseNotesSource {
  const FailingSource();

  @override
  Future<List<ReleaseNote>> fetch() async =>
      throw const ReleaseNotesException(
        'down',
        kind: ReleaseNotesErrorKind.network,
      );
}

class LatestSource extends StaticReleaseNotesSource {
  const LatestSource(super.notes, this.latestNote);

  final ReleaseNote? latestNote;

  @override
  Future<ReleaseNote?> latest() async => latestNote;
}

ReleaseNotesController controller({
  ReleaseNotesSource source = const StaticReleaseNotesSource([]),
  ReleaseNotesConfig config = const ReleaseNotesConfig(),
  String installed = '1.2.0',
  MemorySeenVersionStore? seen,
  ReleaseNotesCache? cache,
  ReleaseNotesCallbacks callbacks = const ReleaseNotesCallbacks(),
}) => ReleaseNotesController(
  source: source,
  config: config.copyWith(platformFilter: PlatformFilter.none),
  seenStore: seen ?? MemorySeenVersionStore(),
  cache: cache ?? MemoryReleaseNotesCache(),
  installedVersionLoader: () async => installed,
  callbacks: callbacks,
);

void main() {
  group('onVersionChange', () {
    test('first launch stores the version and shows nothing', () async {
      final seen = MemorySeenVersionStore();
      final c = controller(source: StaticReleaseNotesSource(notes), seen: seen);
      final decision = await c.check();
      expect(decision.shouldShow, isFalse);
      expect(seen.version, ReleaseVersion.parse('1.2.0'));
      expect(
        c.state.status,
        ReleaseNotesStatus.idle,
        reason: 'no fetch needed',
      );
    });

    test('first launch shows all notes when configured', () async {
      final c = controller(
        source: StaticReleaseNotesSource(notes),
        config: const ReleaseNotesConfig(showOnFirstInstall: true),
      );
      final decision = await c.check();
      expect(decision.reason, ReleaseNotesReason.newVersionInstalled);
      expect(decision.notes.map((n) => n.version.normalized), [
        '1.2.0',
        '1.1.0',
        '1.0.0',
      ]);
      expect(decision.from, isNull);
      expect(decision.to, ReleaseVersion.parse('1.2.0'));
    });

    test(
      'after an update shows the versions in between, newest first',
      () async {
        final seen = MemorySeenVersionStore(ReleaseVersion.parse('1.0.0'));
        final c = controller(
          source: StaticReleaseNotesSource(notes),
          seen: seen,
        );
        final decision = await c.check();
        expect(decision.shouldShow, isTrue);
        expect(decision.notes.map((n) => n.version.normalized), [
          '1.2.0',
          '1.1.0',
        ]);
        expect(decision.from, ReleaseVersion.parse('1.0.0'));
        expect(c.state.notes.map((n) => n.version.normalized), [
          '1.3.0',
          '1.2.0',
          '1.1.0',
          '1.0.0',
        ], reason: 'pre-release hidden for a stable install');
        expect(
          seen.version,
          ReleaseVersion.parse('1.0.0'),
          reason: 'not marked seen until shown',
        );

        await c.notifyShown();
        expect(seen.version, ReleaseVersion.parse('1.2.0'));
        expect((await c.check()).shouldShow, isFalse);
      },
    );

    test('same version shows nothing', () async {
      final c = controller(
        source: StaticReleaseNotesSource(notes),
        seen: MemorySeenVersionStore(ReleaseVersion.parse('1.2.0')),
      );
      expect((await c.check()).shouldShow, isFalse);
    });

    test('no note for the new version stores it and shows nothing', () async {
      final seen = MemorySeenVersionStore(ReleaseVersion.parse('1.3.0'));
      final c = controller(
        source: StaticReleaseNotesSource(notes),
        seen: seen,
        installed: '1.4.0',
      );
      expect((await c.check()).shouldShow, isFalse);
      expect(seen.version, ReleaseVersion.parse('1.4.0'));
    });

    test(
      'a failed fetch leaves the seen version alone so the next launch retries',
      () async {
        final seen = MemorySeenVersionStore(ReleaseVersion.parse('1.0.0'));
        final c = controller(source: const FailingSource(), seen: seen);
        expect((await c.check()).shouldShow, isFalse);
        expect(seen.version, ReleaseVersion.parse('1.0.0'));
        expect(c.state.status, ReleaseNotesStatus.failed);
        expect(c.state.error, isA<ReleaseNotesException>());
      },
    );

    test('a pre-release install keeps pre-release notes', () async {
      final c = controller(
        source: StaticReleaseNotesSource(notes),
        installed: '1.2.0-beta.1',
        seen: MemorySeenVersionStore(ReleaseVersion.parse('1.1.0')),
      );
      final decision = await c.check();
      expect(decision.notes.single.version.normalized, '1.2.0-beta.1');
    });
  });

  group('onRemoteUpdate', () {
    const config = ReleaseNotesConfig(
      trigger: ReleaseNotesTrigger.onRemoteUpdate,
    );

    test('shows the releases between installed and latest', () async {
      final c = controller(
        source: LatestSource(notes, notes.last),
        config: config,
        installed: '1.1.0',
      );
      final decision = await c.check();
      expect(decision.reason, ReleaseNotesReason.updateAvailable);
      expect(decision.notes.map((n) => n.version.normalized), [
        '1.3.0',
        '1.2.0',
      ]);
      expect(decision.from, ReleaseVersion.parse('1.1.0'));
      expect(decision.to, ReleaseVersion.parse('1.3.0'));
      expect(c.state.updateAvailable, isTrue);
    });

    test('adds the release body when the changelog lags behind', () async {
      final newest = note('1.4.0', features: ['Hot fix']);
      final c = controller(
        source: LatestSource(notes, newest),
        config: config,
        installed: '1.3.0',
      );
      final decision = await c.check();
      expect(decision.notes.single.version.normalized, '1.4.0');
      expect(
        decision.notes.single.sections.single.items.single.text.text,
        'Hot fix',
      );
    });

    test('shows nothing when up to date or the check fails', () async {
      expect(
        (await controller(
              source: LatestSource(notes, notes.last),
              config: config,
              installed: '1.3.0',
            ).check())
            .shouldShow,
        isFalse,
      );
      expect(
        (await controller(
              source: LatestSource(notes, null),
              config: config,
              installed: '1.0.0',
            ).check())
            .shouldShow,
        isFalse,
      );
      final failing = controller(
        source: const FailingSource(),
        config: config,
        installed: '1.0.0',
      );
      expect((await failing.check()).shouldShow, isFalse);
      expect(failing.state.error, isNotNull);
    });
  });

  group('load and cache', () {
    test('falls back to the cache when the source fails', () async {
      final cache = MemoryReleaseNotesCache();
      await cache.write(notes, fetchedAt: DateTime(2026, 1, 1));
      final c = controller(source: const FailingSource(), cache: cache);
      await c.load();
      expect(c.state.status, ReleaseNotesStatus.ready);
      expect(c.state.fromCache, isTrue);
      expect(c.state.fetchedAt, DateTime(2026, 1, 1));
      expect(c.state.notes.length, 4);
      expect(c.state.error, isNotNull);
    });

    test('does not touch the cache when disabled', () async {
      final cache = MemoryReleaseNotesCache();
      await cache.write(notes);
      final c = controller(
        source: const FailingSource(),
        cache: cache,
        config: const ReleaseNotesConfig(cacheEnabled: false),
      );
      await c.load();
      expect(c.state.status, ReleaseNotesStatus.failed);
    });

    test(
      'writes the cache after a fetch and shares concurrent loads',
      () async {
        final cache = MemoryReleaseNotesCache();
        var loads = 0;
        final c = controller(
          source: StaticReleaseNotesSource(notes),
          cache: cache,
          callbacks: ReleaseNotesCallbacks(
            onLoaded: (_, {required fromCache}) => loads++,
          ),
        );
        await Future.wait([c.load(), c.load()]);
        expect(loads, 1);
        expect((await cache.read())!.notes.length, 4);
      },
    );

    test('maxNotes trims the history', () async {
      final c = controller(
        source: StaticReleaseNotesSource(notes),
        config: const ReleaseNotesConfig(maxNotes: 2),
      );
      await c.load();
      expect(c.state.notes.map((n) => n.version.normalized), [
        '1.3.0',
        '1.2.0',
      ]);
    });

    test('open sets a manual decision over everything', () async {
      final c = controller(source: StaticReleaseNotesSource(notes));
      final decision = await c.open();
      expect(decision.reason, ReleaseNotesReason.manual);
      expect(decision.notes.length, 4);
    });
  });

  group('platform filter', () {
    final mixed = [
      ReleaseNote(
        version: ReleaseVersion.parse('2.0.0'),
        sections: [
          ReleaseSection(
            kind: ReleaseSectionKind.features,
            items: [
              ReleaseItem.plain('Everywhere'),
              ReleaseItem.plain('Face ID', platforms: {ReleasePlatform.ios}),
            ],
          ),
          ReleaseSection(
            kind: ReleaseSectionKind.fixes,
            items: [
              ReleaseItem.plain(
                'Back button',
                platforms: {ReleasePlatform.android},
              ),
            ],
          ),
        ],
      ),
    ];

    test('narrows to the configured platform and can be lifted', () async {
      final c = ReleaseNotesController(
        source: StaticReleaseNotesSource(mixed),
        config: const ReleaseNotesConfig(platform: ReleasePlatform.ios),
        seenStore: MemorySeenVersionStore(),
        cache: MemoryReleaseNotesCache(),
        installedVersionLoader: () async => '2.0.0',
      );
      await c.load();
      expect(c.canTogglePlatforms, isTrue);
      expect(c.filterHidesChanges, isTrue);
      expect(c.visibleNotes.single.sections.length, 1);
      expect(c.visibleNotes.single.changeCount, 2);
      c.showAllPlatforms = true;
      expect(c.visibleNotes.single.changeCount, 3);
    });

    test('currentOnly cannot be lifted', () async {
      final c = ReleaseNotesController(
        source: StaticReleaseNotesSource(mixed),
        config: const ReleaseNotesConfig(
          platform: ReleasePlatform.android,
          platformFilter: PlatformFilter.currentOnly,
        ),
        seenStore: MemorySeenVersionStore(),
        cache: MemoryReleaseNotesCache(),
        installedVersionLoader: () async => '2.0.0',
      );
      await c.load();
      c.showAllPlatforms = true;
      expect(c.showAllPlatforms, isFalse);
      expect(c.visibleNotes.single.changeCount, 2);
    });
  });
}
