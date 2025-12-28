// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverUrl: json['cover_url'] as String?,
      fileUrl: json['file_url'] as String,
      fileType: $enumDecode(_$BookTypeEnumMap, json['file_type']),
      fileSize: (json['file_size'] as num?)?.toInt(),
      totalPages: (json['total_pages'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'author': instance.author,
      'cover_url': instance.coverUrl,
      'file_url': instance.fileUrl,
      'file_type': _$BookTypeEnumMap[instance.fileType]!,
      'file_size': instance.fileSize,
      'total_pages': instance.totalPages,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$BookTypeEnumMap = {
  BookType.pdf: 'pdf',
  BookType.epub: 'epub',
};
