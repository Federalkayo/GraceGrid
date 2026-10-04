import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/hive_service.dart';
import '../../../../data/services/audio_recording_service.dart';
import '../../../../domain/models/sermon_recording.dart';

class SermonRecordingsViewModel extends ChangeNotifier {
  List<SermonRecording> _recordings = [];
  final AudioRecordingService _recordingService = AudioRecordingService();

  List<SermonRecording> get recordings => _recordings;
  AudioRecordingService get recordingService => _recordingService;

  SermonRecordingsViewModel() {
    loadRecordings();
    _recordingService.addListener(_onRecordingStateChanged);
  }

  void _onRecordingStateChanged() {
    notifyListeners();
  }

  void loadRecordings() {
    _recordings = HiveService.getAllRecordings();
    notifyListeners();
  }

  /// Start a new recording session
  Future<bool> startRecording() async {
    return await _recordingService.startRecording();
  }

  /// Pause the recording
  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
  }

  /// Resume the recording
  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
  }

  /// Stop recording and return result
  Future<RecordingResult?> stopRecording() async {
    return await _recordingService.stopRecording();
  }

  /// Cancel the current recording
  Future<void> cancelRecording() async {
    await _recordingService.cancelRecording();
  }

  /// Save a completed recording to Hive
  Future<SermonRecording> saveRecording({
    required RecordingResult result,
    String? title,
    String? speaker,
    String? linkedNoteId,
  }) async {
    final now = DateTime.now();
    final defaultTitle =
        'Sermon Recording — ${DateFormat('MMMM d').format(now)}';

    final recording = SermonRecording(
      id: const Uuid().v4(),
      title: title?.isNotEmpty == true ? title! : defaultTitle,
      filePath: result.filePath,
      durationMs: result.durationMs,
      createdAt: now,
      updatedAt: now,
      speaker: speaker ?? '',
      fileSizeBytes: result.fileSizeBytes,
      lastPlaybackPositionMs: 0,
      linkedNoteId: linkedNoteId,
    );

    await HiveService.saveRecording(recording);
    _recordingService.reset();
    loadRecordings();
    return recording;
  }

  /// Delete a recording (both file and metadata)
  Future<void> deleteRecording(String id) async {
    final recording = HiveService.getRecording(id);
    if (recording != null) {
      await AudioRecordingService.deleteAudioFile(recording.filePath);
      await HiveService.deleteRecording(id);
      loadRecordings();
    }
  }

  /// Rename a recording
  Future<void> renameRecording(String id, String newTitle) async {
    await HiveService.updateRecordingTitle(id, newTitle);
    loadRecordings();
  }

  /// Update playback position for resume feature
  Future<void> updatePlaybackPosition(String id, int positionMs) async {
    await HiveService.updatePlaybackPosition(id, positionMs);
  }

  /// Request microphone permission
  Future<PermissionResult> requestPermission() async {
    return await _recordingService.requestMicrophonePermission();
  }

  @override
  void dispose() {
    _recordingService.removeListener(_onRecordingStateChanged);
    _recordingService.dispose();
    super.dispose();
  }
}
