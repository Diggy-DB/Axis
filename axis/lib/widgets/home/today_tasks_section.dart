import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../core/constants/app_constants.dart';

class TodayTasksSection extends StatelessWidget {
  const TodayTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.todayTasks.take(5).toList();

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
                      'Today\'s Tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => context.go('/tasks'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (tasks.isEmpty)
                  const Text('No tasks for today')
                else
                  ...tasks.map((task) => _TaskItem(task: task)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.status == TaskStatus.completed,
        onChanged: (value) {
          if (value == true) {
            context.read<TaskProvider>().completeTask(task.id);
          }
        },
      ),
      title: Text(
        task.title,
        style: task.status == TaskStatus.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      trailing: task.domain != null
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.forDomain(task.domain!),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
