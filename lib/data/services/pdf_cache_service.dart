import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for caching PDF metadata to speed up initial loading
/// Note: Syncfusion PDF viewer handles page rendering cache internally
/// This service focuses on metadata caching (page count, etc.)
class PdfCacheService {
  static const String _cacheVersion = '1';

  /// Get the cache directory for PDF metadata
  static Future<Directory> _getCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Get metadata file path for a book
  static Future<File> _getMetadataFile(String bookId) async {
    final cacheDir = await _getCacheDir();
    return File('${cacheDir.path}/$bookId.json');
  }

  /// Check if cached metadata exists for a book
  static Future<bool> hasCache(String bookId) async {
    try {
      final file = await _getMetadataFile(bookId);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get cached page count for a book
  static Future<int?> getCachedPageCount(String bookId) async {
    try {
      final file = await _getMetadataFile(bookId);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final metadata = jsonDecode(content) as Map<String, dynamic>;

      if (metadata['version'] != _cacheVersion) {
        return null;
      }

      return metadata['pageCount'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Cache page count for a book
  static Future<void> cachePageCount(String bookId, int pageCount) async {
    try {
      final file = await _getMetadataFile(bookId);
      await file.writeAsString(jsonEncode({
        'version': _cacheVersion,
        'bookId': bookId,
        'pageCount': pageCount,
        'cachedAt': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      // Ignore cache write errors
    }
  }

  /// Invalidate cache for a specific book
  static Future<void> invalidateCache(String bookId) async {
    try {
      final file = await _getMetadataFile(bookId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all PDF metadata cache
  static Future<void> clearAllCaches() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/pdf_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get total cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/pdf_cache');
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
