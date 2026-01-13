import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/library_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_grid.dart';
import '../../../core/utils/validators.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGridView = true;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<LibraryProvider>().clearSearch();
      }
    });
  }

  Future<void> _uploadBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Validate file
    if (!Validators.isValidFileType(file.extension ?? '')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only PDF and EPUB files are allowed')),
        );
      }
      return;
    }

    if (!Validators.isValidFileSize(file.size)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 100MB')),
        );
      }
      return;
    }

    // Upload book
    final libraryProvider = context.read<LibraryProvider>();
    final title = file.name.replaceAll(RegExp(r'\.(pdf|epub)$'), '');

    try {
      final book = kIsWeb
          ? await libraryProvider.uploadBookBytes(
              file.bytes!,
              fileName: file.name,
              title: title,
            )
          : await libraryProvider.uploadBook(
              File(file.path!),
              title: title,
            );

      if (book != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _showSortOptions() {
    final libraryProvider = context.read<LibraryProvider>();

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
              'Sort by',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSortOption(
              'Recently Added',
              SortOption.recentlyAdded,
              libraryProvider,
            ),
            _buildSortOption(
              'Recently Read',
              SortOption.recentlyRead,
              libraryProvider,
            ),
            _buildSortOption(
              'Title',
              SortOption.title,
              libraryProvider,
            ),
            _buildSortOption(
              'Author',
              SortOption.author,
              libraryProvider,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String label,
    SortOption option,
    LibraryProvider provider,
  ) {
    final isSelected = provider.sortOption == option;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(label),
      onTap: () {
        provider.setSortOption(option);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                style: const TextStyle(fontSize: 18),
                onChanged: (value) {
                  context.read<LibraryProvider>().setSearchQuery(value);
                },
              )
            : const Text('My Library'),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleSearch,
              )
            : null,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                context.read<LibraryProvider>().clearSearch();
              },
            ),
          ],
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          if (library.isLoading && library.books.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (library.status == LibraryStatus.error &&
              library.books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    library.errorMessage ?? 'Something went wrong',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => library.loadBooks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (library.books.isEmpty) {
            // Check if it's due to search filter
            if (library.hasSearchQuery) {
              return _buildNoSearchResults(library.searchQuery);
            }
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => library.refresh(),
            child: _isGridView
                ? BookGrid(
                    books: library.books,
                    onBookTap: (book) => context.push('/reader/${book.id}'),
                    onBookLongPress: (book) =>
                        context.push('/book/${book.id}'),
                  )
                : _buildListView(library),
          );
        },
      ),
      floatingActionButton: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          if (library.isUploading) {
            return FloatingActionButton(
              onPressed: null,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            );
          }

          return FloatingActionButton.extended(
            onPressed: _uploadBook,
            icon: const Icon(Icons.add),
            label: const Text('Add Book'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Your library is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first book to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _uploadBook,
            icon: const Icon(Icons.add),
            label: const Text('Add Book'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No books matching "$query"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _toggleSearch,
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(LibraryProvider library) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: library.books.length,
      itemBuilder: (context, index) {
        final book = library.books[index];
        return BookCard(
          book: book,
          isListView: true,
          onTap: () => context.push('/reader/${book.id}'),
          onLongPress: () => context.push('/book/${book.id}'),
        );
      },
    );
  }
}
