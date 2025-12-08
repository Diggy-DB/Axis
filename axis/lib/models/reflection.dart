import 'package:cloud_firestore/cloud_firestore.dart';

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
