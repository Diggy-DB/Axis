import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final LifeDomain domain;
  final HabitFrequency frequency;
  final int targetPerPeriod; // e.g., 3 for 3x per week
  final String? timeOfDay; // 'morning', 'afternoon', 'evening', 'anytime'
  final bool reminderEnabled;
  final DateTime? reminderTime;
  final String color; // hex color
  final String icon; // emoji or icon name
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.frequency,
    required this.targetPerPeriod,
    this.timeOfDay,
    this.reminderEnabled = false,
    this.reminderTime,
    required this.color,
    required this.icon,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      domain: LifeDomain.values.firstWhere(
        (d) => d.name == data['domain'],
        orElse: () => LifeDomain.health,
      ),
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == data['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      targetPerPeriod: data['targetPerPeriod'] ?? 1,
      timeOfDay: data['timeOfDay'],
      reminderEnabled: data['reminderEnabled'] ?? false,
      reminderTime: data['reminderTime'] != null
          ? (data['reminderTime'] as Timestamp).toDate()
          : null,
      color: data['color'] ?? '#6366F1',
      icon: data['icon'] ?? '⭐',
      archived: data['archived'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'domain': domain.name,
      'frequency': frequency.name,
      'targetPerPeriod': targetPerPeriod,
      'timeOfDay': timeOfDay,
      'reminderEnabled': reminderEnabled,
      'reminderTime':
          reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'color': color,
      'icon': icon,
      'archived': archived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Habit copyWith({
    String? name,
    String? description,
    LifeDomain? domain,
    HabitFrequency? frequency,
    int? targetPerPeriod,
    String? timeOfDay,
    bool? reminderEnabled,
    DateTime? reminderTime,
    String? color,
    String? icon,
    bool? archived,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      domain: domain ?? this.domain,
      frequency: frequency ?? this.frequency,
      targetPerPeriod: targetPerPeriod ?? this.targetPerPeriod,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
