import 'package:flutter/foundation.dart';
import '../models/recommendation.dart';
import '../services/ai_service.dart';

class AIProvider extends ChangeNotifier {
  AIService? _service;

  AIRecommendation? _todayRecommendation;
  AIRecommendation? _tomorrowRecommendation;
  bool _isLoading = false;
  String? _error;

  AIRecommendation? get todayRecommendation => _todayRecommendation;
  AIRecommendation? get tomorrowRecommendation => _tomorrowRecommendation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateUser(String? userId) {
    if (userId != null) {
      _service = AIService(userId: userId);
      loadTodayRecommendation();
    } else {
      _service = null;
      _todayRecommendation = null;
      _tomorrowRecommendation = null;
      notifyListeners();
    }
  }

  Future<void> loadTodayRecommendation() async {
    if (_service == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _todayRecommendation = await _service!.getNextDayRecommendation(
        targetDate: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recommendation: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTomorrowRecommendation() async {
    if (_service == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _tomorrowRecommendation = await _service!.getNextDayRecommendation(
        targetDate: DateTime.now().add(const Duration(days: 1)),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recommendation: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
