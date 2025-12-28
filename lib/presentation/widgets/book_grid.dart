import 'package:flutter/material.dart';
import '../../data/models/book.dart';
import 'book_card.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onBookTap;
  final Function(Book)? onBookLongPress;
  final int crossAxisCount;
  final double childAspectRatio;

  const BookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onBookLongPress,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          onTap: () => onBookTap(book),
          onLongPress: onBookLongPress != null
              ? () => onBookLongPress!(book)
              : null,
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }
}
