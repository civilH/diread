import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/book.dart';
import '../../providers/library_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, _) {
        final book = library.getBookById(bookId);

        if (book == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Book not found'),
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, book),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),

                      // Author
                      if (book.author != null && book.author!.isNotEmpty)
                        Text(
                          book.author!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      const SizedBox(height: 24),

                      // Info Row
                      _buildInfoRow(context, book),
                      const SizedBox(height: 32),

                      // Read Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/reader/${book.id}'),
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Start Reading'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Download / Delete Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: book.isDownloaded
                                  ? null
                                  : () async {
                                      await library.downloadBook(book);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Book downloaded for offline reading'),
                                          ),
                                        );
                                      }
                                    },
                              icon: Icon(
                                book.isDownloaded
                                    ? Icons.download_done
                                    : Icons.download,
                              ),
                              label: Text(
                                book.isDownloaded ? 'Downloaded' : 'Download',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showDeleteConfirmation(context, library, book),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Book book) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: book.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: book.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderCover(book),
              )
            : _buildPlaceholderCover(book),
      ),
    );
  }

  Widget _buildPlaceholderCover(Book book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade700,
            Colors.blueGrey.shade900,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              book.fileType == BookType.pdf
                  ? Icons.picture_as_pdf
                  : Icons.book,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                book.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, Book book) {
    return Row(
      children: [
        _buildInfoItem(
          context,
          Icons.insert_drive_file_outlined,
          book.fileType == BookType.pdf ? 'PDF' : 'EPUB',
        ),
        const SizedBox(width: 24),
        if (book.fileSize != null)
          _buildInfoItem(
            context,
            Icons.storage_outlined,
            book.fileSizeFormatted,
          ),
        const SizedBox(width: 24),
        if (book.totalPages != null)
          _buildInfoItem(
            context,
            Icons.menu_book_outlined,
            '${book.totalPages} pages',
          ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    LibraryProvider library,
    Book book,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);
              // Navigate to home/library immediately (before book is removed from list)
              context.go('/');
              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book deleted')),
              );
              // Delete book in background
              await library.deleteBook(book.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
