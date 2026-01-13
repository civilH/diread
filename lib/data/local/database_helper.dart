import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reading_progress.dart';
import '../models/reading_goal.dart';
import '../models/book.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'diread.db';
  static const int _dbVersion = 2; // Upgraded for new tables

  /// Check if database is available (not on web)
  bool get isAvailable => !kIsWeb;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web platform');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web platform');
    }
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

    // Reading Goals Table
    await db.execute('''
      CREATE TABLE reading_goals (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        target INTEGER NOT NULL,
        current INTEGER DEFAULT 0,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT DEFAULT 'active'
      )
    ''');

    // Reading Sessions Table (for time tracking)
    await db.execute('''
      CREATE TABLE reading_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        pages_read INTEGER DEFAULT 0,
        duration_seconds INTEGER DEFAULT 0
      )
    ''');

    // Daily Stats Table (aggregated daily statistics)
    await db.execute('''
      CREATE TABLE daily_stats (
        date TEXT PRIMARY KEY,
        pages_read INTEGER DEFAULT 0,
        minutes_read INTEGER DEFAULT 0,
        books_opened INTEGER DEFAULT 0,
        sessions_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
    if (oldVersion < 2) {
      // Add new tables for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_goals (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          target INTEGER NOT NULL,
          current INTEGER DEFAULT 0,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          status TEXT DEFAULT 'active'
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          book_id TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          pages_read INTEGER DEFAULT 0,
          duration_seconds INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_stats (
          date TEXT PRIMARY KEY,
          pages_read INTEGER DEFAULT 0,
          minutes_read INTEGER DEFAULT 0,
          books_opened INTEGER DEFAULT 0,
          sessions_count INTEGER DEFAULT 0
        )
      ''');
    }
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
    if (kIsWeb) return; // Skip on web
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
    if (kIsWeb) return []; // Return empty on web
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
    if (kIsWeb) return {}; // Return empty on web
    final db = await database;
    final maps = await db.query('reading_settings', limit: 1);
    if (maps.isEmpty) return {};
    return maps.first;
  }

  Future<void> updateReadingSettings(Map<String, dynamic> settings) async {
    if (kIsWeb) return; // Skip on web
    final db = await database;
    await db.update('reading_settings', settings);
  }

  // Reading Goals Methods
  Future<void> saveGoal(ReadingGoal goal) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'reading_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReadingGoal>> getActiveGoals() async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query(
      'reading_goals',
      where: 'status = ?',
      whereArgs: ['active'],
    );
    return maps.map((map) => ReadingGoal.fromMap(map)).toList();
  }

  Future<ReadingGoal?> getDailyGoal() async {
    if (kIsWeb) return null;
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final maps = await db.query(
      'reading_goals',
      where: 'type = ? AND start_date >= ?',
      whereArgs: ['daily', startOfDay.toIso8601String()],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ReadingGoal.fromMap(maps.first);
  }

  Future<void> updateGoalProgress(String goalId, int current) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'reading_goals',
      {'current': current},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<void> completeGoal(String goalId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'reading_goals',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // Reading Sessions Methods
  Future<int> startReadingSession(String bookId) async {
    if (kIsWeb) return -1;
    final db = await database;
    return await db.insert('reading_sessions', {
      'book_id': bookId,
      'start_time': DateTime.now().toIso8601String(),
    });
  }

  Future<void> endReadingSession(int sessionId, int pagesRead) async {
    if (kIsWeb) return;
    final db = await database;
    final now = DateTime.now();

    // Get session start time
    final maps = await db.query(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isNotEmpty) {
      final startTime = DateTime.parse(maps.first['start_time'] as String);
      final durationSeconds = now.difference(startTime).inSeconds;

      await db.update(
        'reading_sessions',
        {
          'end_time': now.toIso8601String(),
          'pages_read': pagesRead,
          'duration_seconds': durationSeconds,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      // Update daily stats
      await _updateDailyStats(pagesRead, durationSeconds ~/ 60);
    }
  }

  Future<void> _updateDailyStats(int pagesRead, int minutesRead) async {
    final db = await database;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Try to get existing stats for today
    final existing = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (existing.isEmpty) {
      await db.insert('daily_stats', {
        'date': dateStr,
        'pages_read': pagesRead,
        'minutes_read': minutesRead,
        'books_opened': 1,
        'sessions_count': 1,
      });
    } else {
      await db.rawUpdate('''
        UPDATE daily_stats
        SET pages_read = pages_read + ?,
            minutes_read = minutes_read + ?,
            sessions_count = sessions_count + 1
        WHERE date = ?
      ''', [pagesRead, minutesRead, dateStr]);
    }
  }

  Future<Map<String, dynamic>?> getTodayStats() async {
    if (kIsWeb) return null;
    final db = await database;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    if (kIsWeb) return [];
    final db = await database;
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final weekAgoStr = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

    return await db.query(
      'daily_stats',
      where: 'date >= ?',
      whereArgs: [weekAgoStr],
      orderBy: 'date ASC',
    );
  }

  Future<int> getCurrentStreak() async {
    if (kIsWeb) return 0;
    final db = await database;
    final stats = await db.query(
      'daily_stats',
      orderBy: 'date DESC',
      limit: 30, // Check last 30 days
    );

    if (stats.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final stat in stats) {
      final statDate = stat['date'] as String;
      final expectedDate = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      if (statDate == expectedDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Utility Methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('reading_progress');
    await db.delete('books_cache');
    await db.delete('bookmarks_cache');
    await db.delete('highlights_cache');
    await db.delete('reading_goals');
    await db.delete('reading_sessions');
    await db.delete('daily_stats');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
