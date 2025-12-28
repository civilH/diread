import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'highlight.g.dart';

enum HighlightColor {
  @JsonValue('yellow')
  yellow,
  @JsonValue('green')
  green,
  @JsonValue('blue')
  blue,
  @JsonValue('pink')
  pink,
  @JsonValue('orange')
  orange,
}

extension HighlightColorExtension on HighlightColor {
  int get colorValue {
    switch (this) {
      case HighlightColor.yellow:
        return 0xFFFFEB3B;
      case HighlightColor.green:
        return 0xFF4CAF50;
      case HighlightColor.blue:
        return 0xFF2196F3;
      case HighlightColor.pink:
        return 0xFFE91E63;
      case HighlightColor.orange:
        return 0xFFFF9800;
    }
  }

  String get name {
    switch (this) {
      case HighlightColor.yellow:
        return 'Yellow';
      case HighlightColor.green:
        return 'Green';
      case HighlightColor.blue:
        return 'Blue';
      case HighlightColor.pink:
        return 'Pink';
      case HighlightColor.orange:
        return 'Orange';
    }
  }
}

@JsonSerializable()
class Highlight extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'book_id')
  final String bookId;
  final String text;
  @JsonKey(name: 'page_number')
  final int? pageNumber;
  final String? cfi; // For EPUB location
  final HighlightColor color;
  final String? note;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const Highlight({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.text,
    this.pageNumber,
    this.cfi,
    this.color = HighlightColor.yellow,
    this.note,
    this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) =>
      _$HighlightFromJson(json);

  Map<String, dynamic> toJson() => _$HighlightToJson(this);

  Highlight copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? text,
    int? pageNumber,
    String? cfi,
    HighlightColor? color,
    String? note,
    DateTime? createdAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      text: text ?? this.text,
      pageNumber: pageNumber ?? this.pageNumber,
      cfi: cfi ?? this.cfi,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasNote => note != null && note!.isNotEmpty;

  String get previewText {
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bookId,
        text,
        pageNumber,
        cfi,
        color,
        note,
        createdAt,
      ];
}
