import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/config/theme.dart';
import '../../../data/services/epub_service.dart';
import '../../../data/services/epub_cache_service.dart';
import '../../providers/reader_provider.dart';

class EpubReaderView extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;
  final VoidCallback? onTap;
  final Function(String)? onTextSelected;

  const EpubReaderView({
    super.key,
    this.file,
    this.bytes,
    this.onTap,
    this.onTextSelected,
  });

  @override
  State<EpubReaderView> createState() => _EpubReaderViewState();
}

class _EpubReaderViewState extends State<EpubReaderView> {
  EpubBook? _book;
  bool _isLoading = true;
  String? _error;
  int _currentChapterIndex = 0;
  double _scrollProgress = 0.0; // 0.0 to 1.0 for smooth slider tracking
  bool _isScrollingProgrammatically = false;
  int _lastReportedPage = -1; // Track last reported page to avoid duplicate updates

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _loadEpub();
    _setupPositionListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for external page changes (from slider)
    final reader = context.read<ReaderProvider>();
    reader.addListener(_onProviderPageChanged);
  }

  void _onProviderPageChanged() {
    if (_book == null || _isScrollingProgrammatically) return;

    final reader = context.read<ReaderProvider>();
    final targetVirtualPage = reader.currentPage;
    final totalVirtualPages = _book!.totalChapters * _pagesPerChapter;

    // Only scroll if the page changed externally (not from our own scroll)
    if (targetVirtualPage != _lastReportedPage && targetVirtualPage >= 0 && targetVirtualPage < totalVirtualPages) {
      _scrollToVirtualPage(targetVirtualPage);
      _lastReportedPage = targetVirtualPage;
    }
  }

  void _setupPositionListener() {
    _positionsListener.itemPositions.addListener(_onPositionChanged);
  }

  // Granularity multiplier: creates more virtual "pages" per chapter for smoother slider
  static const int _pagesPerChapter = 10;

  void _onPositionChanged() {
    if (_book == null || _isScrollingProgrammatically) return;

    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final totalChapters = _book!.totalChapters;
    if (totalChapters == 0) return;

    // Find the topmost visible item (the one closest to viewport top)
    final sortedPositions = positions.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));

    // Get the first item that's at least partially visible
    ItemPosition? topItem;
    for (final pos in sortedPositions) {
      if (pos.itemTrailingEdge > 0) {
        topItem = pos;
        break;
      }
    }

    if (topItem == null) return;

    final chapterIndex = topItem.index;

    // Calculate precise scroll progress within the chapter
    // itemLeadingEdge/itemTrailingEdge are in viewport units
    // For a chapter 3 viewports tall at top: leading=0, trailing=3
    // When scrolled to bottom: leading=-2, trailing=1
    //
    // Progress formula:
    // - itemHeight = trailing - leading (total chapter height in viewports)
    // - scrolledAmount = -leading (how much of chapter is above viewport)
    // - scrollableHeight = itemHeight - 1 (total scrollable distance)
    // - progress = scrolledAmount / scrollableHeight

    final itemHeight = topItem.itemTrailingEdge - topItem.itemLeadingEdge;
    final scrollableHeight = itemHeight - 1.0; // Minus one viewport
    final scrolledAmount = -topItem.itemLeadingEdge;

    double chapterProgress;
    if (scrollableHeight > 0.01) {
      // Chapter is taller than viewport - calculate scroll progress
      chapterProgress = (scrolledAmount / scrollableHeight).clamp(0.0, 1.0);
    } else {
      // Chapter fits in viewport - consider it fully visible based on position
      chapterProgress = topItem.itemLeadingEdge <= 0 ? 1.0 : 0.0;
    }

    // Calculate overall progress as: (chapterIndex + progressWithinChapter) / totalChapters
    final overallProgress = (chapterIndex + chapterProgress) / totalChapters;
    _scrollProgress = overallProgress.clamp(0.0, 1.0);

    // Update chapter index
    _currentChapterIndex = chapterIndex;

    // Calculate virtual page with increased granularity
    // Each chapter has _pagesPerChapter virtual pages for smoother slider movement
    final totalVirtualPages = totalChapters * _pagesPerChapter;
    final virtualPage = (_scrollProgress * totalVirtualPages).floor().clamp(0, totalVirtualPages - 1);

    // Update provider - always update to keep slider in sync
    final reader = context.read<ReaderProvider>();
    if (virtualPage != _lastReportedPage) {
      _lastReportedPage = virtualPage;
      reader.updatePage(virtualPage);
    }
    reader.updateProgress(_scrollProgress);
  }

  Future<void> _loadEpub() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get book ID for caching
      final reader = context.read<ReaderProvider>();
      final bookId = reader.currentBook?.id ?? '';

      EpubBook book;

      // Try to load from cache first
      if (bookId.isNotEmpty && await EpubCacheService.hasValidCache(bookId)) {
        final cachedBook = await EpubCacheService.loadFromCache(bookId);
        if (cachedBook != null) {
          book = cachedBook;
        } else {
          // Cache was invalid, parse fresh
          book = await _parseAndCacheEpub(bookId);
        }
      } else {
        // No cache, parse and cache for future use
        book = await _parseAndCacheEpub(bookId);
      }

      if (mounted) {
        setState(() {
          _book = book;
          _isLoading = false;
        });

        // Update reader provider with virtual page count for smoother slider
        final totalVirtualPages = book.totalChapters * _pagesPerChapter;
        reader.setTotalPages(totalVirtualPages);
        reader.setTableOfContents(
          book.tableOfContents.map((t) => t.toMap()).toList(),
        );

        // Restore reading position (convert virtual page to chapter)
        final savedPage = reader.currentPage;
        if (savedPage > 0 && savedPage < totalVirtualPages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToVirtualPage(savedPage);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<EpubBook> _parseAndCacheEpub(String bookId) async {
    Uint8List bytes;
    if (widget.bytes != null) {
      bytes = widget.bytes!;
    } else if (widget.file != null) {
      bytes = await widget.file!.readAsBytes();
    } else {
      throw Exception('No EPUB file provided');
    }

    // Parse and cache for future use
    if (bookId.isNotEmpty) {
      return await EpubCacheService.parseAndCache(bytes, bookId);
    } else {
      return await EpubService.parse(bytes);
    }
  }

  void _scrollToChapter(int index) {
    if (_scrollController.isAttached && index < (_book?.totalChapters ?? 0)) {
      _isScrollingProgrammatically = true;
      _currentChapterIndex = index;
      _scrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
      ).then((_) {
        _isScrollingProgrammatically = false;
      });
    }
  }

  void _scrollToVirtualPage(int virtualPage) {
    if (_book == null || !_scrollController.isAttached) return;

    final totalChapters = _book!.totalChapters;
    if (totalChapters == 0) return;

    // Convert virtual page to chapter index and alignment
    // virtualPage / _pagesPerChapter = chapter + fraction
    final chapterIndex = virtualPage ~/ _pagesPerChapter;
    final positionInChapter = (virtualPage % _pagesPerChapter) / _pagesPerChapter;

    // Clamp to valid range
    final targetChapter = chapterIndex.clamp(0, totalChapters - 1);

    _isScrollingProgrammatically = true;
    _currentChapterIndex = targetChapter;

    // Scroll to chapter with alignment based on position within virtual page range
    // alignment: 0 = item top at viewport top, negative = scrolled down into item
    _scrollController.scrollTo(
      index: targetChapter,
      alignment: -positionInChapter, // Negative to scroll down into the chapter
      duration: const Duration(milliseconds: 300),
    ).then((_) {
      _isScrollingProgrammatically = false;
    });
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onPositionChanged);
    // Remove provider listener
    try {
      context.read<ReaderProvider>().removeListener(_onProviderPageChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading book...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load EPUB',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEpub,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_book == null || _book!.chapters.isEmpty) {
      return const Center(
        child: Text('No content found in this EPUB'),
      );
    }

    return Consumer<ReaderProvider>(
      builder: (context, reader, _) {
        final settings = reader.settings;
        final theme = settings.theme;

        return SizedBox.expand(
          child: Container(
            color: theme.backgroundColor,
            child: ScrollablePositionedList.builder(
              itemCount: _book!.chapters.length,
              itemScrollController: _scrollController,
              itemPositionsListener: _positionsListener,
              itemBuilder: (context, index) {
                final chapter = _book!.chapters[index];
                return _ChapterView(
                  chapter: chapter,
                  images: _book!.images,
                  settings: settings,
                  theme: theme,
                  isFirst: index == 0,
                  isLast: index == _book!.chapters.length - 1,
                  onTextSelected: widget.onTextSelected,
                  onTap: widget.onTap,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ChapterView extends StatefulWidget {
  final EpubChapter chapter;
  final Map<String, Uint8List> images;
  final ReaderSettings settings;
  final ReadingTheme theme;
  final bool isFirst;
  final bool isLast;
  final Function(String)? onTextSelected;
  final VoidCallback? onTap;

  const _ChapterView({
    required this.chapter,
    required this.images,
    required this.settings,
    required this.theme,
    required this.isFirst,
    required this.isLast,
    this.onTextSelected,
    this.onTap,
  });

  @override
  State<_ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<_ChapterView> {
  String _selectedText = '';
  bool _hasSelection = false;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = widget.settings.margin;
    final lineHeight = widget.settings.lineHeight;
    final fontSize = widget.settings.fontSize;
    final theme = widget.theme;
    final chapter = widget.chapter;

    return GestureDetector(
      onTap: () {
        // Only toggle controls if no text is selected
        if (!_hasSelection) {
          widget.onTap?.call();
        }
      },
      behavior: HitTestBehavior.deferToChild,
      child: Container(
        color: theme.backgroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isFirst) const SizedBox(height: 40),

            // Chapter title
            if (chapter.title.isNotEmpty &&
                !chapter.title.startsWith('Chapter '))
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SelectableText(
                  chapter.title,
                  style: TextStyle(
                    fontSize: fontSize + 8,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    height: lineHeight,
                  ),
                  contextMenuBuilder: (context, editableTextState) {
                    return _buildContextMenu(context, editableTextState.contextMenuAnchors, () {
                      final selection = editableTextState.textEditingValue.selection;
                      if (selection.isValid && !selection.isCollapsed) {
                        return editableTextState.textEditingValue.text.substring(
                          selection.start,
                          selection.end,
                        );
                      }
                      return '';
                    });
                  },
                ),
              ),

            // Chapter content - wrapped in SelectionArea for text selection
            SelectionArea(
              onSelectionChanged: (selection) {
                if (selection != null) {
                  final text = selection.plainText;
                  _hasSelection = text.isNotEmpty;
                  if (text.isNotEmpty) {
                    _selectedText = text;
                  }
                } else {
                  _hasSelection = false;
                }
              },
              contextMenuBuilder: (context, selectableRegionState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: [
                    ContextMenuButtonItem(
                      onPressed: () {
                        selectableRegionState.copySelection(SelectionChangedCause.tap);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      type: ContextMenuButtonType.copy,
                    ),
                    ContextMenuButtonItem(
                      onPressed: () {
                        if (_selectedText.isNotEmpty) {
                          final text = _selectedText;
                          selectableRegionState.hideToolbar();
                          widget.onTextSelected?.call(text);
                          _selectedText = '';
                          _hasSelection = false;
                        }
                      },
                      label: 'Highlight',
                    ),
                    ContextMenuButtonItem(
                      onPressed: () {
                        if (_selectedText.isNotEmpty) {
                          final text = _selectedText;
                          selectableRegionState.hideToolbar();
                          _lookUpWord(context, text);
                          _selectedText = '';
                          _hasSelection = false;
                        }
                      },
                      label: 'Look Up',
                    ),
                    ContextMenuButtonItem(
                      onPressed: () {
                        selectableRegionState.selectAll(SelectionChangedCause.tap);
                      },
                      type: ContextMenuButtonType.selectAll,
                    ),
                  ],
                );
              },
              child: HtmlWidget(
              chapter.content,
              textStyle: TextStyle(
                fontSize: fontSize,
                color: theme.textColor,
                height: lineHeight,
              ),
              customStylesBuilder: (element) {
                // Apply consistent styling
                final styles = <String, String>{};

                if (element.localName == 'p') {
                  styles['margin-bottom'] = '${fontSize * 0.8}px';
                  styles['text-align'] = 'justify';
                }

                if (element.localName == 'h1' ||
                    element.localName == 'h2' ||
                    element.localName == 'h3') {
                  styles['margin-top'] = '${fontSize * 1.5}px';
                  styles['margin-bottom'] = '${fontSize * 0.5}px';
                }

                if (element.localName == 'blockquote') {
                  styles['border-left'] = '3px solid ${_colorToHex(theme.textColor.withOpacity(0.3))}';
                  styles['padding-left'] = '16px';
                  styles['margin-left'] = '0';
                  styles['font-style'] = 'italic';
                }

                return styles;
              },
              customWidgetBuilder: (element) {
                // Handle images
                if (element.localName == 'img') {
                  final src = element.attributes['data-epub-src'] ??
                      element.attributes['src'];
                  if (src != null) {
                    final imageData = _findImage(src);
                    if (imageData != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Image.memory(
                          imageData,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      );
                    }
                  }
                }
                return null;
              },
              onTapUrl: (url) {
                // Handle internal links (could navigate to chapters)
                return true;
              },
            ),
          ),

          if (widget.isLast) const SizedBox(height: 100),
        ],
        ),
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, TextSelectionToolbarAnchors anchors, String Function() getSelectedText) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: anchors,
      buttonItems: [
        ContextMenuButtonItem(
          onPressed: () {
            final text = getSelectedText();
            if (text.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            }
          },
          type: ContextMenuButtonType.copy,
        ),
        ContextMenuButtonItem(
          onPressed: () {
            final text = getSelectedText();
            if (text.isNotEmpty) {
              widget.onTextSelected?.call(text);
            }
          },
          label: 'Highlight',
        ),
        ContextMenuButtonItem(
          onPressed: () {
            final text = getSelectedText();
            if (text.isNotEmpty) {
              _lookUpWord(context, text);
            }
          },
          label: 'Look Up',
        ),
      ],
    );
  }

  void _lookUpWord(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Look Up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text.length > 100 ? '${text.substring(0, 100)}...' : text,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Dictionary lookup coming soon.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Uint8List? _findImage(String src) {
    // Try exact match
    if (widget.images.containsKey(src)) {
      return widget.images[src];
    }

    // Try without leading path
    final filename = src.split('/').last;
    for (final entry in widget.images.entries) {
      if (entry.key.endsWith(filename)) {
        return entry.value;
      }
    }

    return null;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
