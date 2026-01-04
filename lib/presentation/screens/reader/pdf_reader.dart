import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/config/theme.dart';
import '../../providers/reader_provider.dart';

class PdfReaderView extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;

  const PdfReaderView({super.key, this.file, this.bytes});

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  PdfViewerController? _pdfController;
  Timer? _pageUpdateDebounce;
  int _lastKnownPage = 0;
  ScrollDirection? _lastScrollDirection;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pageUpdateDebounce?.cancel();
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
    // Debounce page updates to reduce rebuilds
    _pageUpdateDebounce?.cancel();
    _pageUpdateDebounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<ReaderProvider>().updatePage(pageNumber - 1);
      }
    });
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
    final PdfPageLayoutMode layoutMode;
    final PdfScrollDirection pdfScrollDirection;

    switch (scrollDirection) {
      case ScrollDirection.horizontal:
        layoutMode = PdfPageLayoutMode.single;
        pdfScrollDirection = PdfScrollDirection.horizontal;
        break;
      case ScrollDirection.vertical:
        layoutMode = PdfPageLayoutMode.single;
        pdfScrollDirection = PdfScrollDirection.vertical;
        break;
      case ScrollDirection.continuous:
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
            enableTextSelection: false,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: false,
            pageSpacing: scrollDirection == ScrollDirection.continuous ? 4 : 0,
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
          )
        : SfPdfViewer.file(
            file!,
            key: viewerKey,
            controller: _pdfController,
            enableDoubleTapZooming: true,
            enableTextSelection: false,
            canShowScrollHead: scrollDirection == ScrollDirection.continuous,
            canShowScrollStatus: scrollDirection == ScrollDirection.continuous,
            canShowPaginationDialog: false,
            pageSpacing: scrollDirection == ScrollDirection.continuous ? 4 : 0,
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
          );

    return RepaintBoundary(child: viewer);
  }
}
