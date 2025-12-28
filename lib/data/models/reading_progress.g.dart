// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadingProgress _$ReadingProgressFromJson(Map<String, dynamic> json) =>
    ReadingProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
      currentCfi: json['current_cfi'] as String?,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      lastReadAt: json['last_read_at'] == null
          ? null
          : DateTime.parse(json['last_read_at'] as String),
    );

Map<String, dynamic> _$ReadingProgressToJson(ReadingProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'book_id': instance.bookId,
      'current_page': instance.currentPage,
      'current_cfi': instance.currentCfi,
      'progress_percent': instance.progressPercent,
      'last_read_at': instance.lastReadAt?.toIso8601String(),
    };
