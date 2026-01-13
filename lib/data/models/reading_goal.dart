import 'package:equatable/equatable.dart';

enum GoalType {
  daily,    // Pages per day
  weekly,   // Books per week
  monthly,  // Books per month
  yearly,   // Books per year
}

enum GoalStatus {
  active,
  completed,
  failed,
}

class ReadingGoal extends Equatable {
  final String id;
  final GoalType type;
  final int target;
  final int current;
  final DateTime startDate;
  final DateTime endDate;
  final GoalStatus status;

  const ReadingGoal({
    required this.id,
    required this.type,
    required this.target,
    this.current = 0,
    required this.startDate,
    required this.endDate,
    this.status = GoalStatus.active,
  });

  double get progressPercent => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => current >= target;

  int get remaining => (target - current).clamp(0, target);

  Duration get timeRemaining => endDate.difference(DateTime.now());

  bool get isExpired => DateTime.now().isAfter(endDate);

  String get typeLabel {
    switch (type) {
      case GoalType.daily:
        return 'Daily Pages';
      case GoalType.weekly:
        return 'Weekly Books';
      case GoalType.monthly:
        return 'Monthly Books';
      case GoalType.yearly:
        return 'Yearly Books';
    }
  }

  String get progressText {
    switch (type) {
      case GoalType.daily:
        return '$current / $target pages';
      default:
        return '$current / $target books';
    }
  }

  ReadingGoal copyWith({
    String? id,
    GoalType? type,
    int? target,
    int? current,
    DateTime? startDate,
    DateTime? endDate,
    GoalStatus? status,
  }) {
    return ReadingGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'target': target,
      'current': current,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory ReadingGoal.fromMap(Map<String, dynamic> map) {
    return ReadingGoal(
      id: map['id'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GoalType.daily,
      ),
      target: map['target'] as int,
      current: map['current'] as int? ?? 0,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GoalStatus.active,
      ),
    );
  }

  /// Create a daily reading goal
  factory ReadingGoal.daily({
    required String id,
    required int pagesPerDay,
  }) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return ReadingGoal(
      id: id,
      type: GoalType.daily,
      target: pagesPerDay,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Create a weekly reading goal
  factory ReadingGoal.weekly({
    required String id,
    required int booksPerWeek,
  }) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));

    return ReadingGoal(
      id: id,
      type: GoalType.weekly,
      target: booksPerWeek,
      startDate: start,
      endDate: end,
    );
  }

  /// Create a yearly reading goal
  factory ReadingGoal.yearly({
    required String id,
    required int booksPerYear,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year + 1, 1, 1);

    return ReadingGoal(
      id: id,
      type: GoalType.yearly,
      target: booksPerYear,
      startDate: start,
      endDate: end,
    );
  }

  @override
  List<Object?> get props => [id, type, target, current, startDate, endDate, status];
}
