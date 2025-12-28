// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bookmark _$BookmarkFromJson(Map<String, dynamic> json) => Bookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      pageNumber: (json['page_number'] as num?)?.toInt(),
      cfi: json['cfi'] as String?,
      title: json['title'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BookmarkToJson(Bookmark instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'book_id': instance.bookId,
      'page_number': instance.pageNumber,
      'cfi': instance.cfi,
      'title': instance.title,
      'created_at': instance.createdAt?.toIso8601String(),
    };
