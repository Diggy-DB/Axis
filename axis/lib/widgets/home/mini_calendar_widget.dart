import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../models/task.dart';

class MiniCalendarWidget extends StatelessWidget {
  const MiniCalendarWidget({super.key});

  bool _hasIncompleteTasks(DateTime day, List<Task> allTasks) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return allTasks.any((task) {
      if (task.status == TaskStatus.completed) return false;
      if (task.scheduledDate == null) return false;
      final taskDate = DateTime(
        task.scheduledDate!.year,
        task.scheduledDate!.month,
        task.scheduledDate!.day,
      );
      return taskDate.isAtSameMomentAs(normalizedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Consumer2<CalendarProvider, TaskProvider>(
              builder: (context, calendarProvider, taskProvider, child) {
                final allTasks = [
                  ...taskProvider.todayTasks,
                  ...taskProvider.upcomingTasks
                ];

                return TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: calendarProvider.focusedMonth,
                  selectedDayPredicate: (day) {
                    return isSameDay(calendarProvider.selectedDate, day);
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (_hasIncompleteTasks(day, allTasks)) {
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    calendarProvider.selectDate(selectedDay);
                    // Navigate to tasks page
                    context.go('/tasks');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
