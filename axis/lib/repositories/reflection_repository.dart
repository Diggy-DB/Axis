import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reflection.dart';
import '../core/constants/app_constants.dart';

class ReflectionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  ReflectionRepository(this.userId);

  /// Get user's reflections collection reference
  CollectionReference<Map<String, dynamic>> get _reflectionsCollection =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection(AppConstants.reflectionsCollection);

  // ==================== REFLECTIONS CRUD ====================

  /// Stream all reflections (most recent first)
  Stream<List<Reflection>> streamReflections({int? limit}) {
    Query<Map<String, dynamic>> query =
        _reflectionsCollection.orderBy('date', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Reflection.fromFirestore(doc)).toList());
  }

  /// Get reflection for a specific date
  Future<Reflection?> getReflectionForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);

    final snapshot = await _reflectionsCollection
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Reflection.fromFirestore(snapshot.docs.first);
  }

  /// Stream reflection for a specific date
  Stream<Reflection?> streamReflectionForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);

    return _reflectionsCollection
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Reflection.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get a single reflection by ID
  Future<Reflection?> getReflection(String reflectionId) async {
    final doc = await _reflectionsCollection.doc(reflectionId).get();
    if (!doc.exists) return null;
    return Reflection.fromFirestore(doc);
  }

  /// Get reflections for a date range
  Future<List<Reflection>> getReflectionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _reflectionsCollection
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_normalizeDate(start)))
        .where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(_normalizeDate(end)))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => Reflection.fromFirestore(doc)).toList();
  }

  /// Create or update reflection for a date
  Future<String> saveReflection(Reflection reflection) async {
    final normalizedDate = _normalizeDate(reflection.date);

    // Check if reflection already exists for this date
    final existingSnapshot = await _reflectionsCollection
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      // Update existing reflection
      final docId = existingSnapshot.docs.first.id;
      await _reflectionsCollection.doc(docId).update(reflection.toFirestore());
      return docId;
    } else {
      // Create new reflection
      final docRef = await _reflectionsCollection.add(reflection.toFirestore());
      return docRef.id;
    }
  }

  /// Delete a reflection
  Future<void> deleteReflection(String reflectionId) async {
    await _reflectionsCollection.doc(reflectionId).delete();
  }

  // ==================== ANALYTICS ====================

  /// Get average mood over the last N days
  Future<double?> getAverageMood(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _reflectionsCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('mood', isNotEqualTo: null)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final reflections = snapshot.docs
        .map((doc) => Reflection.fromFirestore(doc))
        .where((r) => r.mood != null)
        .toList();

    if (reflections.isEmpty) return null;

    final totalMood = reflections.fold<int>(0, (total, r) => total + r.mood!);
    return totalMood / reflections.length;
  }

  /// Get average energy over the last N days
  Future<double?> getAverageEnergy(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _reflectionsCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('energy', isNotEqualTo: null)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final reflections = snapshot.docs
        .map((doc) => Reflection.fromFirestore(doc))
        .where((r) => r.energy != null)
        .toList();

    if (reflections.isEmpty) return null;

    final totalEnergy = reflections.fold<int>(0, (total, r) => total + r.energy!);
    return totalEnergy / reflections.length;
  }

  /// Get reflection count for a date range
  Future<int> getReflectionCount(DateTime start, DateTime end) async {
    final snapshot = await _reflectionsCollection
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_normalizeDate(start)))
        .where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(_normalizeDate(end)))
        .get();

    return snapshot.docs.length;
  }

  /// Get all unique tags used
  Future<List<String>> getAllTags() async {
    final snapshot = await _reflectionsCollection.get();

    final allTags = <String>{};
    for (final doc in snapshot.docs) {
      final reflection = Reflection.fromFirestore(doc);
      allTags.addAll(reflection.tags);
    }

    return allTags.toList()..sort();
  }

  /// Get reflections by tag
  Future<List<Reflection>> getReflectionsByTag(String tag) async {
    final snapshot = await _reflectionsCollection
        .where('tags', arrayContains: tag)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => Reflection.fromFirestore(doc)).toList();
  }

  // ==================== HELPER METHODS ====================

  /// Normalize date to start of day (00:00:00)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
