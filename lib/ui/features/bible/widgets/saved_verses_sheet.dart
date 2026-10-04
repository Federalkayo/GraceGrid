import 'package:flutter/material.dart';
import '../../../../domain/models/bible_highlight_color.dart';

class SavedVersesSheet extends StatefulWidget {
  final Set<String> bookmarkedVerseKeys;
  final Map<String, String> highlightedVerses;
  final Map<String, String> verseNotes;
  final Function(String book, int chapter, int verseNumber) onNavigateToVerse;
  final Function(String verseKey)? onRemoveBookmark;
  final Function(String verseKey)? onRemoveHighlight;

  const SavedVersesSheet({
    super.key,
    required this.bookmarkedVerseKeys,
    required this.highlightedVerses,
    required this.verseNotes,
    required this.onNavigateToVerse,
    this.onRemoveBookmark,
    this.onRemoveHighlight,
  });

  @override
  State<SavedVersesSheet> createState() => _SavedVersesSheetState();
}

class _SavedVersesSheetState extends State<SavedVersesSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _parseAndNavigate(String key) {
    final parts = key.split(':');
    if (parts.length >= 3) {
      final book = parts[0];
      final chapter = int.tryParse(parts[1]) ?? 1;
      final verse = int.tryParse(parts[2]) ?? 1;
      Navigator.pop(context);
      widget.onNavigateToVerse(book, chapter, verse);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    final bookmarksList = widget.bookmarkedVerseKeys.toList()..sort();
    final highlightsList = widget.highlightedVerses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.collections_bookmark_outlined,
                      size: 22, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Saved & Highlights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: primaryBlue,
              unselectedLabelColor:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: primaryBlue,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Bookmarks (${bookmarksList.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.palette_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Highlights (${highlightsList.length})'),
                    ],
                  ),
                ),
              ],
            ),

            // Tab Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Bookmarks Tab
                  bookmarksList.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.bookmark_outline_rounded,
                          message: 'No bookmarked verses yet.\nTap any verse in the reader to bookmark it!',
                          isDark: isDark,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookmarksList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final key = bookmarksList[index];
                            final parts = key.split(':');
                            final ref = parts.length >= 3
                                ? '${parts[0]} ${parts[1]}:${parts[2]}'
                                : key;
                            final note = widget.verseNotes[key];

                            return Card(
                              elevation: 0,
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.bookmark_rounded,
                                    color: primaryBlue),
                                title: Text(
                                  ref,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: note != null && note.isNotEmpty
                                    ? Text('Note: $note',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)
                                    : const Text('Tap to jump to verse'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.onRemoveBookmark != null)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            widget.onRemoveBookmark!(key),
                                        tooltip: 'Remove bookmark',
                                      ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () => _parseAndNavigate(key),
                              ),
                            );
                          },
                        ),

                  // Highlights Tab
                  highlightsList.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.format_paint_outlined,
                          message: 'No highlighted verses yet.\nSelect verses and choose a color to highlight them!',
                          isDark: isDark,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: highlightsList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = highlightsList[index];
                            final key = entry.key;
                            final colorKey = entry.value;
                            final accentColor =
                                BibleHighlightColor.getAccentColor(colorKey);
                            final label =
                                BibleHighlightColor.getLabel(colorKey);
                            final parts = key.split(':');
                            final ref = parts.length >= 3
                                ? '${parts[0]} ${parts[1]}:${parts[2]}'
                                : key;

                            return Card(
                              elevation: 0,
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: accentColor, width: 1.5),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  ref,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('$label Highlight • Tap to view'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.onRemoveHighlight != null)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.format_color_reset_rounded,
                                            size: 20,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            widget.onRemoveHighlight!(key),
                                        tooltip: 'Remove highlight',
                                      ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () => _parseAndNavigate(key),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
