import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/task.dart';
import '../../models/category.dart' as models;
import '../../core/constants/enums.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refreshTasks() async {
    setState(() => _isRefreshing = true);
    try {
      // Providers will automatically refresh via streams
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showCategoryManagement() {
    final categoryProvider = context.read<CategoryProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryManagementSheet(
        categoryProvider: categoryProvider,
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            onPressed: _showCategoryManagement,
            tooltip: 'Manage Categories',
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshTasks,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTasksView(onRefresh: _refreshTasks),
          _CompletedTasksView(onRefresh: _refreshTasks),
          _AllTasksView(onRefresh: _refreshTasks),
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
    String? selectedCategory;

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
                                      'Deadline Date',
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
                                      'Deadline Time',
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
                        Consumer<CategoryProvider>(
                          builder: (context, categoryProvider, child) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.label, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Category',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButton<String?>(
                                          value: selectedCategory,
                                          isExpanded: true,
                                          underline: const SizedBox(),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              selectedCategory = value;
                                            });
                                          },
                                          items: [
                                            const DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text('No category'),
                                            ),
                                            ...categoryProvider.categories.map(
                                              (category) => DropdownMenuItem<String?>(
                                                value: category.label,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: Color(category.colorValue),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(category.label),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                          category: selectedCategory,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        final success = await Provider.of<TaskProvider>(context,
                                listen: false)
                            .createTask(task);

                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Task created successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to create task. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
  final Future<void> Function() onRefresh;

  const _TodayTasksView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // Get all incomplete tasks
    final allTasks = [...taskProvider.todayTasks, ...taskProvider.upcomingTasks]
        .where((task) => task.status != TaskStatus.completed)
        .toList()
      ..sort((a, b) {
        if (a.scheduledDate == null && b.scheduledDate == null) return 0;
        if (a.scheduledDate == null) return 1;
        if (b.scheduledDate == null) return -1;
        return a.scheduledDate!.compareTo(b.scheduledDate!);
      });

    // Group tasks by date
    final Map<DateTime, List<Task>> tasksByDate = {};
    for (var task in allTasks) {
      if (task.scheduledDate != null) {
        final dateKey = DateTime(
          task.scheduledDate!.year,
          task.scheduledDate!.month,
          task.scheduledDate!.day,
        );
        tasksByDate.putIfAbsent(dateKey, () => []).add(task);
      }
    }

    final sortedDates = tasksByDate.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: sortedDates.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
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
                          'No incomplete tasks',
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
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final tasks = tasksByDate[date]!;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: 24),
                    Text(
                      isToday
                          ? 'Today - ${DateFormat('MMMM d').format(date)}'
                          : DateFormat('EEEE, MMMM d').format(date),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...tasks.map((task) => _TaskCard(task: task)),
                  ],
                );
              },
            ),
    );
  }
}

class _CompletedTasksView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CompletedTasksView({required this.onRefresh});

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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: completedTasks.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
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
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) =>
                  _TaskCard(task: completedTasks[index]),
            ),
    );
  }
}

class _AllTasksView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _AllTasksView({required this.onRefresh});

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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: allTasks.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
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
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allTasks.length,
              itemBuilder: (context, index) => _TaskCard(task: allTasks[index]),
            ),
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
                    category: task.category,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                        if (task.category != null) ...[
                          Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, child) {
                              final category = categoryProvider.categories
                                  .where((cat) => cat.label == task.category)
                                  .firstOrNull;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: category != null
                                      ? Color(category.colorValue).withValues(alpha: 0.2)
                                      : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: category != null
                                            ? Color(category.colorValue)
                                            : Theme.of(context).colorScheme.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.category!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
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
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null) ...[
                Text(
                  task.description!,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],
              if (task.scheduledDate != null)
                _DetailRow(
                  icon: Icons.event,
                  label: 'Deadline',
                  value: DateFormat('MMM d, y \'at\' h:mm a')
                      .format(task.scheduledDate!),
                ),
              if (task.dueDate != null && task.scheduledDate == null)
                _DetailRow(
                  icon: Icons.event,
                  label: 'Deadline',
                  value: DateFormat('MMM d, y').format(task.dueDate!),
                ),
              _DetailRow(
                icon: Icons.flag,
                label: 'Priority',
                value: task.priority.name.toUpperCase(),
              ),
              if (task.category != null)
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    final category = categoryProvider.categories
                        .where((cat) => cat.label == task.category)
                        .firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.label,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).disabledColor,
                                      ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: category != null
                                            ? Color(category.colorValue)
                                            : const Color(0xFF9E9E9E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      task.category!,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                  category: task.category,
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

class _CategoryManagementSheet extends StatefulWidget {
  final CategoryProvider categoryProvider;

  const _CategoryManagementSheet({
    required this.categoryProvider,
  });

  @override
  State<_CategoryManagementSheet> createState() =>
      _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends State<_CategoryManagementSheet> {
  final _addCategoryController = TextEditingController();
  Color _selectedColor = const Color(0xFF6B66FF);

  final List<Color> _availableColors = [
    const Color(0xFFFF6B9D),
    const Color(0xFFFFB84D),
    const Color(0xFF6B66FF),
    const Color(0xFF4CAF50),
    const Color(0xFF00BCD4),
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFFFF5722),
  ];

  @override
  void dispose() {
    _addCategoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_addCategoryController.text.trim().isEmpty) return;

    await widget.categoryProvider.createCategory(
      _addCategoryController.text.trim(),
      _selectedColor.toARGB32(),
    );
    _addCategoryController.clear();
  }

  Future<void> _removeCategory(models.Category category) async {
    await widget.categoryProvider.deleteCategory(category.id);
  }

  void _editCategory(models.Category category) {
    final editController = TextEditingController(text: category.label);
    Color editColor = Color(category.colorValue);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => editColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: editColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                editController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (editController.text.trim().isNotEmpty) {
                  final updatedCategory = models.Category(
                    id: category.id,
                    label: editController.text.trim(),
                    colorValue: editColor.toARGB32(),
                    createdAt: category.createdAt,
                  );
                  await widget.categoryProvider.updateCategory(updatedCategory);
                  editController.dispose();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add New Category
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addCategoryController,
                  decoration: InputDecoration(
                    hintText: 'New category name',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<Color>(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                itemBuilder: (context) => _availableColors
                    .map((color) => PopupMenuItem(
                          value: color,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ))
                    .toList(),
                onSelected: (color) {
                  setState(() => _selectedColor = color);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: const Color(0xFF6B66FF),
                iconSize: 32,
                onPressed: _addCategory,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category List
          const Text(
            'Your Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              final categories = categoryProvider.categories;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(category.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(category.label),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editCategory(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            onPressed: () => _removeCategory(category),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B66FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
