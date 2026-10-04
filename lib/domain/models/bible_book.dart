enum Testament { oldTestament, newTestament }

class BibleBook {
  final String bookId;
  final String name;
  final String nameYoruba;
  final String abbreviation;
  final Testament testament;
  final int chapterCount;
  final String category;

  const BibleBook({
    required this.bookId,
    required this.name,
    this.nameYoruba = '',
    required this.abbreviation,
    required this.testament,
    required this.chapterCount,
    required this.category,
  });

  bool get isOldTestament => testament == Testament.oldTestament;
  bool get isNewTestament => testament == Testament.newTestament;
}
