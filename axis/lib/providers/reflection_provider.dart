import 'package:flutter/foundation.dart';
import '../models/reflection.dart';
import '../repositories/reflection_repository.dart';

class ReflectionProvider extends ChangeNotifier {
  ReflectionRepository? _repository;

  List<Reflection> _reflections = [];
  Reflection? _todayReflection;
  final bool _isLoading = false;
  String? _error;

  List<Reflection> get reflections => _reflections;
  Reflection? get todayReflection => _todayReflection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateUser(String? userId) {
    if (userId != null) {
      _repository = ReflectionRepository(userId);
      _loadReflections();
      _loadTodayReflection();
    } else {
      _repository = null;
      _reflections = [];
      _todayReflection = null;
      notifyListeners();
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
