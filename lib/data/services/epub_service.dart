import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;

/// Represents a chapter in an EPUB book
class EpubChapter {
  final String id;
  final String title;
  final String href;
  final String content;
  final int index;

  EpubChapter({
    required this.id,
    required this.title,
    required this.href,
    required this.content,
    required this.index,
  });
}

/// Represents table of contents item
class TocItem {
  final String title;
  final String href;
  final int chapterIndex;
  final List<TocItem> children;

  TocItem({
    required this.title,
    required this.href,
    required this.chapterIndex,
    this.children = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'href': href,
      'chapterIndex': chapterIndex,
      'children': children.map((c) => c.toMap()).toList(),
    };
  }
}

/// Parsed EPUB book data
class EpubBook {
  final String title;
  final String? author;
  final String? cover;
  final List<EpubChapter> chapters;
  final List<TocItem> tableOfContents;
  final Map<String, Uint8List> images;
  final String? language;
  final String? publisher;

  EpubBook({
    required this.title,
    this.author,
    this.cover,
    required this.chapters,
    required this.tableOfContents,
    required this.images,
    this.language,
    this.publisher,
  });

  int get totalChapters => chapters.length;
}

/// Service for parsing EPUB files
class EpubService {
  /// Parse an EPUB file from a File object
  static Future<EpubBook> parseFromFile(File file) async {
    final bytes = await file.readAsBytes();
    return parse(bytes);
  }

  /// Parse an EPUB file from bytes
  static Future<EpubBook> parse(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find container.xml to get the OPF path
    final containerFile = archive.findFile('META-INF/container.xml');
    if (containerFile == null) {
      throw Exception('Invalid EPUB: container.xml not found');
    }

    final containerXml = XmlDocument.parse(
      String.fromCharCodes(containerFile.content as List<int>),
    );

    final rootfileElement = containerXml.findAllElements('rootfile').firstOrNull;
    if (rootfileElement == null) {
      throw Exception('Invalid EPUB: rootfile not found');
    }

    final opfPath = rootfileElement.getAttribute('full-path');
    if (opfPath == null) {
      throw Exception('Invalid EPUB: OPF path not found');
    }

    // Parse OPF file
    final opfFile = archive.findFile(opfPath);
    if (opfFile == null) {
      throw Exception('Invalid EPUB: OPF file not found at $opfPath');
    }

    final opfDir = path.dirname(opfPath);
    final opfXml = XmlDocument.parse(
      String.fromCharCodes(opfFile.content as List<int>),
    );

    // Extract metadata
    final metadata = _parseMetadata(opfXml);

    // Extract manifest (all files in the EPUB)
    final manifest = _parseManifest(opfXml);

    // Extract spine (reading order)
    final spine = _parseSpine(opfXml, manifest);

    // Parse chapters
    final chapters = <EpubChapter>[];
    final images = <String, Uint8List>{};

    for (var i = 0; i < spine.length; i++) {
      final item = spine[i];
      final href = item['href'] as String;
      final fullPath = opfDir.isEmpty ? href : '$opfDir/$href';

      final file = archive.findFile(fullPath);
      if (file != null) {
        var content = String.fromCharCodes(file.content as List<int>);

        // Process content to fix image paths and clean HTML
        content = _processHtmlContent(content, opfDir, archive, images);

        chapters.add(EpubChapter(
          id: item['id'] as String,
          title: item['title'] as String? ?? 'Chapter ${i + 1}',
          href: href,
          content: content,
          index: i,
        ));
      }
    }

    // Parse table of contents
    final toc = _parseTableOfContents(archive, opfXml, opfDir, manifest, chapters);

    // Update chapter titles from TOC
    for (final tocItem in toc) {
      _updateChapterTitles(tocItem, chapters);
    }

    // Extract cover image
    String? coverBase64;
    final coverId = _findCoverId(opfXml);
    if (coverId != null && manifest.containsKey(coverId)) {
      final coverHref = manifest[coverId]!['href'] as String;
      final coverPath = opfDir.isEmpty ? coverHref : '$opfDir/$coverHref';
      final coverFile = archive.findFile(coverPath);
      if (coverFile != null) {
        images[coverHref] = Uint8List.fromList(coverFile.content as List<int>);
      }
    }

    // Extract all images
    for (final entry in manifest.entries) {
      final mediaType = entry.value['media-type'] as String?;
      if (mediaType != null && mediaType.startsWith('image/')) {
        final href = entry.value['href'] as String;
        final imgPath = opfDir.isEmpty ? href : '$opfDir/$href';
        final imgFile = archive.findFile(imgPath);
        if (imgFile != null && !images.containsKey(href)) {
          images[href] = Uint8List.fromList(imgFile.content as List<int>);
        }
      }
    }

    return EpubBook(
      title: metadata['title'] ?? 'Unknown Title',
      author: metadata['creator'],
      cover: coverBase64,
      chapters: chapters,
      tableOfContents: toc,
      images: images,
      language: metadata['language'],
      publisher: metadata['publisher'],
    );
  }

