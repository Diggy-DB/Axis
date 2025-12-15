import 'package:flutter/foundation.dart';
import '../models/daily_summary.dart';
import '../repositories/daily_summary_repository.dart';

class DailySummaryProvider extends ChangeNotifier {
  final DailySummaryRepository _repository;

  DailySummary? _todaySummary;
  List<DailySummary> _recentSummaries = [];
  bool _isLoading = false;
  String? _error;

  DailySummaryProvider({required DailySummaryRepository repository})
      : _repository = repository;

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

      _recentSummaries =
          await _repository.getSummariesInRange(startDate, endDate);
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
