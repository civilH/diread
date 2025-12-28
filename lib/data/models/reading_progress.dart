import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reading_progress.g.dart';

@JsonSerializable()
class ReadingProgress extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'book_id')
  final String bookId;
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'current_cfi')
  final String? currentCfi; // For EPUB location
  @JsonKey(name: 'progress_percent')
  final double progressPercent;
  @JsonKey(name: 'last_read_at')
  final DateTime? lastReadAt;

  const ReadingProgress({
    required this.id,
    required this.userId,
    required this.bookId,
    this.currentPage = 0,
    this.currentCfi,
    this.progressPercent = 0.0,
    this.lastReadAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      _$ReadingProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ReadingProgressToJson(this);

  factory ReadingProgress.empty({
    required String userId,
    required String bookId,
  }) {
    return ReadingProgress(
      id: '',
      userId: userId,
      bookId: bookId,
      currentPage: 0,
      progressPercent: 0.0,
    );
  }

  ReadingProgress copyWith({
    String? id,
    String? userId,
    String? bookId,
    int? currentPage,
    String? currentCfi,
    double? progressPercent,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
      currentCfi: currentCfi ?? this.currentCfi,
      progressPercent: progressPercent ?? this.progressPercent,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  int get progressPercentInt => (progressPercent * 100).round();

  String get progressText => '${progressPercentInt}%';

  bool get hasStarted => currentPage > 0 || progressPercent > 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        bookId,
        currentPage,
        currentCfi,
        progressPercent,
        lastReadAt,
      ];
}
