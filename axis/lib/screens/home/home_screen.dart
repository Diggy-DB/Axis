import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/home/streaks_section.dart';
import '../../widgets/home/today_tasks_section.dart';
import '../../widgets/home/habits_snapshot_section.dart';
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'logout') {
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HabitProvider>().refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
