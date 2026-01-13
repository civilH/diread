import '../models/book.dart';
import '../models/reading_progress.dart';

/// Genre categories detected from book titles and metadata
enum BookGenre {
  fiction,
  nonFiction,
  selfHelp,
  technology,
  science,
  history,
  biography,
  fantasy,
  mystery,
  romance,
  business,
  philosophy,
  religion,
  education,
  unknown,
}

/// Content-based recommendation system for books
/// Uses reading history, preferences, and book metadata to suggest books
class RecommendationService {
  // Genre keywords for detection
  static const Map<BookGenre, List<String>> _genreKeywords = {
    BookGenre.fiction: ['novel', 'fiction', 'story', 'stories', 'tales'],
    BookGenre.nonFiction: ['nonfiction', 'non-fiction', 'true', 'real'],
    BookGenre.selfHelp: ['self-help', 'self help', 'habits', 'success', 'mindset', 'motivation', 'productivity', 'growth', 'improve'],
    BookGenre.technology: ['programming', 'software', 'code', 'coding', 'developer', 'computer', 'tech', 'digital', 'algorithm', 'data', 'web', 'app', 'android', 'ios', 'flutter', 'python', 'javascript'],
    BookGenre.science: ['science', 'physics', 'chemistry', 'biology', 'quantum', 'evolution', 'scientific', 'research'],
    BookGenre.history: ['history', 'historical', 'war', 'ancient', 'civilization', 'century', 'empire'],
    BookGenre.biography: ['biography', 'autobiography', 'memoir', 'life', 'story of'],
    BookGenre.fantasy: ['fantasy', 'magic', 'dragon', 'wizard', 'kingdom', 'quest', 'mythical'],
    BookGenre.mystery: ['mystery', 'detective', 'crime', 'thriller', 'suspense', 'murder'],
    BookGenre.romance: ['romance', 'love', 'heart', 'passion', 'romantic'],
    BookGenre.business: ['business', 'entrepreneur', 'startup', 'marketing', 'leadership', 'management', 'finance', 'investing', 'money', 'wealth'],
    BookGenre.philosophy: ['philosophy', 'philosophical', 'wisdom', 'thinking', 'ethics', 'moral'],
    BookGenre.religion: ['religion', 'spiritual', 'faith', 'god', 'bible', 'quran', 'buddhism', 'meditation', 'prayer'],
    BookGenre.education: ['education', 'learning', 'teaching', 'study', 'guide', 'handbook', 'manual', 'tutorial'],
  };

  /// Detect genre from book title and author
  static BookGenre detectGenre(Book book) {
    final searchText = '${book.title} ${book.author ?? ''}'.toLowerCase();

    int maxScore = 0;
    BookGenre detectedGenre = BookGenre.unknown;

    for (final entry in _genreKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (searchText.contains(keyword)) {
          score += keyword.length; // Longer keywords = more specific match
        }
      }
      if (score > maxScore) {
        maxScore = score;
        detectedGenre = entry.key;
      }
    }

