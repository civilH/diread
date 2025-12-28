import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reading_progress.dart';
import '../models/book.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'diread.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Reading Progress Table
    await db.execute('''
      CREATE TABLE reading_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL UNIQUE,
        current_page INTEGER DEFAULT 0,
        current_cfi TEXT,
        progress_percent REAL DEFAULT 0.0,
        last_read_at TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Books Cache Table
    await db.execute('''
      CREATE TABLE books_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT,
        cover_url TEXT,
        file_url TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER,
        total_pages INTEGER,
        created_at TEXT,
        local_path TEXT,
        local_cover_path TEXT
      )
    ''');

    // Bookmarks Cache Table
    await db.execute('''
      CREATE TABLE bookmarks_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        page_number INTEGER,
        cfi TEXT,
        title TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Highlights Cache Table
    await db.execute('''
      CREATE TABLE highlights_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        text TEXT NOT NULL,
        page_number INTEGER,
        cfi TEXT,
        color TEXT DEFAULT 'yellow',
        note TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Reading Settings Table
    await db.execute('''
      CREATE TABLE reading_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        font_size REAL DEFAULT 18.0,
        font_family TEXT DEFAULT 'default',
        line_height REAL DEFAULT 1.6,
        margin REAL DEFAULT 16.0,
        theme TEXT DEFAULT 'light',
        scroll_mode INTEGER DEFAULT 0
      )
    ''');

    // Insert default reading settings
    await db.insert('reading_settings', {
      'font_size': 18.0,
      'font_family': 'default',
      'line_height': 1.6,
      'margin': 16.0,
      'theme': 'light',
      'scroll_mode': 0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
  }

  // Reading Progress Methods
  Future<void> saveProgress(ReadingProgress progress) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'id': progress.id,
        'user_id': progress.userId,
        'book_id': progress.bookId,
        'current_page': progress.currentPage,
        'current_cfi': progress.currentCfi,
        'progress_percent': progress.progressPercent,
        'last_read_at': progress.lastReadAt?.toIso8601String(),
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReadingProgress?> getProgress(String bookId) async {
    final db = await database;
    final maps = await db.query(
      'reading_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );

    if (maps.isEmpty) return null;

    return ReadingProgress(
      id: maps.first['id'] as String,
      userId: maps.first['user_id'] as String,
      bookId: maps.first['book_id'] as String,
      currentPage: maps.first['current_page'] as int,
      currentCfi: maps.first['current_cfi'] as String?,
      progressPercent: maps.first['progress_percent'] as double,
      lastReadAt: maps.first['last_read_at'] != null
          ? DateTime.parse(maps.first['last_read_at'] as String)
          : null,
    );
  }

  Future<List<ReadingProgress>> getAllProgress() async {
    final db = await database;
    final maps = await db.query('reading_progress');

    return maps.map((map) => ReadingProgress(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      bookId: map['book_id'] as String,
      currentPage: map['current_page'] as int,
      currentCfi: map['current_cfi'] as String?,
      progressPercent: map['progress_percent'] as double,
      lastReadAt: map['last_read_at'] != null
          ? DateTime.parse(map['last_read_at'] as String)
          : null,
    )).toList();
  }

  Future<List<ReadingProgress>> getPendingSync() async {
    final db = await database;
    final maps = await db.query(
      'reading_progress',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return maps.map((map) => ReadingProgress(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      bookId: map['book_id'] as String,
      currentPage: map['current_page'] as int,
      currentCfi: map['current_cfi'] as String?,
      progressPercent: map['progress_percent'] as double,
      lastReadAt: map['last_read_at'] != null
          ? DateTime.parse(map['last_read_at'] as String)
          : null,
    )).toList();
  }

  Future<void> markAsSynced(String bookId) async {
    final db = await database;
    await db.update(
      'reading_progress',
      {'is_synced': 1},
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  // Books Cache Methods
  Future<void> cacheBook(Book book) async {
    final db = await database;
    await db.insert(
      'books_cache',
      {
        'id': book.id,
        'user_id': book.userId,
        'title': book.title,
        'author': book.author,
        'cover_url': book.coverUrl,
        'file_url': book.fileUrl,
        'file_type': book.fileType.name,
        'file_size': book.fileSize,
        'total_pages': book.totalPages,
        'created_at': book.createdAt?.toIso8601String(),
        'local_path': book.localPath,
        'local_cover_path': book.localCoverPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Book>> getCachedBooks() async {
    final db = await database;
    final maps = await db.query('books_cache');

    return maps.map((map) => Book(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      coverUrl: map['cover_url'] as String?,
      fileUrl: map['file_url'] as String,
      fileType: BookType.values.firstWhere(
        (e) => e.name == map['file_type'],
        orElse: () => BookType.pdf,
      ),
      fileSize: map['file_size'] as int?,
      totalPages: map['total_pages'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      localPath: map['local_path'] as String?,
      localCoverPath: map['local_cover_path'] as String?,
      isDownloaded: map['local_path'] != null,
    )).toList();
  }

  Future<void> deleteCachedBook(String bookId) async {
    final db = await database;
    await db.delete(
      'books_cache',
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // Reading Settings Methods
  Future<Map<String, dynamic>> getReadingSettings() async {
    final db = await database;
    final maps = await db.query('reading_settings', limit: 1);
    return maps.first;
  }

  Future<void> updateReadingSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.update('reading_settings', settings);
  }

  // Utility Methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('reading_progress');
    await db.delete('books_cache');
    await db.delete('bookmarks_cache');
    await db.delete('highlights_cache');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
