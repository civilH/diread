// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      pageNumber: json['page_number'] as int?,
      cfi: json['cfi'] as String?,
      selectedText: json['selected_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
      'id': instance.id,
      'book_id': instance.bookId,
      'user_id': instance.userId,
      'content': instance.content,
      'page_number': instance.pageNumber,
      'cfi': instance.cfi,
      'selected_text': instance.selectedText,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
