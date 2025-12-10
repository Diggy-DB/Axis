import 'package:cloud_firestore/cloud_firestore.dart';

class ActualScheduleEntry {
  final String activity;
  final DateTime startTime;
  final DateTime endTime;

  ActualScheduleEntry({
    required this.activity,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
  }

  factory ActualScheduleEntry.fromMap(Map<String, dynamic> map) {
    return ActualScheduleEntry(
      activity: map['activity'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
    );
  }
}

class Reflection {
  final String id;
  final DateTime date; // Normalized to start of day
  final String text;
  final int? mood; // 1-10 scale
  final int? energy; // 1-10 scale
  final String? gratitude;
  final String? challenges;
  final String? wins;
  final List<String> tags;
  final List<String> completedTaskIds; // IDs of tasks completed today
  final List<ActualScheduleEntry> actualSchedule; // What user actually did
  final String? aiPromptForNextDay; // AI-generated prompt for next day
  final DateTime createdAt;
  final DateTime updatedAt;

  Reflection({
    required this.id,
    required this.date,
    required this.text,
    this.mood,
    this.energy,
    this.gratitude,
    this.challenges,
    this.wins,
    this.tags = const [],
    this.completedTaskIds = const [],
    this.actualSchedule = const [],
    this.aiPromptForNextDay,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reflection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reflection(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      text: data['text'] ?? '',
      mood: data['mood'],
      energy: data['energy'],
      gratitude: data['gratitude'],
      challenges: data['challenges'],
      wins: data['wins'],
      tags: List<String>.from(data['tags'] ?? []),
      completedTaskIds: List<String>.from(data['completedTaskIds'] ?? []),
      actualSchedule: (data['actualSchedule'] as List<dynamic>?)
              ?.map(
                  (e) => ActualScheduleEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiPromptForNextDay: data['aiPromptForNextDay'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(_normalizeDate(date)),
      'text': text,
      'mood': mood,
      'energy': energy,
      'gratitude': gratitude,
      'challenges': challenges,
      'wins': wins,
      'tags': tags,
      'completedTaskIds': completedTaskIds,
      'actualSchedule': actualSchedule.map((e) => e.toMap()).toList(),
      'aiPromptForNextDay': aiPromptForNextDay,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Normalize date to start of day (00:00:00)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Reflection copyWith({
    DateTime? date,
    String? text,
    int? mood,
    int? energy,
    String? gratitude,
    String? challenges,
    String? wins,
    List<String>? tags,
    List<String>? completedTaskIds,
    List<ActualScheduleEntry>? actualSchedule,
    String? aiPromptForNextDay,
    DateTime? updatedAt,
  }) {
    return Reflection(
      id: id,
      date: date ?? this.date,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      gratitude: gratitude ?? this.gratitude,
      challenges: challenges ?? this.challenges,
      wins: wins ?? this.wins,
      tags: tags ?? this.tags,
      completedTaskIds: completedTaskIds ?? this.completedTaskIds,
      actualSchedule: actualSchedule ?? this.actualSchedule,
      aiPromptForNextDay: aiPromptForNextDay ?? this.aiPromptForNextDay,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get a preview of the reflection text (first 100 characters)
  String get preview {
    if (text.length <= 100) return text;
    return '${text.substring(0, 97)}...';
  }
}
