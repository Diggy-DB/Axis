import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/reflection_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/reflection.dart';
import '../../models/task.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isGeneratingInsights = false;
  bool _showCalendar = false;

  Future<void> _generateInsights() async {
    setState(() => _isGeneratingInsights = true);

    try {
      // Configure Firebase Functions to use the correct region if needed
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('generateInsightsForUser');

      final result = await callable.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ??
                'AI insights generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // The reflection provider automatically updates via streams
        // No manual refresh needed
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions Error: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');

      if (mounted) {
        String errorMessage = 'Error generating insights';
        if (e.code == 'not-found') {
          errorMessage =
              'No reflection found for yesterday. Please add a reflection first.';
        } else if (e.code == 'unauthenticated') {
          errorMessage = 'Please sign in to generate insights.';
        } else if (e.message != null) {
          errorMessage = 'Error: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reflection'),
        actions: [
          if (_isGeneratingInsights)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate AI Insights',
              onPressed: _generateInsights,
            ),
          IconButton(
            icon: Icon(
                _showCalendar ? Icons.calendar_today : Icons.calendar_month),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
            if (_showCalendar)
              _CalendarView(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                    _showCalendar = false;
                  });
                },
              ),
            _ReflectionContent(selectedDate: _selectedDate),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              onDateChanged(selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(selectedDate),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isToday)
                Text(
                  'Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday(selectedDate)
                ? null
                : () {
                    onDateChanged(selectedDate.add(const Duration(days: 1)));
                  },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _CalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _CalendarView({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reflectionProvider = Provider.of<ReflectionProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime.now(),
          focusedDay: selectedDate,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (selectedDay, focusedDay) {
            if (!selectedDay.isAfter(DateTime.now())) {
              onDateSelected(selectedDay);
            }
          },
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 1,
            markerDecoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              // Show a dot if there's a reflection for this date
              final hasReflection =
                  reflectionProvider.getReflectionForDate(date) != null;
              if (hasReflection) {
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          enabledDayPredicate: (day) {
            // Disable future dates
            return !day.isAfter(DateTime.now());
          },
        ),
      ),
    );
  }
}

class _ReflectionContent extends StatelessWidget {
  final DateTime selectedDate;

