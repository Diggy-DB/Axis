import 'package:flutter/foundation.dart';
import '../models/reflection.dart';
import '../models/user.dart';
import '../repositories/reflection_repository.dart';
import '../services/notification_service.dart';

class ReflectionProvider extends ChangeNotifier {
  ReflectionRepository? _repository;
  final NotificationService _notificationService = NotificationService();

  List<Reflection> _reflections = [];
  Reflection? _todayReflection;
  final bool _isLoading = false;
  String? _error;
  UserModel? _currentUser;

  List<Reflection> get reflections => _reflections;
  Reflection? get todayReflection => _todayReflection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get reflection for a specific date
  Reflection? getReflectionForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    try {
      return _reflections.firstWhere(
        (r) {
          final rDate = DateTime(r.date.year, r.date.month, r.date.day);
          return rDate.isAtSameMomentAs(normalizedDate);
        },
      );
    } catch (e) {
      return null;
    }
  }

  void updateUser(String? userId, {UserModel? user}) {
    _currentUser = user;
    if (userId != null) {
      _repository = ReflectionRepository(userId);
      _loadReflections();
      _loadTodayReflection();
      _scheduleReflectionReminderIfEnabled();
    } else {
      _repository = null;
      _reflections = [];
      _todayReflection = null;
      notifyListeners();
    }
  }

  Future<void> _scheduleReflectionReminderIfEnabled() async {
    if (_currentUser == null) return;
    
    try {
      if (_currentUser!.preferences.reflectionReminderEnabled) {
        await _notificationService.scheduleRecurringReflectionReminder(
          hour: _currentUser!.preferences.reflectionReminderHour,
          minute: _currentUser!.preferences.reflectionReminderMinute,
        );
        debugPrint('Reflection reminder scheduled for ${_currentUser!.preferences.reflectionReminderHour}:${_currentUser!.preferences.reflectionReminderMinute.toString().padLeft(2, '0')} daily');
      } else {
        await _notificationService.cancelReflectionReminder();
        debugPrint('Reflection reminder disabled');
      }
    } catch (e) {
      debugPrint('Error scheduling reflection reminder: $e');
    }
  }

  /// Update reflection reminder settings
  Future<void> updateReflectionReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    try {
      if (enabled) {
        await _notificationService.scheduleRecurringReflectionReminder(
          hour: hour,
          minute: minute,
        );
        debugPrint('Reflection reminder updated to $hour:${minute.toString().padLeft(2, '0')} daily');
      } else {
        await _notificationService.cancelReflectionReminder();
        debugPrint('Reflection reminder disabled');
      }
    } catch (e) {
      debugPrint('Error updating reflection reminder: $e');
    }
  }

  void _loadReflections() {
    if (_repository == null) return;
    _repository!.streamReflections(limit: 30).listen((reflections) {
      _reflections = reflections;
      notifyListeners();
    });
  }

  void _loadTodayReflection() {
    if (_repository == null) return;
    _repository!.streamReflectionForDate(DateTime.now()).listen((reflection) {
      _todayReflection = reflection;
      notifyListeners();
    });
  }

  Future<bool> saveReflection(Reflection reflection) async {
    if (_repository == null) return false;
    try {
      await _repository!.saveReflection(reflection);
      return true;
    } catch (e) {
      _error = 'Failed to save reflection: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReflection(String reflectionId) async {
    if (_repository == null) return false;
    try {
      await _repository!.deleteReflection(reflectionId);
      return true;
    } catch (e) {
      _error = 'Failed to delete reflection: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
