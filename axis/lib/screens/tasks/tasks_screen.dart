import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../core/constants/enums.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTasksView(),
          _UpcomingTasksView(),
          _CompletedTasksView(),
          _AllTasksView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    TaskPriority priority = TaskPriority.medium;
    int estimatedMinutes = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Task',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 24),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedDate != null
                                          ? DateFormat('MMM d, y')
                                              .format(selectedDate!)
                                          : 'Not set',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 24),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedTime != null
                                          ? selectedTime!.format(context)
                                          : 'Not set',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Priority',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButton<TaskPriority>(
                                      value: priority,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setDialogState(() {
                                            priority = value;
                                          });
                                        }
                                      },
                                      items: [
                                        TaskPriority.low,
                                        TaskPriority.medium,
                                        TaskPriority.high
                                      ]
                                          .map((p) => DropdownMenuItem(
                                                value: p,
                                                child: Text(_priorityName(p)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final result = await showDialog<int>(
                              context: context,
                              builder: (context) => _DurationPicker(
                                initialMinutes: estimatedMinutes,
                              ),
                            );
                            if (result != null) {
                              setDialogState(() {
                                estimatedMinutes = result;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, size: 24),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$estimatedMinutes min',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;

                        DateTime? scheduledDateTime;
                        if (selectedDate != null && selectedTime != null) {
                          scheduledDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );
                        }

                        final task = Task(
                          id: '',
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          scheduledDate: scheduledDateTime,
                          dueDate: selectedDate,
                          status: TaskStatus.pending,
                          priority: priority,
                          estimatedMinutes: estimatedMinutes,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await Provider.of<TaskProvider>(context, listen: false)
                            .createTask(task);

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _priorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

class _TodayTasksView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // Get tasks scheduled for today or tasks from calendar
    final today = DateTime.now();
    final allTasks = [
      ...taskProvider.todayTasks,
      ...taskProvider.upcomingTasks
    ];
    final todayTasks = allTasks.where((task) {
      if (task.status == TaskStatus.completed) return false;
      if (task.scheduledDate != null) {
        return task.scheduledDate!.year == today.year &&
            task.scheduledDate!.month == today.month &&
            task.scheduledDate!.day == today.day;
      }
      return false;
    }).toList()
      ..sort((a, b) {
        if (a.scheduledDate == null || b.scheduledDate == null) return 0;
        return a.scheduledDate!.compareTo(b.scheduledDate!);
      });

    return todayTasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks for today',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add tasks from the calendar or create new ones',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(today),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${todayTasks.length} task${todayTasks.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              ...todayTasks.map((task) => _TaskCard(task: task)),
            ],
          );
  }
}

class _UpcomingTasksView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final today = DateTime.now();
    final allTasks = [
      ...taskProvider.todayTasks,
      ...taskProvider.upcomingTasks
    ];
    final upcomingTasks = allTasks.where((task) {
      if (task.status == TaskStatus.completed) return false;
      if (task.scheduledDate != null) {
        return task.scheduledDate!.isAfter(
          DateTime(today.year, today.month, today.day, 23, 59),
        );
      }
      if (task.dueDate != null) {
        return task.dueDate!.isAfter(
          DateTime(today.year, today.month, today.day, 23, 59),
        );
      }
      return false;
    }).toList()
      ..sort((a, b) {
        final aDate = a.scheduledDate ?? a.dueDate;
        final bDate = b.scheduledDate ?? b.dueDate;
        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
      });

    if (upcomingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingTasks.length,
      itemBuilder: (context, index) => _TaskCard(task: upcomingTasks[index]),
    );
  }
}

class _CompletedTasksView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final allTasks = [
      ...taskProvider.todayTasks,
      ...taskProvider.upcomingTasks
    ];
    final completedTasks =
        allTasks.where((task) => task.status == TaskStatus.completed).toList()
          ..sort((a, b) {
            if (a.completedAt == null || b.completedAt == null) return 0;
            return b.completedAt!.compareTo(a.completedAt!);
          });

    if (completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No completed tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedTasks.length,
      itemBuilder: (context, index) => _TaskCard(task: completedTasks[index]),
    );
  }
}

