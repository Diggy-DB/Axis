import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/schedule.dart';
import '../../models/category.dart' as models;
import '../../models/task.dart';
import '../../models/habit.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/enums.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  final PageController _pageController = PageController(
    initialPage: DateTime.now().day - 1,
    viewportFraction: 0.15,
  );
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      // Force reload by notifying listeners
      final scheduleProvider =
          Provider.of<ScheduleProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);

      // Providers will automatically refresh via streams
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final now = DateTime.now();

    // Get schedules for selected day - using StreamBuilder for real-time updates
    final allSchedules = scheduleProvider.schedules;
    final schedulesForDay = allSchedules.where((schedule) {
      return schedule.scheduledDate.year == _selectedDay.year &&
          schedule.scheduledDate.month == _selectedDay.month &&
          schedule.scheduledDate.day == _selectedDay.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Also get tasks for selected day (for backward compatibility)
    final allTasks = [
      ...taskProvider.todayTasks,
      ...taskProvider.upcomingTasks
    ];
    final tasksForDay = allTasks.where((task) {
      if (task.scheduledDate == null) return false;
      return task.scheduledDate!.year == _selectedDay.year &&
          task.scheduledDate!.month == _selectedDay.month &&
          task.scheduledDate!.day == _selectedDay.day;
    }).toList()
      ..sort((a, b) {
        if (a.scheduledDate == null || b.scheduledDate == null) return 0;
        return a.scheduledDate!.compareTo(b.scheduledDate!);
      });

    // Get habits scheduled for the selected day (based on weekDays)
    final selectedDayOfWeek = _selectedDay.weekday; // 1=Monday, 7=Sunday
    final habitsForDay = habitProvider.habits.where((habit) {
      return !habit.archived && habit.weekDays.contains(selectedDayOfWeek);
    }).toList()
      ..sort((a, b) {
        if (a.startTime == null || b.startTime == null) return 0;
        return a.startTime!.compareTo(b.startTime!);
      });

    // Combine schedules, tasks, and habits
    final totalItems =
        schedulesForDay.length + tasksForDay.length + habitsForDay.length;

    // Get current month days
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with refresh button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calendar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isRefreshing ? null : _refreshData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              // Mini Calendar Carousel
              SizedBox(
                height: 80,
                child: ListView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final date = DateTime(now.year, now.month, day);
                    final isSelected = _selectedDay.day == day &&
                        _selectedDay.month == now.month &&
                        _selectedDay.year == now.year;
                    final isToday = now.day == day;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = date;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? theme.primaryColor : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday && !isSelected
                              ? Border.all(color: theme.primaryColor, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.toString(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('EEE').format(date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? Colors.white70
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Schedule Today Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Schedule Today',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Hourly Calendar View
              Expanded(
                child: _HourlyCalendarView(
                  schedulesForDay: schedulesForDay,
                  habitsForDay: habitsForDay,
                  tasksForDay: tasksForDay,
                  selectedDay: _selectedDay,
                  onScheduleTap: (schedule) =>
                      _showScheduleDetails(context, schedule),
                  onHabitTap: (habit) => _showHabitDetails(context, habit),
                  onTaskTap: (task) => _showTaskDetails(context, task),
                ),
              ),

              // Set Schedule Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _showAddTaskDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Set schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AddTaskScreen(selectedDay: _selectedDay),
        fullscreenDialog: true,
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            if (task.scheduledDate != null)
              Row(
                children: [
                  const Icon(Icons.event, size: 16),
                  const SizedBox(width: 8),
                  Text(
                      'Deadline: ${DateFormat('MMM d, h:mm a').format(task.scheduledDate!)}'),
                ],
              ),
          ],
        ),
        actions: [
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
                  category: task.category,
                  linkedHabitId: task.linkedHabitId,
                  completedAt: DateTime.now(),
                  createdAt: task.createdAt,
                  updatedAt: DateTime.now(),
                );
                await Provider.of<TaskProvider>(context, listen: false)
                    .updateTask(updatedTask);
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

  void _showHabitDetails(BuildContext context, Habit habit) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final repeatDays =
        habit.weekDays.map((day) => dayNames[day - 1]).join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(habit.icon),
            const SizedBox(width: 8),
            Expanded(child: Text(habit.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(habit.domain.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                habit.domain.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(habit.domain.colorValue),
                ),
              ),
            ),
            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                habit.description,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            if (habit.startTime != null)
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    habit.endTime != null
                        ? '${DateFormat('h:mm a').format(habit.startTime!)} - ${DateFormat('h:mm a').format(habit.endTime!)}'
                        : DateFormat('h:mm a').format(habit.startTime!),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.repeat, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    repeatDays,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetails(BuildContext context, Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          schedule.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedule.description != null) ...[
              Text(schedule.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('h:mm a').format(schedule.startTime)} - ${DateFormat('h:mm a').format(schedule.endTime)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('EEEE, MMM d, y')
                    .format(schedule.scheduledDate)),
              ],
            ),
            if (schedule.category != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.category!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (schedule.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(schedule.location!)),
                ],
              ),
            ],
            if (schedule.recurrence != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.repeat, size: 16),
                  const SizedBox(width: 8),
                  Text(schedule.recurrence!.substring(0, 1).toUpperCase() +
                      schedule.recurrence!.substring(1)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // If it's a recurring schedule, ask which ones to edit
              if (schedule.recurrenceId != null) {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Edit Recurring Schedule'),
                    content:
                        const Text('Which schedules would you like to edit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'this'),
                        child: const Text('Just this schedule'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'future'),
                        child: const Text('This and future schedules'),
                      ),
                    ],
                  ),
                );

                if (choice == 'this' || choice == 'future') {
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => _EditScheduleScreen(
                          schedule: schedule,
                          editMode: choice == 'future' ? 'future' : 'this',
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  }
                }
              } else {
                // Not a recurring schedule, just edit normally
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => _EditScheduleScreen(
                      schedule: schedule,
                      editMode: 'this',
                    ),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () async {
              // If it's a recurring schedule, ask which ones to delete
              if (schedule.recurrenceId != null) {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Recurring Schedule'),
                    content:
                        const Text('Which schedules would you like to delete?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'this'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Just this schedule'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'future'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('This and future schedules'),
                      ),
                    ],
                  ),
                );

                if (choice == 'this' && context.mounted) {
                  await Provider.of<ScheduleProvider>(context, listen: false)
                      .deleteSchedule(schedule.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else if (choice == 'future' && context.mounted) {
                  await Provider.of<ScheduleProvider>(context, listen: false)
                      .deleteScheduleAndFuture(schedule);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              } else {
                // Not a recurring schedule, show normal confirmation
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Schedule'),
                    content: const Text(
                        'Are you sure you want to delete this schedule?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await Provider.of<ScheduleProvider>(context, listen: false)
                      .deleteSchedule(schedule.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _ScheduleTaskCard({
    required this.task,
    required this.onTap,
  });

  Color _getTaskColor(BuildContext context) {
    // Different colors for different tasks like in the design
    final colors = [
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFF6B66FF), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
    ];
    return colors[task.title.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = _getTaskColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: taskColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.scheduledDate != null
                            ? DateFormat('HH.mm').format(task.scheduledDate!)
                            : '00.00',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Hourly Calendar View Widget
class _HourlyCalendarView extends StatefulWidget {
  final List<Schedule> schedulesForDay;
  final List<Habit> habitsForDay;
  final List<Task> tasksForDay;
  final DateTime selectedDay;
  final Function(Schedule) onScheduleTap;
  final Function(Habit) onHabitTap;
  final Function(Task) onTaskTap;

  const _HourlyCalendarView({
    required this.schedulesForDay,
    required this.habitsForDay,
    required this.tasksForDay,
    required this.selectedDay,
    required this.onScheduleTap,
    required this.onHabitTap,
    required this.onTaskTap,
  });

  @override
  State<_HourlyCalendarView> createState() => _HourlyCalendarViewState();
}

class _HourlyCalendarViewState extends State<_HourlyCalendarView> {
  final ScrollController _scrollController = ScrollController();
  static const double hourHeight = 80.0;
  static const double timeColumnWidth = 60.0;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('schedule_categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      if (mounted) {
        setState(() {
          _categories = decoded.map((item) {
            return {
              'label': item['label'] as String,
              'color': Color(item['color'] as int),
            };
          }).toList();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    if (widget.selectedDay.day == now.day &&
        widget.selectedDay.month == now.month &&
        widget.selectedDay.year == now.year) {
      final currentMinutes = now.hour * 60 + now.minute;
      final scrollPosition = (currentMinutes / 60) * hourHeight - 100;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = widget.selectedDay.day == now.day &&
        widget.selectedDay.month == now.month &&
        widget.selectedDay.year == now.year;

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time labels column
              SizedBox(
                width: timeColumnWidth,
                child: Column(
                  children: List.generate(24, (hour) {
                    return SizedBox(
                      height: hourHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          DateFormat('h a').format(DateTime(2000, 1, 1, hour)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Events column
              Expanded(
                child: Stack(
                  children: [
                    // Hour lines
                    Column(
                      children: List.generate(24, (hour) {
                        return Container(
                          height: hourHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // Events positioned by time
                    ..._buildScheduleWidgets(theme),
                    ..._buildHabitWidgets(theme),

                    // Current time indicator (red line)
                    if (isToday) _buildCurrentTimeIndicator(now),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildScheduleWidgets(ThemeData theme) {
    return widget.schedulesForDay.map((schedule) {
      final startMinutes =
          schedule.startTime.hour * 60 + schedule.startTime.minute;
      var endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

      // Handle events that span midnight or have end before start
      if (endMinutes <= startMinutes) {
        endMinutes = startMinutes + 60; // Default to 1 hour duration
      }

      final duration = endMinutes - startMinutes;

      final top = (startMinutes / 60) * hourHeight;
      final height =
          ((duration / 60) * hourHeight).clamp(40.0, double.infinity);

      return Positioned(
        top: top,
        left: 8,
        right: 8,
        child: GestureDetector(
          onTap: () => widget.onScheduleTap(schedule),
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getScheduleCategoryColor(schedule).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getScheduleCategoryColor(schedule),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  schedule.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: height > 40 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 50) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('h:mm a').format(schedule.startTime)} - ${DateFormat('h:mm a').format(schedule.endTime)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildHabitWidgets(ThemeData theme) {
    return widget.habitsForDay
        .where((habit) => habit.startTime != null)
        .map((habit) {
      final startTime = habit.startTime!;
      final endTime = habit.endTime ?? startTime.add(const Duration(hours: 1));

      final startMinutes = startTime.hour * 60 + startTime.minute;
      var endMinutes = endTime.hour * 60 + endTime.minute;

      // Handle habits that span midnight or have end before start
      if (endMinutes <= startMinutes) {
        endMinutes = startMinutes + 60; // Default to 1 hour duration
      }

      final duration = endMinutes - startMinutes;

      final top = (startMinutes / 60) * hourHeight;
      final height =
          ((duration / 60) * hourHeight).clamp(40.0, double.infinity);

      return Positioned(
        top: top,
        left: 8,
        right: 8,
        child: GestureDetector(
          onTap: () => widget.onHabitTap(habit),
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(habit.domain.colorValue).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(habit.domain.colorValue),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (height > 40) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCurrentTimeIndicator(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    final top = (currentMinutes / 60) * hourHeight;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScheduleCategoryColor(Schedule schedule) {
    if (schedule.category != null) {
      try {
        final categoryProvider = context.read<CategoryProvider>();
        final matchingCategory = categoryProvider.categories.firstWhere(
          (cat) => cat.label == schedule.category,
        );
        return Color(matchingCategory.colorValue);
      } catch (e) {
        return const Color(0xFF9E9E9E);
      }
    }
    return const Color(0xFF9E9E9E);
  }

  Color _getTaskCategoryColor(Task task) {
    if (task.category != null) {
      try {
        final categoryProvider = context.read<CategoryProvider>();
        final matchingCategory = categoryProvider.categories.firstWhere(
          (cat) => cat.label == task.category,
        );
        return Color(matchingCategory.colorValue);
      } catch (e) {
        return const Color(0xFF9E9E9E);
      }
    }
    return const Color(0xFF9E9E9E);
  }
}

class _AddTaskScreen extends StatefulWidget {
  final DateTime selectedDay;

  const _AddTaskScreen({required this.selectedDay});

  @override
  State<_AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<_AddTaskScreen> {
  DateTime? _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);
  String _selectedCategory = 'Design';
  String _recurrence = 'none';
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDay;
    // Load categories from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
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

  List<DateTime> _getUpcomingDates() {
    final now = DateTime.now();
    return List.generate(7, (index) => now.add(Duration(days: index)));
  }

  String _formatDate(DateTime date) {
    return DateFormat('d').format(date);
  }

  String _formatWeekday(DateTime date) {
    return DateFormat('EEE').format(date).substring(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getUpcomingDates();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's set the\nschedule easily",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 32),

            // Date Selection
            const Text(
              'Select the date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...dates.take(4).map((date) {
                  final isSelected = _selectedDate?.day == date.day &&
                      _selectedDate?.month == date.month;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        height: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6B66FF)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              _formatWeekday(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Other',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Time Selection
            const Text(
              'Select time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeSelector(
                    time: _startTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (time != null) {
                        setState(() => _startTime = time);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward, size: 20),
                ),
                Expanded(
                  child: _TimeSelector(
                    time: _endTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (time != null) {
                        setState(() => _endTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Schedule Name
            const Text(
              'Schedule Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter schedule name',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCategoryManagement,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...categoryProvider.categories.map((cat) => _CategoryChip(
                          label: cat.label,
                          color: Color(cat.colorValue),
                          isSelected: _selectedCategory == cat.label,
                          onTap: () =>
                              setState(() => _selectedCategory = cat.label),
                        )),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Location
            const Text(
              'Location (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Add location',
                prefixIcon: const Icon(Icons.location_on_outlined),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Recurrence
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _recurrence,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recurrence = value);
                }
              },
            ),

            const SizedBox(height: 32),

            // Note
            const Text(
              'Note',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add details about the task...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedDate == null) return;

                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.user == null) return;

                  final scheduledDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                  );

                  final startDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _startTime.hour,
                    _startTime.minute,
                  );

                  final endDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _endTime.hour,
                    _endTime.minute,
                  );

                  final schedule = Schedule(
                    id: '',
                    userId: authProvider.user!.id,
                    title: _nameController.text.trim().isEmpty
                        ? _selectedCategory
                        : _nameController.text.trim(),
                    description: _noteController.text.trim().isEmpty
                        ? null
                        : _noteController.text.trim(),
                    scheduledDate: scheduledDateTime,
                    startTime: startDateTime,
                    endTime: endDateTime,
                    category: _selectedCategory,
                    location: _locationController.text.trim().isEmpty
                        ? null
                        : _locationController.text.trim(),
                    recurrence: _recurrence == 'none' ? null : _recurrence,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await Provider.of<ScheduleProvider>(context, listen: false)
                      .createSchedule(schedule);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditScheduleScreen extends StatefulWidget {
  final Schedule schedule;
  final String editMode; // 'this' or 'future'

  const _EditScheduleScreen({
    required this.schedule,
    required this.editMode,
  });

  @override
  State<_EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<_EditScheduleScreen> {
  late DateTime? _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _selectedCategory;
  late String _recurrence;
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.schedule.scheduledDate;
    _startTime = TimeOfDay.fromDateTime(widget.schedule.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.schedule.endTime);
    _selectedCategory = widget.schedule.category ?? 'Design';
    _recurrence = widget.schedule.recurrence ?? 'none';
    _nameController = TextEditingController(text: widget.schedule.title);
    _locationController =
        TextEditingController(text: widget.schedule.location ?? '');
    _noteController =
        TextEditingController(text: widget.schedule.description ?? '');
    // Load categories from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
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

  List<DateTime> _getUpcomingDates() {
    final now = DateTime.now();
    return List.generate(7, (index) => now.add(Duration(days: index)));
  }

  String _formatDate(DateTime date) {
    return DateFormat('d').format(date);
  }

  String _formatWeekday(DateTime date) {
    return DateFormat('EEE').format(date).substring(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getUpcomingDates();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text('Edit Schedule', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            const Text(
              'Select the date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...dates.take(4).map((date) {
                  final isSelected = _selectedDate?.day == date.day &&
                      _selectedDate?.month == date.month;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        height: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6B66FF)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              _formatWeekday(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Other',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Time Selection
            const Text(
              'Select time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeSelector(
                    time: _startTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (time != null) {
                        setState(() => _startTime = time);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward, size: 20),
                ),
                Expanded(
                  child: _TimeSelector(
                    time: _endTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (time != null) {
                        setState(() => _endTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Schedule Name
            const Text(
              'Schedule Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter schedule name',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCategoryManagement,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...categoryProvider.categories.map((cat) => _CategoryChip(
                          label: cat.label,
                          color: Color(cat.colorValue),
                          isSelected: _selectedCategory == cat.label,
                          onTap: () =>
                              setState(() => _selectedCategory = cat.label),
                        )),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Location
            const Text(
              'Location (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Add location',
                prefixIcon: const Icon(Icons.location_on_outlined),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Recurrence
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _recurrence,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recurrence = value);
                }
              },
            ),

            const SizedBox(height: 32),

            // Note
            const Text(
              'Note',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add details about the task...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedDate == null) return;

                  final scheduledDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                  );

                  final startDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _startTime.hour,
                    _startTime.minute,
                  );

                  final endDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _endTime.hour,
                    _endTime.minute,
                  );

                  final updatedSchedule = widget.schedule.copyWith(
                    title: _nameController.text.trim().isEmpty
                        ? _selectedCategory
                        : _nameController.text.trim(),
                    description: _noteController.text.trim().isEmpty
                        ? null
                        : _noteController.text.trim(),
                    scheduledDate: scheduledDateTime,
                    startTime: startDateTime,
                    endTime: endDateTime,
                    category: _selectedCategory,
                    location: _locationController.text.trim().isEmpty
                        ? null
                        : _locationController.text.trim(),
                    recurrence: _recurrence == 'none' ? null : _recurrence,
                    updatedAt: DateTime.now(),
                  );

                  final scheduleProvider =
                      Provider.of<ScheduleProvider>(context, listen: false);

                  // Update based on edit mode
                  if (widget.editMode == 'future') {
                    await scheduleProvider
                        .updateScheduleAndFuture(updatedSchedule);
                  } else {
                    await scheduleProvider.updateSchedule(updatedSchedule);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B66FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Update Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            time.format(context),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  final Schedule schedule;
  final VoidCallback? onTap;

  const _ScheduleCard({
    required this.schedule,
    this.onTap,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('schedule_categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      if (mounted) {
        setState(() {
          _categories = decoded
              .map((item) => {
                    'label': item['label'] as String,
                    'color': Color(item['color'] as int),
                  })
              .toList();
        });
      }
    }
  }

  Color _getCategoryColor() {
    if (widget.schedule.category != null) {
      try {
        final categoryProvider = context.read<CategoryProvider>();
        final matchingCategory = categoryProvider.categories.firstWhere(
          (cat) => cat.label == widget.schedule.category,
        );
        return Color(matchingCategory.colorValue);
      } catch (e) {
        return const Color(0xFF9E9E9E);
      }
    }
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getCategoryColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time and Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('h:mm a').format(widget.schedule.startTime)} - ${DateFormat('h:mm a').format(widget.schedule.endTime)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.schedule.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.schedule.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.schedule.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (widget.schedule.category != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            widget.schedule.category!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.schedule.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.schedule.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Category Indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const _HabitCard({
    required this.habit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.domain.colorValue);

    String timeText = '';
    if (habit.startTime != null) {
      timeText = DateFormat('h:mm a').format(habit.startTime!);
      if (habit.endTime != null) {
        timeText += ' - ${DateFormat('h:mm a').format(habit.endTime!)}';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            // Habit Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  habit.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Habit Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (timeText.isNotEmpty)
                    Text(
                      timeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    habit.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    habit.domain.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Habit Category Indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
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
