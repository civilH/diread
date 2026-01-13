import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final String id;
  final String bookId;
  final String userId;
  final String content;
  final int? pageNumber;
  final String? cfi; // For EPUB location
  final String? selectedText; // Text the note is attached to
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.content,
    this.pageNumber,
    this.cfi,
    this.selectedText,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  Note copyWith({
    String? id,
    String? bookId,
    String? userId,
    String? content,
    int? pageNumber,
    String? cfi,
    String? selectedText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      cfi: cfi ?? this.cfi,
      selectedText: selectedText ?? this.selectedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
