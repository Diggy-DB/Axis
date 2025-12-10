import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  TaskRepository? _repository;

  List<Task> _todayTasks = [];
  List<Task> _upcomingTasks = [];
  final bool _isLoading = false;
  String? _error;

  List<Task> get todayTasks => _todayTasks;
  List<Task> get upcomingTasks => _upcomingTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateUser(String? userId) {
    if (userId != null) {
      _repository = TaskRepository(userId);
      _loadTasks();
    } else {
      _repository = null;
      _todayTasks = [];
      _upcomingTasks = [];
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
  }

  Future<bool> createTask(Task task) async {
    if (_repository == null) return false;
    try {
      await _repository!.createTask(task);
      return true;
    } catch (e) {
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
