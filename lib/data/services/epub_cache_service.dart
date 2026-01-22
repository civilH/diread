import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'epub_service.dart';

/// Service for caching parsed EPUB content to speed up subsequent opens
class EpubCacheService {
  static const String _cacheVersion = '1';

  /// Get the cache directory for a specific book
  static Future<Directory> _getCacheDir(String bookId) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/epub_cache/$bookId');
    return cacheDir;
  }

  /// Check if a valid cache exists for the given book
  static Future<bool> hasValidCache(String bookId, {String? fileHash}) async {
    try {
      final cacheDir = await _getCacheDir(bookId);
      final metadataFile = File('${cacheDir.path}/metadata.json');

      if (!await metadataFile.exists()) {
        return false;
      }

      final metadataJson = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      // Check cache version
      if (metadata['version'] != _cacheVersion) {
        return false;
      }

      // Check if file hash matches (if provided)
      if (fileHash != null && metadata['fileHash'] != fileHash) {
        return false;
      }

      // Check if chapters directory exists and has files
      final chaptersDir = Directory('${cacheDir.path}/chapters');
      if (!await chaptersDir.exists()) {
        return false;
      }

      final chapterCount = metadata['totalChapters'] as int? ?? 0;
      if (chapterCount == 0) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load cached EPUB book data
  static Future<EpubBook?> loadFromCache(String bookId) async {
    try {
      final cacheDir = await _getCacheDir(bookId);
      final metadataFile = File('${cacheDir.path}/metadata.json');

      if (!await metadataFile.exists()) {
        return null;
      }

      final metadataJson = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      // Load chapters
      final chapters = <EpubChapter>[];
      final chaptersDir = Directory('${cacheDir.path}/chapters');
      final totalChapters = metadata['totalChapters'] as int? ?? 0;

      for (var i = 0; i < totalChapters; i++) {
        final chapterFile = File('${chaptersDir.path}/chapter_$i.json');
        if (await chapterFile.exists()) {
          final chapterJson = await chapterFile.readAsString();
          final chapterData = jsonDecode(chapterJson) as Map<String, dynamic>;
          chapters.add(EpubChapter(
            id: chapterData['id'] as String,
            title: chapterData['title'] as String,
            href: chapterData['href'] as String,
            content: chapterData['content'] as String,
            index: chapterData['index'] as int,
          ));
        }
      }

      if (chapters.isEmpty) {
        return null;
      }

      // Load table of contents
      final tocList = (metadata['tableOfContents'] as List<dynamic>?) ?? [];
      final tableOfContents = tocList.map((item) => _tocItemFromMap(item as Map<String, dynamic>)).toList();

      // Load images
      final images = <String, Uint8List>{};
      final imagesDir = Directory('${cacheDir.path}/images');
      if (await imagesDir.exists()) {
        final imageIndex = metadata['imageIndex'] as Map<String, dynamic>? ?? {};
        for (final entry in imageIndex.entries) {
          final imageFile = File('${imagesDir.path}/${entry.value}');
          if (await imageFile.exists()) {
            images[entry.key] = await imageFile.readAsBytes();
          }
        }
      }

      return EpubBook(
        title: metadata['title'] as String? ?? 'Unknown Title',
        author: metadata['author'] as String?,
        cover: metadata['cover'] as String?,
        chapters: chapters,
        tableOfContents: tableOfContents,
        images: images,
        language: metadata['language'] as String?,
        publisher: metadata['publisher'] as String?,
      );
    } catch (e) {
      // If loading fails, return null to trigger re-parsing
      return null;
    }
  }

  /// Parse EPUB and cache the result for future use
  static Future<EpubBook> parseAndCache(Uint8List bytes, String bookId) async {
    // Parse the EPUB first
    final book = await EpubService.parse(bytes);

    // Cache the parsed data in background (don't block return)
    _cacheBook(book, bookId, bytes).catchError((e) {
      // Silently ignore cache errors - the book is already parsed
    });

    return book;
  }

  /// Internal method to cache book data
  static Future<void> _cacheBook(EpubBook book, String bookId, Uint8List originalBytes) async {
    try {
      final cacheDir = await _getCacheDir(bookId);

      // Create cache directories
      await cacheDir.create(recursive: true);
      final chaptersDir = Directory('${cacheDir.path}/chapters');
      await chaptersDir.create(recursive: true);
      final imagesDir = Directory('${cacheDir.path}/images');
      await imagesDir.create(recursive: true);

      // Calculate file hash for cache invalidation
      final fileHash = md5.convert(originalBytes).toString();

      // Save chapters
      for (final chapter in book.chapters) {
        final chapterFile = File('${chaptersDir.path}/chapter_${chapter.index}.json');
        await chapterFile.writeAsString(jsonEncode({
          'id': chapter.id,
          'title': chapter.title,
          'href': chapter.href,
          'content': chapter.content,
          'index': chapter.index,
        }));
      }

      // Save images and build index
      final imageIndex = <String, String>{};
      var imageCounter = 0;
      for (final entry in book.images.entries) {
        final extension = _getImageExtension(entry.key);
        final imageName = 'img_$imageCounter$extension';
        final imageFile = File('${imagesDir.path}/$imageName');
        await imageFile.writeAsBytes(entry.value);
        imageIndex[entry.key] = imageName;
        imageCounter++;
      }

      // Save metadata
      final metadataFile = File('${cacheDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode({
        'version': _cacheVersion,
        'title': book.title,
        'author': book.author,
        'cover': book.cover,
        'language': book.language,
        'publisher': book.publisher,
        'totalChapters': book.chapters.length,
        'tableOfContents': book.tableOfContents.map((t) => t.toMap()).toList(),
        'imageIndex': imageIndex,
        'fileHash': fileHash,
        'cachedAt': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      // If caching fails, just ignore - the book is already loaded
    }
  }

  /// Invalidate cache for a specific book
  static Future<void> invalidateCache(String bookId) async {
    try {
      final cacheDir = await _getCacheDir(bookId);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors when invalidating cache
    }
  }

  /// Clear all EPUB caches
  static Future<void> clearAllCaches() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final epubCacheDir = Directory('${tempDir.path}/epub_cache');
      if (await epubCacheDir.exists()) {
        await epubCacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors when clearing cache
    }
  }

  /// Get total cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final epubCacheDir = Directory('${tempDir.path}/epub_cache');
      if (!await epubCacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in epubCacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clean old caches to stay within size limit
  static Future<void> cleanOldCaches({int maxSizeBytes = 500 * 1024 * 1024}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final epubCacheDir = Directory('${tempDir.path}/epub_cache');
      if (!await epubCacheDir.exists()) {
        return;
      }

      // Get all cached books with their metadata
      final cachedBooks = <String, DateTime>{};
      await for (final entity in epubCacheDir.list()) {
        if (entity is Directory) {
          final metadataFile = File('${entity.path}/metadata.json');
          if (await metadataFile.exists()) {
            try {
              final metadata = jsonDecode(await metadataFile.readAsString());
              final cachedAt = DateTime.tryParse(metadata['cachedAt'] ?? '');
              if (cachedAt != null) {
                cachedBooks[entity.path] = cachedAt;
              }
            } catch (e) {
              // Invalid cache, mark for deletion with old date
              cachedBooks[entity.path] = DateTime(2000);
            }
          }
        }
      }

      // Sort by date (oldest first)
      final sortedPaths = cachedBooks.keys.toList()
        ..sort((a, b) => cachedBooks[a]!.compareTo(cachedBooks[b]!));

      // Delete oldest caches until we're under the size limit
      int currentSize = await getCacheSize();
      for (final path in sortedPaths) {
        if (currentSize <= maxSizeBytes) {
          break;
        }
        final dir = Directory(path);
        if (await dir.exists()) {
          int dirSize = 0;
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              dirSize += await entity.length();
            }
          }
          await dir.delete(recursive: true);
          currentSize -= dirSize;
        }
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  static TocItem _tocItemFromMap(Map<String, dynamic> map) {
    final childrenList = (map['children'] as List<dynamic>?) ?? [];
    return TocItem(
      title: map['title'] as String? ?? '',
      href: map['href'] as String? ?? '',
      chapterIndex: map['chapterIndex'] as int? ?? 0,
      children: childrenList.map((c) => _tocItemFromMap(c as Map<String, dynamic>)).toList(),
    );
  }

  static String _getImageExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.gif')) return '.gif';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.svg')) return '.svg';
    return '.jpg'; // Default to jpg
  }
}
