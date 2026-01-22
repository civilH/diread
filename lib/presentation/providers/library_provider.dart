import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/book.dart';
import '../../data/models/reading_stats.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/local/database_helper.dart';

enum LibraryStatus {
  initial,
  loading,
  loaded,
  uploading,
  error,
}

enum SortOption {
  recentlyAdded,
  recentlyRead,
  title,
  author,
}

class LibraryProvider with ChangeNotifier {
  final BookRepository _bookRepository;
  final DatabaseHelper _dbHelper;

  LibraryStatus _status = LibraryStatus.initial;
  List<Book> _books = [];
  String? _errorMessage;
  SortOption _sortOption = SortOption.recentlyAdded;
  double _uploadProgress = 0.0;
  String _searchQuery = '';

  LibraryProvider({
    required BookRepository bookRepository,
    required DatabaseHelper dbHelper,
  })  : _bookRepository = bookRepository,
        _dbHelper = dbHelper;

  LibraryStatus get status => _status;
  List<Book> get books => _filteredAndSortedBooks;
  String? get errorMessage => _errorMessage;
  SortOption get sortOption => _sortOption;
  double get uploadProgress => _uploadProgress;
  bool get isLoading => _status == LibraryStatus.loading;
  bool get isUploading => _status == LibraryStatus.uploading;
  String get searchQuery => _searchQuery;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;

  List<Book> get _filteredAndSortedBooks {
    var filtered = _books;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = _books.where((book) {
        return book.title.toLowerCase().contains(query) ||
            (book.author?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sorting
    final sorted = List<Book>.from(filtered);
    switch (_sortOption) {
      case SortOption.recentlyAdded:
        sorted.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case SortOption.recentlyRead:
        sorted.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case SortOption.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.author:
        sorted.sort((a, b) =>
            (a.author?.toLowerCase() ?? '').compareTo(b.author?.toLowerCase() ?? ''));
        break;
    }
    return sorted;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  List<Book> get recentBooks {
    final sorted = List<Book>.from(_books);
    sorted.sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));
    return sorted.take(5).toList();
  }

  Future<void> loadBooks({bool forceRefresh = false}) async {
    // Skip if already loading (prevents duplicate API calls from multiple screens)
    if (_status == LibraryStatus.loading) {
      return;
    }

    // Skip if already loaded and not forcing refresh
    if (!forceRefresh && _status == LibraryStatus.loaded && _books.isNotEmpty) {
      return;
    }

    _status = LibraryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await _bookRepository.getBooks();
      // Cache books locally (skip on web - no SQLite support)
      if (!kIsWeb) {
        for (final book in _books) {
          await _dbHelper.cacheBook(book);
        }
      }
      _status = LibraryStatus.loaded;
    } catch (e) {
      // Try to load from cache (skip on web)
      if (!kIsWeb) {
        _books = await _dbHelper.getCachedBooks();
      }
      if (_books.isEmpty) {
        _errorMessage = 'Failed to load books: $e';
        _status = LibraryStatus.error;
      } else {
        _status = LibraryStatus.loaded;
      }
    }
    notifyListeners();
  }

  Future<void> refreshMetadata() async {
    _status = LibraryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await _bookRepository.refreshMetadata();
      // Cache books locally (skip on web - no SQLite support)
      if (!kIsWeb) {
        for (final book in _books) {
          await _dbHelper.cacheBook(book);
        }
      }
      _status = LibraryStatus.loaded;
    } catch (e) {
      _errorMessage = 'Failed to refresh metadata: $e';
      _status = LibraryStatus.error;
    }
    notifyListeners();
  }

  Future<Book?> uploadBook(File file, {String? title}) async {
    _status = LibraryStatus.uploading;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final book = await _bookRepository.uploadBook(file, title: title);
      _books.insert(0, book);
      _status = LibraryStatus.loaded;
      _uploadProgress = 1.0;
      notifyListeners();
      return book;
    } catch (e) {
      _errorMessage = 'Failed to upload book';
      _status = LibraryStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<Book?> uploadBookBytes(
    Uint8List bytes, {
    required String fileName,
    String? title,
  }) async {
    _status = LibraryStatus.uploading;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final book = await _bookRepository.uploadBookBytes(
        bytes,
        fileName: fileName,
        title: title,
      );
      _books.insert(0, book);
      _status = LibraryStatus.loaded;
      _uploadProgress = 1.0;
      notifyListeners();
      return book;
    } catch (e) {
      _errorMessage = 'Failed to upload book';
      _status = LibraryStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      await _bookRepository.deleteBook(bookId);
      _books.removeWhere((book) => book.id == bookId);
      await _dbHelper.deleteCachedBook(bookId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete book';
      notifyListeners();
      return false;
    }
  }

  Future<File?> downloadBook(Book book) async {
    try {
      final file = await _bookRepository.downloadBook(book);
      // Update book with local path
      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = _books[index].copyWith(
          isDownloaded: true,
          localPath: file.path,
        );
        await _dbHelper.cacheBook(_books[index]);
        notifyListeners();
      }
      return file;
    } catch (e) {
      _errorMessage = 'Failed to download book';
      notifyListeners();
      return null;
    }
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadBooks(forceRefresh: true);
  }

  /// Calculate reading statistics from available data
  Future<ReadingStats> getReadingStats() async {
    if (kIsWeb) {
      // On web, return basic stats from in-memory data
      return ReadingStats(
        totalBooks: _books.length,
        booksCompleted: 0,
        booksInProgress: 0,
        totalPagesRead: 0,
        totalHighlights: 0,
        totalBookmarks: 0,
      );
    }

    try {
      final allProgress = await _dbHelper.getAllProgress();

      int booksCompleted = 0;
      int booksInProgress = 0;
      int totalPagesRead = 0;
      DateTime? lastReadAt;

      for (final progress in allProgress) {
        totalPagesRead += progress.currentPage;

        if (progress.progressPercent >= 0.95) {
          booksCompleted++;
        } else if (progress.progressPercent > 0) {
          booksInProgress++;
        }

        if (progress.lastReadAt != null) {
          if (lastReadAt == null || progress.lastReadAt!.isAfter(lastReadAt)) {
            lastReadAt = progress.lastReadAt;
          }
        }
      }

      // Calculate streak (simplified: check if read today or yesterday)
      int streak = 0;
      if (lastReadAt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastRead = DateTime(lastReadAt.year, lastReadAt.month, lastReadAt.day);
        final difference = today.difference(lastRead).inDays;

        if (difference <= 1) {
          streak = 1; // At least 1 day streak
        }
      }

      return ReadingStats(
        totalBooks: _books.length,
        booksCompleted: booksCompleted,
        booksInProgress: booksInProgress,
        totalPagesRead: totalPagesRead,
        totalHighlights: 0, // Would need to count from highlights table
        totalBookmarks: 0, // Would need to count from bookmarks table
        lastReadAt: lastReadAt,
        currentStreak: streak,
      );
    } catch (_) {
      // Fallback to basic stats if detailed stats fail
      return ReadingStats(totalBooks: _books.length);
    }
  }
}
