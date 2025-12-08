import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../repositories/habit_repository.dart';
import '../core/constants/enums.dart';

class HabitProvider extends ChangeNotifier {
  HabitRepository? _repository;

  List<Habit> _habits = [];
  List<HabitLog> _todayLogs = [];
  Map<String, HabitStreak> _streaks = {};
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => _habits;
  List<HabitLog> get todayLogs => _todayLogs;
  Map<String, HabitStreak> get streaks => _streaks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Update user ID and reinitialize repository
  void updateUser(String? userId) {
    if (userId != null) {
      _repository = HabitRepository(userId);
      _loadHabits();
      _loadTodayLogs();
      _loadStreaks();
    } else {
      _repository = null;
      _habits = [];
      _todayLogs = [];
      _streaks = {};
      notifyListeners();
    }
  }

  /// Load habits from Firestore
  void _loadHabits() {
    if (_repository == null) return;

    _repository!.streamHabits().listen((habits) {
      _habits = habits;
      notifyListeners();
    });
  }

  /// Load today's logs
  void _loadTodayLogs() {
    if (_repository == null) return;

    _repository!.streamTodayLogs().listen((logs) {
      _todayLogs = logs;
      notifyListeners();
    });
  }

  /// Load streaks for all habits
  Future<void> _loadStreaks() async {
    if (_repository == null) return;

    try {
      _streaks = await _repository!.getAllStreaks();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load streaks: $e';
      notifyListeners();
    }
  }

  /// Get habits by domain
  List<Habit> getHabitsByDomain(LifeDomain domain) {
    return _habits.where((habit) => habit.domain == domain).toList();
  }

  /// Get today's log for a habit
  HabitLog? getTodayLogForHabit(String habitId) {
    try {
      return _todayLogs.firstWhere((log) => log.habitId == habitId);
    } catch (e) {
      return null;
    }
  }

  /// Create a new habit
  Future<bool> createHabit(Habit habit) async {
    if (_repository == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _repository!.createHabit(habit);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create habit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a habit
  Future<bool> updateHabit(Habit habit) async {
    if (_repository == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _repository!.updateHabit(habit);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update habit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log habit completion
  Future<bool> logHabit({
    required String habitId,
    required HabitLogStatus status,
    DateTime? date,
    String? notes,
  }) async {
    if (_repository == null) return false;

    try {
      await _repository!.logHabit(
        habitId: habitId,
        date: date ?? DateTime.now(),
        status: status,
        notes: notes,
      );

      // Reload streaks after logging
      await _loadStreaks();

      return true;
    } catch (e) {
      _error = 'Failed to log habit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Archive a habit
  Future<bool> archiveHabit(String habitId) async {
    if (_repository == null) return false;

    try {
      await _repository!.archiveHabit(habitId);
      return true;
    } catch (e) {
      _error = 'Failed to archive habit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a habit
  Future<bool> deleteHabit(String habitId) async {
    if (_repository == null) return false;

    try {
      await _repository!.deleteHabit(habitId);
      return true;
    } catch (e) {
      _error = 'Failed to delete habit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get streak for a habit
  HabitStreak? getStreak(String habitId) {
    return _streaks[habitId];
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _loadStreaks();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
