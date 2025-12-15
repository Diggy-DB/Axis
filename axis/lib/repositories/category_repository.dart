import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  CategoryRepository({
    FirebaseFirestore? firestore,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _basePath => 'users/$userId/categories';

  // Stream all categories
  Stream<List<Category>> streamCategories() {
    return _firestore
        .collection(_basePath)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((error) {
      debugPrint('CategoryRepository: Error streaming categories: $error');
    }).map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  // Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_basePath)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('CategoryRepository: Error getting categories: $e');
      rethrow;
    }
  }

  // Create category
  Future<String> createCategory(Category category) async {
    try {
      final docRef =
          await _firestore.collection(_basePath).add(category.toFirestore());

      debugPrint('CategoryRepository: Category created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('CategoryRepository: Error creating category: $e');
      rethrow;
    }
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    try {
      await _firestore
          .collection(_basePath)
          .doc(category.id)
          .update(category.toFirestore());

      debugPrint('CategoryRepository: Category updated: ${category.id}');
    } catch (e) {
      debugPrint('CategoryRepository: Error updating category: $e');
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_basePath).doc(categoryId).delete();

      debugPrint('CategoryRepository: Category deleted: $categoryId');
    } catch (e) {
      debugPrint('CategoryRepository: Error deleting category: $e');
      rethrow;
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore.collection(_basePath).doc(categoryId).get();

      if (!doc.exists) return null;
      return Category.fromFirestore(doc);
    } catch (e) {
      debugPrint('CategoryRepository: Error getting category: $e');
      return null;
    }
  }
}
