import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

class AIRecommendation {
  final String id;
  final DateTime dateFor; // The date this recommendation is for
  final DateTime generatedAt;
  final List<RecommendedHabit> recommendedHabits;
  final int suggestedTaskLimit;
  final Map<LifeDomain, double> domainBalance; // 0.0 to 1.0 scores
  final List<String> insights;
  final LifeDomain? focusArea;
  final double confidence; // 0.0 to 1.0

  AIRecommendation({
    required this.id,
    required this.dateFor,
    required this.generatedAt,
    required this.recommendedHabits,
    required this.suggestedTaskLimit,
    required this.domainBalance,
    required this.insights,
    this.focusArea,
    required this.confidence,
  });

  factory AIRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse recommended habits
    final habitsData = data['recommendedHabits'] as List<dynamic>;
    final habits = habitsData.map((h) {
      final habitMap = h as Map<String, dynamic>;
      return RecommendedHabit(
        habitId: habitMap['habitId'] ?? '',
        habitName: habitMap['habitName'] ?? '',
        priority: RecommendationPriority.values.firstWhere(
          (p) => p.name == habitMap['priority'],
          orElse: () => RecommendationPriority.medium,
        ),
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
      id: doc.id,
      dateFor: (data['dateFor'] as Timestamp).toDate(),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      recommendedHabits: habits,
      suggestedTaskLimit: data['suggestedTaskLimit'] ?? 4,
      domainBalance: balance,
      insights: List<String>.from(data['insights'] ?? []),
      focusArea: data['focusArea'] != null
          ? LifeDomain.values.firstWhere(
              (d) => d.name == data['focusArea'],
              orElse: () => LifeDomain.healthAndEnergy,
            )
          : null,
      confidence: (data['confidence'] ?? 0.5).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dateFor': Timestamp.fromDate(dateFor),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'recommendedHabits': recommendedHabits
          .map((h) => {
                'habitId': h.habitId,
                'habitName': h.habitName,
                'priority': h.priority.name,
                'reason': h.reason,
              })
          .toList(),
      'suggestedTaskLimit': suggestedTaskLimit,
      'domainBalance': domainBalance.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'insights': insights,
      'focusArea': focusArea?.name,
      'confidence': confidence,
    };
  }
}

class RecommendedHabit {
  final String habitId;
  final String habitName;
  final RecommendationPriority priority;
  final String reason;

  RecommendedHabit({
    required this.habitId,
    required this.habitName,
    required this.priority,
    required this.reason,
  });
}
