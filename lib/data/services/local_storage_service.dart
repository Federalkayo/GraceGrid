import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bible_reading.dart';
import '../../domain/models/sermon.dart';

class LocalStorageService {
  static const String _keyBibleReading = 'grace_grid_bible_reading';
  static const String _keySermonProgress = 'grace_grid_sermon_progress';
  static const String _keyIsSignedIn = 'grace_grid_is_signed_in';
  static const String _keyUserName = 'grace_grid_user_name';
  static const String _keySavedVerses = 'grace_grid_saved_verses';
  static const String _keyThemeMode = 'grace_grid_theme_mode';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    await _getPrefs();
  }

  // Bible Reading Persistence
  Future<void> saveBibleReading(BibleReadingProgress progress) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(progress.toJson());
    await prefs.setString(_keyBibleReading, jsonStr);
  }

  Future<BibleReadingProgress?> getBibleReading() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyBibleReading);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BibleReadingProgress.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Sermon Progress Persistence
  Future<void> saveSermonProgress(Sermon sermon) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(sermon.toJson());
    await prefs.setString(_keySermonProgress, jsonStr);
  }

  Future<Sermon?> getSermonProgress() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keySermonProgress);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Sermon.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Auth / User persistence
  Future<void> setSignedIn(bool isSignedIn, {String? userName}) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsSignedIn, isSignedIn);
    if (userName != null) {
      await prefs.setString(_keyUserName, userName);
    }
  }

  Future<bool> getIsSignedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyIsSignedIn) ?? false;
  }

  Future<String> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyUserName) ?? 'Grace';
  }

  static const String _keyBookmarkedVerses = 'grace_grid_bookmarked_verses';
  static const String _keyVerseHighlights = 'grace_grid_verse_highlights';
  static const String _keyVerseNotes = 'grace_grid_verse_notes';

  // Bookmarks persistence
  Future<void> toggleSaveVerse(String verseId) async {
    final prefs = await _getPrefs();
    final currentList = prefs.getStringList(_keyBookmarkedVerses) ??
        prefs.getStringList(_keySavedVerses) ??
        [];
    if (currentList.contains(verseId)) {
      currentList.remove(verseId);
    } else {
      currentList.add(verseId);
    }
    await prefs.setStringList(_keyBookmarkedVerses, currentList);
  }

  Future<bool> isVerseSaved(String verseId) async {
    final prefs = await _getPrefs();
    final currentList = prefs.getStringList(_keyBookmarkedVerses) ??
        prefs.getStringList(_keySavedVerses) ??
        [];
    return currentList.contains(verseId);
  }

  Future<Set<String>> getBookmarkedVerseKeys() async {
    final prefs = await _getPrefs();
    final list = prefs.getStringList(_keyBookmarkedVerses) ??
        prefs.getStringList(_keySavedVerses) ??
        [];
    return list.toSet();
  }

  Future<void> setVerseBookmarked(String verseKey, bool isBookmarked) async {
    final prefs = await _getPrefs();
    final list = (prefs.getStringList(_keyBookmarkedVerses) ??
            prefs.getStringList(_keySavedVerses) ??
            [])
        .toSet();
    if (isBookmarked) {
      list.add(verseKey);
    } else {
      list.remove(verseKey);
    }
    await prefs.setStringList(_keyBookmarkedVerses, list.toList());
  }

  // Highlights persistence (Map of verseKey -> colorName)
  Future<Map<String, String>> getVerseHighlights() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyVerseHighlights);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> setVerseHighlight(String verseKey, String? colorName) async {
    final highlights = await getVerseHighlights();
    if (colorName == null || colorName.isEmpty) {
      highlights.remove(verseKey);
    } else {
      highlights[verseKey] = colorName;
    }
    final prefs = await _getPrefs();
    await prefs.setString(_keyVerseHighlights, jsonEncode(highlights));
  }

  // Verse Notes persistence (Map of verseKey -> noteText)
  Future<Map<String, String>> getVerseNotes() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyVerseNotes);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> setVerseNote(String verseKey, String? noteText) async {
    final notes = await getVerseNotes();
    if (noteText == null || noteText.trim().isEmpty) {
      notes.remove(verseKey);
    } else {
      notes[verseKey] = noteText.trim();
    }
    final prefs = await _getPrefs();
    await prefs.setString(_keyVerseNotes, jsonEncode(notes));
  }

  static const String _keyFontSize = 'grace_grid_bible_font_size';

  // Font Size persistence
  Future<double> getFontSize() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyFontSize) ?? 16.0;
  }

  Future<void> saveFontSize(double size) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyFontSize, size);
  }

  // Theme preference
  Future<void> saveThemeMode(String mode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyThemeMode);
  }
}


