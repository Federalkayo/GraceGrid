import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { idle, recording, paused, stopped }

class AudioRecordingService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  Duration _elapsed = Duration.zero;
  String? _currentFilePath;
  DateTime? _recordingStartTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;

  RecordingState get state => _state;
  Duration get elapsed => _elapsed;
  String? get currentFilePath => _currentFilePath;

  // Timer for updating the elapsed display
  bool _timerRunning = false;

  /// Returns the directory for storing sermon recordings
  static Future<String> get _recordingsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/GraceGrid/sermons');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Check and request microphone permission
  Future<PermissionResult> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return PermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    }

    final result = await Permission.microphone.request();

    if (result.isGranted) {
      return PermissionResult.granted;
    } else if (result.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    } else {
      return PermissionResult.denied;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      final permResult = await requestMicrophonePermission();
      if (permResult != PermissionResult.granted) {
        return false;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return false;

      final dir = await _recordingsDir;
      final fileName = 'sermon_${const Uuid().v4()}.m4a';
      _currentFilePath = '$dir/$fileName';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1, // Mono is sufficient for voice
      );

      await _recorder.start(config, path: _currentFilePath!);

      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _state = RecordingState.recording;
      _elapsed = Duration.zero;
      notifyListeners();

      _startTimer();
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) return;
    try {
      await _recorder.pause();
      _pauseTime = DateTime.now();
      _state = RecordingState.paused;
      _timerRunning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) return;
    try {
      await _recorder.resume();
      if (_pauseTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseTime!);
      }
      _state = RecordingState.recording;
      notifyListeners();
      _startTimer();
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  /// Stop recording and return the file path
  Future<RecordingResult?> stopRecording() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return null;
    }
    try {
      if (_state == RecordingState.paused && _pauseTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseTime!);
      }

      final path = await _recorder.stop();
      _timerRunning = false;
      _state = RecordingState.stopped;
      notifyListeners();

      if (path == null || path.isEmpty) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final fileSize = await file.length();
      final totalElapsed = _elapsed;

      return RecordingResult(
        filePath: path,
        durationMs: totalElapsed.inMilliseconds,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel recording and clean up
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _timerRunning = false;
      _state = RecordingState.idle;

      // Delete the file if it exists
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentFilePath = null;
      _elapsed = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  /// Reset to idle state
  void reset() {
    _timerRunning = false;
    _state = RecordingState.idle;
    _elapsed = Duration.zero;
    _currentFilePath = null;
    _recordingStartTime = null;
    _pauseTime = null;
    _pausedDuration = Duration.zero;
    notifyListeners();
  }

  void _startTimer() {
    _timerRunning = true;
    _tick();
  }

  Future<void> _tick() async {
    while (_timerRunning && _state == RecordingState.recording) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_timerRunning && _state == RecordingState.recording && _recordingStartTime != null) {
        _elapsed = DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
        notifyListeners();
      }
    }
  }

  /// Delete an audio file from device storage
  static Future<bool> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting audio file: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _timerRunning = false;
    _recorder.dispose();
    super.dispose();
  }
}

enum PermissionResult { granted, denied, permanentlyDenied }

class RecordingResult {
  final String filePath;
  final int durationMs;
  final int fileSizeBytes;

  const RecordingResult({
    required this.filePath,
    required this.durationMs,
    required this.fileSizeBytes,
  });
}
