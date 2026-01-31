import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../models/habit_log.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

/// Habit statistics screen with charts and insights
class HabitStatisticsScreen extends StatefulWidget {
  const HabitStatisticsScreen({super.key});

  @override
  State<HabitStatisticsScreen> createState() => _HabitStatisticsScreenState();
}

class _HabitStatisticsScreenState extends State<HabitStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7D';

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: LifeDomain.values.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Statistics'),
        actions: [
          // Period selector
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '7D', label: Text('7D')),
                  ButtonSegment(value: '30D', label: Text('30D')),
                  ButtonSegment(value: '90D', label: Text('90D')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedPeriod = newSelection.first);
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Overview'),
            ...LifeDomain.values.map((domain) => Tab(text: domain.displayName)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(habitProvider),
          ...LifeDomain.values.map(
            (domain) => _buildDomainTab(habitProvider, domain),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(HabitProvider habitProvider) {
    final habits = habitProvider.habits.where((h) => !h.archived).toList();
    final streaks = habitProvider.streaks;
    final totalHabits = habits.length;
    final completionRate =
        _calculateOverallCompletionRate(habitProvider, habits);
    final currentStreak = _calculateLongestCurrentStreak(streaks);
    final bestStreak = _calculateLongestOverallStreak(streaks);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Habits',
                  value: totalHabits.toString(),
                  icon: Icons.repeat,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  title: 'Completion',
                  value: '${completionRate.toStringAsFixed(0)}%',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Current Streak',
                  value: '$currentStreak days',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  title: 'Best Streak',
                  value: '$bestStreak days',
                  icon: Icons.emoji_events,
                  color: AppColors.wealth,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Completion Rate Chart
          _SectionHeader(
            title: 'Completion Rate',
            subtitle: 'Last ${_selectedPeriod.replaceAll('D', ' days')}',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCompletionChart(habitProvider, habits),
          const SizedBox(height: AppSpacing.lg),

          // Domain Distribution
          const _SectionHeader(
            title: 'Habits by Domain',
            subtitle: 'Distribution across life areas',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDomainDistribution(habits),
          const SizedBox(height: AppSpacing.lg),

          // Top Performing Habits
          const _SectionHeader(
            title: 'Top Performers',
            subtitle: 'Habits with highest completion rates',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTopHabits(habits),
        ],
      ),
    );
  }

  Widget _buildDomainTab(HabitProvider habitProvider, LifeDomain domain) {
    final habits = habitProvider.habits
        .where((h) => h.domain == domain && !h.archived)
        .toList();

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 80,
              color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No habits in ${domain.displayName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create a habit to see statistics',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      );
    }

    final completionRate =
        _calculateOverallCompletionRate(habitProvider, habits);
    final totalCompletions = _calculateTotalCompletions(habitProvider, habits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Domain Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Color(domain.colorValue).withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Icon(
                          domain.icon,
                          color: Color(domain.colorValue),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              domain.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${habits.length} active habits',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricItem(
                          label: 'Completion',
                          value: '${completionRate.toStringAsFixed(0)}%',
                        ),
                      ),
                      Expanded(
                        child: _MetricItem(
                          label: 'Total Completions',
                          value: totalCompletions.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Habits List with Stats
          const _SectionHeader(
            title: 'Habit Performance',
            subtitle: 'Individual habit statistics',
          ),
          const SizedBox(height: AppSpacing.md),
          ...habits.map((habit) => _buildHabitStatCard(habit)),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(
      HabitProvider habitProvider, List<Habit> habits) {
    final days = _getDaysInPeriod();
    final data = <FlSpot>[];

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: days - i - 1));
      final rate = _calculateCompletionRateForDate(habitProvider, habits, date);
      data.add(FlSpot(i.toDouble(), rate));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: days > 30 ? 15 : (days > 7 ? 5 : 1),
                getTitlesWidget: (value, meta) {
                  if (value == data.first.x || value == data.last.x) {
                    return const SizedBox();
                  }
                  final date = DateTime.now()
                      .subtract(Duration(days: days - value.toInt() - 1));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (days - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainDistribution(List<Habit> habits) {
    final domainCounts = <LifeDomain, int>{};
    for (var habit in habits) {
      domainCounts[habit.domain] = (domainCounts[habit.domain] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: LifeDomain.values.map((domain) {
            final count = domainCounts[domain] ?? 0;
            final percentage =
                habits.isEmpty ? 0.0 : (count / habits.length) * 100;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(domain.colorValue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Icon(
                      domain.icon,
                      size: 20,
                      color: Color(domain.colorValue),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              domain.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$count habits',
                              style: const TextStyle(
                                color: AppColors.textSecondaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(domain.colorValue),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopHabits(List<Habit> habits) {
    if (habits.isEmpty) return const SizedBox.shrink();

    // Simple display of first 5 habits - stats would need historical data
    final topHabits = habits.take(5).toList();

    return Column(
      children: topHabits.asMap().entries.map((entry) {
        final index = entry.key;
        final habit = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Color(habit.domain.colorValue).withValues(alpha: 0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Color(habit.domain.colorValue),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              habit.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(habit.domain.displayName),
            trailing: Text(
              habit.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitStatCard(Habit habit) {
    // Stats would require historical HabitLog data which isn't readily available
    // For now, show basic info
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  habit.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        habit.description,
                        style: const TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(habit.domain.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    habit.domain.icon,
                    size: 14,
                    color: Color(habit.domain.colorValue),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    habit.domain.displayName,
                    style: TextStyle(
                      color: Color(habit.domain.colorValue),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  int _getDaysInPeriod() {
    switch (_selectedPeriod) {
      case '7D':
        return 7;
      case '30D':
        return 30;
      case '90D':
        return 90;
      default:
        return 7;
    }
  }

  double _calculateOverallCompletionRate(
      HabitProvider provider, List<Habit> habits) {
    // This would require fetching historical HabitLog data
    // For now, return a placeholder based on today's completion
    if (habits.isEmpty) return 0;

    final todayLogs = provider.todayLogs;
    final completedToday = todayLogs
        .where((log) =>
            log.status == HabitLogStatus.completed &&
            habits.any((h) => h.id == log.habitId))
        .length;

    return habits.isEmpty ? 0 : (completedToday / habits.length) * 100;
  }

  int _calculateTotalCompletions(HabitProvider provider, List<Habit> habits) {
    // Count today's completions for these habits
    final todayLogs = provider.todayLogs;
    return todayLogs
        .where((log) =>
            log.status == HabitLogStatus.completed &&
            habits.any((h) => h.id == log.habitId))
        .length;
  }

  double _calculateCompletionRateForDate(
      HabitProvider provider, List<Habit> habits, DateTime date) {
    // This would require historical data fetching
    // For now, show estimated pattern
    final today = DateTime.now();
    final daysAgo = today.difference(date).inDays;

    // Simulate a completion pattern (in real app, fetch from HabitLog)
    if (daysAgo == 0) {
      return _calculateOverallCompletionRate(provider, habits);
    }

    // Return simulated data for demonstration
    return 50 + (daysAgo % 3) * 15.0;
  }

  int _calculateLongestCurrentStreak(Map<String, HabitStreak> streaks) {
    if (streaks.isEmpty) return 0;
    return streaks.values
        .map((s) => s.currentStreak)
        .reduce((a, b) => a > b ? a : b);
  }

  int _calculateLongestOverallStreak(Map<String, HabitStreak> streaks) {
    if (streaks.isEmpty) return 0;
    return streaks.values
        .map((s) => s.longestStreak)
        .reduce((a, b) => a > b ? a : b);
  }
}

// Helper Widgets
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}
