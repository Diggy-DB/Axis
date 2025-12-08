import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

class HabitsSnapshotSection extends StatelessWidget {
  const HabitsSnapshotSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;
        final todayLogs = habitProvider.todayLogs;

        final completedCount = todayLogs
            .where((log) => log.status == HabitLogStatus.completed)
            .length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Habits',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => context.go('/habits'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: habits.isEmpty ? 0 : completedCount / habits.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$completedCount of ${habits.length} habits completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
