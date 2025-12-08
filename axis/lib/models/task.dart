import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? scheduledDate; // When user plans to do it
  final TaskStatus status;
  final TaskPriority priority;
  final LifeDomain? domain;
  final String? linkedHabitId;
  final int? estimatedMinutes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.scheduledDate,
    required this.status,
    this.priority = TaskPriority.medium,
    this.domain,
    this.linkedHabitId,
    this.estimatedMinutes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      scheduledDate: data['scheduledDate'] != null
          ? (data['scheduledDate'] as Timestamp).toDate()
          : null,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      domain: data['domain'] != null
          ? LifeDomain.values.firstWhere(
              (d) => d.name == data['domain'],
              orElse: () => LifeDomain.career,
            )
          : null,
      linkedHabitId: data['linkedHabitId'],
      estimatedMinutes: data['estimatedMinutes'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'status': status.name,
      'priority': priority.name,
      'domain': domain?.name,
      'linkedHabitId': linkedHabitId,
      'estimatedMinutes': estimatedMinutes,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isScheduledToday {
    if (scheduledDate == null) return false;
    final now = DateTime.now();
    return scheduledDate!.year == now.year &&
        scheduledDate!.month == now.month &&
        scheduledDate!.day == now.day;
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? scheduledDate,
    TaskStatus? status,
    TaskPriority? priority,
    LifeDomain? domain,
    String? linkedHabitId,
    int? estimatedMinutes,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      domain: domain ?? this.domain,
      linkedHabitId: linkedHabitId ?? this.linkedHabitId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
