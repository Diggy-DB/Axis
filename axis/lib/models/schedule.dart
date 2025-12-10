import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? category;
  final String? location;
  final String? recurrence; // 'none', 'daily', 'weekly', 'biweekly', 'monthly'
  final String? recurrenceId; // Links recurring schedules together
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    this.category,
    this.location,
    this.recurrence,
    this.recurrenceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      category: data['category'],
      location: data['location'],
      recurrence: data['recurrence'],
      recurrenceId: data['recurrenceId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'category': category,
      'location': location,
      'recurrence': recurrence,
      'recurrenceId': recurrenceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Schedule copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? location,
    String? recurrence,
    String? recurrenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      location: location ?? this.location,
      recurrence: recurrence ?? this.recurrence,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
