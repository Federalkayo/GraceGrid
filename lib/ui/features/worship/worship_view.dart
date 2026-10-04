import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/sermon_note.dart';
import '../../../domain/models/sermon_recording.dart';
import 'view_models/sermon_notes_view_model.dart';
import 'view_models/sermon_recordings_view_model.dart';
import 'views/sermon_note_editor_view.dart';
import 'views/record_sermon_view.dart';
import 'views/recording_complete_view.dart';
import 'views/sermon_player_view.dart';

class WorshipView extends StatefulWidget {
  const WorshipView({super.key});

  @override
  State<WorshipView> createState() => _WorshipViewState();
}

class _WorshipViewState extends State<WorshipView> {
  late SermonNotesViewModel _notesViewModel;
  late SermonRecordingsViewModel _recordingsViewModel;

  @override
  void initState() {
    super.initState();
    _notesViewModel = SermonNotesViewModel();
    _recordingsViewModel = SermonRecordingsViewModel();
  }

  @override
  void dispose() {
    _notesViewModel.dispose();
    _recordingsViewModel.dispose();
    super.dispose();
  }

  void _openNewNote() {
    final note = _notesViewModel.createNewNote();
    _notesViewModel.openNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SermonNoteEditorView(
          viewModel: _notesViewModel,
          note: note,
          onPlayRecording: () {
            final linked = _notesViewModel.getLinkedRecording();
            if (linked != null) _openPlayer(linked);
          },
        ),
      ),
    ).then((_) {
      _notesViewModel.closeNote();
    });
  }

  void _openExistingNote(SermonNote note) {
    _notesViewModel.openNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SermonNoteEditorView(
          viewModel: _notesViewModel,
          note: note,
          onPlayRecording: () {
            final linked = _notesViewModel.getLinkedRecording();
            if (linked != null) _openPlayer(linked);
          },
        ),
      ),
    ).then((_) {
      _notesViewModel.closeNote();
    });
  }

  void _startRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordSermonView(
          viewModel: _recordingsViewModel,
          onRecordingComplete: (result) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RecordingCompleteView(
                  viewModel: _recordingsViewModel,
                  result: result,
                  onSaved: () {
                    Navigator.pop(context);
                    _recordingsViewModel.loadRecordings();
                  },
                  onDiscarded: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPlayer(SermonRecording recording) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SermonPlayerView(
          recording: recording,
          viewModel: _recordingsViewModel,
        ),
      ),
    );
  }

  void _showRenameDialog(SermonRecording recording) {
    final controller = TextEditingController(text: recording.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Recording'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new title...',
            border: OutlineInputBorder(),
          ),
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
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                await _recordingsViewModel.renameRecording(
                    recording.id, newTitle);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Rename',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  void _showDeleteRecordingDialog(SermonRecording recording) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text(
          'Are you sure you want to delete "${recording.title}"? '
          'The audio file will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _recordingsViewModel.deleteRecording(recording.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showDeleteNoteDialog(SermonNote note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${note.title.isNotEmpty ? note.title : 'Untitled Note'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _notesViewModel.deleteNote(note.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
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
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.graphic_eq, color: primaryBlue),
            const SizedBox(width: 8),
            const Text('Worship & Sermons',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_notesViewModel, _recordingsViewModel]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.mic,
                      label: 'Record Sermon',
                      color: const Color(0xFFEF4444),
                      onTap: _startRecording,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.edit_note,
                      label: 'New Sermon Note',
                      color: primaryBlue,
                      onTap: _openNewNote,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // My Sermons section
              _buildSection(
                title: 'My Sermons',
                icon: Icons.mic,
                count: _recordingsViewModel.recordings.length,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              if (_recordingsViewModel.recordings.isEmpty)
                _buildEmptyState(
                  icon: Icons.mic_none,
                  message: 'No recordings yet',
                  subtitle: 'Tap "Record Sermon" to get started',
                  textSecondary: textSecondary,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                )
              else
                ..._recordingsViewModel.recordings
                    .take(5)
                    .map((rec) => _buildRecordingTile(
                          rec, primaryBlue, textSecondary, surfaceColor,
                          borderColor)),

              if (_recordingsViewModel.recordings.length > 5) ...[
                const SizedBox(height: 8),
                _buildShowAllButton(
                  label:
                      'View all ${_recordingsViewModel.recordings.length} recordings',
                  primaryBlue: primaryBlue,
                  onTap: () => _showAllRecordings(),
                ),
              ],

              const SizedBox(height: 28),

              // My Notes section
              _buildSection(
                title: 'My Notes',
                icon: Icons.note_alt_outlined,
                count: _notesViewModel.notes.length,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
                trailing: _notesViewModel.notes.isNotEmpty
                    ? _buildSearchIcon(primaryBlue)
                    : null,
              ),
              const SizedBox(height: 8),
              if (_notesViewModel.notes.isEmpty)
                _buildEmptyState(
                  icon: Icons.note_add_outlined,
                  message: 'No sermon notes yet',
                  subtitle: 'Tap "New Sermon Note" to begin',
                  textSecondary: textSecondary,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                )
              else
                ..._notesViewModel.notes.take(5).map((note) =>
                    _buildNoteTile(note, primaryBlue, textSecondary,
                        surfaceColor, borderColor)),

              if (_notesViewModel.notes.length > 5) ...[
                const SizedBox(height: 8),
                _buildShowAllButton(
                  label:
                      'View all ${_notesViewModel.notes.length} notes',
                  primaryBlue: primaryBlue,
                  onTap: () => _showAllNotes(),
                ),
              ],

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Color surfaceColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required int count,
    required Color primaryBlue,
    required Color textSecondary,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryBlue),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  color: primaryBlue,
                  fontWeight: FontWeight.w600)),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }

  Widget _buildSearchIcon(Color primaryBlue) {
    return IconButton(
      icon: Icon(Icons.search, size: 20, color: primaryBlue),
      onPressed: () => _showSearchNotes(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
    required Color textSecondary,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textSecondary)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: textSecondary.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildRecordingTile(
    SermonRecording rec,
    Color primaryBlue,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mic, color: primaryBlue, size: 22),
        ),
        title: Text(rec.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${rec.speaker.isNotEmpty ? '${rec.speaker} • ' : ''}${rec.durationFormatted} • ${DateFormat('MMM d').format(rec.createdAt)}',
          style: TextStyle(fontSize: 12, color: textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textSecondary, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'play':
                _openPlayer(rec);
                break;
              case 'rename':
                _showRenameDialog(rec);
                break;
              case 'delete':
                _showDeleteRecordingDialog(rec);
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'play', child: Text('Play')),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(
              value: 'delete',
              child:
                  Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        ),
        onTap: () => _openPlayer(rec),
      ),
    );
  }

  Widget _buildNoteTile(
    SermonNote note,
    Color primaryBlue,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final displayTitle =
        note.title.isNotEmpty ? note.title : 'Untitled Note';
    final preview = note.content.isNotEmpty
        ? note.content.replaceAll('\n', ' ').trim()
        : 'No content yet';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_outlined, color: primaryBlue, size: 22),
        ),
        title: Text(displayTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.speaker.isNotEmpty)
              Text(note.speaker,
                  style: TextStyle(fontSize: 12, color: textSecondary)),
            Text(
              preview,
              style: TextStyle(
                  fontSize: 11, color: textSecondary.withValues(alpha: 0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textSecondary, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _openExistingNote(note);
                break;
              case 'delete':
                _showDeleteNoteDialog(note);
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child:
                  Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        ),
        onTap: () => _openExistingNote(note),
      ),
    );
  }

  Widget _buildShowAllButton({
    required String label,
    required Color primaryBlue,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w500,
              fontSize: 13)),
    );
  }

  void _showAllRecordings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllRecordingsView(
          viewModel: _recordingsViewModel,
          onPlay: _openPlayer,
          onRename: _showRenameDialog,
          onDelete: _showDeleteRecordingDialog,
        ),
      ),
    );
  }

  void _showAllNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllNotesView(
          viewModel: _notesViewModel,
          onOpen: _openExistingNote,
          onDelete: _showDeleteNoteDialog,
        ),
      ),
    );
  }

  void _showSearchNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SearchNotesView(
          viewModel: _notesViewModel,
          onOpen: _openExistingNote,
        ),
      ),
    );
  }
}

