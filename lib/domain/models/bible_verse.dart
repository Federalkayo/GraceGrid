/// Sentinel value used to explicitly set a nullable field to null in copyWith.
const _sentinel = Object();

class BibleVerse {
  final String book;
  final int chapter;
  final int verseNumber;
  final String text;
  final bool isBookmarked;
  final String? highlightColor;
  final String? userNote;

  const BibleVerse({
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    this.isBookmarked = false,
    this.highlightColor,
    this.userNote,
  });

  BibleVerse copyWith({
    String? book,
    int? chapter,
    int? verseNumber,
    String? text,
    bool? isBookmarked,
    Object? highlightColor = _sentinel,
    Object? userNote = _sentinel,
  }) {
    return BibleVerse(
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      text: text ?? this.text,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      highlightColor: highlightColor == _sentinel
          ? this.highlightColor
          : highlightColor as String?,
      userNote: userNote == _sentinel
          ? this.userNote
          : userNote as String?,
    );
  }

  String get reference => '$book $chapter:$verseNumber';
}
