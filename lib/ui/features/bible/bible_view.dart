import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gracegride2/data/services/bible_data_service.dart';
import 'package:gracegride2/data/services/local_storage_service.dart';
import 'package:gracegride2/domain/models/bible_reading.dart';
import 'package:gracegride2/domain/models/bible_verse.dart';
import 'package:gracegride2/domain/models/bible_highlight_color.dart';
import 'widgets/scripture_header_bar.dart';
import 'widgets/scripture_selector_page.dart';
import 'widgets/bible_reader_content.dart';
import 'widgets/scripture_share_sheet.dart';
import 'widgets/saved_verses_sheet.dart';
import 'widgets/reader_settings_sheet.dart';

class BibleView extends StatefulWidget {
  const BibleView({super.key});

  @override
  State<BibleView> createState() => _BibleViewState();
}

class _BibleViewState extends State<BibleView> {
  String _selectedBook = 'John';
  int _selectedChapter = 3;
  int _selectedVerse = 16;
  String _selectedTranslation = 'KJV';
  double _fontSize = 16.0;

  static const List<String> _translations = ['KJV', 'ASV', 'YOR'];
  final LocalStorageService _storageService = LocalStorageService();

  // Verse data loaded from DB.
  List<BibleVerse> _currentVerses = [];
  bool _isLoadingVerses = true;

