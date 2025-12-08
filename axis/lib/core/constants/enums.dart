/// Life domains for habit categorization
enum LifeDomain {
  health(
      'Health', 'Mental, emotional, spiritual, and physical well-being', '💚'),
  wealth('Wealth', 'Financial stability, security, and money mindset', '💰'),
  relationships('Relationships',
      'Connections with self, partners, family, and friends', '💖'),
  career('Career', 'Job, purpose in life, and personal contribution', '💼'),
  growth('Growth', 'Hobbies, learning, leisure, and self-improvement', '🌱'),
  spirituality(
      'Spirituality', 'Purpose, community, higher power, and impact', '✨');

  final String displayName;
  final String description;
  final String emoji;

  const LifeDomain(this.displayName, this.description, this.emoji);
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
enum TimeOfDay {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  anytime('Anytime');

  final String displayName;
  const TimeOfDay(this.displayName);
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
