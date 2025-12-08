import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/task.dart';
import '../models/reflection.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';

class AIService {
  final String baseUrl;
  final String userId;

  AIService({
    required this.userId,
    this.baseUrl = AppConstants.aiBackendUrl,
  });

  /// Get next day recommendation from AI backend
  Future<AIRecommendation> getNextDayRecommendation({
    DateTime? targetDate,
    int lookbackDays = AppConstants.aiLookbackDays,
  }) async {
    final date = targetDate ?? DateTime.now().add(const Duration(days: 1));

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/recommendations/next-day'),
            headers: {
              'Content-Type': 'application/json',
              // Add authentication header if needed
              // 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userId': userId,
              'targetDate': date.toIso8601String(),
              'lookbackDays': lookbackDays,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseRecommendation(data);
      } else {
        throw AIServiceException(
          'Failed to get recommendation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw AIServiceException('Failed to get recommendation: $e');
    }
  }

  /// Parse recommendation from API response
  AIRecommendation _parseRecommendation(Map<String, dynamic> data) {
    // Parse recommended habits
    final habitsData = data['recommendedHabits'] as List<dynamic>;
    final habits = habitsData.map((h) {
      final habitMap = h as Map<String, dynamic>;
      return RecommendedHabit(
        habitId: habitMap['habitId'] ?? '',
        habitName: habitMap['habitName'] ?? '',
        priority: _parsePriority(habitMap['priority']),
        reason: habitMap['reason'] ?? '',
      );
    }).toList();

    // Parse domain balance
    final balanceData = data['domainBalance'] as Map<String, dynamic>;
    final balance = <LifeDomain, double>{};
    for (final domain in LifeDomain.values) {
      balance[domain] = (balanceData[domain.name] ?? 0.5).toDouble();
    }

    return AIRecommendation(
      id: '', // Will be set when saved to Firestore
      dateFor: DateTime.parse(data['dateFor']),
      generatedAt: DateTime.parse(data['generatedAt']),
      recommendedHabits: habits,
      suggestedTaskLimit: data['suggestedTaskLimit'] ?? 4,
      domainBalance: balance,
      insights: List<String>.from(data['insights'] ?? []),
      focusArea: data['focusArea'] != null
          ? LifeDomain.values.firstWhere(
              (d) => d.name == data['focusArea'],
              orElse: () => LifeDomain.health,
            )
          : null,
      confidence: (data['confidence'] ?? 0.5).toDouble(),
    );
  }

  /// Parse priority from string
  RecommendationPriority _parsePriority(String? priority) {
    return RecommendationPriority.values.firstWhere(
      (p) => p.name == priority,
      orElse: () => RecommendationPriority.medium,
    );
  }

  /// Submit user data to AI for analysis (if needed for training)
  Future<void> submitUserData({
    required List<Habit> habits,
    required List<HabitLog> habitLogs,
    required List<Task> tasks,
    required List<Reflection> reflections,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/v1/data/submit'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'habits': habits.map((h) => h.toFirestore()).toList(),
              'habitLogs': habitLogs.map((l) => l.toFirestore()).toList(),
              'tasks': tasks.map((t) => t.toFirestore()).toList(),
              'reflections': reflections.map((r) => r.toFirestore()).toList(),
            }),
          )
          .timeout(AppConstants.apiTimeout);
    } catch (e) {
      // Log error but don't throw - data submission is not critical
      print('Failed to submit user data: $e');
    }
  }

  /// Get AI insights for a specific domain
  Future<List<String>> getDomainInsights(LifeDomain domain) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/insights/domain/${domain.name}?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['insights'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Failed to get domain insights: $e');
      return [];
    }
  }
}

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
