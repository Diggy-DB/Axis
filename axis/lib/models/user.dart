import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final String timezone;
  final UserPreferences preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.timezone,
    required this.preferences,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      timezone: data['timezone'] ?? 'UTC',
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'timezone': timezone,
      'preferences': preferences.toMap(),
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    String? timezone,
    UserPreferences? preferences,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      timezone: timezone ?? this.timezone,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserPreferences {
  final String theme; // 'light', 'dark', 'system'
  final int firstDayOfWeek; // 0 = Sunday, 1 = Monday
  final bool notificationsEnabled;

  UserPreferences({
    this.theme = 'system',
    this.firstDayOfWeek = 1,
    this.notificationsEnabled = true,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? 'system',
      firstDayOfWeek: map['firstDayOfWeek'] ?? 1,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'firstDayOfWeek': firstDayOfWeek,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserPreferences copyWith({
    String? theme,
    int? firstDayOfWeek,
    bool? notificationsEnabled,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