class _AllTasksView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final allTasks = [...taskProvider.todayTasks, ...taskProvider.upcomingTasks]
      ..sort((a, b) {
        // Sort by status first (pending before completed)
        if (a.status != b.status) {
          return a.status == TaskStatus.completed ? 1 : -1;
        }
        // Then by scheduled date or due date
        final aDate = a.scheduledDate ?? a.dueDate ?? a.createdAt;
        final bDate = b.scheduledDate ?? b.dueDate ?? b.createdAt;
        return aDate.compareTo(bDate);
      });

    if (allTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first task',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allTasks.length,
      itemBuilder: (context, index) => _TaskCard(task: allTasks[index]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completed;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(context, task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: (value) {
                  final updatedTask = Task(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    scheduledDate: task.scheduledDate,
                    dueDate: task.dueDate,
                    status: value == true
                        ? TaskStatus.completed
                        : TaskStatus.pending,
                    priority: task.priority,
                    domain: task.domain,
                    linkedHabitId: task.linkedHabitId,
                    estimatedMinutes: task.estimatedMinutes,
                    completedAt: value == true ? DateTime.now() : null,
                    createdAt: task.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  if (value == true) {
                    taskProvider.updateTask(updatedTask);
                  } else {
                    taskProvider.updateTask(updatedTask);
                  }
                },
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? theme.disabledColor : null,
                      ),
                    ),
                    if (task.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (task.scheduledDate != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a')
                                .format(task.scheduledDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ] else if (task.dueDate != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(task.dueDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                        if (task.estimatedMinutes != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.estimatedMinutes} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Priority indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPriorityColor(theme, task.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(ThemeData theme, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.green;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  void _showTaskDetails(BuildContext context, Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null) ...[
                Text(task.description!),
                const SizedBox(height: 16),
              ],
              if (task.scheduledDate != null)
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Scheduled',
                  value: DateFormat('MMM d, y \'at\' h:mm a')
                      .format(task.scheduledDate!),
                ),
              if (task.dueDate != null)
                _DetailRow(
                  icon: Icons.event,
                  label: 'Due date',
                  value: DateFormat('MMM d, y').format(task.dueDate!),
                ),
              if (task.estimatedMinutes != null)
                _DetailRow(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: '${task.estimatedMinutes} minutes',
                ),
              _DetailRow(
                icon: Icons.flag,
                label: 'Priority',
                value: task.priority.name.toUpperCase(),
              ),
              if (task.completedAt != null)
                _DetailRow(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: DateFormat('MMM d, y \'at\' h:mm a')
                      .format(task.completedAt!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await taskProvider.deleteTask(task.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (task.status != TaskStatus.completed)
            FilledButton(
              onPressed: () async {
                final updatedTask = Task(
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  scheduledDate: task.scheduledDate,
                  dueDate: task.dueDate,
                  status: TaskStatus.completed,
                  priority: task.priority,
                  domain: task.domain,
                  linkedHabitId: task.linkedHabitId,
                  estimatedMinutes: task.estimatedMinutes,
                  completedAt: DateTime.now(),
                  createdAt: task.createdAt,
                  updatedAt: DateTime.now(),
                );
                await taskProvider.updateTask(updatedTask);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Complete'),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationPicker extends StatefulWidget {
  final int initialMinutes;

  const _DurationPicker({required this.initialMinutes});

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Duration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              '$_minutes minutes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Slider(
              value: _minutes.toDouble(),
              min: 15,
              max: 240,
              divisions: 15,
              label: '$_minutes min',
              onChanged: (value) {
                setState(() {
                  _minutes = value.toInt();
                });
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _minutes),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
