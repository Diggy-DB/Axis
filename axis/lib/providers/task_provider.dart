import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  TaskRepository? _repository;

  List<Task> _allTasks = [];
  final bool _isLoading = false;
  String? _error;

  List<Task> get allTasks => _allTasks;

  // Compatibility getters for existing code
  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _allTasks.where((task) {
      if (task.scheduledDate == null) return false;
      final taskDate = DateTime(
        task.scheduledDate!.year,
        task.scheduledDate!.month,
        task.scheduledDate!.day,
      );
      return taskDate.isAtSameMomentAs(today) ||
          (taskDate.isAfter(today) && taskDate.isBefore(tomorrow));
    }).toList();
  }

  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    return _allTasks.where((task) {
      if (task.scheduledDate == null) return false;
      final taskDate = DateTime(
        task.scheduledDate!.year,
        task.scheduledDate!.month,
        task.scheduledDate!.day,
      );
      return taskDate.isAfter(tomorrow) || taskDate.isAtSameMomentAs(tomorrow);
    }).toList();
  }

  List<Task> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _allTasks.where((task) {
      if (task.scheduledDate == null) return false;
      final taskDate = DateTime(
        task.scheduledDate!.year,
        task.scheduledDate!.month,
        task.scheduledDate!.day,
      );
      return taskDate.isBefore(today);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return _allTasks.where((task) {
      if (task.scheduledDate == null) return false;
      final taskDate = DateTime(
        task.scheduledDate!.year,
        task.scheduledDate!.month,
        task.scheduledDate!.day,
      );
      return taskDate.isAtSameMomentAs(normalizedDate);
    }).toList();
  }

  void updateUser(String? userId) {
    if (userId != null) {
      _repository = TaskRepository(userId);
      _loadTasks();
    } else {
      _repository = null;
      _allTasks = [];
      notifyListeners();
    }
  }

  void _loadTasks() {
    if (_repository == null) return;

    _repository!.streamTasks().listen((tasks) {
      _allTasks = tasks;
      notifyListeners();
    });
  }

  Future<bool> createTask(Task task) async {
    if (_repository == null) {
      debugPrint('TaskProvider: Repository is null - user not authenticated');
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }
    try {
      debugPrint('TaskProvider: Creating task: ${task.title}');
      final taskId = await _repository!.createTask(task);
      debugPrint('TaskProvider: Task created successfully with ID: $taskId');
      return true;
    } catch (e) {
      debugPrint('TaskProvider: Error creating task: $e');
      _error = 'Failed to create task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    if (_repository == null) return false;
    try {
      await _repository!.updateTask(task);
      return true;
    } catch (e) {
      _error = 'Failed to update task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(String taskId) async {
    if (_repository == null) return false;
    try {
      await _repository!.completeTask(taskId);
      return true;
    } catch (e) {
      _error = 'Failed to complete task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    if (_repository == null) return false;
    try {
      await _repository!.deleteTask(taskId);
      return true;
    } catch (e) {
      _error = 'Failed to delete task: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
