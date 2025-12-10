import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_summary.dart';

class DailySummaryRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  DailySummaryRepository({
    FirebaseFirestore? firestore,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _basePath => 'users/$userId/dailySummaries';

  // Get summary for specific date
  Future<DailySummary?> getSummaryForDate(DateTime date) async {
    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final querySnapshot = await _firestore
          .collection(_basePath)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return DailySummary.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('DailySummaryRepository: Error getting summary for date: $e');
      rethrow;
    }
  }

  // Stream of summaries (most recent first)
  Stream<List<DailySummary>> streamRecentSummaries({int limit = 7}) {
    return _firestore
        .collection(_basePath)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
      print('DailySummaryRepository: Error streaming recent summaries: $error');
    }).map((snapshot) => snapshot.docs
            .map((doc) => DailySummary.fromFirestore(doc))
            .toList());
  }

  // Get today's summary
  Future<DailySummary?> getTodaySummary() async {
    final today = DateTime.now();
    return getSummaryForDate(today);
  }

  // Stream today's summary
  Stream<DailySummary?> streamTodaySummary() {
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection(_basePath)
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .snapshots()
        .handleError((error) {
      print('DailySummaryRepository: Error streaming today summary: $error');
    }).map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return DailySummary.fromFirestore(snapshot.docs.first);
    });
  }

  // Get summaries for date range
  Future<List<DailySummary>> getSummariesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final normalizedStart =
          DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEnd =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_basePath)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(normalizedEnd))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DailySummary.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('DailySummaryRepository: Error getting summaries in range: $e');
      rethrow;
    }
  }

  // Note: Create is handled by Cloud Function only
  // Users cannot create/update/delete daily summaries directly
}