  static Map<String, String> _parseMetadata(XmlDocument opfXml) {
    final metadata = <String, String>{};
    final metadataElement = opfXml.findAllElements('metadata').firstOrNull;

    if (metadataElement != null) {
      // Check for dc: prefixed elements
      for (final child in metadataElement.children.whereType<XmlElement>()) {
        final localName = child.name.local;
        final text = child.innerText.trim();
        if (text.isNotEmpty) {
          metadata[localName] = text;
        }
      }
    }

    return metadata;
  }

  static Map<String, Map<String, String>> _parseManifest(XmlDocument opfXml) {
    final manifest = <String, Map<String, String>>{};
    final manifestElement = opfXml.findAllElements('manifest').firstOrNull;

    if (manifestElement != null) {
      for (final item in manifestElement.findAllElements('item')) {
        final id = item.getAttribute('id');
        if (id != null) {
          manifest[id] = {
            'id': id,
            'href': item.getAttribute('href') ?? '',
            'media-type': item.getAttribute('media-type') ?? '',
            'properties': item.getAttribute('properties') ?? '',
          };
        }
      }
    }

    return manifest;
  }

  static List<Map<String, dynamic>> _parseSpine(
    XmlDocument opfXml,
    Map<String, Map<String, String>> manifest,
  ) {
    final spine = <Map<String, dynamic>>[];
    final spineElement = opfXml.findAllElements('spine').firstOrNull;

    if (spineElement != null) {
      for (final itemref in spineElement.findAllElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref != null && manifest.containsKey(idref)) {
          final item = manifest[idref]!;
          spine.add({
            'id': idref,
            'href': item['href'],
            'title': null,
          });
        }
      }
    }

