import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String label;
  final int colorValue; // Store as int for Firestore
  final DateTime createdAt;

  Category({
    required this.id,
    required this.label,
    required this.colorValue,
    required this.createdAt,
  });

  // Convert Color to Category
  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      label: map['label'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF6B66FF,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      label: data['label'] ?? '',
      colorValue: data['colorValue'] ?? 0xFF6B66FF,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'colorValue': colorValue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert to old format for backward compatibility
  Map<String, dynamic> toLegacyMap() {
    return {
      'label': label,
      'color': colorValue,
    };
  }
}
