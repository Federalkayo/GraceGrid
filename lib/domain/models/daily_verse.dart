class DailyVerse {
  final String id;
  final String verseText;
  final String reference;
  final String translation;
  final String category;
  final String dateString;
  final bool isSaved;
  final int shareCount;

  const DailyVerse({
    required this.id,
    required this.verseText,
    required this.reference,
    required this.translation,
    required this.category,
    required this.dateString,
    this.isSaved = false,
    this.shareCount = 142,
  });

  DailyVerse copyWith({
    String? id,
    String? verseText,
    String? reference,
    String? translation,
    String? category,
    String? dateString,
    bool? isSaved,
    int? shareCount,
  }) {
    return DailyVerse(
      id: id ?? this.id,
      verseText: verseText ?? this.verseText,
      reference: reference ?? this.reference,
      translation: translation ?? this.translation,
      category: category ?? this.category,
      dateString: dateString ?? this.dateString,
      isSaved: isSaved ?? this.isSaved,
      shareCount: shareCount ?? this.shareCount,
    );
  }
}