    return spine;
  }

  static String _processHtmlContent(
    String html,
    String opfDir,
    Archive archive,
    Map<String, Uint8List> images,
  ) {
    try {
      final document = html_parser.parse(html);

      // Process images - convert to base64 data URIs
      for (final img in document.querySelectorAll('img')) {
        final src = img.attributes['src'];
        if (src != null && !src.startsWith('data:')) {
          // Store reference for later
          img.attributes['data-epub-src'] = src;
        }
      }

      // Get body content only
      final body = document.body;
      if (body != null) {
        return body.innerHtml;
      }

      return html;
    } catch (e) {
      return html;
    }
  }

  static List<TocItem> _parseTableOfContents(
    Archive archive,
    XmlDocument opfXml,
    String opfDir,
    Map<String, Map<String, String>> manifest,
    List<EpubChapter> chapters,
  ) {
    // Try EPUB 3 nav document first
    for (final item in manifest.values) {
      if (item['properties']?.contains('nav') == true) {
        final navPath = opfDir.isEmpty
            ? item['href']!
            : '$opfDir/${item['href']}';
        final navFile = archive.findFile(navPath);
        if (navFile != null) {
          final toc = _parseNavDocument(
            String.fromCharCodes(navFile.content as List<int>),
            chapters,
          );
          if (toc.isNotEmpty) return toc;
        }
      }
    }

    // Try NCX file (EPUB 2)
    final spineElement = opfXml.findAllElements('spine').firstOrNull;
    final tocId = spineElement?.getAttribute('toc');
    if (tocId != null && manifest.containsKey(tocId)) {
      final ncxHref = manifest[tocId]!['href']!;
      final ncxPath = opfDir.isEmpty ? ncxHref : '$opfDir/$ncxHref';
      final ncxFile = archive.findFile(ncxPath);
      if (ncxFile != null) {
        return _parseNcxDocument(
          String.fromCharCodes(ncxFile.content as List<int>),
          chapters,
        );
      }
    }

    // Fallback: generate TOC from chapters
    return chapters.map((ch) => TocItem(
      title: ch.title,
      href: ch.href,
      chapterIndex: ch.index,
    )).toList();
  }

  static List<TocItem> _parseNavDocument(String navHtml, List<EpubChapter> chapters) {
    final toc = <TocItem>[];

    try {
      final document = html_parser.parse(navHtml);
      final nav = document.querySelector('nav[*|type="toc"], nav.toc, nav#toc');

      if (nav != null) {
        final items = nav.querySelectorAll(':scope > ol > li, :scope > ul > li');
        for (final item in items) {
          final tocItem = _parseTocListItem(item, chapters);
          if (tocItem != null) {
            toc.add(tocItem);
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return toc;
  }

  static TocItem? _parseTocListItem(dynamic element, List<EpubChapter> chapters) {
    final anchor = element.querySelector('a');
    if (anchor == null) return null;

    final title = anchor.text.trim();
    final href = anchor.attributes['href'] ?? '';
    final baseHref = href.split('#').first;

    final chapterIndex = chapters.indexWhere(
      (ch) => ch.href == baseHref || ch.href.endsWith(baseHref),
    );

    final children = <TocItem>[];
    final nestedList = element.querySelector(':scope > ol, :scope > ul');
    if (nestedList != null) {
      for (final child in nestedList.querySelectorAll(':scope > li')) {
        final childItem = _parseTocListItem(child, chapters);
        if (childItem != null) {
          children.add(childItem);
        }
      }
    }

    return TocItem(
      title: title,
      href: href,
      chapterIndex: chapterIndex >= 0 ? chapterIndex : 0,
      children: children,
    );
  }

  static List<TocItem> _parseNcxDocument(String ncxXml, List<EpubChapter> chapters) {
    final toc = <TocItem>[];

    try {
      final document = XmlDocument.parse(ncxXml);
      final navMap = document.findAllElements('navMap').firstOrNull;

      if (navMap != null) {
        for (final navPoint in navMap.findAllElements('navPoint')) {
          final tocItem = _parseNavPoint(navPoint, chapters);
          if (tocItem != null) {
            toc.add(tocItem);
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return toc;
  }

  static TocItem? _parseNavPoint(XmlElement navPoint, List<EpubChapter> chapters) {
    final labelElement = navPoint.findAllElements('navLabel').firstOrNull;
    final contentElement = navPoint.findAllElements('content').firstOrNull;

    if (labelElement == null || contentElement == null) return null;

    final title = labelElement.findAllElements('text').firstOrNull?.innerText.trim() ?? '';
    final src = contentElement.getAttribute('src') ?? '';
    final baseHref = src.split('#').first;

    final chapterIndex = chapters.indexWhere(
      (ch) => ch.href == baseHref || ch.href.endsWith(baseHref),
    );

    final children = <TocItem>[];
    for (final childNavPoint in navPoint.findElements('navPoint')) {
      final childItem = _parseNavPoint(childNavPoint, chapters);
      if (childItem != null) {
        children.add(childItem);
      }
    }

    return TocItem(
      title: title,
      href: src,
      chapterIndex: chapterIndex >= 0 ? chapterIndex : 0,
      children: children,
    );
  }

  static void _updateChapterTitles(TocItem tocItem, List<EpubChapter> chapters) {
    if (tocItem.chapterIndex >= 0 && tocItem.chapterIndex < chapters.length) {
      final chapter = chapters[tocItem.chapterIndex];
      chapters[tocItem.chapterIndex] = EpubChapter(
        id: chapter.id,
        title: tocItem.title.isNotEmpty ? tocItem.title : chapter.title,
        href: chapter.href,
        content: chapter.content,
        index: chapter.index,
      );
    }

    for (final child in tocItem.children) {
      _updateChapterTitles(child, chapters);
    }
  }

  static String? _findCoverId(XmlDocument opfXml) {
    // Check for cover in metadata
    final metadataElement = opfXml.findAllElements('metadata').firstOrNull;
    if (metadataElement != null) {
      for (final meta in metadataElement.findAllElements('meta')) {
        if (meta.getAttribute('name') == 'cover') {
          return meta.getAttribute('content');
        }
      }
    }

    // Check manifest for cover-image property
    final manifestElement = opfXml.findAllElements('manifest').firstOrNull;
    if (manifestElement != null) {
      for (final item in manifestElement.findAllElements('item')) {
        final properties = item.getAttribute('properties') ?? '';
        if (properties.contains('cover-image')) {
          return item.getAttribute('id');
        }
      }
    }

    return null;
  }
}
