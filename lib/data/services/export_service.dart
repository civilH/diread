import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';

/// Service for exporting reading data (highlights, bookmarks, notes)
class ExportService {
  /// Export highlights and bookmarks as Markdown
  static Future<String> exportToMarkdown({
    required Book book,
    required List<Highlight> highlights,
    required List<Bookmark> bookmarks,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Header
    buffer.writeln('# ${book.title}');
    if (book.author != null) {
      buffer.writeln('**Author:** ${book.author}');
    }
    buffer.writeln();
    buffer.writeln('*Exported on ${dateFormat.format(DateTime.now())}*');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Highlights Section
    if (highlights.isNotEmpty) {
      buffer.writeln('## Highlights');
      buffer.writeln();

      // Sort by page/position
      final sortedHighlights = List<Highlight>.from(highlights)
        ..sort((a, b) => (a.pageNumber ?? 0).compareTo(b.pageNumber ?? 0));

      for (final highlight in sortedHighlights) {
        // Page reference
        if (highlight.pageNumber != null) {
          buffer.writeln('**Page ${highlight.pageNumber! + 1}**');
        }

        // Highlight text
        buffer.writeln('> ${highlight.text}');
        buffer.writeln();

        // Note if present
        if (highlight.note != null && highlight.note!.isNotEmpty) {
          buffer.writeln('*Note: ${highlight.note}*');
          buffer.writeln();
        }

        // Color tag
        buffer.writeln('`${highlight.color}`');
        buffer.writeln();
      }
    }

    // Bookmarks Section
    if (bookmarks.isNotEmpty) {
      buffer.writeln('## Bookmarks');
      buffer.writeln();

      // Sort by page
      final sortedBookmarks = List<Bookmark>.from(bookmarks)
        ..sort((a, b) => (a.pageNumber ?? 0).compareTo(b.pageNumber ?? 0));

      for (final bookmark in sortedBookmarks) {
        final page = bookmark.pageNumber != null ? 'Page ${bookmark.pageNumber! + 1}' : '';
        final title = bookmark.displayTitle;
        final date = bookmark.createdAt != null
            ? dateFormat.format(bookmark.createdAt!)
            : '';

        buffer.writeln('- **$title** ($page) - $date');
      }
      buffer.writeln();
    }

    // Footer
    buffer.writeln('---');
    buffer.writeln('*Exported from diRead*');

    return buffer.toString();
  }

  /// Export highlights and bookmarks as plain text
  static Future<String> exportToText({
    required Book book,
    required List<Highlight> highlights,
    required List<Bookmark> bookmarks,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Header
    buffer.writeln(book.title.toUpperCase());
    buffer.writeln('=' * book.title.length);
    if (book.author != null) {
      buffer.writeln('Author: ${book.author}');
    }
    buffer.writeln('Exported: ${dateFormat.format(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('-' * 40);
    buffer.writeln();

    // Highlights Section
    if (highlights.isNotEmpty) {
      buffer.writeln('HIGHLIGHTS');
      buffer.writeln('-' * 10);
      buffer.writeln();

      final sortedHighlights = List<Highlight>.from(highlights)
        ..sort((a, b) => (a.pageNumber ?? 0).compareTo(b.pageNumber ?? 0));

      for (int i = 0; i < sortedHighlights.length; i++) {
        final highlight = sortedHighlights[i];
        buffer.writeln('[${i + 1}] Page ${(highlight.pageNumber ?? 0) + 1}');
        buffer.writeln('"${highlight.text}"');
        if (highlight.note != null && highlight.note!.isNotEmpty) {
          buffer.writeln('Note: ${highlight.note}');
        }
        buffer.writeln();
      }
    }

    // Bookmarks Section
    if (bookmarks.isNotEmpty) {
      buffer.writeln('BOOKMARKS');
      buffer.writeln('-' * 9);
      buffer.writeln();

      final sortedBookmarks = List<Bookmark>.from(bookmarks)
        ..sort((a, b) => (a.pageNumber ?? 0).compareTo(b.pageNumber ?? 0));

      for (final bookmark in sortedBookmarks) {
        buffer.writeln('* ${bookmark.displayTitle} - Page ${(bookmark.pageNumber ?? 0) + 1}');
      }
      buffer.writeln();
    }

    buffer.writeln('-' * 40);
    buffer.writeln('Exported from diRead');

    return buffer.toString();
  }

  /// Export as JSON for backup/import
  static Map<String, dynamic> exportToJson({
    required Book book,
    required List<Highlight> highlights,
    required List<Bookmark> bookmarks,
  }) {
    return {
      'book': {
        'id': book.id,
        'title': book.title,
        'author': book.author,
        'file_type': book.fileType.name,
      },
      'exported_at': DateTime.now().toIso8601String(),
      'highlights': highlights.map((h) => {
        'text': h.text,
        'page_number': h.pageNumber,
        'cfi': h.cfi,
        'color': h.color,
        'note': h.note,
        'created_at': h.createdAt?.toIso8601String(),
      }).toList(),
      'bookmarks': bookmarks.map((b) => {
        'title': b.displayTitle,
        'page_number': b.pageNumber,
        'cfi': b.cfi,
        'created_at': b.createdAt?.toIso8601String(),
      }).toList(),
    };
  }

  /// Save content to file and share
  static Future<void> shareExport({
    required String content,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      // On web, just share as text
      await Share.share(content, subject: fileName);
      return;
    }

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);

    // Share file
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
    );
  }

  /// Export and share as Markdown
  static Future<void> shareAsMarkdown({
    required Book book,
    required List<Highlight> highlights,
    required List<Bookmark> bookmarks,
  }) async {
    final content = await exportToMarkdown(
      book: book,
      highlights: highlights,
      bookmarks: bookmarks,
    );

    final safeTitle = book.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName = '${safeTitle}_notes.md';

    await shareExport(
      content: content,
      fileName: fileName,
      mimeType: 'text/markdown',
    );
  }

  /// Export and share as Text
  static Future<void> shareAsText({
    required Book book,
    required List<Highlight> highlights,
    required List<Bookmark> bookmarks,
  }) async {
    final content = await exportToText(
      book: book,
      highlights: highlights,
      bookmarks: bookmarks,
    );

    final safeTitle = book.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName = '${safeTitle}_notes.txt';

    await shareExport(
      content: content,
      fileName: fileName,
      mimeType: 'text/plain',
    );
  }
}
