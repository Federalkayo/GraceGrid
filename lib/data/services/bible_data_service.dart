import '../../domain/models/bible_book.dart';
import '../../domain/models/bible_verse.dart';
import 'bible_database_service.dart';

/// Provides Bible book metadata and verse data.
///
/// This service now delegates entirely to [BibleDatabaseService], which reads
/// from the bundled SQLite asset. Synchronous accessors are kept for backward
/// compatibility by pre-loading the books list at startup via [initialize].
class BibleDataService {
  // Pre-loaded book list – populated by [initialize].
  static List<BibleBook> _allBooks = [];

  /// Must be called once (e.g. in main.dart) before the UI accesses
  /// [allBooks] or [findBook]. This is a fast in-memory cache after the
  /// first DB hit.
  static Future<void> initialize() async {
    _allBooks = await BibleDatabaseService.instance.getBooks();
  }

  static List<BibleBook> get allBooks => _allBooks;

  static List<BibleBook> get oldTestamentBooks =>
      _allBooks.where((b) => b.isOldTestament).toList();

  static List<BibleBook> get newTestamentBooks =>
      _allBooks.where((b) => b.isNewTestament).toList();

  static BibleBook findBook(String name) {
    return _allBooks.firstWhere(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
      orElse: () => _allBooks.firstWhere(
        (b) => b.bookId == 'JHN',
        orElse: () => _allBooks.first,
      ),
    );
  }

  /// Fetches verses for a chapter from the SQLite database.
  /// [translation] should be one of: 'KJV', 'ASV', 'YOR'.
  static Future<List<BibleVerse>> getVersesForChapter(
    String bookName,
    int chapter, {
    String translation = 'KJV',
  }) {
    return BibleDatabaseService.instance.getVersesForChapter(
      bookName,
      chapter,
      translation: translation,
    );
  }

  /// Returns the verse count for a specific chapter.
  static Future<int> getVerseCount(
    String bookName,
    int chapter, {
    String translation = 'KJV',
  }) {
    return BibleDatabaseService.instance.getVerseCount(
      bookName,
      chapter,
      translation: translation,
    );
  }

  /// Clears the in-memory verse cache (call when translation changes).
  static void clearVerseCache() {
    BibleDatabaseService.instance.clearVerseCache();
  }
}
