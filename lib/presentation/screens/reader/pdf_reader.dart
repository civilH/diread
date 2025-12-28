import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../data/models/highlight.dart';
import '../../providers/reader_provider.dart';

class PdfReaderView extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;

  const PdfReaderView({super.key, this.file, this.bytes});

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  late PdfViewerController _pdfController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  Timer? _pageUpdateDebounce;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pageUpdateDebounce?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageNumber) {
    // Debounce page updates to reduce rebuilds
    _pageUpdateDebounce?.cancel();
    _pageUpdateDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ReaderProvider>().updatePage(pageNumber - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when scroll mode changes
    final scrollMode = context.select<ReaderProvider, bool>(
      (provider) => provider.settings.scrollMode,
    );

    if (kIsWeb && widget.bytes != null) {
      return _buildViewer(widget.bytes!, null, scrollMode);
    } else if (widget.file != null) {
      return _buildViewer(null, widget.file!, scrollMode);
    }
    return const Center(child: Text('No PDF file available'));
  }

  Widget _buildViewer(Uint8List? bytes, File? file, bool scrollMode) {
    final reader = context.read<ReaderProvider>();

    final viewer = bytes != null
        ? SfPdfViewer.memory(
            bytes,
            key: _pdfViewerKey,
            controller: _pdfController,
            enableDoubleTapZooming: true,
            enableTextSelection: false, // Disable for better performance
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
            pageSpacing: 0,
            pageLayoutMode: scrollMode
                ? PdfPageLayoutMode.continuous
                : PdfPageLayoutMode.single,
            scrollDirection: scrollMode
                ? PdfScrollDirection.vertical
                : PdfScrollDirection.horizontal,
            onDocumentLoaded: (details) {
              reader.setTotalPages(details.document.pages.count);
              if (reader.currentPage > 0) {
                _pdfController.jumpToPage(reader.currentPage + 1);
              }
            },
            onPageChanged: (details) => _onPageChanged(details.newPageNumber),
          )
        : SfPdfViewer.file(
            file!,
            key: _pdfViewerKey,
            controller: _pdfController,
            enableDoubleTapZooming: true,
            enableTextSelection: false, // Disable for better performance
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
            pageSpacing: 0,
            pageLayoutMode: scrollMode
                ? PdfPageLayoutMode.continuous
                : PdfPageLayoutMode.single,
            scrollDirection: scrollMode
                ? PdfScrollDirection.vertical
                : PdfScrollDirection.horizontal,
            onDocumentLoaded: (details) {
              reader.setTotalPages(details.document.pages.count);
              if (reader.currentPage > 0) {
                _pdfController.jumpToPage(reader.currentPage + 1);
              }
            },
            onPageChanged: (details) => _onPageChanged(details.newPageNumber),
          );

    return RepaintBoundary(child: viewer);
  }
}
