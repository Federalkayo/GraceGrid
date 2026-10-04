import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/services/hive_service.dart';
import '../../../../domain/models/sermon_note.dart';
import '../../../../domain/models/sermon_recording.dart';

enum SaveStatus { idle, saving, saved, error }

class SermonNotesViewModel extends ChangeNotifier {
  List<SermonNote> _notes = [];
  SermonNote? _currentNote;
  SaveStatus _saveStatus = SaveStatus.idle;
  String _searchQuery = '';
  Timer? _debounceTimer;

  List<SermonNote> get notes =>
      _searchQuery.isEmpty ? _notes : HiveService.searchNotes(_searchQuery);
  SermonNote? get currentNote => _currentNote;
  SaveStatus get saveStatus => _saveStatus;
  String get searchQuery => _searchQuery;

  SermonNotesViewModel() {
    loadNotes();
  }

  void loadNotes() {
    _notes = HiveService.getAllNotes();
    notifyListeners();
  }

  /// Create a new blank sermon note
  SermonNote createNewNote() {
    final now = DateTime.now();
    final note = SermonNote(
      id: const Uuid().v4(),
      title: '',
      speaker: '',
      event: '',
      date: now,
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    _currentNote = note;
    notifyListeners();
    return note;
  }

  /// Open an existing note for editing
  void openNote(SermonNote note) {
    _currentNote = note;
    _saveStatus = SaveStatus.idle;
    notifyListeners();
  }

  /// Close the current note
  void closeNote() {
    _debounceTimer?.cancel();
    _currentNote = null;
    _saveStatus = SaveStatus.idle;
    loadNotes();
    notifyListeners();
  }

  /// Update note field with debounced autosave
  void updateNoteField({
    String? title,
    String? speaker,
    String? event,
    DateTime? date,
    String? content,
    String? linkedRecordingId,
  }) {
    if (_currentNote == null) return;

    if (title != null) _currentNote!.title = title;
    if (speaker != null) _currentNote!.speaker = speaker;
    if (event != null) _currentNote!.event = event;
    if (date != null) _currentNote!.date = date;
    if (content != null) _currentNote!.content = content;
    if (linkedRecordingId != null) {
      _currentNote!.linkedRecordingId = linkedRecordingId;
    }

    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _debounceTimer?.cancel();
    _saveStatus = SaveStatus.saving;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _performSave();
    });
  }

  Future<void> _performSave() async {
    if (_currentNote == null) return;

    try {
      _currentNote!.updatedAt = DateTime.now();
      await HiveService.saveNote(_currentNote!);
      _saveStatus = SaveStatus.saved;
      loadNotes();
      notifyListeners();

      // Reset save status after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (_saveStatus == SaveStatus.saved) {
          _saveStatus = SaveStatus.idle;
          notifyListeners();
        }
      });
    } catch (e) {
      _saveStatus = SaveStatus.error;
      notifyListeners();
      debugPrint('Error saving note: $e');
    }
  }

  /// Force save immediately (e.g., on leaving the note)
  Future<void> saveNow() async {
    _debounceTimer?.cancel();
    if (_currentNote != null) {
      await _performSave();
    }
  }

  /// Delete a sermon note
  Future<void> deleteNote(String id) async {
    await HiveService.deleteNote(id);
    if (_currentNote?.id == id) {
      _currentNote = null;
    }
    loadNotes();
    notifyListeners();
  }

  /// Search notes
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Link a recording to the current note
  void linkRecording(String recordingId) {
    if (_currentNote == null) return;
    _currentNote!.linkedRecordingId = recordingId;
    _scheduleAutosave();
  }

  /// Unlink a recording from the current note
  void unlinkRecording() {
    if (_currentNote == null) return;
    _currentNote!.linkedRecordingId = null;
    _scheduleAutosave();
  }

  /// Get linked recording for the current note
  SermonRecording? getLinkedRecording() {
    if (_currentNote?.linkedRecordingId == null) return null;
    return HiveService.getRecording(_currentNote!.linkedRecordingId!);
  }

  /// Get all available recordings (for linking)
  List<SermonRecording> getAvailableRecordings() {
    return HiveService.getAllRecordings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
