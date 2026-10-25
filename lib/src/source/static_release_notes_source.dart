import '../model/release_note.dart';
import '../model/release_note_json.dart';
import 'release_notes_source.dart';

/// Release notes from a list in code. Handy for tests, previews, and apps
/// that ship their notes inside the binary.
class StaticReleaseNotesSource extends ReleaseNotesSource {
  /// Creates a source over [notes].
  const StaticReleaseNotesSource(this.notes);

  /// Creates a source from JSON objects in the [ReleaseNoteJson] shape.
  StaticReleaseNotesSource.json(Iterable<Map<String, Object?>> json)
    : notes = json
          .map(ReleaseNoteJson.decode)
          .whereType<ReleaseNote>()
          .toList(growable: false);

  /// The notes, in any order.
  final List<ReleaseNote> notes;

  @override
  Future<List<ReleaseNote>> fetch() async => notes.newestFirst;
}
