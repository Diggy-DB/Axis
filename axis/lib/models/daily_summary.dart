import 'package:cloud_firestore/cloud_firestore.dart';

class DailySummary {
  final String id;
  final DateTime date; // Date this summary is for
  final String aiMessage; // AI-generated motivational message
  final int tasksCompleted;
  final double productiveHours;
  final String? keyInsight; // AI's key insight from reflection
  final DateTime createdAt;

  DailySummary({
    required this.id,
    required this.date,
    required this.aiMessage,
    required this.tasksCompleted,
    required this.productiveHours,
    this.keyInsight,
    required this.createdAt,
  });

  factory DailySummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailySummary(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      aiMessage: data['aiMessage'] ?? '',
      tasksCompleted: data['tasksCompleted'] ?? 0,
      productiveHours: (data['productiveHours'] ?? 0.0).toDouble(),
      keyInsight: data['keyInsight'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(_normalizeDate(date)),
      'aiMessage': aiMessage,
      'tasksCompleted': tasksCompleted,
      'productiveHours': productiveHours,
      'keyInsight': keyInsight,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Normalize date to start of day (00:00:00)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
