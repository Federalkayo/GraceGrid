class BibleReadingProgress {
  final String book;
  final int chapter;
  final int verse;
  final String translation;
  final double progressPercentage;
  final String snippetText;
  final DateTime lastReadAt;
  final bool hasReadingHistory;
  final String? activePlanName;
  final int? activePlanDay;
  final int? activePlanTotalDays;

  const BibleReadingProgress({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.translation,
    required this.progressPercentage,
    required this.snippetText,
    required this.lastReadAt,
    this.hasReadingHistory = true,
    this.activePlanName,
    this.activePlanDay,
    this.activePlanTotalDays,
  });

  factory BibleReadingProgress.empty() {
    return BibleReadingProgress(
      book: 'Genesis',
      chapter: 1,
      verse: 1,
      translation: 'KJV',
      progressPercentage: 0.0,
      snippetText: 'In the beginning God created the heavens and the earth.',
      lastReadAt: DateTime.now(),
      hasReadingHistory: false,
    );
  }

  factory BibleReadingProgress.fromJson(Map<String, dynamic> json) {
    final rawTranslation = json['translation'] ?? 'KJV';
    // Migrate old NIV prefs to KJV.
    final translation = (rawTranslation == 'NIV' || rawTranslation == 'New International Version')
        ? 'KJV'
        : rawTranslation;
    return BibleReadingProgress(
      book: json['book'] ?? 'John',
      chapter: json['chapter'] ?? 3,
      verse: json['verse'] ?? 16,
      translation: translation,
      progressPercentage: (json['progressPercentage'] ?? 0.65).toDouble(),
      snippetText: json['snippetText'] ?? 'For God so loved the world that he gave his one and only Son...',
      lastReadAt: json['lastReadAt'] != null 
          ? DateTime.parse(json['lastReadAt']) 
          : DateTime.now(),
      hasReadingHistory: json['hasReadingHistory'] ?? true,
      activePlanName: json['activePlanName'],
      activePlanDay: json['activePlanDay'],
      activePlanTotalDays: json['activePlanTotalDays'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'translation': translation,
      'progressPercentage': progressPercentage,
      'snippetText': snippetText,
      'lastReadAt': lastReadAt.toIso8601String(),
      'hasReadingHistory': hasReadingHistory,
      'activePlanName': activePlanName,
      'activePlanDay': activePlanDay,
      'activePlanTotalDays': activePlanTotalDays,
    };
  }

  String get reference => '$book $chapter:$verse';
}
