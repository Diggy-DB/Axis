import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;

  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider({required CategoryRepository repository})
      : _repository = repository;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream categories
  Stream<List<models.Category>> streamCategories() {
    return _repository.streamCategories();
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _categories = await _repository.getCategories();
    } catch (e) {
      _error = e.toString();
      debugPrint('CategoryProvider: Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create category
  Future<String?> createCategory(String label, int colorValue) async {
    try {
      final category = models.Category(
        id: '',
        label: label,
        colorValue: colorValue,
        createdAt: DateTime.now(),
      );

      final id = await _repository.createCategory(category);
      await loadCategories(); // Refresh list
      return id;
    } catch (e) {
      _error = e.toString();
      debugPrint('CategoryProvider: Error creating category: $e');
      notifyListeners();
      return null;
    }
  }

  // Update category
  Future<bool> updateCategory(models.Category category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('CategoryProvider: Error updating category: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);
      await loadCategories(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('CategoryProvider: Error deleting category: $e');
      notifyListeners();
      return false;
    }
  }

  // Get category by ID
  models.Category? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }
}