    return detectedGenre;
  }

  /// Generate recommendations based on user's reading history
  static List<BookRecommendation> getRecommendations({
    required List<Book> allBooks,
    required List<ReadingProgress> readingHistory,
    int limit = 5,
  }) {
    if (allBooks.isEmpty) return [];

    // Build user profile from reading history
    final userProfile = _buildUserProfile(allBooks, readingHistory);

    // Score each book
    final scoredBooks = <BookRecommendation>[];

    for (final book in allBooks) {
      // Skip books already completed (>90% read)
      final progress = readingHistory.where((p) => p.bookId == book.id).firstOrNull;
      if (progress != null && progress.progressPercent > 0.9) continue;

      final score = _calculateBookScore(book, userProfile, progress);
      final reasons = _getRecommendationReasons(book, userProfile, progress);

      if (score > 0) {
        scoredBooks.add(BookRecommendation(
          book: book,
          score: score,
          reasons: reasons,
          genre: detectGenre(book),
        ));
      }
    }

    // Sort by score and return top recommendations
    scoredBooks.sort((a, b) => b.score.compareTo(a.score));
    return scoredBooks.take(limit).toList();
  }

  /// Get "Because you read X" recommendations
  static List<BecauseYouReadRecommendation> getBecauseYouRead({
    required List<Book> allBooks,
    required List<ReadingProgress> readingHistory,
    int limit = 3,
  }) {
    final recommendations = <BecauseYouReadRecommendation>[];

    // Get recently completed or highly progressed books
    final recentlyRead = readingHistory
        .where((p) => p.progressPercent > 0.5)
        .toList()
      ..sort((a, b) {
        final aTime = a.lastReadAt ?? DateTime(2000);
        final bTime = b.lastReadAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

    for (final progress in recentlyRead.take(5)) {
      final sourceBook = allBooks.where((b) => b.id == progress.bookId).firstOrNull;
      if (sourceBook == null) continue;

      final similarBooks = getSimilarBooks(
        targetBook: sourceBook,
        allBooks: allBooks,
        readingHistory: readingHistory,
        limit: 3,
      );

      if (similarBooks.isNotEmpty) {
        recommendations.add(BecauseYouReadRecommendation(
          sourceBook: sourceBook,
          recommendedBooks: similarBooks,
        ));
      }

      if (recommendations.length >= limit) break;
    }

    return recommendations;
  }

  /// Get "Continue Reading" books - started but not finished
  static List<Book> getContinueReading({
    required List<Book> allBooks,
    required List<ReadingProgress> readingHistory,
    int limit = 3,
  }) {
    final continueBooks = <_BookWithProgress>[];

    for (final progress in readingHistory) {
      // Books with progress between 1% and 95%
      if (progress.progressPercent > 0.01 && progress.progressPercent < 0.95) {
        final book = allBooks.where((b) => b.id == progress.bookId).firstOrNull;
        if (book != null) {
          continueBooks.add(_BookWithProgress(book, progress));
        }
      }
    }

    // Sort by last read time (most recent first)
    continueBooks.sort((a, b) {
      final aTime = a.progress.lastReadAt ?? DateTime(2000);
      final bTime = b.progress.lastReadAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return continueBooks.take(limit).map((bp) => bp.book).toList();
  }

  /// Get books similar to a specific book
  static List<Book> getSimilarBooks({
    required Book targetBook,
    required List<Book> allBooks,
    List<ReadingProgress>? readingHistory,
    int limit = 4,
  }) {
    final similarBooks = <_ScoredBook>[];
    final targetGenre = detectGenre(targetBook);
    final targetKeywords = _extractKeywords(targetBook.title);

    for (final book in allBooks) {
      if (book.id == targetBook.id) continue;

      // Skip already completed books if history is provided
      if (readingHistory != null) {
        final progress = readingHistory.where((p) => p.bookId == book.id).firstOrNull;
        if (progress != null && progress.progressPercent > 0.9) continue;
      }

      double score = 0;

      // Same author - highest weight
      if (targetBook.author != null &&
          book.author != null &&
          _normalizeAuthor(targetBook.author!) == _normalizeAuthor(book.author!)) {
        score += 50;
      }

      // Same genre - high weight
      final bookGenre = detectGenre(book);
      if (bookGenre != BookGenre.unknown && bookGenre == targetGenre) {
        score += 35;
      }

      // Same file type
      if (book.fileType == targetBook.fileType) {
        score += 10;
      }

      // Similar page count (within 30%)
      if (targetBook.totalPages != null && book.totalPages != null) {
        final ratio = book.totalPages! / targetBook.totalPages!;
        if (ratio >= 0.7 && ratio <= 1.3) {
          score += 15;
        }
      }

      // Similar title words (keyword matching)
      final bookWords = _extractKeywords(book.title);
      final commonWords = targetKeywords.intersection(bookWords);
      score += commonWords.length * 8;

      if (score > 0) {
        similarBooks.add(_ScoredBook(book, score));
      }
    }

    similarBooks.sort((a, b) => b.score.compareTo(a.score));
    return similarBooks.take(limit).map((sb) => sb.book).toList();
  }

  /// Get books by genre
  static List<Book> getBooksByGenre({
    required BookGenre genre,
    required List<Book> allBooks,
    List<ReadingProgress>? readingHistory,
    int limit = 10,
  }) {
    final genreBooks = <Book>[];

    for (final book in allBooks) {
      if (detectGenre(book) == genre) {
        // Skip completed books if history provided
        if (readingHistory != null) {
          final progress = readingHistory.where((p) => p.bookId == book.id).firstOrNull;
          if (progress != null && progress.progressPercent > 0.9) continue;
        }
        genreBooks.add(book);
      }
    }

    return genreBooks.take(limit).toList();
  }

  /// Get user's favorite genres based on reading history
  static List<GenrePreference> getFavoriteGenres({
    required List<Book> allBooks,
    required List<ReadingProgress> readingHistory,
  }) {
    final genreCounts = <BookGenre, int>{};
    final genreProgress = <BookGenre, double>{};

    for (final progress in readingHistory) {
      if (progress.progressPercent < 0.1) continue; // Skip barely started

      final book = allBooks.where((b) => b.id == progress.bookId).firstOrNull;
      if (book == null) continue;

      final genre = detectGenre(book);
      if (genre == BookGenre.unknown) continue;

      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      genreProgress[genre] = (genreProgress[genre] ?? 0) + progress.progressPercent;
    }

    final preferences = <GenrePreference>[];
    for (final entry in genreCounts.entries) {
      preferences.add(GenrePreference(
        genre: entry.key,
        bookCount: entry.value,
        averageProgress: genreProgress[entry.key]! / entry.value,
      ));
    }

    // Sort by book count, then by average progress
    preferences.sort((a, b) {
      final countCompare = b.bookCount.compareTo(a.bookCount);
      if (countCompare != 0) return countCompare;
      return b.averageProgress.compareTo(a.averageProgress);
    });

    return preferences;
  }

  /// Get quick picks based on reading time available
  static List<Book> getQuickReads({
    required List<Book> allBooks,
    required List<ReadingProgress> readingHistory,
    int maxPages = 100,
    int limit = 5,
  }) {
    final quickBooks = <Book>[];

    for (final book in allBooks) {
      // Skip completed books
      final progress = readingHistory.where((p) => p.bookId == book.id).firstOrNull;
      if (progress != null && progress.progressPercent > 0.9) continue;

      // Check if it's a quick read
      if (book.totalPages != null && book.totalPages! <= maxPages) {
        quickBooks.add(book);
      }
    }

    // Sort by page count (shortest first)
    quickBooks.sort((a, b) => (a.totalPages ?? 0).compareTo(b.totalPages ?? 0));

    return quickBooks.take(limit).toList();
  }

  /// Build user profile from reading history
  static _UserProfile _buildUserProfile(
    List<Book> allBooks,
    List<ReadingProgress> readingHistory,
  ) {
    final authorCounts = <String, int>{};
    final fileTypeCounts = <BookType, int>{};
    final genreCounts = <BookGenre, int>{};
    int totalPagesRead = 0;
    int booksStarted = 0;
    int booksCompleted = 0;

    for (final progress in readingHistory) {
      final book = allBooks.where((b) => b.id == progress.bookId).firstOrNull;
      if (book == null) continue;

      // Count authors (normalize names)
      if (book.author != null) {
        final normalizedAuthor = _normalizeAuthor(book.author!);
        authorCounts[normalizedAuthor] = (authorCounts[normalizedAuthor] ?? 0) + 1;
      }

      // Count file types
      fileTypeCounts[book.fileType] = (fileTypeCounts[book.fileType] ?? 0) + 1;

      // Count genres
      final genre = detectGenre(book);
      if (genre != BookGenre.unknown) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }

      // Track pages read
      totalPagesRead += progress.currentPage;

      // Track completion
      if (progress.progressPercent > 0.01) booksStarted++;
      if (progress.progressPercent > 0.9) booksCompleted++;
    }

    // Find favorite authors (read more than once)
    final favoriteAuthors = authorCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toList();

    // Find preferred file type
    BookType? preferredType;
    if (fileTypeCounts.isNotEmpty) {
      preferredType = fileTypeCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Find favorite genres
    final favoriteGenres = genreCounts.entries
        .where((e) => e.value >= 1)
        .map((e) => e.key)
        .toList();

    return _UserProfile(
      favoriteAuthors: favoriteAuthors,
      authorCounts: authorCounts,
      preferredFileType: preferredType,
      favoriteGenres: favoriteGenres,
      genreCounts: genreCounts,
      totalPagesRead: totalPagesRead,
      booksStarted: booksStarted,
      booksCompleted: booksCompleted,
    );
  }

  /// Calculate recommendation score for a book
  static double _calculateBookScore(
    Book book,
    _UserProfile profile,
    ReadingProgress? progress,
  ) {
    double score = 10; // Base score

    // Boost for favorite authors (highest priority)
    if (book.author != null) {
      final normalizedAuthor = _normalizeAuthor(book.author!);
      if (profile.favoriteAuthors.contains(normalizedAuthor)) {
        score += 40;
      } else if (profile.authorCounts.containsKey(normalizedAuthor)) {
        score += 20;
      }
    }

    // Boost for favorite genres
    final genre = detectGenre(book);
    if (genre != BookGenre.unknown) {
      if (profile.favoriteGenres.contains(genre)) {
        score += 25;
      }
      // Additional boost based on how many books of this genre user has read
      final genreCount = profile.genreCounts[genre] ?? 0;
      score += genreCount * 5;
    }

    // Boost for preferred file type
    if (profile.preferredFileType == book.fileType) {
      score += 10;
    }

    // Boost for unstarted books (discovery)
    if (progress == null || progress.progressPercent == 0) {
      score += 8;
    }

    // Slight boost for books with page count (better metadata)
    if (book.totalPages != null && book.totalPages! > 0) {
      score += 3;
    }

    // Boost newer books
    if (book.createdAt != null) {
      final daysSinceAdded = DateTime.now().difference(book.createdAt!).inDays;
      if (daysSinceAdded < 7) {
        score += 15; // Recently added
      } else if (daysSinceAdded < 30) {
        score += 8;
      }
    }

    return score;
  }

  /// Get human-readable reasons for recommendation
  static List<String> _getRecommendationReasons(
    Book book,
    _UserProfile profile,
    ReadingProgress? progress,
  ) {
    final reasons = <String>[];

    if (book.author != null) {
      final normalizedAuthor = _normalizeAuthor(book.author!);
      if (profile.favoriteAuthors.contains(normalizedAuthor)) {
        reasons.add('By an author you love');
      } else if (profile.authorCounts.containsKey(normalizedAuthor)) {
        reasons.add('From a familiar author');
      }
    }

    final genre = detectGenre(book);
    if (genre != BookGenre.unknown && profile.favoriteGenres.contains(genre)) {
      reasons.add('Matches your favorite genre');
    }

    if (progress == null || progress.progressPercent == 0) {
      reasons.add('Not started yet');
    }

    if (book.createdAt != null) {
      final daysSinceAdded = DateTime.now().difference(book.createdAt!).inDays;
      if (daysSinceAdded < 7) {
        reasons.add('Recently added');
      }
    }

    if (book.fileType == profile.preferredFileType) {
      reasons.add('Your preferred format');
    }

    if (reasons.isEmpty) {
      reasons.add('Picked for you');
    }

    return reasons;
  }

  /// Normalize author name for comparison
  static String _normalizeAuthor(String author) {
    return author.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Extract keywords from title
  static Set<String> _extractKeywords(String title) {
    final stopWords = {'the', 'a', 'an', 'of', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'dare', 'ought', 'used', 'with', 'by', 'from', 'as', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between', 'under', 'again', 'further', 'then', 'once'};
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();
  }
}

/// A book recommendation with score and reasons
class BookRecommendation {
  final Book book;
  final double score;
  final List<String> reasons;
  final BookGenre genre;

  const BookRecommendation({
    required this.book,
    required this.score,
    required this.reasons,
    this.genre = BookGenre.unknown,
  });

  String get primaryReason => reasons.isNotEmpty ? reasons.first : 'Recommended';
}

/// "Because you read X" recommendation
class BecauseYouReadRecommendation {
  final Book sourceBook;
  final List<Book> recommendedBooks;

  const BecauseYouReadRecommendation({
    required this.sourceBook,
    required this.recommendedBooks,
  });
}

/// Genre preference based on reading history
class GenrePreference {
  final BookGenre genre;
  final int bookCount;
  final double averageProgress;

  const GenrePreference({
    required this.genre,
    required this.bookCount,
    required this.averageProgress,
  });

  String get genreName {
    switch (genre) {
      case BookGenre.fiction: return 'Fiction';
      case BookGenre.nonFiction: return 'Non-Fiction';
      case BookGenre.selfHelp: return 'Self-Help';
      case BookGenre.technology: return 'Technology';
      case BookGenre.science: return 'Science';
      case BookGenre.history: return 'History';
      case BookGenre.biography: return 'Biography';
      case BookGenre.fantasy: return 'Fantasy';
      case BookGenre.mystery: return 'Mystery';
      case BookGenre.romance: return 'Romance';
      case BookGenre.business: return 'Business';
      case BookGenre.philosophy: return 'Philosophy';
      case BookGenre.religion: return 'Religion';
      case BookGenre.education: return 'Education';
      case BookGenre.unknown: return 'Other';
    }
  }
}

/// Internal class for user reading profile
class _UserProfile {
  final List<String> favoriteAuthors;
  final Map<String, int> authorCounts;
  final BookType? preferredFileType;
  final List<BookGenre> favoriteGenres;
  final Map<BookGenre, int> genreCounts;
  final int totalPagesRead;
  final int booksStarted;
  final int booksCompleted;

  const _UserProfile({
    required this.favoriteAuthors,
    required this.authorCounts,
    this.preferredFileType,
    required this.favoriteGenres,
    required this.genreCounts,
    required this.totalPagesRead,
    required this.booksStarted,
    required this.booksCompleted,
  });
}

/// Internal helper class
class _BookWithProgress {
  final Book book;
  final ReadingProgress progress;

  _BookWithProgress(this.book, this.progress);
}

/// Internal helper class
class _ScoredBook {
  final Book book;
  final double score;

  _ScoredBook(this.book, this.score);
}
