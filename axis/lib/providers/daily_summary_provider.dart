import 'package:flutter/foundation.dart';
import '../models/daily_summary.dart';
import '../repositories/daily_summary_repository.dart';
import '../services/notification_service.dart';

class DailySummaryProvider extends ChangeNotifier {
  final DailySummaryRepository _repository;
  final NotificationService _notificationService = NotificationService();

  DailySummary? _todaySummary;
  List<DailySummary> _recentSummaries = [];
  bool _isLoading = false;
  String? _error;

  DailySummaryProvider({required DailySummaryRepository repository})
      : _repository = repository {
    // Listen to today's summary and schedule morning notification
    // Only start listening if we have a valid userId
    if (_repository.userId.isNotEmpty) {
      _listenToTodaySummary();
      _scheduleReflectionReminder();
    }
  }

  void _listenToTodaySummary() {
    streamTodaySummary().listen((summary) {
      _todaySummary = summary;
      notifyListeners();

      // Schedule morning notification if we have morning motivation
      if (summary?.morningMotivation != null) {
        _scheduleMorningNotification(summary!.morningMotivation!);
      }
    });
  }

  Future<void> _scheduleMorningNotification(String message) async {
    try {
      await _notificationService.scheduleDailyMorningNotification(message);
      debugPrint('Morning notification scheduled: $message');
    } catch (e) {
      debugPrint('Error scheduling morning notification: $e');
    }
  }

  Future<void> _scheduleReflectionReminder() async {
    try {
      await _notificationService.scheduleRecurringReflectionReminder();
      debugPrint('Reflection reminder scheduled for 8:00 PM daily');
    } catch (e) {
      debugPrint('Error scheduling reflection reminder: $e');
    }
  }

  DailySummary? get todaySummary => _todaySummary;
  List<DailySummary> get recentSummaries => _recentSummaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream today's summary
  Stream<DailySummary?> streamTodaySummary() {
    return _repository.streamTodaySummary();
  }

  // Stream recent summaries
  Stream<List<DailySummary>> streamRecentSummaries({int limit = 7}) {
    return _repository.streamRecentSummaries(limit: limit);
  }

  // Get today's summary
  Future<void> loadTodaySummary() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _todaySummary = await _repository.getTodaySummary();
    } catch (e) {
      _error = e.toString();
      debugPrint('DailySummaryProvider: Error loading today summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get summary for specific date
  Future<DailySummary?> getSummaryForDate(DateTime date) async {
    try {
      return await _repository.getSummaryForDate(date);
    } catch (e) {
      debugPrint('DailySummaryProvider: Error getting summary for date: $e');
      return null;
    }
  }

  // Get summaries for date range
  Future<List<DailySummary>> getSummariesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recentSummaries = await _repository.getSummariesInRange(startDate, endDate);
      return _recentSummaries;
    } catch (e) {
      _error = e.toString();
      debugPrint('DailySummaryProvider: Error getting summaries in range: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
