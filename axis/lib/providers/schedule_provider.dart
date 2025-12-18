import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/schedule.dart';
import '../repositories/schedule_repository.dart';

class ScheduleProvider with ChangeNotifier {
  ScheduleRepository? _repository;

  List<Schedule> _schedules = [];
  List<Schedule> _todaySchedules = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<Schedule>>? _schedulesSubscription;
  StreamSubscription<List<Schedule>>? _todaySchedulesSubscription;

  List<Schedule> get schedules => _schedules;
  List<Schedule> get todaySchedules => _todaySchedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateUser(String? userId) {
    // Cancel existing subscriptions
    _schedulesSubscription?.cancel();
    _todaySchedulesSubscription?.cancel();

    if (userId == null) {
      _repository = null;
      _schedules = [];
      _todaySchedules = [];
      notifyListeners();
      return;
    }

    _repository = ScheduleRepository(userId);
    _loadSchedules();
  }

  void _loadSchedules() {
    if (_repository == null) return;

    _isLoading = true;
    notifyListeners();

    // Check and regenerate recurring schedules in the background
    _repository!.checkAndRegenerateRecurringSchedules();

    // Stream current month schedules (more efficient)
    _schedulesSubscription = _repository!.streamCurrentMonthSchedules().listen(
      (schedules) {
        _schedules = schedules;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    // Stream today's schedules
    final today = DateTime.now();
    _todaySchedulesSubscription =
        _repository!.streamSchedulesForDate(today).listen(
      (schedules) {
        _todaySchedules = schedules;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<String> createSchedule(Schedule schedule) async {
    if (_repository == null) {
      throw Exception('User not authenticated');
    }

    try {
      _error = null;
      final scheduleId = await _repository!.createSchedule(schedule);

      // The stream listener will automatically update the list
      return scheduleId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    if (_repository == null) {
      throw Exception('User not authenticated');
    }

    try {
      _error = null;
      await _repository!.updateSchedule(schedule);

      // The stream listener will automatically update the list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateScheduleAndFuture(Schedule schedule) async {
    if (_repository == null) {
      throw Exception('User not authenticated');
    }

    try {
      _error = null;
      await _repository!.updateScheduleAndFuture(schedule);

      // The stream listener will automatically update the list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    print('deleteSchedule called with ID: $scheduleId');
    print('_repository is null: ${_repository == null}');
    
    if (_repository == null) {
      print('Repository is null - user not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      _error = null;
      print('Deleting schedule with ID: $scheduleId');

      await _repository!.deleteSchedule(scheduleId);
      print('Schedule deleted successfully: $scheduleId');
      // The stream listener will automatically update the list
    } catch (e) {
      print('Error deleting schedule $scheduleId: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteScheduleAndFuture(Schedule schedule) async {
    if (_repository == null) {
      throw Exception('User not authenticated');
    }

    try {
      _error = null;
      print('Deleting schedule and future occurrences: ${schedule.id}, recurrenceId: ${schedule.recurrenceId}');

      await _repository!.deleteScheduleAndFuture(schedule);
      print('Schedule series deleted successfully: ${schedule.id}');
      // The stream listener will automatically update the list
    } catch (e) {
      print('Error deleting schedule series ${schedule.id}: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Schedule>> getSchedulesForDate(DateTime date) async {
    if (_repository == null) {
      throw Exception('User not authenticated');
    }

    try {
      return await _repository!.getSchedulesForDate(date);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Stream<List<Schedule>> streamSchedulesForDate(DateTime date) {
    if (_repository == null) {
      return Stream.value([]);
    }
    return _repository!.streamSchedulesForDate(date);
  }

  Stream<List<Schedule>> streamSchedulesForRange(DateTime start, DateTime end) {
    if (_repository == null) {
      return Stream.value([]);
    }
    return _repository!.streamSchedulesForRange(start, end);
  }

  @override
  void dispose() {
    _schedulesSubscription?.cancel();
    _todaySchedulesSubscription?.cancel();
    super.dispose();
  }
}
