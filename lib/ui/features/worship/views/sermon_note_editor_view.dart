import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/sermon_note.dart';
import '../../../../domain/models/sermon_recording.dart';
import '../view_models/sermon_notes_view_model.dart';

class SermonNoteEditorView extends StatefulWidget {
  final SermonNotesViewModel viewModel;
  final SermonNote note;
  final VoidCallback? onPlayRecording;

  const SermonNoteEditorView({
    super.key,
    required this.viewModel,
    required this.note,
    this.onPlayRecording,
  });

  @override
  State<SermonNoteEditorView> createState() => _SermonNoteEditorViewState();
}

class _SermonNoteEditorViewState extends State<SermonNoteEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _speakerController;
  late TextEditingController _eventController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _speakerController = TextEditingController(text: widget.note.speaker);
    _eventController = TextEditingController(text: widget.note.event);
    _contentController = TextEditingController(text: widget.note.content);
    _selectedDate = widget.note.date;
  }

  @override
  void dispose() {
    // Force save on exit
    widget.viewModel.saveNow();
    _titleController.dispose();
    _speakerController.dispose();
    _eventController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      widget.viewModel.updateNoteField(date: picked);
    }
  }

  void _showDeleteConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this sermon note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.viewModel.deleteNote(widget.note.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showLinkRecordingSheet() {
    final recordings = widget.viewModel.getAvailableRecordings();
    if (recordings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recordings available. Record a sermon first.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LinkRecordingSheet(
        recordings: recordings,
        currentLinkedId: widget.note.linkedRecordingId,
        onLink: (id) {
          widget.viewModel.linkRecording(id);
          Navigator.pop(ctx);
          setState(() {});
        },
        onUnlink: () {
          widget.viewModel.unlinkRecording();
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            widget.viewModel.saveNow();
            widget.viewModel.closeNote();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Sermon Note',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          // Save status indicator
          ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return _buildSaveIndicator(widget.viewModel.saveStatus, primaryBlue, textSecondary);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'link_recording':
                  _showLinkRecordingSheet();
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'link_recording',
                child: Row(
                  children: [
                    Icon(Icons.link, size: 20),
                    SizedBox(width: 8),
                    Text('Link Recording'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Delete Note',
                        style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            _buildField(
              label: 'Sermon Title',
              controller: _titleController,
              hintText: 'Enter sermon title...',
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textSecondary: textSecondary,
              onChanged: (v) => widget.viewModel.updateNoteField(title: v),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Speaker field
            _buildField(
              label: 'Speaker',
              controller: _speakerController,
              hintText: 'Pastor / Speaker name...',
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textSecondary: textSecondary,
              onChanged: (v) => widget.viewModel.updateNoteField(speaker: v),
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Event field
            _buildField(
              label: 'Church / Event',
              controller: _eventController,
              hintText: 'Optional — church or event name...',
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textSecondary: textSecondary,
              onChanged: (v) => widget.viewModel.updateNoteField(event: v),
              icon: Icons.church_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Date field
            Text('Date',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMMM d, y').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Linked recording card
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                final linked = widget.viewModel.getLinkedRecording();
                if (linked == null) return const SizedBox.shrink();
                return _buildLinkedRecordingCard(
                    linked, primaryBlue, surfaceColor, borderColor, textSecondary);
              },
            ),

            // Notes content
            Text('Notes',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 300),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 15,
                onChanged: (v) =>
                    widget.viewModel.updateNoteField(content: v),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Write your sermon notes here...',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textSecondary,
    required ValueChanged<String> onChanged,
    IconData? icon,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
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
            controller: controller,
            onChanged: onChanged,
            textInputAction: textInputAction,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle:
                  TextStyle(color: textSecondary.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: textSecondary)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveIndicator(
      SaveStatus status, Color primaryBlue, Color textSecondary) {
    switch (status) {
      case SaveStatus.saving:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text('Saving...',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        );
      case SaveStatus.saved:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
              const SizedBox(width: 4),
              Text('Saved',
                  style: TextStyle(
                      fontSize: 11, color: Colors.green.shade400)),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      case SaveStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text('Error',
                  style:
                      TextStyle(fontSize: 11, color: Colors.red.shade400)),
            ],
          ),
        );
      case SaveStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLinkedRecordingCard(
    SermonRecording recording,
    Color primaryBlue,
    Color surfaceColor,
    Color borderColor,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, color: primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recording.durationFormatted,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_circle_filled,
                  color: primaryBlue, size: 32),
              onPressed: widget.onPlayRecording,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

class _LinkRecordingSheet extends StatelessWidget {
  final List<SermonRecording> recordings;
  final String? currentLinkedId;
  final ValueChanged<String> onLink;
  final VoidCallback onUnlink;

  const _LinkRecordingSheet({
    required this.recordings,
    this.currentLinkedId,
    required this.onLink,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Link a Recording',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a recording to link with this note',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              if (currentLinkedId != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Unlink current recording'),
                  onPressed: onUnlink,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recordings.length,
                  itemBuilder: (ctx, i) {
                    final rec = recordings[i];
                    final isLinked = rec.id == currentLinkedId;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLinked
                              ? primaryBlue.withValues(alpha: 0.2)
                              : primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLinked ? Icons.check : Icons.mic,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ),
                      title: Text(rec.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        '${rec.durationFormatted} • ${DateFormat('MMM d, y').format(rec.createdAt)}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      trailing: isLinked
                          ? Icon(Icons.check_circle,
                              color: primaryBlue, size: 20)
                          : null,
                      onTap: () => onLink(rec.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
