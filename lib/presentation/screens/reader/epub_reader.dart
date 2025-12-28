import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../providers/reader_provider.dart';

class EpubReaderView extends StatelessWidget {
  final File file;

  const EpubReaderView({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, reader, _) {
        return Container(
          color: reader.settings.theme.backgroundColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book,
                    size: 80,
                    color: reader.settings.theme.textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'EPUB Reader',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: reader.settings.theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EPUB support is coming soon!\n\nFor now, please use PDF files.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: reader.settings.theme.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
