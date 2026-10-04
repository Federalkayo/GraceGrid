import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/models/bible_verse.dart';
import '../../../../domain/models/bible_highlight_color.dart';
import 'highlight_color_picker_sheet.dart';

class BibleReaderContent extends StatefulWidget {
  final String book;
  final int chapter;
  final int targetVerseNumber;
  final List<BibleVerse> verses;
  final double fontSize;
  final Function(List<BibleVerse> verses) onToggleBookmark;
  final Function(List<BibleVerse> verses, String? colorName) onToggleHighlight;
  final Function(List<BibleVerse> verses) onShareVerse;
  final Function(List<BibleVerse> verses) onCopyVerse;
  final Function(BibleVerse verse) onAddNote;

  const BibleReaderContent({
    super.key,
    required this.book,
    required this.chapter,
    required this.targetVerseNumber,
    required this.verses,
    this.fontSize = 16.0,
    required this.onToggleBookmark,
    required this.onToggleHighlight,
    required this.onShareVerse,
    required this.onCopyVerse,
    required this.onAddNote,
  });

  @override
  State<BibleReaderContent> createState() => _BibleReaderContentState();
}

class _BibleReaderContentState extends State<BibleReaderContent>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  final Set<int> _selectedVerseNumbers = {};
  late AnimationController _toolbarAnimController;
  late Animation<double> _toolbarSlideAnim;
  late Animation<double> _toolbarFadeAnim;

  bool get _isSelectionMode => _selectedVerseNumbers.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _generateKeys();
    _toolbarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _toolbarSlideAnim = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
          parent: _toolbarAnimController, curve: Curves.easeOutCubic),
    );
    _toolbarFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _toolbarAnimController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetVerse();
    });
  }

  @override
  void didUpdateWidget(BibleReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book ||
        oldWidget.chapter != widget.chapter ||
        oldWidget.targetVerseNumber != widget.targetVerseNumber) {
      _generateKeys();
      _clearSelection();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTargetVerse();
      });
    }
  }

  void _generateKeys() {
    _verseKeys.clear();
    for (var verse in widget.verses) {
      _verseKeys[verse.verseNumber] = GlobalKey();
    }
  }

  void _scrollToTargetVerse() {
    final key = _verseKeys[widget.targetVerseNumber];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleVerseSelection(int verseNumber) {
    setState(() {
      if (_selectedVerseNumbers.contains(verseNumber)) {
        _selectedVerseNumbers.remove(verseNumber);
      } else {
        _selectedVerseNumbers.add(verseNumber);
      }
    });
    if (_selectedVerseNumbers.isNotEmpty) {
      _toolbarAnimController.forward();
    } else {
      _toolbarAnimController.reverse();
    }
    HapticFeedback.selectionClick();
  }

  void _onLongPressVerse(int verseNumber) {
    if (!_isSelectionMode) {
      _toggleVerseSelection(verseNumber);
    }
  }

  void _onTapVerse(int verseNumber) {
    if (_isSelectionMode) {
      _toggleVerseSelection(verseNumber);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedVerseNumbers.clear();
    });
    _toolbarAnimController.reverse();
  }

  List<BibleVerse> _getSelectedVerses() {
    return widget.verses
        .where((v) => _selectedVerseNumbers.contains(v.verseNumber))
        .toList()
      ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
  }

  String _getSelectionLabel() {
    final sorted = _selectedVerseNumbers.toList()..sort();
    if (sorted.isEmpty) return '';
    if (sorted.length == 1) {
      return '${widget.book} ${widget.chapter}:${sorted.first}';
    }
    final ranges = <String>[];
    int start = sorted.first;
    int end = start;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = sorted[i];
        end = start;
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');
    return '${widget.book} ${widget.chapter}:${ranges.join(', ')}';
  }

  void _openHighlightColorPicker() {
    final selected = _getSelectedVerses();
    if (selected.isEmpty) return;
    final currentColor = selected.first.highlightColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HighlightColorPickerSheet(
        currentColor: currentColor,
        onColorSelected: (colorName) {
          widget.onToggleHighlight(selected, colorName);
          _clearSelection();
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _toolbarAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    final selectedVerses = _getSelectedVerses();
    final areAllSelectedBookmarked = selectedVerses.isNotEmpty &&
        selectedVerses.every((v) => v.isBookmarked);

    return Stack(
      children: [
        // Main content
        GestureDetector(
          onTap: _isSelectionMode ? _clearSelection : null,
          behavior: HitTestBehavior.translucent,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Chapter Heading
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.book} ${widget.chapter}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // Verses List
              ...widget.verses.map((verse) {
                final isTarget =
                    verse.verseNumber == widget.targetVerseNumber;
                final isHighlighted = verse.highlightColor != null &&
                    verse.highlightColor!.isNotEmpty;
                final isBookmarked = verse.isBookmarked;
                final hasNote = verse.userNote != null &&
                    verse.userNote!.trim().isNotEmpty;
                final isVerseSelected =
                    _selectedVerseNumbers.contains(verse.verseNumber);

                final highlightBg = isHighlighted
                    ? BibleHighlightColor.getColor(
                        verse.highlightColor, isDark)
                    : Colors.transparent;
                final highlightAccent = isHighlighted
                    ? BibleHighlightColor.getAccentColor(
                        verse.highlightColor)
                    : Colors.transparent;

                // Background color calculation
                final cardBgColor = isVerseSelected
                    ? (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEFF6FF))
                    : (isHighlighted
                        ? highlightBg
                        : (isTarget
                            ? primaryBlue.withValues(alpha: 0.1)
                            : Colors.transparent));

                // Border calculation
                final Border borderDecoration = Border(
                  left: isVerseSelected
                      ? BorderSide(color: primaryBlue, width: 4.0)
                      : (isHighlighted
                          ? BorderSide(color: highlightAccent, width: 3.5)
                          : (isTarget
                              ? BorderSide(color: primaryBlue, width: 3.0)
                              : BorderSide.none)),
                  top: isVerseSelected
                      ? BorderSide(
                          color: primaryBlue.withValues(alpha: 0.5), width: 1.5)
                      : BorderSide.none,
                  right: isVerseSelected
                      ? BorderSide(
                          color: primaryBlue.withValues(alpha: 0.5), width: 1.5)
                      : BorderSide.none,
                  bottom: isVerseSelected
                      ? BorderSide(
                          color: primaryBlue.withValues(alpha: 0.5), width: 1.5)
                      : BorderSide.none,
                );

                return GestureDetector(
                  onLongPress: () => _onLongPressVerse(verse.verseNumber),
                  onTap: () => _onTapVerse(verse.verseNumber),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    key: _verseKeys[verse.verseNumber],
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: borderDecoration,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox in selection mode
                        if (_isSelectionMode) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10, top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isVerseSelected
                                  ? primaryBlue
                                  : Colors.transparent,
                              border: Border.all(
                                color: isVerseSelected
                                    ? primaryBlue
                                    : (isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8)),
                                width: 2,
                              ),
                            ),
                            child: isVerseSelected
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                        ],

                        // Verse Text Content with dynamic font size!
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                height: 1.65,
                                color: textColor,
                              ),
                              children: [
                                // Verse Number Badge
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isVerseSelected
                                          ? primaryBlue
                                          : (isTarget
                                              ? primaryBlue
                                              : (isHighlighted
                                                  ? highlightAccent
                                                      .withValues(alpha: 0.25)
                                                  : primaryBlue.withValues(
                                                      alpha: 0.14))),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${verse.verseNumber}',
                                      style: TextStyle(
                                        fontSize: (widget.fontSize * 0.7).clamp(10.0, 14.0),
                                        fontWeight: FontWeight.bold,
                                        color: (isVerseSelected || isTarget)
                                            ? Colors.white
                                            : (isHighlighted
                                                ? highlightAccent
                                                : primaryBlue),
                                      ),
                                    ),
                                  ),
                                ),

                                // Bookmark Ribbon Indicator
                                if (isBookmarked)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.bookmark_rounded,
                                        size: (widget.fontSize * 0.95).clamp(14.0, 20.0),
                                        color: isDark
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),

                                // Note Indicator
                                if (hasNote)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.sticky_note_2_rounded,
                                        size: (widget.fontSize * 0.9).clamp(13.0, 18.0),
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),

                                TextSpan(
                                  text: verse.text,
                                  style: TextStyle(
                                    fontSize: widget.fontSize,
                                    height: 1.65,
                                    color: textColor,
                                    fontWeight: isVerseSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 100),
            ],
          ),
        ),

        // Floating Selection Toolbar
        if (_isSelectionMode)
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: AnimatedBuilder(
              animation: _toolbarAnimController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _toolbarSlideAnim.value),
                  child: Opacity(
                    opacity: _toolbarFadeAnim.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selection info header row
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 6, left: 6, right: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_selectedVerseNumbers.length} verse${_selectedVerseNumbers.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getSelectionLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              onPressed: _clearSelection,
                              padding: EdgeInsets.zero,
                              tooltip: 'Clear selection',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ToolbarAction(
                          icon: Icons.palette_outlined,
                          label: 'Highlight',
                          color: primaryBlue,
                          isDark: isDark,
                          onTap: _openHighlightColorPicker,
                        ),
                        _ToolbarAction(
                          icon: areAllSelectedBookmarked
                              ? Icons.bookmark_remove_rounded
                              : Icons.bookmark_outline_rounded,
                          label: areAllSelectedBookmarked ? 'Unbookmark' : 'Bookmark',
                          color: areAllSelectedBookmarked
                              ? (isDark
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFD97706))
                              : primaryBlue,
                          isDark: isDark,
                          onTap: () {
                            widget.onToggleBookmark(_getSelectedVerses());
                            _clearSelection();
                          },
                        ),
                        _ToolbarAction(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: primaryBlue,
                          isDark: isDark,
                          onTap: () {
                            final selected = _getSelectedVerses();
                            widget.onShareVerse(selected);
                            _clearSelection();
                          },
                        ),
                        _ToolbarAction(
                          icon: Icons.copy_outlined,
                          label: 'Copy',
                          color: primaryBlue,
                          isDark: isDark,
                          onTap: () {
                            widget.onCopyVerse(_getSelectedVerses());
                            _clearSelection();
                          },
                        ),
                        _ToolbarAction(
                          icon: Icons.edit_note_rounded,
                          label: 'Note',
                          color: primaryBlue,
                          isDark: isDark,
                          onTap: () {
                            final selected = _getSelectedVerses();
                            if (selected.isNotEmpty) {
                              widget.onAddNote(selected.first);
                              _clearSelection();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