// ─── All Recordings View ────────────────────────────────────────

class _AllRecordingsView extends StatelessWidget {
  final SermonRecordingsViewModel viewModel;
  final void Function(SermonRecording) onPlay;
  final void Function(SermonRecording) onRename;
  final void Function(SermonRecording) onDelete;

  const _AllRecordingsView({
    required this.viewModel,
    required this.onPlay,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('My Sermons',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final recordings = viewModel.recordings;
          if (recordings.isEmpty) {
            return Center(
              child: Text('No recordings yet',
                  style: TextStyle(color: textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recordings.length,
            itemBuilder: (ctx, i) {
              final rec = recordings[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic, color: primaryBlue, size: 22),
                  ),
                  title: Text(rec.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${rec.speaker.isNotEmpty ? '${rec.speaker} • ' : ''}${rec.durationFormatted} • ${DateFormat('MMM d, y').format(rec.createdAt)}',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon:
                        Icon(Icons.more_vert, color: textSecondary, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'play':
                          onPlay(rec);
                          break;
                        case 'rename':
                          onRename(rec);
                          break;
                        case 'delete':
                          onDelete(rec);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'play', child: Text('Play')),
                      const PopupMenuItem(
                          value: 'rename', child: Text('Rename')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                  onTap: () => onPlay(rec),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── All Notes View ─────────────────────────────────────────────

class _AllNotesView extends StatelessWidget {
  final SermonNotesViewModel viewModel;
  final void Function(SermonNote) onOpen;
  final void Function(SermonNote) onDelete;

  const _AllNotesView({
    required this.viewModel,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('My Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final notes = viewModel.notes;
          if (notes.isEmpty) {
            return Center(
              child: Text('No notes yet',
                  style: TextStyle(color: textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (ctx, i) {
              final note = notes[i];
              final displayTitle =
                  note.title.isNotEmpty ? note.title : 'Untitled Note';
              final preview = note.content.isNotEmpty
                  ? note.content.replaceAll('\n', ' ').trim()
                  : 'No content yet';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.description_outlined,
                        color: primaryBlue, size: 22),
                  ),
                  title: Text(displayTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.speaker.isNotEmpty)
                        Text(note.speaker,
                            style: TextStyle(
                                fontSize: 12, color: textSecondary)),
                      Text(
                        preview,
                        style: TextStyle(
                            fontSize: 11,
                            color: textSecondary.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon:
                        Icon(Icons.more_vert, color: textSecondary, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete(note);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                  onTap: () => onOpen(note),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Search Notes View ──────────────────────────────────────────

class _SearchNotesView extends StatefulWidget {
  final SermonNotesViewModel viewModel;
  final void Function(SermonNote) onOpen;

  const _SearchNotesView({
    required this.viewModel,
    required this.onOpen,
  });

  @override
  State<_SearchNotesView> createState() => _SearchNotesViewState();
}

class _SearchNotesViewState extends State<_SearchNotesView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.setSearchQuery('');
  }

  @override
  void dispose() {
    widget.viewModel.setSearchQuery('');
    _searchController.dispose();
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
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => widget.viewModel.setSearchQuery(v),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Search notes...',
              hintStyle: TextStyle(
                  color: textSecondary.withValues(alpha: 0.6), fontSize: 14),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon:
                  Icon(Icons.search, size: 18, color: textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        widget.viewModel.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final results = widget.viewModel.notes;

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 48,
                      color: textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    widget.viewModel.searchQuery.isEmpty
                        ? 'Start typing to search'
                        : 'No notes found',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final note = results[i];
              final displayTitle =
                  note.title.isNotEmpty ? note.title : 'Untitled Note';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined,
                        color: primaryBlue, size: 20),
                  ),
                  title: Text(displayTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    note.content.replaceAll('\n', ' ').trim(),
                    style: TextStyle(
                        fontSize: 11, color: textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => widget.onOpen(note),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
