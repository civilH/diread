import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

enum BookType {
  @JsonValue('pdf')
  pdf,
  @JsonValue('epub')
  epub,
}

@JsonSerializable()
class Book extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  final String? author;
  @JsonKey(name: 'cover_url')
  final String? coverUrl;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'file_type')
  final BookType fileType;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'total_pages')
  final int? totalPages;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  // Local-only fields (not from API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localPath;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localCoverPath;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isDownloaded;

  const Book({
    required this.id,
    required this.userId,
    required this.title,
    this.author,
    this.coverUrl,
    required this.fileUrl,
    required this.fileType,
    this.fileSize,
    this.totalPages,
    this.createdAt,
    this.localPath,
    this.localCoverPath,
    this.isDownloaded = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? coverUrl,
    String? fileUrl,
    BookType? fileType,
    int? fileSize,
    int? totalPages,
    DateTime? createdAt,
    String? localPath,
    String? localCoverPath,
    bool? isDownloaded,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
      localPath: localPath ?? this.localPath,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  String get fileExtension => fileType == BookType.pdf ? 'pdf' : 'epub';

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize} B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        author,
        coverUrl,
        fileUrl,
        fileType,
        fileSize,
        totalPages,
        createdAt,
      ];
}
