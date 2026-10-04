import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/sermon_note.dart';
import '../../domain/models/sermon_recording.dart';

class HiveService {
  static const String _sermonNotesBox = 'sermon_notes';
  static const String _sermonRecordingsBox = 'sermon_recordings';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SermonNoteAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SermonRecordingAdapter());
    }

    // Open boxes
    await Hive.openBox<SermonNote>(_sermonNotesBox);
    await Hive.openBox<SermonRecording>(_sermonRecordingsBox);

    _initialized = true;
  }

  // ─── Sermon Notes ──────────────────────────────────────────────

  static Box<SermonNote> get notesBox => Hive.box<SermonNote>(_sermonNotesBox);

  static Future<void> saveNote(SermonNote note) async {
    await notesBox.put(note.id, note);
  }

  static Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
  }

  static SermonNote? getNote(String id) {
    return notesBox.get(id);
  }

  static List<SermonNote> getAllNotes() {
    final notes = notesBox.values.toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static List<SermonNote> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllNotes().where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.speaker.toLowerCase().contains(lowerQuery) ||
          note.event.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ─── Sermon Recordings ────────────────────────────────────────

  static Box<SermonRecording> get recordingsBox =>
      Hive.box<SermonRecording>(_sermonRecordingsBox);

  static Future<void> saveRecording(SermonRecording recording) async {
    await recordingsBox.put(recording.id, recording);
  }

  static Future<void> deleteRecording(String id) async {
    await recordingsBox.delete(id);
  }

  static SermonRecording? getRecording(String id) {
    return recordingsBox.get(id);
  }

  static List<SermonRecording> getAllRecordings() {
    final recordings = recordingsBox.values.toList();
    recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recordings;
  }

  static Future<void> updatePlaybackPosition(
      String id, int positionMs) async {
    final recording = recordingsBox.get(id);
    if (recording != null) {
      recording.lastPlaybackPositionMs = positionMs;
      recording.updatedAt = DateTime.now();
      await recording.save();
    }
  }

  static Future<void> updateRecordingTitle(
      String id, String newTitle) async {
    final recording = recordingsBox.get(id);
    if (recording != null) {
      recording.title = newTitle;
      recording.updatedAt = DateTime.now();
      await recording.save();
    }
  }
}
