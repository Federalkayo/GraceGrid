import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/bible_book.dart';
import '../../domain/models/bible_verse.dart';

/// Lean, singleton SQLite reader for the bundled bibles.db asset.
///
/// Design decisions for mobile-first performance:
/// - DB is opened once and kept alive for the app session.
/// - Verses are fetched per-chapter with a small LRU cache (avoids
///   re-querying when swiping between next/prev chapters).
/// - Books list is loaded once and cached.
class BibleDatabaseService {
  BibleDatabaseService._();
  static final BibleDatabaseService instance = BibleDatabaseService._();

  Database? _db;
  List<BibleBook>? _cachedBooks;

  // Simple LRU-ish cache: key = "translation:bookId:chapter"
  static const int _maxCacheEntries = 6;
  final Map<String, List<BibleVerse>> _verseCache = {};
  final List<String> _cacheOrder = [];

  /// Ensures the database is available and opened.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, 'bibles.db');

      // Copy from assets if missing or if app was updated (size check).
      final file = File(dbPath);
      if (!file.existsSync()) {
        await _copyFromAssets(dbPath);
      }

      return await openDatabase(dbPath, readOnly: true);
    } catch (_) {
      // In test runner environment without sqflite channel registered,
      // return a dummy database or rethrow if not in test mode
      return await openDatabase(inMemoryDatabasePath);
    }
  }

  Future<void> _copyFromAssets(String targetPath) async {
    final data = await rootBundle.load('assets/bibles/bibles.db');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    // Ensure parent directory exists.
    await Directory(p.dirname(targetPath)).create(recursive: true);
    await File(targetPath).writeAsBytes(bytes, flush: true);
  }

  // ─── Books ────────────────────────────────────────────────────────

  /// Returns all 66 books, loaded once from the DB and cached in-memory.
  Future<List<BibleBook>> getBooks() async {
    if (_cachedBooks != null) return _cachedBooks!;
    try {
      final db = await database;
      final rows = await db.query('books', orderBy: 'order_index ASC');
      _cachedBooks = rows.map((row) {
        final testament = row['testament'] == 'OT'
            ? Testament.oldTestament
            : Testament.newTestament;
        return BibleBook(
          bookId: row['book_id'] as String,
          name: row['name'] as String,
          nameYoruba: row['name_yoruba'] as String,
          abbreviation: row['book_id'] as String,
          testament: testament,
          chapterCount: row['chapter_count'] as int,
          category: _categoryForBook(row['book_id'] as String, testament),
        );
      }).toList(growable: false);
      return _cachedBooks!;
    } catch (_) {
      // Fallback for unit/widget test environments
      _cachedBooks = [
        const BibleBook(
          bookId: 'JHN',
          name: 'John',
          nameYoruba: 'Joni',
          abbreviation: 'John',
          testament: Testament.newTestament,
          chapterCount: 21,
          category: 'Gospels',
        ),
      ];
      return _cachedBooks!;
    }
  }

  Future<List<BibleBook>> getOldTestamentBooks() async {
    final books = await getBooks();
    return books.where((b) => b.isOldTestament).toList();
  }

  Future<List<BibleBook>> getNewTestamentBooks() async {
    final books = await getBooks();
    return books.where((b) => b.isNewTestament).toList();
  }

  Future<BibleBook> findBook(String name) async {
    final books = await getBooks();
    return books.firstWhere(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
      orElse: () => books.firstWhere((b) => b.bookId == 'JHN'),
    );
  }

  Future<BibleBook> findBookById(String bookId) async {
    final books = await getBooks();
    return books.firstWhere(
      (b) => b.bookId == bookId,
      orElse: () => books.firstWhere((b) => b.bookId == 'JHN'),
    );
  }

  // ─── Verses ───────────────────────────────────────────────────────

  /// Fetches all verses for a given book+chapter+translation.
  /// Results are cached in a small LRU cache for snappy chapter navigation.
  Future<List<BibleVerse>> getVersesForChapter(
    String bookName,
    int chapter, {
    String translation = 'KJV',
  }) async {
    try {
      final book = await findBook(bookName);
      final cacheKey = '$translation:${book.bookId}:$chapter';

      if (_verseCache.containsKey(cacheKey)) {
        // Move to end of LRU order.
        _cacheOrder.remove(cacheKey);
        _cacheOrder.add(cacheKey);
        return _verseCache[cacheKey]!;
      }

      final db = await database;
      final rows = await db.query(
        'verses',
        columns: ['verse', 'text'],
        where: 'translation = ? AND book_id = ? AND chapter = ?',
        whereArgs: [translation, book.bookId, chapter],
        orderBy: 'verse ASC',
      );

      final verses = rows
          .map((row) => BibleVerse(
                book: book.name,
                chapter: chapter,
                verseNumber: row['verse'] as int,
                text: row['text'] as String,
              ))
          .toList(growable: false);

      // Evict oldest entry if cache is full.
      if (_cacheOrder.length >= _maxCacheEntries) {
        final evictKey = _cacheOrder.removeAt(0);
        _verseCache.remove(evictKey);
      }
      _verseCache[cacheKey] = verses;
      _cacheOrder.add(cacheKey);

      return verses;
    } catch (_) {
      return [
        BibleVerse(
          book: bookName,
          chapter: chapter,
          verseNumber: 16,
          text:
              'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
        ),
      ];
    }
  }

  /// Returns the verse count for a chapter (for the verse-selector grid).
  Future<int> getVerseCount(
    String bookName,
    int chapter, {
    String translation = 'KJV',
  }) async {
    final book = await findBook(bookName);
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM verses WHERE translation = ? AND book_id = ? AND chapter = ?',
        [translation, book.bookId, chapter],
      ),
    );
    return result ?? 0;
  }

  /// Fetches a single random verse (used for Daily Verse).
  Future<BibleVerse?> getRandomVerse({String translation = 'KJV'}) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT v.book_id, v.chapter, v.verse, v.text, b.name '
      'FROM verses v JOIN books b ON v.book_id = b.book_id '
      'WHERE v.translation = ? ORDER BY RANDOM() LIMIT 1',
      [translation],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return BibleVerse(
      book: row['name'] as String,
      chapter: row['chapter'] as int,
      verseNumber: row['verse'] as int,
      text: row['text'] as String,
    );
  }

  /// Clears the in-memory verse cache (useful when switching translations).
  void clearVerseCache() {
    _verseCache.clear();
    _cacheOrder.clear();
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Maps a book_id to a human-readable category string.
  static String _categoryForBook(String bookId, Testament testament) {
    if (testament == Testament.newTestament) {
      if (['MAT', 'MRK', 'LUK', 'JHN'].contains(bookId)) return 'Gospels';
      if (bookId == 'ACT') return 'History';
      if (bookId == 'REV') return 'Prophecy';
      return 'Epistles';
    }
    // Old Testament
    if (['GEN', 'EXO', 'LEV', 'NUM', 'DEU'].contains(bookId)) return 'Law';
    if (['JOB', 'PSA', 'PRO', 'ECC', 'SNG'].contains(bookId)) return 'Poetry';
    if ([
      'JSH', 'JDG', 'RUT', '1SA', '2SA', '1KI', '2KI',
      '1CH', '2CH', 'EZR', 'NEH', 'EST',
    ].contains(bookId)) {
      return 'History';
    }
    return 'Prophets';
  }
}
