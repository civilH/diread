import 'package:flutter/material.dart';
import '../../data/models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isListView;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: isListView ? _buildListItem(context) : _buildGridItem(context),
    );
  }

  Widget _buildGridItem(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _BookCover(book: book),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (book.author != null && book.author!.isNotEmpty)
            Text(
              book.author!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 60,
                  height: 80,
                  child: _BookCover(book: book),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (book.author != null && book.author!.isNotEmpty)
                      Text(
                        book.author!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _BookTag(
                          text: book.fileType == BookType.pdf ? 'PDF' : 'EPUB',
                        ),
                        const SizedBox(width: 8),
                        if (book.fileSize != null)
                          Text(
                            book.fileSizeFormatted,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const Spacer(),
                        if (book.isDownloaded)
                          const Icon(
                            Icons.download_done,
                            size: 18,
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final Book book;

  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    // Always use placeholder - no network images for performance
    return _BookPlaceholder(book: book);
  }
}

class _BookPlaceholder extends StatelessWidget {
  final Book book;

  const _BookPlaceholder({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade600,
            Colors.blueGrey.shade800,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              book.fileType == BookType.pdf ? Icons.picture_as_pdf : Icons.book,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookTag extends StatelessWidget {
  final String text;

  const _BookTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
