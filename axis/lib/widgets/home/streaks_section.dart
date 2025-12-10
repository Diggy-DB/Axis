import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../core/constants/app_constants.dart';

class StreaksSection extends StatelessWidget {
  const StreaksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final streaks = habitProvider.streaks.entries
            .where((entry) =>
                entry.value.currentStreak >= AppConstants.minimumStreakDays)
            .toList()
          ..sort(
              (a, b) => b.value.currentStreak.compareTo(a.value.currentStreak));

        if (streaks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: Colors.orange[700]),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Active Streaks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: streaks.take(5).map((entry) {
                    final habit = habitProvider.habits
                        .where((h) => h.id == entry.key)
                        .firstOrNull;
                    if (habit == null) return const SizedBox.shrink();

                    return Chip(
                      avatar: Text(habit.icon),
                      label: Text(
                        '${habit.name}: ${entry.value.currentStreak} days',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppColors.forDomain(habit.domain)
                          .withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
