import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../data/models/book.dart';
import '../../data/models/reading_progress.dart';
import '../../data/models/bookmark.dart';
import '../../data/models/highlight.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/local/database_helper.dart';
import '../../core/config/theme.dart';
import '../../core/config/app_config.dart';

class ReaderSettings {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double margin;
  final ReadingTheme theme;
  final bool scrollMode;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.fontFamily = 'default',
    this.lineHeight = 1.6,
    this.margin = 16.0,
    this.theme = ReadingTheme.light,
    this.scrollMode = false,
  });

  ReaderSettings copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? margin,
    ReadingTheme? theme,
    bool? scrollMode,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      margin: margin ?? this.margin,
      theme: theme ?? this.theme,
      scrollMode: scrollMode ?? this.scrollMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'font_size': fontSize,
      'font_family': fontFamily,
      'line_height': lineHeight,
      'margin': margin,
      'theme': theme.name,
      'scroll_mode': scrollMode ? 1 : 0,
    };
  }

  factory ReaderSettings.fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      fontSize: (map['font_size'] as num?)?.toDouble() ?? 18.0,
      fontFamily: map['font_family'] as String? ?? 'default',
      lineHeight: (map['line_height'] as num?)?.toDouble() ?? 1.6,
      margin: (map['margin'] as num?)?.toDouble() ?? 16.0,
      theme: ReadingTheme.values.firstWhere(
        (e) => e.name == map['theme'],
        orElse: () => ReadingTheme.light,
      ),
      scrollMode: map['scroll_mode'] == 1,
    );
  }
}

enum ReaderStatus {
  initial,
  loading,
  ready,
  error,
}

class ReaderProvider with ChangeNotifier {
  final BookRepository _bookRepository;
  final ProgressRepository _progressRepository;
  final DatabaseHelper _dbHelper;

  ReaderStatus _status = ReaderStatus.initial;
  Book? _currentBook;
  File? _bookFile;
  Uint8List? _bookBytes; // For web support
  ReadingProgress? _progress;
  List<Bookmark> _bookmarks = [];
  List<Highlight> _highlights = [];
  ReaderSettings _settings = const ReaderSettings();
  String? _errorMessage;

  // PDF specific
  int _currentPage = 0;
  int _totalPages = 0;

  // EPUB specific
  String? _currentCfi;
  List<Map<String, dynamic>> _tableOfContents = [];

  ReaderProvider({
    required BookRepository bookRepository,
    required ProgressRepository progressRepository,
    required DatabaseHelper dbHelper,
  })  : _bookRepository = bookRepository,
        _progressRepository = progressRepository,
        _dbHelper = dbHelper;

  ReaderStatus get status => _status;
  Book? get currentBook => _currentBook;
  File? get bookFile => _bookFile;
  Uint8List? get bookBytes => _bookBytes;
  ReadingProgress? get progress => _progress;
  List<Bookmark> get bookmarks => _bookmarks;
  List<Highlight> get highlights => _highlights;
  ReaderSettings get settings => _settings;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get currentCfi => _currentCfi;
  List<Map<String, dynamic>> get tableOfContents => _tableOfContents;

  double get progressPercent {
    if (_totalPages == 0) return 0.0;
    return _currentPage / _totalPages;
  }

  bool get isBookmarked {
    if (_currentBook == null) return false;
    if (_currentBook!.fileType == BookType.pdf) {
      return _bookmarks.any((b) => b.pageNumber == _currentPage);
    } else {
      return _bookmarks.any((b) => b.cfi == _currentCfi);
    }
  }

  Future<void> loadBook(Book book) async {
    _status = ReaderStatus.loading;
    _currentBook = book;
    _errorMessage = null;
    notifyListeners();

    try {
      // Download book - handle web differently
      if (kIsWeb) {
        // On web, download as bytes
        _bookBytes = await _bookRepository.downloadBookBytes(book);
      } else {
        // On native platforms, use file system
        if (book.localPath != null && await File(book.localPath!).exists()) {
          _bookFile = File(book.localPath!);
        } else {
          _bookFile = await _bookRepository.downloadBook(book);
        }
      }

      // Load reading progress
      _progress = await _progressRepository.getProgress(book.id);
      if (_progress != null) {
        _currentPage = _progress!.currentPage;
        _currentCfi = _progress!.currentCfi;
      }

      // Load bookmarks and highlights
      _bookmarks = await _bookRepository.getBookmarks(book.id);
      _highlights = await _bookRepository.getHighlights(book.id);

      // Load reading settings
      final settingsMap = await _dbHelper.getReadingSettings();
      _settings = ReaderSettings.fromMap(settingsMap);

      _status = ReaderStatus.ready;
    } catch (e) {
      _errorMessage = 'Failed to load book: $e';
      _status = ReaderStatus.error;
    }
    notifyListeners();
  }

