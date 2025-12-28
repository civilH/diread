// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Highlight _$HighlightFromJson(Map<String, dynamic> json) => Highlight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      text: json['text'] as String,
      pageNumber: (json['page_number'] as num?)?.toInt(),
      cfi: json['cfi'] as String?,
      color: $enumDecodeNullable(_$HighlightColorEnumMap, json['color']) ??
          HighlightColor.yellow,
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$HighlightToJson(Highlight instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'book_id': instance.bookId,
      'text': instance.text,
      'page_number': instance.pageNumber,
      'cfi': instance.cfi,
      'color': _$HighlightColorEnumMap[instance.color]!,
      'note': instance.note,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$HighlightColorEnumMap = {
  HighlightColor.yellow: 'yellow',
  HighlightColor.green: 'green',
  HighlightColor.blue: 'blue',
  HighlightColor.pink: 'pink',
  HighlightColor.orange: 'orange',
};
