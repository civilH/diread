import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bookmark.g.dart';

@JsonSerializable()
class Bookmark extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'book_id')
  final String bookId;
  @JsonKey(name: 'page_number')
  final int? pageNumber;
  final String? cfi; // For EPUB location
  final String? title;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.bookId,
    this.pageNumber,
    this.cfi,
    this.title,
    this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) =>
      _$BookmarkFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkToJson(this);

  Bookmark copyWith({
    String? id,
    String? userId,
    String? bookId,
    int? pageNumber,
    String? cfi,
    String? title,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      cfi: cfi ?? this.cfi,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayTitle => title ?? 'Page ${pageNumber ?? 0}';

  @override
  List<Object?> get props => [id, userId, bookId, pageNumber, cfi, title, createdAt];
}
