import 'dart:io';
import 'dart:typed_data';
import '../models/book.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../services/api_service.dart';
import '../../core/utils/file_utils.dart';

class BookRepository {
  final ApiService _apiService;

  BookRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<Book>> getBooks() async {
    final response = await _apiService.getBooks();
    final books = response.map((json) => Book.fromJson(json)).toList();

    // Check local availability for each book
    final updatedBooks = <Book>[];
    for (final book in books) {
      final localFile = await FileUtils.getLocalBook(book.id, book.fileExtension);
      final localCover = await FileUtils.getLocalCover(book.id);
      updatedBooks.add(book.copyWith(
        isDownloaded: localFile != null,
        localPath: localFile?.path,
        localCoverPath: localCover?.path,
      ));
    }

    return updatedBooks;
  }

  Future<Book> uploadBook(File file, {String? title}) async {
    final response = await _apiService.uploadBook(file, title: title);
    return Book.fromJson(response);
  }

  Future<Book> uploadBookBytes(
    Uint8List bytes, {
    required String fileName,
    String? title,
  }) async {
    final response = await _apiService.uploadBookBytes(
      bytes,
      fileName: fileName,
      title: title,
    );
    return Book.fromJson(response);
  }

  Future<Book> getBook(String id) async {
    final response = await _apiService.getBook(id);
    final book = Book.fromJson(response);

    final localFile = await FileUtils.getLocalBook(book.id, book.fileExtension);
    final localCover = await FileUtils.getLocalCover(book.id);

    return book.copyWith(
      isDownloaded: localFile != null,
      localPath: localFile?.path,
      localCoverPath: localCover?.path,
    );
  }

  Future<void> deleteBook(String id) async {
    await _apiService.deleteBook(id);
    // Also delete local files
    final book = await getBook(id).catchError((_) => throw Exception('Book not found'));
    await FileUtils.deleteLocalBook(id, book.fileExtension);
  }

  Future<File> downloadBook(Book book) async {
    // Check if already downloaded
    final existingFile = await FileUtils.getLocalBook(book.id, book.fileExtension);
    if (existingFile != null) {
      return existingFile;
    }

    // Download from server
    final bytes = await _apiService.downloadBook(book.id);
    return await FileUtils.saveBookLocally(book.id, bytes, book.fileExtension);
  }

  Future<Uint8List> downloadBookBytes(Book book) async {
    // Download from server as bytes (for web)
    final bytes = await _apiService.downloadBook(book.id);
    return Uint8List.fromList(bytes);
  }

  Future<bool> isBookDownloaded(String bookId, String extension) async {
    final file = await FileUtils.getLocalBook(bookId, extension);
    return file != null;
  }

  Future<void> deleteLocalBook(String bookId, String extension) async {
    await FileUtils.deleteLocalBook(bookId, extension);
  }

  // Bookmark Methods
  Future<List<Bookmark>> getBookmarks(String bookId) async {
    final response = await _apiService.getBookmarks(bookId);
    return response.map((json) => Bookmark.fromJson(json)).toList();
  }

  Future<Bookmark> addBookmark({
    required String bookId,
    int? pageNumber,
    String? cfi,
    String? title,
  }) async {
    final response = await _apiService.addBookmark(
      bookId: bookId,
      pageNumber: pageNumber,
      cfi: cfi,
      title: title,
    );
    return Bookmark.fromJson(response);
  }

  Future<void> deleteBookmark(String id) async {
    await _apiService.deleteBookmark(id);
  }

  // Highlight Methods
  Future<List<Highlight>> getHighlights(String bookId) async {
    final response = await _apiService.getHighlights(bookId);
    return response.map((json) => Highlight.fromJson(json)).toList();
  }

  Future<Highlight> addHighlight({
    required String bookId,
    required String text,
    int? pageNumber,
    String? cfi,
    String? color,
    String? note,
  }) async {
    final response = await _apiService.addHighlight(
      bookId: bookId,
      text: text,
      pageNumber: pageNumber,
      cfi: cfi,
      color: color,
      note: note,
    );
    return Highlight.fromJson(response);
  }

  Future<Highlight> updateHighlight({
    required String id,
    String? color,
    String? note,
  }) async {
    final response = await _apiService.updateHighlight(
      id: id,
      color: color,
      note: note,
    );
    return Highlight.fromJson(response);
  }

  Future<void> deleteHighlight(String id) async {
    await _apiService.deleteHighlight(id);
  }
}
