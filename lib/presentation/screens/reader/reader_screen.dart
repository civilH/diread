import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/book.dart';
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
  bool _isFullScreen = false;
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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
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
                        // Navigate to chapter
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

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
          // Reader Content - wrapped in GestureDetector for tap to toggle controls
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleControls,
            child: RepaintBoundary(
              child: book.fileType == BookType.pdf
                  ? PdfReaderView(
                      file: kIsWeb ? null : reader.bookFile,
                      bytes: kIsWeb ? reader.bookBytes : null,
                    )
                  : EpubReaderView(
                      file: kIsWeb ? null : reader.bookFile,
                      bytes: kIsWeb ? reader.bookBytes : null,
                    ),
            ),
          ),

          // Top Bar
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context, book),
            ),

          // Bottom Bar
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(context, reader),
            ),

          // Navigation buttons (always visible on sides)
          _buildNavigationButtons(context, reader),
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
                onPressed: () => context.pop(),
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
              if (book.fileType == BookType.epub)
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.white),
                  onPressed: _showTableOfContents,
                ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                onPressed: _showBookmarks,
              ),
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ReaderProvider reader) {
    return Positioned.fill(
      child: Row(
        children: [
          // Previous page button (left side)
          GestureDetector(
            onTap: () {
              if (reader.currentPage > 0) {
                reader.updatePage(reader.currentPage - 1, fromNavButton: true);
              }
            },
            child: Container(
              width: 60,
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_left,
                size: 40,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          // Center area - tap to toggle controls
          const Expanded(child: SizedBox()),
          // Next page button (right side)
          GestureDetector(
            onTap: () {
              if (reader.currentPage < reader.totalPages - 1) {
                reader.updatePage(reader.currentPage + 1, fromNavButton: true);
              }
            },
            child: Container(
              width: 60,
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_right,
                size: 40,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              Row(
                children: [
                  Text(
                    '${reader.currentPage + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: Slider(
                      value: reader.currentPage.toDouble(),
                      min: 0,
                      max: (reader.totalPages - 1).clamp(0, double.maxFinite).toDouble(),
                      onChanged: (value) {
                        reader.updatePage(value.toInt());
                      },
                    ),
                  ),
                  Text(
                    '${reader.totalPages}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      reader.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: reader.isBookmarked ? Colors.amber : Colors.white,
                    ),
                    onPressed: () => reader.toggleBookmark(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // TODO: Implement search
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_format, color: Colors.white),
                    onPressed: _showSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.brightness_6, color: Colors.white),
                    onPressed: () {
                      // Cycle through themes
                      final themes = ReadingTheme.values;
                      final currentIndex =
                          themes.indexOf(reader.settings.theme);
                      final nextIndex = (currentIndex + 1) % themes.length;
                      reader.updateTheme(themes[nextIndex]);
                    },
                  ),
                ],
              ),

              // Progress text
              Text(
                '${(reader.progressPercent * 100).toStringAsFixed(0)}% completed',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