  // In-memory cache for fast session updates: Key = "book:chapter"
  final Map<String, Map<int, BibleVerse>> _modifications = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
  }

  String _normalizeTranslation(String raw) {
    switch (raw) {
      case 'New International Version':
      case 'NIV':
        return 'KJV';
      case 'King James Version':
        return 'KJV';
      default:
        return _translations.contains(raw) ? raw : 'KJV';
    }
  }

  Future<void> _loadSavedPosition() async {
    final saved = await _storageService.getBibleReading();
    final savedFontSize = await _storageService.getFontSize();
    if (mounted) {
      setState(() {
        _fontSize = savedFontSize;
        if (saved != null) {
          _selectedBook = saved.book;
          _selectedChapter = saved.chapter;
          _selectedVerse = saved.verse;
          _selectedTranslation = _normalizeTranslation(saved.translation);
        }
      });
    }
    await _loadVerses();
  }

  Future<void> _loadVerses() async {
    if (!mounted) return;
    setState(() => _isLoadingVerses = true);

    final dbVerses = await BibleDataService.getVersesForChapter(
      _selectedBook,
      _selectedChapter,
      translation: _selectedTranslation,
    );

    // Fetch persisted bookmarks, highlights, and notes from disk
    final savedBookmarks = await _storageService.getBookmarkedVerseKeys();
    final savedHighlights = await _storageService.getVerseHighlights();
    final savedNotes = await _storageService.getVerseNotes();

    if (!mounted) return;

    final cacheKey = '$_selectedBook:$_selectedChapter';
    final mods = _modifications[cacheKey];

    // Merge persistent data onto fetched DB verses while ALWAYS keeping v.text for active translation
    final mergedVerses = dbVerses.map((v) {
      final verseKey = '${v.book}:${v.chapter}:${v.verseNumber}';
      final isBookmarked = savedBookmarks.contains(verseKey);
      final highlightColor = savedHighlights[verseKey];
      final userNote = savedNotes[verseKey];

      final mod = mods?[v.verseNumber];

      return v.copyWith(
        isBookmarked: mod != null ? mod.isBookmarked : isBookmarked,
        highlightColor: mod != null ? mod.highlightColor : highlightColor,
        userNote: mod != null ? mod.userNote : userNote,
      );
    }).toList();

    setState(() {
      _currentVerses = mergedVerses;
      _isLoadingVerses = false;
    });
  }

  void _persistPosition() {
    final book = BibleDataService.findBook(_selectedBook);
    final progress = BibleReadingProgress(
      book: _selectedBook,
      chapter: _selectedChapter,
      verse: _selectedVerse,
      translation: _selectedTranslation,
      progressPercentage:
          (_selectedChapter / book.chapterCount).clamp(0.0, 1.0),
      snippetText: 'Read $_selectedBook $_selectedChapter:$_selectedVerse',
      lastReadAt: DateTime.now(),
      hasReadingHistory: true,
    );
    _storageService.saveBibleReading(progress);
  }

  void _openScriptureSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScriptureSelectorPage(
        initialBook: _selectedBook,
        initialChapter: _selectedChapter,
        initialVerse: _selectedVerse,
        selectedTranslation: _selectedTranslation,
        onSelectLocation: (book, chapter, verse) {
          setState(() {
            _selectedBook = book;
            _selectedChapter = chapter;
            _selectedVerse = verse;
          });
          _persistPosition();
          _loadVerses();
        },
      ),
    );
  }

  Future<void> _openSavedVersesSheet() async {
    final bookmarks = await _storageService.getBookmarkedVerseKeys();
    final highlights = await _storageService.getVerseHighlights();
    final notes = await _storageService.getVerseNotes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavedVersesSheet(
        bookmarkedVerseKeys: bookmarks,
        highlightedVerses: highlights,
        verseNotes: notes,
        onNavigateToVerse: (book, chapter, verse) {
          setState(() {
            _selectedBook = book;
            _selectedChapter = chapter;
            _selectedVerse = verse;
          });
          _persistPosition();
          _loadVerses();
        },
        onRemoveBookmark: (verseKey) async {
          await _storageService.setVerseBookmarked(verseKey, false);
          _modifications.clear();
          await _loadVerses();
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark removed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onRemoveHighlight: (verseKey) async {
          await _storageService.setVerseHighlight(verseKey, null);
          _modifications.clear();
          await _loadVerses();
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Highlight removed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _openFontSizeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderSettingsSheet(
        currentFontSize: _fontSize,
        onFontSizeChanged: (newSize) {
          setState(() {
            _fontSize = newSize;
          });
          _storageService.saveFontSize(newSize);
        },
      ),
    );
  }

  void _onNextChapter() {
    final currentBook = BibleDataService.findBook(_selectedBook);
    if (_selectedChapter < currentBook.chapterCount) {
      setState(() {
        _selectedChapter++;
        _selectedVerse = 1;
      });
    } else {
      final currentIdx = BibleDataService.allBooks.indexOf(currentBook);
      if (currentIdx < BibleDataService.allBooks.length - 1) {
        final nextBook = BibleDataService.allBooks[currentIdx + 1];
        setState(() {
          _selectedBook = nextBook.name;
          _selectedChapter = 1;
          _selectedVerse = 1;
        });
      }
    }
    _persistPosition();
    _loadVerses();
  }

  void _onPreviousChapter() {
    if (_selectedChapter > 1) {
      setState(() {
        _selectedChapter--;
        _selectedVerse = 1;
      });
    } else {
      final currentBook = BibleDataService.findBook(_selectedBook);
      final currentIdx = BibleDataService.allBooks.indexOf(currentBook);
      if (currentIdx > 0) {
        final prevBook = BibleDataService.allBooks[currentIdx - 1];
        setState(() {
          _selectedBook = prevBook.name;
          _selectedChapter = prevBook.chapterCount;
          _selectedVerse = 1;
        });
      }
    }
    _persistPosition();
    _loadVerses();
  }

  void _onChangeTranslation(String newTranslation) {
    setState(() => _selectedTranslation = newTranslation);
    _modifications.clear(); // Clear session cache so text re-renders in new translation!
    BibleDataService.clearVerseCache();
    _persistPosition();
    _loadVerses();
  }

  // ─── Modification helpers ───────────────────────────────────────

  void _applyModification(int verseNumber, BibleVerse updated) {
    final cacheKey = '$_selectedBook:$_selectedChapter';
    _modifications.putIfAbsent(cacheKey, () => {});
    _modifications[cacheKey]![verseNumber] = updated;

    final idx =
        _currentVerses.indexWhere((v) => v.verseNumber == verseNumber);
    if (idx != -1) {
      _currentVerses[idx] = updated;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Scripture Header Bar
            ScriptureHeaderBar(
              book: _selectedBook,
              chapter: _selectedChapter,
              verse: _selectedVerse,
              translation: _selectedTranslation,
              translations: _translations,
              onTapSelector: _openScriptureSelector,
              onChangeTranslation: _onChangeTranslation,
              onPreviousChapter: _onPreviousChapter,
              onNextChapter: _onNextChapter,
              onTapSavedVerses: _openSavedVersesSheet,
              onTapFontSize: _openFontSizeSheet,
            ),

            // Bible Reader Body
            Expanded(
              child: _isLoadingVerses
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : _currentVerses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No verses found for this chapter',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : BibleReaderContent(
                          book: _selectedBook,
                          chapter: _selectedChapter,
                          targetVerseNumber: _selectedVerse,
                          verses: _currentVerses,
                          fontSize: _fontSize,
                          onToggleBookmark: (selectedVerses) async {
                            final areAllBookmarked =
                                selectedVerses.every((v) => v.isBookmarked);
                            final newStatus = !areAllBookmarked;

                            for (final verse in selectedVerses) {
                              final verseKey =
                                  '${verse.book}:${verse.chapter}:${verse.verseNumber}';
                              await _storageService.setVerseBookmarked(
                                  verseKey, newStatus);
                              final updated =
                                  verse.copyWith(isBookmarked: newStatus);
                              _applyModification(verse.verseNumber, updated);
                            }
                            setState(() {});
                            if (!context.mounted) return;
                            final label = selectedVerses.length == 1
                                ? selectedVerses.first.reference
                                : '${selectedVerses.length} verses';
                            final actionLabel =
                                newStatus ? 'Bookmarked' : 'Removed bookmark for';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$actionLabel $label'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onToggleHighlight:
                              (selectedVerses, colorName) async {
                            for (final verse in selectedVerses) {
                              final verseKey =
                                  '${verse.book}:${verse.chapter}:${verse.verseNumber}';
                              await _storageService.setVerseHighlight(
                                  verseKey, colorName);
                              final updated = verse.copyWith(
                                highlightColor: colorName,
                              );
                              _applyModification(verse.verseNumber, updated);
                            }
                            setState(() {});
                            if (!context.mounted) return;
                            final label = selectedVerses.length == 1
                                ? selectedVerses.first.reference
                                : '${selectedVerses.length} verses';
                            final colorLabel = colorName != null
                                ? '${BibleHighlightColor.getLabel(colorName)} highlight for'
                                : 'Removed highlight for';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$colorLabel $label'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onShareVerse: (selectedVerses) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ScriptureShareSheet(
                                book: _selectedBook,
                                chapter: _selectedChapter,
                                selectedVerses: selectedVerses,
                                translation: _selectedTranslation,
                              ),
                            );
                          },
                          onCopyVerse: (selectedVerses) {
                            final text = selectedVerses
                                .map((v) => '${v.reference} "${v.text}"')
                                .join('\n\n');
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedVerses.length == 1
                                      ? 'Copied ${selectedVerses.first.reference}'
                                      : 'Copied ${selectedVerses.length} verses',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onAddNote: (verse) {
                            _showNoteDialog(context, verse);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, BibleVerse verse) {
    final controller = TextEditingController(text: verse.userNote ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note for ${verse.reference}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your reflections or notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final noteText = controller.text.trim();
              final verseKey =
                  '${verse.book}:${verse.chapter}:${verse.verseNumber}';
              await _storageService.setVerseNote(
                  verseKey, noteText.isEmpty ? null : noteText);

              final updated = verse.copyWith(
                userNote: noteText.isEmpty ? null : noteText,
              );
              _applyModification(verse.verseNumber, updated);
              setState(() {});
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note saved successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }
}