  const _ReflectionContent({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final reflectionProvider = Provider.of<ReflectionProvider>(context);
    final reflection = reflectionProvider.getReflectionForDate(selectedDate);

    return Column(
      children: [
        _CompletedTasksSection(
          completedTaskIds: reflection?.completedTaskIds ?? [],
          date: selectedDate,
        ),
        const SizedBox(height: 16),
        _ActualScheduleSection(
          actualSchedule: reflection?.actualSchedule ?? [],
          date: selectedDate,
          onEdit: () => _showScheduleEditor(context, reflection),
        ),
        const SizedBox(height: 16),
        if (reflection != null)
          _ReflectionTextSection(
            reflection: reflection,
            onEdit: () => _showReflectionEditor(context, reflection),
          )
        else
          _EmptyReflectionText(
            selectedDate: selectedDate,
            onCreatePressed: () => _showReflectionEditor(context, null),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showReflectionEditor(BuildContext context, Reflection? reflection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ReflectionEditorScreen(
          date: selectedDate,
          existingReflection: reflection,
        ),
      ),
    );
  }

  void _showScheduleEditor(BuildContext context, Reflection? reflection) async {
    // Create a reflection if it doesn't exist
    if (reflection == null) {
      final newReflection = Reflection(
        id: '',
        date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
        text: '',
        tags: [],
        completedTaskIds: [],
        actualSchedule: [],
        aiPromptForNextDay: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ScheduleEditorScreen(
            date: selectedDate,
            existingReflection: newReflection,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ScheduleEditorScreen(
            date: selectedDate,
            existingReflection: reflection,
          ),
        ),
      );
    }
  }
}

class _EmptyReflectionText extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onCreatePressed;

  const _EmptyReflectionText({
    required this.selectedDate,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.edit_note,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isToday
                  ? 'Add a reflection for today'
                  : 'Add a reflection for this date',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Reflect on your day, mood, and accomplishments',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add, size: 24),
              label: const Text('Write Reflection',
                  style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedTasksSection extends StatefulWidget {
  final List<String> completedTaskIds;
  final DateTime date;

  const _CompletedTasksSection({
    required this.completedTaskIds,
    required this.date,
  });

  @override
  State<_CompletedTasksSection> createState() => _CompletedTasksSectionState();
}

class _CompletedTasksSectionState extends State<_CompletedTasksSection> {
  List<Task> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  @override
  void didUpdateWidget(_CompletedTasksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadCompletedTasks();
    }
  }

  Future<void> _loadCompletedTasks() async {
    setState(() => _isLoading = true);

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      // Get ALL tasks and filter by completedAt date
      final allTasks = taskProvider.allTasks;

      // Filter to only tasks completed on this specific date
      final completedTasks = allTasks.where((task) {
        if (task.status != TaskStatus.completed) return false;
        if (task.completedAt == null) return false;
        final completedDate = task.completedAt!;
        return completedDate.year == widget.date.year &&
            completedDate.month == widget.date.month &&
            completedDate.day == widget.date.day;
      }).toList();

      setState(() {
        _completedTasks = completedTasks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading completed tasks: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Completed Tasks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Completed Tasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_completedTasks.isEmpty)
              Text(
                'No tasks completed on this day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              )
            else
              ..._completedTasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check,
                            size: 20, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Text(
              '${_completedTasks.length} task${_completedTasks.length == 1 ? '' : 's'} completed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActualScheduleSection extends StatelessWidget {
  final List<ActualScheduleEntry> actualSchedule;
  final DateTime date;
  final VoidCallback onEdit;

  const _ActualScheduleSection({
    required this.actualSchedule,
    required this.date,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'What I Actually Did',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (actualSchedule.isEmpty)
              Column(
                children: [
                  Text(
                    'Track what you actually did during the day with time ranges.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time Entry'),
                  ),
                ],
              )
            else
              _HourlyScheduleView(entries: actualSchedule),
          ],
        ),
      ),
    );
  }
}

class _HourlyScheduleView extends StatelessWidget {
  final List<ActualScheduleEntry> entries;

  const _HourlyScheduleView({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedEntries = List<ActualScheduleEntry>.from(entries)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      children: sortedEntries.map((entry) {
        final duration = entry.endTime.difference(entry.startTime);
        final hours = duration.inMinutes / 60;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(
                '${DateFormat('HH:mm').format(entry.startTime)} - ${DateFormat('HH:mm').format(entry.endTime)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.activity,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                '${hours.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReflectionTextSection extends StatelessWidget {
  final Reflection reflection;
  final VoidCallback onEdit;

  const _ReflectionTextSection({
    required this.reflection,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reflection',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reflection.mood != null || reflection.energy != null)
              Row(
                children: [
                  if (reflection.mood != null) ...[
                    const Icon(Icons.mood, size: 20),
                    const SizedBox(width: 4),
                    Text('${reflection.mood}/10'),
                    const SizedBox(width: 16),
                  ],
                  if (reflection.energy != null) ...[
                    const Icon(Icons.battery_charging_full, size: 20),
                    const SizedBox(width: 4),
                    Text('${reflection.energy}/10'),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            Text(
              reflection.text,
              style: theme.textTheme.bodyLarge,
            ),
            if (reflection.gratitude != null) ...[
              const SizedBox(height: 16),
              Text(
                'Gratitude',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(reflection.gratitude!),
            ],
            if (reflection.wins != null) ...[
              const SizedBox(height: 16),
              Text(
                'Wins',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(reflection.wins!),
            ],
            if (reflection.challenges != null) ...[
              const SizedBox(height: 16),
              Text(
                'Challenges',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(reflection.challenges!),
            ],
            if (reflection.aiPromptForNextDay != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'AI Prompt for Tomorrow',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reflection.aiPromptForNextDay!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReflectionEditorScreen extends StatefulWidget {
  final DateTime date;
  final Reflection? existingReflection;

  const _ReflectionEditorScreen({
    required this.date,
    this.existingReflection,
  });

  @override
  State<_ReflectionEditorScreen> createState() =>
      _ReflectionEditorScreenState();
}

class _ReflectionEditorScreenState extends State<_ReflectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late TextEditingController _gratitudeController;
  late TextEditingController _winsController;
  late TextEditingController _challengesController;
  double _mood = 5.0;
  double _energy = 5.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.existingReflection?.text ?? '');
    _gratitudeController =
        TextEditingController(text: widget.existingReflection?.gratitude ?? '');
    _winsController =
        TextEditingController(text: widget.existingReflection?.wins ?? '');
    _challengesController = TextEditingController(
        text: widget.existingReflection?.challenges ?? '');
    _mood = widget.existingReflection?.mood?.toDouble() ?? 5.0;
    _energy = widget.existingReflection?.energy?.toDouble() ?? 5.0;
  }

  @override
  void dispose() {
    _textController.dispose();
    _gratitudeController.dispose();
    _winsController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final reflectionProvider = context.read<ReflectionProvider>();

      if (widget.existingReflection != null) {
        // Update existing
        final updated = widget.existingReflection!.copyWith(
          text: _textController.text,
          mood: _mood.round(),
          energy: _energy.round(),
          gratitude: _gratitudeController.text.isNotEmpty
              ? _gratitudeController.text
              : null,
          wins: _winsController.text.isNotEmpty ? _winsController.text : null,
          challenges: _challengesController.text.isNotEmpty
              ? _challengesController.text
              : null,
        );
        await reflectionProvider.saveReflection(updated);
      } else {
        // Create new
        final newReflection = Reflection(
          id: '',
          date: DateTime(widget.date.year, widget.date.month, widget.date.day),
          text: _textController.text,
          mood: _mood.round(),
          energy: _energy.round(),
          gratitude: _gratitudeController.text.isNotEmpty
              ? _gratitudeController.text
              : null,
          wins: _winsController.text.isNotEmpty ? _winsController.text : null,
          challenges: _challengesController.text.isNotEmpty
              ? _challengesController.text
              : null,
          tags: [],
          completedTaskIds: [],
          actualSchedule: [],
          aiPromptForNextDay: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await reflectionProvider.saveReflection(newReflection);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reflection: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingReflection != null
            ? 'Edit Reflection'
            : 'New Reflection'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveReflection,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),

            // Main reflection text
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'How was your day?',
                hintText: 'Write about your day...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please write something about your day';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Mood slider
            Text('Mood', style: theme.textTheme.titleSmall),
            Row(
              children: [
                const Text('😢'),
                Expanded(
                  child: Slider(
                    value: _mood,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _mood.round().toString(),
                    onChanged: (value) => setState(() => _mood = value),
                  ),
                ),
                const Text('😊'),
                const SizedBox(width: 8),
                Text(_mood.round().toString(),
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Energy slider
            Text('Energy', style: theme.textTheme.titleSmall),
            Row(
              children: [
                const Text('😴'),
                Expanded(
                  child: Slider(
                    value: _energy,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _energy.round().toString(),
                    onChanged: (value) => setState(() => _energy = value),
                  ),
                ),
                const Text('⚡'),
                const SizedBox(width: 8),
                Text(_energy.round().toString(),
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 24),

            // Gratitude
            TextFormField(
              controller: _gratitudeController,
              decoration: const InputDecoration(
                labelText: 'Gratitude (Optional)',
                hintText: 'What are you grateful for?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Wins
            TextFormField(
              controller: _winsController,
              decoration: const InputDecoration(
                labelText: 'Wins (Optional)',
                hintText: 'What went well today?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Challenges
            TextFormField(
              controller: _challengesController,
              decoration: const InputDecoration(
                labelText: 'Challenges (Optional)',
                hintText: 'What was difficult today?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEditorScreen extends StatefulWidget {
  final DateTime date;
  final Reflection existingReflection;

  const _ScheduleEditorScreen({
    required this.date,
    required this.existingReflection,
  });

  @override
  State<_ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<_ScheduleEditorScreen> {
  late List<ActualScheduleEntry> _entries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.existingReflection.actualSchedule);
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    try {
      final updated = widget.existingReflection.copyWith(
        actualSchedule: _entries,
      );
      await context.read<ReflectionProvider>().saveReflection(updated);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addEntry() async {
    final now = DateTime.now();
    final startTime = DateTime(
        widget.date.year, widget.date.month, widget.date.day, now.hour, 0);
    final endTime = startTime.add(const Duration(hours: 1));

    final result = await showDialog<ActualScheduleEntry>(
      context: context,
      builder: (context) => _ScheduleEntryDialog(
        date: widget.date,
        initialEntry: ActualScheduleEntry(
          activity: '',
          startTime: startTime,
          endTime: endTime,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _entries.add(result);
        _entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
    }
  }

  Future<void> _editEntry(int index) async {
    final result = await showDialog<ActualScheduleEntry>(
      context: context,
      builder: (context) => _ScheduleEntryDialog(
        date: widget.date,
        initialEntry: _entries[index],
      ),
    );

    if (result != null) {
      setState(() {
        _entries[index] = result;
        _entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
    }
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Schedule'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSchedule,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule,
                            size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          'No schedule entries yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add what you did today',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final duration =
                          entry.endTime.difference(entry.startTime);
                      final hours = duration.inMinutes / 60;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.schedule,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(entry.activity),
                          subtitle: Text(
                            '${DateFormat('h:mm a').format(entry.startTime)} - ${DateFormat('h:mm a').format(entry.endTime)} (${hours.toStringAsFixed(1)}h)',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editEntry(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteEntry(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ScheduleEntryDialog extends StatefulWidget {
  final DateTime date;
  final ActualScheduleEntry initialEntry;

  const _ScheduleEntryDialog({
    required this.date,
    required this.initialEntry,
  });

  @override
  State<_ScheduleEntryDialog> createState() => _ScheduleEntryDialogState();
}

class _ScheduleEntryDialogState extends State<_ScheduleEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _activityController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _activityController =
        TextEditingController(text: widget.initialEntry.activity);
    _startTime = TimeOfDay.fromDateTime(widget.initialEntry.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.initialEntry.endTime);
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    Navigator.pop(
      context,
      ActualScheduleEntry(
        activity: _activityController.text,
        startTime: startDateTime,
        endTime: endDateTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Entry'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: 'Activity',
                hintText: 'What did you do?',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an activity';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time),
                    label: Text(_startTime.format(context)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.access_time),
                    label: Text(_endTime.format(context)),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
