import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/book.dart';
import '../../../data/services/export_service.dart';
import '../../../data/models/highlight.dart';
import '../../providers/library_provider.dart';
import '../../providers/reader_provider.dart';
import 'pdf_reader.dart';
import 'epub_reader.dart';
import 'reader_settings.dart';

class ReaderScreen extends StatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showControls = true;
  ReaderProvider? _readerProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readerProvider = context.read<ReaderProvider>();
      _loadBook();
    });
  }

  Future<void> _loadBook() async {
    if (!mounted) return;
    final library = context.read<LibraryProvider>();
    final reader = context.read<ReaderProvider>();
    final book = library.getBookById(widget.bookId);

    if (book != null) {
      await reader.loadBook(book);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ReaderSettingsSheet(),
    );
  }

  void _showBookmarks() {
    final reader = context.read<ReaderProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookmarks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (reader.bookmarks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No bookmarks yet'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reader.bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = reader.bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(bookmark.displayTitle),
                      subtitle: bookmark.createdAt != null
                          ? Text(
                              _formatDate(bookmark.createdAt!),
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        reader.goToBookmark(bookmark);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTableOfContents() {
    final reader = context.read<ReaderProvider>();

    if (reader.tableOfContents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table of contents not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table of Contents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: reader.tableOfContents.length,
                  itemBuilder: (context, index) {
                    final item = reader.tableOfContents[index];
                    return ListTile(
                      title: Text(item['title'] ?? 'Chapter ${index + 1}'),
                      onTap: () {
                        Navigator.pop(context);
                        reader.goToChapter(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTextSelectionMenu(BuildContext context, String selectedText, ReaderProvider reader) {
    if (selectedText.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selected text preview
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedText.length > 150
                      ? '${selectedText.substring(0, 150)}...'
                      : selectedText,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              // Copy option
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(selectedText);
                },
              ),
              // Highlight options
              ListTile(
                leading: const Icon(Icons.highlight, color: Colors.yellow),
                title: const Text('Highlight Yellow'),
                onTap: () {
                  Navigator.pop(context);
                  _addHighlight(reader, selectedText, HighlightColor.yellow);
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight, color: Colors.green),
                title: const Text('Highlight Green'),
                onTap: () {
                  Navigator.pop(context);
                  _addHighlight(reader, selectedText, HighlightColor.green);
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight, color: Colors.blue),
                title: const Text('Highlight Blue'),
                onTap: () {
                  Navigator.pop(context);
                  _addHighlight(reader, selectedText, HighlightColor.blue);
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight, color: Colors.pink),
                title: const Text('Highlight Pink'),
                onTap: () {
                  Navigator.pop(context);
                  _addHighlight(reader, selectedText, HighlightColor.pink);
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight, color: Colors.orange),
                title: const Text('Highlight Orange'),
                onTap: () {
                  Navigator.pop(context);
                  _addHighlight(reader, selectedText, HighlightColor.orange);
                },
              ),
              // Add note option
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('Add Note'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddNoteDialog(reader, selectedText);
                },
              ),
              // Search/Look up option
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Look Up'),
                onTap: () {
                  Navigator.pop(context);
                  _lookUpText(selectedText);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _addHighlight(ReaderProvider reader, String text, HighlightColor color) {
    reader.addHighlight(text: text, color: color);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Highlighted in ${color.name}')),
    );
  }

  void _showAddNoteDialog(ReaderProvider reader, String selectedText) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selectedText.length > 100
                    ? '${selectedText.substring(0, 100)}...'
                    : selectedText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Enter your note...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              reader.addHighlight(
                text: selectedText,
                color: HighlightColor.yellow,
                note: noteController.text,
              );
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Note added')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _lookUpText(String text) {
    // Show definition or search results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Look Up: "$text"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dictionary lookup coming soon.\n\nFor now, you can copy the text and search online.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Text'),
              onPressed: () {
                Navigator.pop(context);
                _copyToClipboard(text);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSearch() {
    final reader = context.read<ReaderProvider>();
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search in Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Enter search text...',
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Search feature coming soon for: "$value"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Full text search will be available in a future update.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final query = searchController.text;
              if (query.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Search feature coming soon for: "$query"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Book book) {
    final reader = context.read<ReaderProvider>();

    switch (action) {
      case 'export_md':
        _exportNotes(book, reader, asMarkdown: true);
        break;
      case 'export_txt':
        _exportNotes(book, reader, asMarkdown: false);
        break;
      case 'book_info':
        context.push('/book/${book.id}');
        break;
    }
  }

  Future<void> _exportNotes(Book book, ReaderProvider reader, {required bool asMarkdown}) async {
    final highlights = reader.highlights;
    final bookmarks = reader.bookmarks;

    if (highlights.isEmpty && bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No highlights or bookmarks to export')),
      );
      return;
    }

    try {
      if (asMarkdown) {
        await ExportService.shareAsMarkdown(
          book: book,
          highlights: highlights,
          bookmarks: bookmarks,
        );
      } else {
        await ExportService.shareAsText(
          book: book,
          highlights: highlights,
          bookmarks: bookmarks,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _readerProvider?.closeBook(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild on status changes
    final status = context.select<ReaderProvider, ReaderStatus>(
      (provider) => provider.status,
    );

    // Show loading for both initial and loading states
    if (status == ReaderStatus.initial || status == ReaderStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (status == ReaderStatus.error) {
      final errorMessage = context.read<ReaderProvider>().errorMessage;
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(errorMessage ?? 'Failed to load book'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final reader = context.read<ReaderProvider>();
    final book = reader.currentBook;
    // Check for bookFile (native) OR bookBytes (web)
    final hasBookData = kIsWeb ? reader.bookBytes != null : reader.bookFile != null;
    if (book == null || !hasBookData) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Scaffold(
      backgroundColor: reader.settings.theme.backgroundColor,
      body: Stack(
        children: [
          // Reader Content - needs SizedBox.expand for proper sizing in Stack
          // No GestureDetector wrapper to allow text selection to work
          Positioned.fill(
            child: book.fileType == BookType.pdf
                ? PdfReaderView(
                    file: kIsWeb ? null : reader.bookFile,
                    bytes: kIsWeb ? reader.bookBytes : null,
                    onTap: _toggleControls,
                    onTextSelected: (text) => _showTextSelectionMenu(context, text, reader),
                  )
                : EpubReaderView(
                    file: kIsWeb ? null : reader.bookFile,
                    bytes: kIsWeb ? reader.bookBytes : null,
                    onTap: _toggleControls,
                    onTextSelected: (text) => _showTextSelectionMenu(context, text, reader),
                  ),
          ),

          // Navigation buttons - BEFORE top/bottom bars so they don't block them
          _buildNavigationButtons(context, reader),

          // Top Bar - rendered AFTER nav buttons so it's on top
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context, book),
            ),

          // Bottom Bar - rendered AFTER nav buttons so it's on top
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(context, reader),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Book book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/library'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author != null)
                      Text(
                        book.author!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.list, color: Colors.white),
                tooltip: 'Table of Contents',
                onPressed: _showTableOfContents,
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                tooltip: 'Bookmarks',
                onPressed: _showBookmarks,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) => _handleMenuAction(value, book),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export_md',
                    child: Row(
                      children: [
                        Icon(Icons.description),
                        SizedBox(width: 12),
                        Text('Export as Markdown'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_txt',
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet),
                        SizedBox(width: 12),
                        Text('Export as Text'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'book_info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Text('Book Info'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ReaderProvider reader) {
    // Use Selector to only rebuild when page/totalPages changes
    return Selector<ReaderProvider, ({int current, int total})>(
      selector: (_, r) => (current: r.currentPage, total: r.totalPages),
      builder: (context, pages, _) {
        return Positioned.fill(
          child: Row(
            children: [
              // Previous page button (left side)
              GestureDetector(
                onTap: pages.current > 0
                    ? () => reader.updatePage(pages.current - 1, fromNavButton: true)
                    : null,
                child: Container(
                  width: 60,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_left,
                    size: 40,
                    color: Colors.white.withOpacity(pages.current > 0 ? 0.3 : 0.1),
                  ),
                ),
              ),
              // Center area - tap to toggle controls
              const Expanded(child: SizedBox()),
              // Next page button (right side)
              GestureDetector(
                onTap: pages.current < pages.total - 1
                    ? () => reader.updatePage(pages.current + 1, fromNavButton: true)
                    : null,
                child: Container(
                  width: 60,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right,
                    size: 40,
                    color: Colors.white.withOpacity(pages.current < pages.total - 1 ? 0.3 : 0.1),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, ReaderProvider reader) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<ReaderProvider>(
            builder: (context, readerState, _) {
              final currentPage = readerState.currentPage;
              final totalPages = readerState.totalPages;
              final isBookmarked = readerState.isBookmarked;
              final progressPercent = readerState.progressPercent;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar with slider
                  Row(
                    children: [
                      Text(
                        '${currentPage + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white30,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                          ),
                          child: Slider(
                            value: totalPages > 0
                                ? currentPage.toDouble().clamp(0, (totalPages - 1).toDouble())
                                : 0,
                            min: 0,
                            max: totalPages > 1 ? (totalPages - 1).toDouble() : 1,
                            onChanged: totalPages > 0
                                ? (value) {
                                    readerState.updatePage(value.toInt(), fromNavButton: true);
                                  }
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '$totalPages',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bookmark toggle button
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.red : Colors.white,
                          size: 28,
                        ),
                        tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                        onPressed: () {
                          readerState.toggleBookmark();
                        },
                      ),
                      // Go to page button
                      IconButton(
                        icon: const Icon(Icons.format_list_numbered, color: Colors.white, size: 28),
                        tooltip: 'Go to Page',
                        onPressed: () => _showGoToPageDialog(context, readerState),
                      ),
                      // Settings button (gear icon)
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                        tooltip: 'Reading Settings',
                        onPressed: _showSettings,
                      ),
                      // Scroll direction quick toggle
                      IconButton(
                        icon: Icon(
                          readerState.settings.scrollDirection.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Scroll: ${readerState.settings.scrollDirection.displayName}',
                        onPressed: () {
                          // Cycle through scroll directions
                          final directions = ScrollDirection.values;
                          final currentIndex = directions.indexOf(readerState.settings.scrollDirection);
                          final nextIndex = (currentIndex + 1) % directions.length;
                          readerState.updateScrollDirection(directions[nextIndex]);
                        },
                      ),
                    ],
                  ),

                  // Progress text
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(0)}% completed',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showGoToPageDialog(BuildContext context, ReaderProvider reader) {
    final pageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-${reader.totalPages})',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= reader.totalPages) {
              reader.updatePage(page - 1, fromNavButton: true);
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page >= 1 && page <= reader.totalPages) {
                reader.updatePage(page - 1, fromNavButton: true);
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid page (1-${reader.totalPages})'),
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
