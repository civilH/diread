/// Reading statistics model
class ReadingStats {
  final int totalBooks;
  final int booksCompleted;
  final int booksInProgress;
  final int totalPagesRead;
  final int totalHighlights;
  final int totalBookmarks;
  final DateTime? lastReadAt;
  final int currentStreak; // Consecutive days reading
  final Map<String, int> readingByMonth; // Pages read per month

  const ReadingStats({
    this.totalBooks = 0,
    this.booksCompleted = 0,
    this.booksInProgress = 0,
    this.totalPagesRead = 0,
    this.totalHighlights = 0,
    this.totalBookmarks = 0,
    this.lastReadAt,
    this.currentStreak = 0,
    this.readingByMonth = const {},
  });

  double get completionRate {
    if (totalBooks == 0) return 0.0;
    return booksCompleted / totalBooks;
  }

  ReadingStats copyWith({
    int? totalBooks,
    int? booksCompleted,
    int? booksInProgress,
    int? totalPagesRead,
    int? totalHighlights,
    int? totalBookmarks,
    DateTime? lastReadAt,
    int? currentStreak,
    Map<String, int>? readingByMonth,
  }) {
    return ReadingStats(
      totalBooks: totalBooks ?? this.totalBooks,
      booksCompleted: booksCompleted ?? this.booksCompleted,
      booksInProgress: booksInProgress ?? this.booksInProgress,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      totalHighlights: totalHighlights ?? this.totalHighlights,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      currentStreak: currentStreak ?? this.currentStreak,
      readingByMonth: readingByMonth ?? this.readingByMonth,
    );
  }
}
