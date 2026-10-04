import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../domain/models/sermon_recording.dart';
import '../view_models/sermon_recordings_view_model.dart';

class SermonPlayerView extends StatefulWidget {
  final SermonRecording recording;
  final SermonRecordingsViewModel viewModel;

  const SermonPlayerView({
    super.key,
    required this.recording,
    required this.viewModel,
  });

  @override
  State<SermonPlayerView> createState() => _SermonPlayerViewState();
}

class _SermonPlayerViewState extends State<SermonPlayerView> {
  late AudioPlayer _player;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const Duration _skipDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.recording.filePath);
      if (!await file.exists()) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Audio file not found on device.';
        });
        return;
      }

      await _player.setFilePath(widget.recording.filePath);

      // Restore previous playback position
      final savedPosition = widget.recording.lastPlaybackPositionMs;
      if (savedPosition > 0) {
        await _player.seek(Duration(milliseconds: savedPosition));
      }

      // Listen to streams
      _player.positionStream.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
        }
      });

      _player.durationStream.listen((dur) {
        if (dur != null && mounted) {
          setState(() => _duration = dur);
        }
      });

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });

          // Save position periodically while playing
          if (state.playing && _position.inMilliseconds > 0) {
            _savePlaybackPosition();
          }

          // Handle completion
          if (state.processingState == ProcessingState.completed) {
            _savePlaybackPosition();
          }
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading audio: $e';
      });
    }
  }

  void _savePlaybackPosition() {
    widget.viewModel.updatePlaybackPosition(
      widget.recording.id,
      _position.inMilliseconds,
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      _savePlaybackPosition();
    } else {
      // If completed, restart
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> _seekRelative(Duration offset) async {
    final newPos = _position + offset;
    final clamped = Duration(
      milliseconds: newPos.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await _player.seek(clamped);
  }

  Future<void> _setSpeed(double speed) async {
    await _player.setSpeed(speed);
    setState(() => _playbackSpeed = speed);
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryBlue =
            isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Playback Speed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _speeds.map((speed) {
                  final isSelected = speed == _playbackSpeed;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    selectedColor: primaryBlue.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? primaryBlue : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      _setSpeed(speed);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _savePlaybackPosition();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _savePlaybackPosition();
            Navigator.pop(context);
          },
        ),
        title: const Text('Now Playing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            onPressed: _showSpeedPicker,
            tooltip: 'Playback Speed',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildError(textSecondary, primaryBlue)
              : _buildPlayer(isDark, primaryBlue, textSecondary, surfaceColor),
    );
  }

  Widget _buildError(Color textSecondary, Color primaryBlue) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.error_outline,
                  size: 32, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(_errorMessage,
                style: TextStyle(color: textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(
      bool isDark, Color primaryBlue, Color textSecondary, Color surfaceColor) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Album art placeholder
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.mic, size: 64, color: primaryBlue.withValues(alpha: 0.4)),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
              ),

          const SizedBox(height: 32),

          // Title
          Text(
            widget.recording.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (widget.recording.speaker.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(widget.recording.speaker,
                style: TextStyle(fontSize: 14, color: textSecondary)),
          ],

          // Speed indicator
          if (_playbackSpeed != 1.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${_playbackSpeed}x',
                  style: TextStyle(
                      fontSize: 12,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600)),
            ),
          ],

          const Spacer(flex: 2),

          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: primaryBlue,
              inactiveTrackColor: primaryBlue.withValues(alpha: 0.15),
              thumbColor: primaryBlue,
              overlayColor: primaryBlue.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPos = Duration(
                    milliseconds: (value * _duration.inMilliseconds).round());
                _player.seek(newPos);
              },
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position),
                    style: TextStyle(fontSize: 12, color: textSecondary)),
                Text(_formatDuration(_duration),
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Skip backward
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                color: textSecondary,
                onPressed: () => _seekRelative(-_skipDuration),
              ),

              const SizedBox(width: 16),

              // Play/Pause
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryBlue,
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Skip forward
              IconButton(
                icon: const Icon(Icons.forward_30),
                iconSize: 32,
                color: textSecondary,
                onPressed: () => _seekRelative(_skipDuration),
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
