import 'package:flutter/material.dart';
import '../../data/models/book.dart';
import '../../core/utils/responsive.dart';
import 'book_card.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onBookTap;
  final Function(Book)? onBookLongPress;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final EdgeInsets? padding;

  const BookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onBookLongPress,
    this.crossAxisCount,
    this.childAspectRatio,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveCrossAxisCount = crossAxisCount ?? Responsive.gridCrossAxisCount(context);
    final responsiveAspectRatio = childAspectRatio ?? Responsive.bookCardAspectRatio(context);
    final responsivePadding = padding ?? Responsive.padding(context);
    final spacing = Responsive.value(context, mobile: 12.0, tablet: 16.0, desktop: 20.0);

    return Responsive.constrainWidth(
      context,
      child: GridView.builder(
        padding: responsivePadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsiveCrossAxisCount,
          childAspectRatio: responsiveAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
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
      ),
    );
  }
}

/// Sliver version for use in CustomScrollView
class SliverBookGrid extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onBookTap;
  final Function(Book)? onBookLongPress;
  final int? crossAxisCount;
  final double? childAspectRatio;

  const SliverBookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onBookLongPress,
    this.crossAxisCount,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveCrossAxisCount = crossAxisCount ?? Responsive.gridCrossAxisCount(context);
    final responsiveAspectRatio = childAspectRatio ?? Responsive.bookCardAspectRatio(context);
    final spacing = Responsive.value(context, mobile: 12.0, tablet: 16.0, desktop: 20.0);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount,
        childAspectRatio: responsiveAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final book = books[index];
          return BookCard(
            book: book,
            onTap: () => onBookTap(book),
            onLongPress: onBookLongPress != null
                ? () => onBookLongPress!(book)
                : null,
          );
        },
        childCount: books.length,
      ),
    );
  }
}
