import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  TaskRepository? _repository;

  List<Task> _todayTasks = [];
  List<Task> _upcomingTasks = [];
  List<Task> _overdueTasks = [];
  final bool _isLoading = false;
  String? _error;

  List<Task> get todayTasks => _todayTasks;
  List<Task> get upcomingTasks => _upcomingTasks;
  List<Task> get overdueTasks => _overdueTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final allTasks = [..._todayTasks, ..._upcomingTasks, ..._overdueTasks];

    return allTasks.where((task) {
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
      _todayTasks = [];
      _upcomingTasks = [];
      _overdueTasks = [];
      notifyListeners();
    }
  }

  void _loadTasks() {
    if (_repository == null) return;

    _repository!.streamTodayTasks().listen((tasks) {
      _todayTasks = tasks;
      notifyListeners();
    });

    _repository!.streamUpcomingTasks().listen((tasks) {
      _upcomingTasks = tasks;
      notifyListeners();
    });

    _repository!.streamOverdueTasks().listen((tasks) {
      _overdueTasks = tasks;
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
