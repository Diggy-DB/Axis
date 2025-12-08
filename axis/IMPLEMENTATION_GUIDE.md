# Axis - Complete Implementation Guide

## Remaining Flutter Widgets (Patterns to Follow)

### Home Screen Widgets

All home widgets follow this pattern:

```dart
// widgets/home/today_tasks_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                    Text('Today\'s Tasks', 
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.go('/tasks'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (tasks.isEmpty)
                  const Text('No tasks for today'),
                ...tasks.map((task) => ListTile(
                  leading: Checkbox(
                    value: task.status == TaskStatus.completed,
                    onChanged: (value) {
                      if (value == true) {
                        context.read<TaskProvider>().completeTask(task.id);
                      }
                    },
                  ),
                  title: Text(task.title),
                  subtitle: task.domain != null 
                      ? Text(task.domain!.displayName)
                      : null,
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Similarly create:
- `habits_snapshot_section.dart` - Shows today's habit completion status
- `ai_recommendation_card.dart` - Displays AI insights
- `mini_calendar_widget.dart` - Small calendar view with table_calendar package

### Calendar Screen

```dart
// screens/calendar/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              context.read<CalendarProvider>().goToToday();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TableCalendar widget
          Consumer<CalendarProvider>(
            builder: (context, calendarProvider, child) {
              return TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: calendarProvider.focusedMonth,
                selectedDayPredicate: (day) {
                  return isSameDay(calendarProvider.selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  calendarProvider.selectDate(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // Day detail view showing tasks and habits
          Expanded(
            child: _DayDetailView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.task_alt),
            title: const Text('New Task'),
            onTap: () {
              // Navigate to create task
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('New Event'),
            onTap: () {
              // Navigate to create event
            },
          ),
        ],
      ),
    );
  }
}
```

### Tasks Screen

```dart
// screens/tasks/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskStatus _filterStatus = TaskStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterTabs(),
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = _filterStatus == TaskStatus.pending
              ? taskProvider.todayTasks
              : taskProvider.upcomingTasks;

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _TaskCard(task: tasks[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SegmentedButton<TaskStatus>(
      segments: const [
        ButtonSegment(value: TaskStatus.pending, label: Text('Today')),
        ButtonSegment(value: TaskStatus.inProgress, label: Text('In Progress')),
        ButtonSegment(value: TaskStatus.completed, label: Text('Completed')),
      ],
      selected: {_filterStatus},
      onSelectionChanged: (Set<TaskStatus> selection) {
        setState(() {
          _filterStatus = selection.first;
        });
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
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
        subtitle: Text(task.description ?? ''),
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
        onTap: () {
          // Show task details/edit
        },
      ),
    );
  }
}
```

### Habits Screen (6 Domains)

```dart
// screens/habits/habits_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../core/constants/enums.dart';
import '../../models/habit.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: LifeDomain.values.map((domain) {
              final habits = habitProvider.getHabitsByDomain(domain);
              return _DomainSection(
                domain: domain,
                habits: habits,
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateHabitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  final LifeDomain domain;
  final List<Habit> habits;

  const _DomainSection({required this.domain, required this.habits});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ExpansionTile(
        leading: Text(domain.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          domain.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.forDomain(domain),
              ),
        ),
        subtitle: Text(domain.description),
        children: habits.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No habits yet'),
                )
              ]
            : habits.map((habit) => _HabitTile(habit: habit)).toList(),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;

  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final todayLog = habitProvider.getTodayLogForHabit(habit.id);
    final streak = habitProvider.getStreak(habit.id);

    return ListTile(
      leading: Text(habit.icon, style: const TextStyle(fontSize: 24)),
      title: Text(habit.name),
      subtitle: streak != null && streak.currentStreak > 0
          ? Text('🔥 ${streak.currentStreak} day streak')
          : null,
      trailing: IconButton(
        icon: Icon(
          todayLog?.status == HabitLogStatus.completed
              ? Icons.check_circle
              : Icons.circle_outlined,
          color: todayLog?.status == HabitLogStatus.completed
              ? Colors.green
              : null,
        ),
        onPressed: () {
          habitProvider.logHabit(
            habitId: habit.id,
            status: todayLog?.status == HabitLogStatus.completed
                ? HabitLogStatus.skipped
                : HabitLogStatus.completed,
          );
        },
      ),
    );
  }
}
```

### Reflection Screen

```dart
// screens/reflection/reflection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reflection_provider.dart';
import '../../models/reflection.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _textController = TextEditingController();
  final _gratitudeController = TextEditingController();
  final _challengesController = TextEditingController();
  final _winsController = TextEditingController();
  int? _mood;
  int? _energy;

  @override
  void initState() {
    super.initState();
    _loadTodayReflection();
  }

  void _loadTodayReflection() {
    final reflection = context.read<ReflectionProvider>().todayReflection;
    if (reflection != null) {
      _textController.text = reflection.text;
      _gratitudeController.text = reflection.gratitude ?? '';
      _challengesController.text = reflection.challenges ?? '';
      _winsController.text = reflection.wins ?? '';
      _mood = reflection.mood;
      _energy = reflection.energy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reflection'),
        actions: [
          TextButton(
            onPressed: _saveReflection,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMd().format(DateTime.now()),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildMoodSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildEnergySelector(),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _gratitudeController,
              decoration: const InputDecoration(
                labelText: 'What am I grateful for?',
                hintText: 'List 3 things...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _winsController,
              decoration: const InputDecoration(
                labelText: 'What went well today?',
                hintText: 'Celebrate your wins...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _challengesController,
              decoration: const InputDecoration(
                labelText: 'What challenged me?',
                hintText: 'Reflect on difficulties...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Additional thoughts',
                hintText: 'Write freely...',
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How do I feel today?'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: List.generate(10, (index) {
            final value = index + 1;
            return ChoiceChip(
              label: Text('$value'),
              selected: _mood == value,
              onSelected: (selected) {
                setState(() {
                  _mood = selected ? value : null;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEnergySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Energy level?'),
        Slider(
          value: (_energy ?? 5).toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: _energy?.toString(),
          onChanged: (value) {
            setState(() {
              _energy = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveReflection() async {
    final reflection = Reflection(
      id: '',
      date: DateTime.now(),
      text: _textController.text,
      mood: _mood,
      energy: _energy,
      gratitude: _gratitudeController.text,
      challenges: _challengesController.text,
      wins: _winsController.text,
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<ReflectionProvider>()
        .saveReflection(reflection);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reflection saved')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _gratitudeController.dispose();
    _challengesController.dispose();
    _winsController.dispose();
    super.dispose();
  }
}
```

## Firebase Setup

Create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.example.axis',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.example.axis',
  );
}
```

Replace with your actual Firebase configuration from Firebase Console.

## Building the App

```bash
# Get dependencies
flutter pub get

# Run on iOS
flutter run -d ios

# Run on macOS
flutter run -d macos

# Build for release
flutter build ios --release
flutter build macos --release
```

## Next Steps

1. Complete all widget implementations following the patterns above
2. Add form validation and error handling
3. Implement create/edit dialogs for tasks, habits, events
4. Add animations and micro-interactions
5. Implement offline support with Hive
6. Add unit and widget tests
7. Set up CI/CD pipeline
