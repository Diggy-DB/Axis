import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/ai_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/home/streaks_section.dart';
import '../../widgets/home/today_tasks_section.dart';
import '../../widgets/home/habits_snapshot_section.dart';
import '../../widgets/home/ai_recommendation_card.dart';
import '../../widgets/home/mini_calendar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Load today's recommendation
    Future.microtask(() {
      context.read<AIProvider>().loadTodayRecommendation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Home'),
            Text(
              _getGreeting(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HabitProvider>().refresh();
          await context.read<AIProvider>().loadTodayRecommendation();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Recommendation Card
              const AIRecommendationCard(),
              const SizedBox(height: AppSpacing.lg),

              // Streaks Section
              const StreaksSection(),
              const SizedBox(height: AppSpacing.lg),

              // Layout adapts based on screen width
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= AppConstants.tabletBreakpoint) {
                    // Two-column layout for tablet/desktop
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TodayTasksSection(),
                              SizedBox(height: AppSpacing.lg),
                              HabitsSnapshotSection(),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(
                          flex: 1,
                          child: MiniCalendarWidget(),
                        ),
                      ],
                    );
                  } else {
                    // Single-column layout for mobile
                    return const Column(
                      children: [
                        TodayTasksSection(),
                        SizedBox(height: AppSpacing.lg),
                        HabitsSnapshotSection(),
                        SizedBox(height: AppSpacing.lg),
                        MiniCalendarWidget(),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
