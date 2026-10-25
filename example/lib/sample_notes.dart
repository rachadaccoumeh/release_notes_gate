import 'package:release_notes_gate/release_notes_gate.dart';

/// Notes for the demo, written the way a Firestore document or a JSON
/// response would carry them, then decoded with [ReleaseNoteJson].
final List<ReleaseNote> sampleNotes = ReleaseNoteJson.decodeList([
  {
    'version': '1.4.0',
    'date': _daysAgo(0),
    'url': 'https://github.com/rachadaccoumeh/release_notes_gate/releases',
    'sections': {
      'features': [
        'Recent files card on the home screen',
        {
          'text': {
            'default': 'Face ID sign-in',
            'ar': 'تسجيل الدخول ببصمة الوجه',
          },
          'platforms': ['ios'],
        },
        {
          'text': 'Open a project\'s notes from its info sheet',
          'scope': 'Home',
        },
        'Pull to refresh the file picker and the sources page',
        'Share a report as `PDF` or **CSV** ([#42](https://github.com/rachadaccoumeh/release_notes_gate/issues))',
        'Import a project from an opened file',
      ],
      'fixes': [
        'Auto-save during a long edit',
        'Stop an export that runs out of memory instead of hanging',
        {
          'text': 'Remote and D-pad navigation on TV',
          'platforms': ['android'],
        },
        'Give the exporter more memory on 64-bit devices',
        'Sort versions by the source they come from',
        'Keep lists clear of the home alerts',
        'Fix a crash on Android 11 when the app resumes',
        'Tell a full disk from a full memory',
        'Wait longer before cancelling a slow sync',
      ],
      'performance': ['Faster startup on cold launch'],
    },
  },
  {
    'version': '1.3.0',
    'date': _daysAgo(12),
    'sections': {
      'features': ['Dark mode', 'Search across releases'],
      'fixes': [
        'Crash when the changelog is empty',
        'Login loop on expired sessions',
        'Wrong date on the last release',
      ],
      'Notes': [
        {'text': 'This release drops support for Android 7.', 'note': true},
      ],
    },
  },
  {
    'version': '1.2.0',
    'date': _daysAgo(40),
    'sections': {
      'features': ['Sync between devices'],
      'improvements': [
        'Smoother scrolling in long lists',
        'Clearer error messages',
      ],
    },
  },
  {
    'version': '1.1.0',
    'date': _daysAgo(70),
    'sections': {
      'fixes': ['Back button closes the sheet'],
    },
  },
  {
    'version': '1.0.0',
    'date': _daysAgo(100),
    'sections': {
      'features': ['First release'],
    },
  },
]);

String _daysAgo(int days) {
  final date = DateTime.now().subtract(Duration(days: days));
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
