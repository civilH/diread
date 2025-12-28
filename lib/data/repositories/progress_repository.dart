import '../models/reading_progress.dart';
import '../services/api_service.dart';
import '../local/database_helper.dart';

class ProgressRepository {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;

  ProgressRepository({
    required ApiService apiService,
    required DatabaseHelper dbHelper,
  })  : _apiService = apiService,
        _dbHelper = dbHelper;

  Future<ReadingProgress?> getProgress(String bookId) async {
    try {
      // Try to get from server first
      final response = await _apiService.getReadingProgress(bookId);
      if (response != null) {
        final progress = ReadingProgress.fromJson(response);
        // Cache locally
        await _dbHelper.saveProgress(progress);
        return progress;
      }
    } catch (e) {
      // If network fails, try local cache
      return await _dbHelper.getProgress(bookId);
    }
    return null;
  }

  Future<ReadingProgress> updateProgress({
    required String bookId,
    required int currentPage,
    String? currentCfi,
    required double progressPercent,
  }) async {
    // Save locally first for offline support
    final localProgress = ReadingProgress(
      id: '', // Will be updated from server
      userId: '', // Will be updated from server
      bookId: bookId,
      currentPage: currentPage,
      currentCfi: currentCfi,
      progressPercent: progressPercent,
      lastReadAt: DateTime.now(),
    );
    await _dbHelper.saveProgress(localProgress);

    try {
      // Sync with server
      final response = await _apiService.updateReadingProgress(
        bookId: bookId,
        currentPage: currentPage,
        currentCfi: currentCfi,
        progressPercent: progressPercent,
      );
      final progress = ReadingProgress.fromJson(response);
      // Update local cache with server response
      await _dbHelper.saveProgress(progress);
      return progress;
    } catch (e) {
      // Return local progress if server fails
      // It will be synced later
      return localProgress;
    }
  }

  Future<List<ReadingProgress>> getAllProgress() async {
    return await _dbHelper.getAllProgress();
  }

  Future<void> syncPendingProgress() async {
    final pendingProgress = await _dbHelper.getPendingSync();
    for (final progress in pendingProgress) {
      try {
        await _apiService.updateReadingProgress(
          bookId: progress.bookId,
          currentPage: progress.currentPage,
          currentCfi: progress.currentCfi,
          progressPercent: progress.progressPercent,
        );
        await _dbHelper.markAsSynced(progress.bookId);
      } catch (e) {
        // Will retry later
      }
    }
  }
}