  void setTotalPages(int pages) {
    if (_totalPages == pages) return;
    _totalPages = pages;
    notifyListeners();
  }

  void setTableOfContents(List<Map<String, dynamic>> toc) {
    _tableOfContents = toc;
    notifyListeners();
  }

  Future<void> updatePage(int page) async {
    if (_currentPage == page) return;
    _currentPage = page;
    // Don't notify - let UI update independently
    _debouncedSaveProgress();
  }

  Future<void> updateCfi(String cfi) async {
    if (_currentCfi == cfi) return;
    _currentCfi = cfi;
    _debouncedSaveProgress();
  }

  DateTime? _lastSaveTime;

  void _debouncedSaveProgress() {
    final now = DateTime.now();
    if (_lastSaveTime != null &&
        now.difference(_lastSaveTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastSaveTime = now;
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (_currentBook == null) return;

    _progress = await _progressRepository.updateProgress(
      bookId: _currentBook!.id,
      currentPage: _currentPage,
      currentCfi: _currentCfi,
      progressPercent: progressPercent,
    );
  }

  // Bookmark Methods
  Future<void> toggleBookmark() async {
    if (_currentBook == null) return;

    if (isBookmarked) {
      // Remove bookmark
      final bookmark = _currentBook!.fileType == BookType.pdf
          ? _bookmarks.firstWhere((b) => b.pageNumber == _currentPage)
          : _bookmarks.firstWhere((b) => b.cfi == _currentCfi);
      await _bookRepository.deleteBookmark(bookmark.id);
      _bookmarks.removeWhere((b) => b.id == bookmark.id);
    } else {
      // Add bookmark
      final bookmark = await _bookRepository.addBookmark(
        bookId: _currentBook!.id,
        pageNumber: _currentBook!.fileType == BookType.pdf ? _currentPage : null,
        cfi: _currentBook!.fileType == BookType.epub ? _currentCfi : null,
        title: 'Page ${_currentPage + 1}',
      );
      _bookmarks.add(bookmark);
    }
    notifyListeners();
  }

  Future<void> goToBookmark(Bookmark bookmark) async {
    if (bookmark.pageNumber != null) {
      _currentPage = bookmark.pageNumber!;
    }
    if (bookmark.cfi != null) {
      _currentCfi = bookmark.cfi;
    }
    notifyListeners();
    await _saveProgress();
  }

  // Highlight Methods
  Future<void> addHighlight({
    required String text,
    HighlightColor color = HighlightColor.yellow,
    String? note,
  }) async {
    if (_currentBook == null) return;

    final highlight = await _bookRepository.addHighlight(
      bookId: _currentBook!.id,
      text: text,
      pageNumber: _currentBook!.fileType == BookType.pdf ? _currentPage : null,
      cfi: _currentBook!.fileType == BookType.epub ? _currentCfi : null,
      color: color.name,
      note: note,
    );
    _highlights.add(highlight);
    notifyListeners();
  }

  Future<void> updateHighlight({
    required String id,
    HighlightColor? color,
    String? note,
  }) async {
    final highlight = await _bookRepository.updateHighlight(
      id: id,
      color: color?.name,
      note: note,
    );
    final index = _highlights.indexWhere((h) => h.id == id);
    if (index != -1) {
      _highlights[index] = highlight;
    }
    notifyListeners();
  }

  Future<void> deleteHighlight(String id) async {
    await _bookRepository.deleteHighlight(id);
    _highlights.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // Settings Methods
  void updateFontSize(double size) {
    final clampedSize = size.clamp(
      AppConfig.minFontSize,
      AppConfig.maxFontSize,
    );
    _settings = _settings.copyWith(fontSize: clampedSize);
    _saveSettings();
    notifyListeners();
  }

  void updateFontFamily(String family) {
    _settings = _settings.copyWith(fontFamily: family);
    _saveSettings();
    notifyListeners();
  }

  void updateLineHeight(double height) {
    _settings = _settings.copyWith(lineHeight: height);
    _saveSettings();
    notifyListeners();
  }

  void updateMargin(double margin) {
    _settings = _settings.copyWith(margin: margin);
    _saveSettings();
    notifyListeners();
  }

  void updateTheme(ReadingTheme theme) {
    _settings = _settings.copyWith(theme: theme);
    _saveSettings();
    notifyListeners();
  }

  void toggleScrollMode() {
    _settings = _settings.copyWith(scrollMode: !_settings.scrollMode);
    _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _dbHelper.updateReadingSettings(_settings.toMap());
  }

  void closeBook() {
    _currentBook = null;
    _bookFile = null;
    _progress = null;
    _bookmarks = [];
    _highlights = [];
    _currentPage = 0;
    _totalPages = 0;
    _currentCfi = null;
    _tableOfContents = [];
    _status = ReaderStatus.initial;
    notifyListeners();
  }
}
