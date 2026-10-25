import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_notes_gate/release_notes_gate.dart';

ReleaseNote note(
  String version, {
  List<String> features = const [],
  List<String> fixes = const [],
  DateTime? date,
}) => ReleaseNote(
  version: ReleaseVersion.parse(version),
  date: date,
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
  note('2.0.0', features: ['Old']),
  note('2.1.0', fixes: ['Crash on start', 'Login loop']),
  note(
    '2.2.0',
    features: ['Dark mode', 'Sync', 'Search'],
    fixes: ['Back button'],
    date: DateTime.now(),
  ),
];

Widget wrap(
  Widget child, {
  Size size = const Size(400, 900),
  bool dark = false,
}) => MediaQuery(
  data: MediaQueryData(size: size, disableAnimations: true),
  child: MaterialApp(
    theme:
        dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData(useMaterial3: true),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  group('ReleaseNotesSummaryCard', () {
    testWidgets('shows the version step, the release count and count pills', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ReleaseNotesSummaryCard(
            notes: notes.sublist(1),
            from: ReleaseVersion.parse('2.0.0'),
            to: ReleaseVersion.parse('2.2.0'),
            animate: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('v2.0.0'), findsOneWidget);
      expect(find.textContaining('v2.2.0'), findsOneWidget);
      expect(find.text('2 new releases'), findsOneWidget);
      expect(find.text('3 features'), findsOneWidget);
      expect(find.text('3 fixes'), findsOneWidget);
    });
  });

  group('ReleaseNotesTimeline', () {
    testWidgets(
      'lists releases newest first with badges and folds older ones',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            ReleaseNotesTimeline(
              notes: notes,
              installedVersion: ReleaseVersion.parse('2.1.0'),
              highlighted: [notes.last],
              animateEntrance: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final versions =
            tester
                .widgetList<Text>(
                  find.byWidgetPredicate(
                    (w) => w is Text && (w.data?.startsWith('v2.') ?? false),
                  ),
                )
                .map((t) => t.data)
                .toList();
        expect(versions, ['v2.2.0', 'v2.1.0', 'v2.0.0']);
        expect(find.text('Latest'), findsOneWidget);
        expect(find.text('Installed'), findsOneWidget);
        expect(
          find.text('Dark mode'),
          findsOneWidget,
          reason: 'newest release starts open',
        );
        expect(
          find.text('Crash on start'),
          findsNothing,
          reason: 'older release starts folded',
        );
        expect(find.text('Today · 3 features · 1 fix'), findsOneWidget);

        await tester.tap(find.text('v2.1.0'));
        await tester.pumpAndSettle();
        expect(find.text('Crash on start'), findsOneWidget);
      },
    );

    testWidgets('shows the section heading, count and the Fixes label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ReleaseNotesTimeline(notes: [notes.last], animateEntrance: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Fixes'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('ReleaseSectionCard', () {
    testWidgets('previews five of a long section and expands on Show all', (
      tester,
    ) async {
      final section = ReleaseSection(
        kind: ReleaseSectionKind.fixes,
        items: [for (var i = 1; i <= 9; i++) ReleaseItem.plain('Fix $i')],
      );
      await tester.pumpWidget(wrap(ReleaseSectionCard(section: section)));
      await tester.pumpAndSettle();
      expect(find.text('Fix 5'), findsOneWidget);
      expect(find.text('Fix 6'), findsNothing);
      await tester.tap(find.text('Show all 9'));
      await tester.pumpAndSettle();
      expect(find.text('Fix 9'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('renders inline code, bold and the scope label', (
      tester,
    ) async {
      final section = ReleaseSection(
        kind: ReleaseSectionKind.features,
        items: [ReleaseItem.plain('Use `foo` and **bar**', scope: 'Login')],
      );
      await tester.pumpWidget(wrap(ReleaseSectionCard(section: section)));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('foo'), findsOneWidget);
      expect(find.textContaining('bar', findRichText: true), findsOneWidget);
    });
  });

  group('ReleaseNotesTheme', () {
    testWidgets('derives from the app theme and honours overrides', (
      tester,
    ) async {
      late ReleaseNotesThemeData derived;
      late ReleaseNotesThemeData overridden;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Builder(
            builder: (context) {
              derived = ReleaseNotesTheme.of(context);
              return ReleaseNotesTheme(
                data: derived.copyWith(
                  cardRadius: 4,
                  warning: const ReleaseNotesTone(
                    container: Colors.red,
                    content: Colors.white,
                    accent: Colors.red,
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    overridden = ReleaseNotesTheme.of(context);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(derived.cardRadius, 20);
      expect(derived.railSlotWidth, 18);
      expect(overridden.cardRadius, 4);
      expect(
        overridden.sectionStyle(ReleaseSectionKind.fixes).tone.container,
        Colors.red,
        reason: 'fixes follow the warning tone',
      );
    });

    testWidgets('the midnight preset is dark', (tester) async {
      final theme = ReleaseNotesThemeData.midnight();
      expect(theme.backgroundColor.computeLuminance(), lessThan(0.1));
      expect(
        theme.sectionStyle(ReleaseSectionKind.features).icon,
        Icons.auto_awesome_rounded,
      );
    });
  });
}
