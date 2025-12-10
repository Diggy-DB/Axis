/// Life domains for habit categorization
enum LifeDomain {
  soulAndSpirit(
      'Soul and Spirit', 'Spiritual growth, meditation, and inner peace', '✨', 0xFF9C27B0),
  healthAndEnergy(
      'Health and Energy', 'Physical fitness, nutrition, and vitality', '💚', 0xFF4CAF50),
  familyAndRelationships(
      'Family and Relationships', 'Connections with loved ones and community', '💖', 0xFFE91E63),
  workAndCalling(
      'Work and Calling', 'Career, purpose, and professional growth', '💼', 0xFF2196F3),
  moneyAndWealth(
      'Money and Wealth', 'Financial stability, investments, and abundance', '💰', 0xFFFFC107);

  final String displayName;
  final String description;
  final String emoji;
  final int colorValue;

  const LifeDomain(this.displayName, this.description, this.emoji, this.colorValue);
}

/// Task status
enum TaskStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  final String displayName;
  const TaskStatus(this.displayName);
}

/// Task priority
enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  final String displayName;
  const TaskPriority(this.displayName);
}

/// Habit frequency
enum HabitFrequency {
  daily('Daily'),
  weekly('Weekly'),
  custom('Custom');

  final String displayName;
  const HabitFrequency(this.displayName);
}

/// Time of day for habit scheduling
enum HabitTimeOfDay {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  anytime('Anytime');

  final String displayName;
  const HabitTimeOfDay(this.displayName);
}

/// Habit log status
enum HabitLogStatus {
  completed('Completed'),
  skipped('Skipped'),
  partial('Partial');

  final String displayName;
  const HabitLogStatus(this.displayName);
}

/// Recommendation priority
enum RecommendationPriority {
  critical('Critical'),
  high('High'),
  medium('Medium');

  final String displayName;
  const RecommendationPriority(this.displayName);
}
