import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/services/audio_recording_service.dart';
import '../view_models/sermon_recordings_view_model.dart';

class RecordingCompleteView extends StatefulWidget {
  final SermonRecordingsViewModel viewModel;
  final RecordingResult result;
  final VoidCallback onSaved;
  final VoidCallback onDiscarded;

  const RecordingCompleteView({
    super.key,
    required this.viewModel,
    required this.result,
    required this.onSaved,
    required this.onDiscarded,
  });

  @override
  State<RecordingCompleteView> createState() => _RecordingCompleteViewState();
}

class _RecordingCompleteViewState extends State<RecordingCompleteView> {
  late TextEditingController _titleController;
  late TextEditingController _speakerController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final defaultTitle = _generateDefaultTitle();
    _titleController = TextEditingController(text: defaultTitle);
    _speakerController = TextEditingController();
  }

  String _generateDefaultTitle() {
    final now = DateTime.now();
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return 'Sermon Recording — ${months[now.month]} ${now.day}';
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await widget.viewModel.saveRecording(
        result: widget.result,
        title: _titleController.text.trim(),
        speaker: _speakerController.text.trim(),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving recording')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Recording?'),
        content:
            const Text('This recording will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
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
      await AudioRecordingService.deleteAudioFile(widget.result.filePath);
      widget.onDiscarded();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleDiscard,
        ),
        title: const Text('Recording Complete',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade400.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.check_circle,
                  size: 40, color: Colors.green.shade400),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.elasticOut)
                .fadeIn(),

            const SizedBox(height: 20),

            const Text('Recording Complete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),

            const SizedBox(height: 8),

            // Duration and size
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Text(_formatDuration(widget.result.durationMs),
                    style: TextStyle(fontSize: 14, color: textSecondary)),
                const SizedBox(width: 16),
                Icon(Icons.storage_outlined, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Text(_formatFileSize(widget.result.fileSizeBytes),
                    style: TextStyle(fontSize: 14, color: textSecondary)),
              ],
            ),

            const SizedBox(height: 32),

            // Title input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recording Title',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Give this recording a title...',
                      hintStyle: TextStyle(
                          color: textSecondary.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon:
                          Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Speaker input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Speaker (Optional)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _speakerController,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pastor / Speaker name...',
                      hintStyle: TextStyle(
                          color: textSecondary.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon: Icon(Icons.person_outline,
                          size: 18, color: textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Recording',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 12),

            // Discard
            TextButton(
              onPressed: _handleDiscard,
              child: const Text('Discard Recording',
                  style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
