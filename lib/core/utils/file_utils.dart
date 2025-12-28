import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> getBooksDirectory() async {
    final appDir = await getAppDirectory();
    final booksDir = Directory('${appDir.path}/books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  static Future<Directory> getCoversDirectory() async {
    final appDir = await getAppDirectory();
    final coversDir = Directory('${appDir.path}/covers');
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir;
  }

  static Future<Directory> getCacheDirectory() async {
    return await getTemporaryDirectory();
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).replaceFirst('.', '').toLowerCase();
  }

  static String getFileName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  static String getFileNameWithExtension(String filePath) {
    return path.basename(filePath);
  }

  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static Future<File> saveBookLocally(String bookId, List<int> bytes, String extension) async {
    final booksDir = await getBooksDirectory();
    final filePath = '${booksDir.path}/$bookId.$extension';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File?> getLocalBook(String bookId, String extension) async {
    final booksDir = await getBooksDirectory();
    final filePath = '${booksDir.path}/$bookId.$extension';
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static Future<bool> deleteLocalBook(String bookId, String extension) async {
    final booksDir = await getBooksDirectory();
    final filePath = '${booksDir.path}/$bookId.$extension';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  static Future<File> saveCoverLocally(String bookId, List<int> bytes) async {
    final coversDir = await getCoversDirectory();
    final filePath = '${coversDir.path}/$bookId.jpg';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File?> getLocalCover(String bookId) async {
    final coversDir = await getCoversDirectory();
    final filePath = '${coversDir.path}/$bookId.jpg';
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static Future<void> clearCache() async {
    final cacheDir = await getCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
    }
  }

  static Future<int> getCacheSize() async {
    final cacheDir = await getCacheDirectory();
    int totalSize = 0;
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    return totalSize;
  }
}
