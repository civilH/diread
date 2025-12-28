import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../data/models/book.dart';
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

  LibraryProvider({
    required BookRepository bookRepository,
    required DatabaseHelper dbHelper,
  })  : _bookRepository = bookRepository,
        _dbHelper = dbHelper;

  LibraryStatus get status => _status;
  List<Book> get books => _sortedBooks;
  String? get errorMessage => _errorMessage;
  SortOption get sortOption => _sortOption;
  double get uploadProgress => _uploadProgress;
  bool get isLoading => _status == LibraryStatus.loading;
  bool get isUploading => _status == LibraryStatus.uploading;

  List<Book> get _sortedBooks {
    final sorted = List<Book>.from(_books);
    switch (_sortOption) {
      case SortOption.recentlyAdded:
        sorted.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case SortOption.recentlyRead:
        // This would need reading progress data
        sorted.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case SortOption.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.author:
        sorted.sort((a, b) =>
            (a.author ?? '').compareTo(b.author ?? ''));
        break;
    }
    return sorted;
  }

  List<Book> get recentBooks {
    final sorted = List<Book>.from(_books);
    sorted.sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));
    return sorted.take(5).toList();
  }

  Future<void> loadBooks() async {
    _status = LibraryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await _bookRepository.getBooks();
      // Cache books locally
      for (final book in _books) {
        await _dbHelper.cacheBook(book);
      }
      _status = LibraryStatus.loaded;
    } catch (e) {
      // Try to load from cache
      _books = await _dbHelper.getCachedBooks();
      if (_books.isEmpty) {
        _errorMessage = 'Failed to load books';
        _status = LibraryStatus.error;
      } else {
        _status = LibraryStatus.loaded;
      }
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
    await loadBooks();
  }
}
