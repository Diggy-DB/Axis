import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final String timezone;
  final UserPreferences preferences;
  final bool emailVerified;
  // New onboarding fields
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? coreValues; // Answer 1: Core values
  final String? worldview; // Answer 2: Worldview, belief system and purpose
  final String? ambition; // Answer 3: Future ambition and role

  // Convenience getter for name
  String get name => displayName.isNotEmpty ? displayName : (firstName != null && lastName != null ? '$firstName $lastName' : 'User');

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.timezone,
    required this.preferences,
    this.emailVerified = false,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.coreValues,
    this.worldview,
    this.ambition,
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
      emailVerified: data['emailVerified'] ?? false,
      firstName: data['firstName'],
      lastName: data['lastName'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      coreValues: data['answer1'],
      worldview: data['answer2'],
      ambition: data['answer3'],
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
      'emailVerified': emailVerified,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'answer1': coreValues,
      'answer2': worldview,
      'answer3': ambition,
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    String? timezone,
    UserPreferences? preferences,
    bool? emailVerified,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? coreValues,
    String? worldview,
    String? ambition,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      timezone: timezone ?? this.timezone,
      preferences: preferences ?? this.preferences,
      emailVerified: emailVerified ?? this.emailVerified,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      coreValues: coreValues ?? this.coreValues,
      worldview: worldview ?? this.worldview,
      ambition: ambition ?? this.ambition,
    );
  }
}

class UserPreferences {
  final String theme; // 'light', 'dark', 'system'
  final int firstDayOfWeek; // 0 = Sunday, 1 = Monday
  final bool notificationsEnabled;
  final bool reflectionReminderEnabled;
  final int reflectionReminderHour; // 0-23
  final int reflectionReminderMinute; // 0-59

  UserPreferences({
    this.theme = 'system',
    this.firstDayOfWeek = 1,
    this.notificationsEnabled = true,
    this.reflectionReminderEnabled = true,
    this.reflectionReminderHour = 20, // 8:00 PM by default
    this.reflectionReminderMinute = 0,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? 'system',
      firstDayOfWeek: map['firstDayOfWeek'] ?? 1,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      reflectionReminderEnabled: map['reflectionReminderEnabled'] ?? true,
      reflectionReminderHour: map['reflectionReminderHour'] ?? 20,
      reflectionReminderMinute: map['reflectionReminderMinute'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'firstDayOfWeek': firstDayOfWeek,
      'notificationsEnabled': notificationsEnabled,
      'reflectionReminderEnabled': reflectionReminderEnabled,
      'reflectionReminderHour': reflectionReminderHour,
      'reflectionReminderMinute': reflectionReminderMinute,
    };
  }

  UserPreferences copyWith({
    String? theme,
    int? firstDayOfWeek,
    bool? notificationsEnabled,
    bool? reflectionReminderEnabled,
    int? reflectionReminderHour,
    int? reflectionReminderMinute,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reflectionReminderEnabled: reflectionReminderEnabled ?? this.reflectionReminderEnabled,
      reflectionReminderHour: reflectionReminderHour ?? this.reflectionReminderHour,
      reflectionReminderMinute: reflectionReminderMinute ?? this.reflectionReminderMinute,
    );
  }
}
