import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/config/theme.dart';
import '../../providers/reader_provider.dart';

class PdfReaderView extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;
  final VoidCallback? onTap;
  final Function(String)? onTextSelected;

  const PdfReaderView({
    super.key,
    this.file,
    this.bytes,
    this.onTap,
    this.onTextSelected,
  });

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  PdfViewerController? _pdfController;
  int _lastKnownPage = 0;
  ScrollDirection? _lastScrollDirection;
  String _selectedText = '';
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    if (_pdfController != null && _pdfController!.pageNumber != page + 1) {
      _pdfController!.jumpToPage(page + 1);
      _lastKnownPage = page;
    }
  }

  void _onPageChanged(int pageNumber) {
    _lastKnownPage = pageNumber - 1;
    // Immediate update for responsive slider/page sync
    if (mounted) {
      context.read<ReaderProvider>().updatePage(pageNumber - 1);
    }
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails? details) {
    if (details?.selectedText != null && details!.selectedText!.isNotEmpty) {
      setState(() {
        _selectedText = details.selectedText!;
        _hasSelection = true;
      });
    } else if (details?.selectedText == null || details!.selectedText!.isEmpty) {
      // Only clear if there's no text (selection was cleared)
      if (_hasSelection && _selectedText.isEmpty) {
        setState(() {
          _hasSelection = false;
        });
      }
    }
  }

  void _showSelectionOptions() {
    if (_selectedText.isEmpty) return;

    final text = _selectedText;
    widget.onTextSelected?.call(text);

    // Clear selection after showing options
    setState(() {
      _selectedText = '';
      _hasSelection = false;
    });
    _pdfController?.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to scroll direction and current page for navigation
    final scrollDirection = context.select<ReaderProvider, ScrollDirection>(
      (provider) => provider.settings.scrollDirection,
    );
    final currentPage = context.select<ReaderProvider, int>(
      (provider) => provider.currentPage,
    );

    // Check if scroll direction changed - need to recreate controller
    if (_lastScrollDirection != null && _lastScrollDirection != scrollDirection) {
      _pdfController?.dispose();
      _pdfController = PdfViewerController();
    }
    _lastScrollDirection = scrollDirection;

    // Jump to page if changed externally (from nav buttons or slider)
    if (currentPage != _lastKnownPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _jumpToPage(currentPage);
        }
      });
    }

    if (kIsWeb && widget.bytes != null) {
      return _buildViewer(widget.bytes!, null, scrollDirection);
    } else if (widget.file != null) {
      return _buildViewer(null, widget.file!, scrollDirection);
    }
    return const Center(child: Text('No PDF file available'));
  }

  Widget _buildViewer(Uint8List? bytes, File? file, ScrollDirection scrollDirection) {
    final reader = context.read<ReaderProvider>();

    // Convert ScrollDirection to Syncfusion options
    // Horizontal = Page-by-page, swipe left/right (like flipping pages)
    // Vertical = Continuous scroll (like a web page)
    // Continuous = Continuous scroll with page indicators
    final PdfPageLayoutMode layoutMode;
    final PdfScrollDirection pdfScrollDirection;

    switch (scrollDirection) {
      case ScrollDirection.horizontal:
        // Single page mode, swipe left/right between pages
        layoutMode = PdfPageLayoutMode.single;
        pdfScrollDirection = PdfScrollDirection.horizontal;
        break;
      case ScrollDirection.vertical:
        // Continuous vertical scrolling (what users expect)
        layoutMode = PdfPageLayoutMode.continuous;
        pdfScrollDirection = PdfScrollDirection.vertical;
        break;
      case ScrollDirection.continuous:
        // Same as vertical but with page spacing
        layoutMode = PdfPageLayoutMode.continuous;
        pdfScrollDirection = PdfScrollDirection.vertical;
        break;
    }

    // Use ValueKey to force rebuild when scroll direction changes
    final viewerKey = ValueKey('pdf_viewer_${scrollDirection.name}');

    final viewer = bytes != null
        ? SfPdfViewer.memory(
            bytes,
            key: viewerKey,
            controller: _pdfController,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: false,
            pageSpacing: scrollDirection != ScrollDirection.horizontal ? 4 : 0,
            pageLayoutMode: layoutMode,
            scrollDirection: pdfScrollDirection,
            onDocumentLoaded: (details) {
              reader.setTotalPages(details.document.pages.count);
              // Restore page position after rebuild
              if (_lastKnownPage > 0) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _pdfController?.jumpToPage(_lastKnownPage + 1);
                });
              }
            },
            onDocumentLoadFailed: (details) {
              debugPrint('PDF load failed: ${details.error}, ${details.description}');
            },
            onPageChanged: (details) => _onPageChanged(details.newPageNumber),
            onTextSelectionChanged: _onTextSelectionChanged,
            onTap: (details) {
              // If text is selected, show the selection menu
              if (_hasSelection && _selectedText.isNotEmpty) {
                _showSelectionOptions();
              } else {
                // Toggle controls on tap
                widget.onTap?.call();
              }
            },
          )
        : SfPdfViewer.file(
            file!,
            key: viewerKey,
            controller: _pdfController,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: scrollDirection != ScrollDirection.horizontal,
            canShowScrollStatus: scrollDirection != ScrollDirection.horizontal,
            canShowPaginationDialog: false,
            pageSpacing: scrollDirection != ScrollDirection.horizontal ? 4 : 0,
            pageLayoutMode: layoutMode,
            scrollDirection: pdfScrollDirection,
            onDocumentLoaded: (details) {
              reader.setTotalPages(details.document.pages.count);
              // Restore page position after rebuild
              if (_lastKnownPage > 0) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _pdfController?.jumpToPage(_lastKnownPage + 1);
                });
              }
            },
            onPageChanged: (details) => _onPageChanged(details.newPageNumber),
            onTextSelectionChanged: _onTextSelectionChanged,
            onTap: (details) {
              // If text is selected, show the selection menu
              if (_hasSelection && _selectedText.isNotEmpty) {
                _showSelectionOptions();
              } else {
                // Toggle controls on tap
                widget.onTap?.call();
              }
            },
          );

    // Wrap viewer with floating action button for text selection
    return Stack(
      children: [
        SizedBox.expand(child: viewer),
        // Floating action button when text is selected
        if (_hasSelection && _selectedText.isNotEmpty)
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _showSelectionOptions,
              icon: const Icon(Icons.format_quote),
              label: const Text('Highlight'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
