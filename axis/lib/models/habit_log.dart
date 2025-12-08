import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

class HabitLog {
  final String id;
  final String habitId;
  final DateTime date; // Normalized to start of day
  final HabitLogStatus status;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.notes,
    this.completedAt,
    required this.createdAt,
  });

  factory HabitLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitLog(
      id: doc.id,
      habitId: data['habitId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: HabitLogStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => HabitLogStatus.completed,
      ),
      notes: data['notes'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'date': Timestamp.fromDate(_normalizeDate(date)),
      'status': status.name,
      'notes': notes,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Normalize date to start of day (00:00:00)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  HabitLog copyWith({
    String? habitId,
    DateTime? date,
    HabitLogStatus? status,
    String? notes,
    DateTime? completedAt,
  }) {
    return HabitLog(
      id: id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }
}

/// Helper class to track habit streaks
class HabitStreak {
  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  HabitStreak({
    required this.habitId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
  });
}
