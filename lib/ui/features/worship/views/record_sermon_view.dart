import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/services/audio_recording_service.dart';
import '../view_models/sermon_recordings_view_model.dart';

class RecordSermonView extends StatefulWidget {
  final SermonRecordingsViewModel viewModel;
  final void Function(RecordingResult result)? onRecordingComplete;

  const RecordSermonView({
    super.key,
    required this.viewModel,
    this.onRecordingComplete,
  });

  @override
  State<RecordSermonView> createState() => _RecordSermonViewState();
}

class _RecordSermonViewState extends State<RecordSermonView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final result = await widget.viewModel.requestPermission();
    setState(() {
      _hasPermission = result == PermissionResult.granted;
      _checkingPermission = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleStartRecording() async {
    final started = await widget.viewModel.startRecording();
    if (started) {
      _pulseController.repeat(reverse: true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not start recording. Please check microphone permission.'),
          ),
        );
      }
    }
  }

  Future<void> _handlePause() async {
    await widget.viewModel.pauseRecording();
    _pulseController.stop();
    _pulseController.value = 0;
  }

  Future<void> _handleResume() async {
    await widget.viewModel.resumeRecording();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _handleStop() async {
    _pulseController.stop();
    _pulseController.value = 0;
    final result = await widget.viewModel.stopRecording();
    if (result != null && mounted) {
      widget.onRecordingComplete?.call(result);
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text(
            'Are you sure you want to discard this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Recording'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _pulseController.stop();
      _pulseController.value = 0;
      await widget.viewModel.cancelRecording();
      if (mounted) Navigator.pop(context);
    }
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

    if (_checkingPermission) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Record Sermon',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDenied(isDark, primaryBlue, textSecondary);
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            final state = widget.viewModel.recordingService.state;
            if (state == RecordingState.recording ||
                state == RecordingState.paused) {
              _handleCancel();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Record Sermon',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final recService = widget.viewModel.recordingService;
          final state = recService.state;
          final elapsed = recService.elapsed;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Microphone icon with pulse
                  _buildMicrophoneIndicator(
                      state, primaryBlue, surfaceColor, isDark),

                  const SizedBox(height: 32),

                  // Timer
                  Text(
                    _formatDuration(elapsed),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status text
                  _buildStatusText(state, primaryBlue, textSecondary),

                  const Spacer(flex: 2),

                  // Controls
                  _buildControls(state, primaryBlue, textSecondary, surfaceColor, isDark),

                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMicrophoneIndicator(
      RecordingState state, Color primaryBlue, Color surfaceColor, bool isDark) {
    final isRecording = state == RecordingState.recording;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isRecording ? 1.0 + (_pulseController.value * 0.15) : 1.0;
        final opacity = isRecording ? 0.15 + (_pulseController.value * 0.15) : 0.1;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording
                  ? const Color(0xFFEF4444).withValues(alpha: opacity)
                  : primaryBlue.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : primaryBlue.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.mic,
                  size: 40,
                  color: isRecording
                      ? const Color(0xFFEF4444)
                      : state == RecordingState.paused
                          ? Colors.amber.shade600
                          : primaryBlue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(
      RecordingState state, Color primaryBlue, Color textSecondary) {
    String text;
    Color color;
    switch (state) {
      case RecordingState.idle:
        text = 'Ready to Record';
        color = textSecondary;
        break;
      case RecordingState.recording:
        text = 'Recording...';
        color = const Color(0xFFEF4444);
        break;
      case RecordingState.paused:
        text = 'Paused';
        color = Colors.amber.shade600;
        break;
      case RecordingState.stopped:
        text = 'Recording Complete';
        color = primaryBlue;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state == RecordingState.recording)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEF4444),
            ),
          ).animate(onPlay: (c) => c.repeat()).fadeOut(
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
        Text(text, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildControls(RecordingState state, Color primaryBlue,
      Color textSecondary, Color surfaceColor, bool isDark) {
    switch (state) {
      case RecordingState.idle:
      case RecordingState.stopped:
        return _buildStartButton(primaryBlue);
      case RecordingState.recording:
        return _buildRecordingControls(
            primaryBlue, textSecondary, surfaceColor, isDark);
      case RecordingState.paused:
        return _buildPausedControls(
            primaryBlue, textSecondary, surfaceColor, isDark);
    }
  }

  Widget _buildStartButton(Color primaryBlue) {
    return GestureDetector(
      onTap: _handleStartRecording,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryBlue,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 32),
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildRecordingControls(
      Color primaryBlue, Color textSecondary, Color surfaceColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause button
        _buildControlButton(
          icon: Icons.pause_rounded,
          label: 'Pause',
          onTap: _handlePause,
          color: textSecondary,
          surfaceColor: surfaceColor,
          isDark: isDark,
        ),
        const SizedBox(width: 40),
        // Stop button
        _buildControlButton(
          icon: Icons.stop_rounded,
          label: 'Stop',
          onTap: _handleStop,
          color: const Color(0xFFEF4444),
          surfaceColor: surfaceColor,
          isDark: isDark,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildPausedControls(
      Color primaryBlue, Color textSecondary, Color surfaceColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Resume button
        _buildControlButton(
          icon: Icons.play_arrow_rounded,
          label: 'Resume',
          onTap: _handleResume,
          color: primaryBlue,
          surfaceColor: surfaceColor,
          isDark: isDark,
        ),
        const SizedBox(width: 40),
        // Stop button
        _buildControlButton(
          icon: Icons.stop_rounded,
          label: 'Stop',
          onTap: _handleStop,
          color: const Color(0xFFEF4444),
          surfaceColor: surfaceColor,
          isDark: isDark,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color surfaceColor,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 64 : 56,
            height: isPrimary ? 64 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? color : color.withValues(alpha: 0.12),
              border: isPrimary
                  ? null
                  : Border.all(
                      color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: isPrimary ? 30 : 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(
      bool isDark, Color primaryBlue, Color textSecondary) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Record Sermon',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.mic_off, size: 36, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Microphone Access Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'GraceGrid needs access to your microphone to record sermons. '
                'Please grant microphone permission in your device settings.',
                style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Open Settings',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  setState(() => _checkingPermission = true);
                  await _checkPermission();
                },
                child: Text('Try Again', style: TextStyle(color: primaryBlue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
