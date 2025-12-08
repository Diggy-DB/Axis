import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';

class HabitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  HabitRepository(this.userId);

  /// Get user's habits collection reference
  CollectionReference<Map<String, dynamic>> get _habitsCollection => _firestore
      .collection('users')
      .doc(userId)
      .collection(AppConstants.habitsCollection);

  /// Get habit logs collection reference
  CollectionReference<Map<String, dynamic>> get _habitLogsCollection =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection(AppConstants.habitLogsCollection);

  // ==================== HABITS CRUD ====================

  /// Stream all active (non-archived) habits
  Stream<List<Habit>> streamHabits() {
    return _habitsCollection
        .where('archived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList());
  }

  /// Stream habits by domain
  Stream<List<Habit>> streamHabitsByDomain(LifeDomain domain) {
    return _habitsCollection
        .where('archived', isEqualTo: false)
        .where('domain', isEqualTo: domain.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList());
  }

  /// Get a single habit
  Future<Habit?> getHabit(String habitId) async {
    final doc = await _habitsCollection.doc(habitId).get();
    if (!doc.exists) return null;
    return Habit.fromFirestore(doc);
  }

  /// Create a new habit
  Future<String> createHabit(Habit habit) async {
    final data = habit.toFirestore();
    final docRef = await _habitsCollection.add(data);
    return docRef.id;
  }

  /// Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    await _habitsCollection.doc(habit.id).update(habit.toFirestore());
  }

  /// Archive a habit (soft delete)
  Future<void> archiveHabit(String habitId) async {
    await _habitsCollection.doc(habitId).update({
      'archived': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a habit permanently
  Future<void> deleteHabit(String habitId) async {
    // Delete habit
    await _habitsCollection.doc(habitId).delete();

    // Delete all logs for this habit
    final logsSnapshot =
        await _habitLogsCollection.where('habitId', isEqualTo: habitId).get();

    for (final doc in logsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ==================== HABIT LOGS ====================

  /// Log a habit completion
  Future<void> logHabit({
    required String habitId,
    required DateTime date,
    required HabitLogStatus status,
    String? notes,
  }) async {
    final normalizedDate = _normalizeDate(date);

    // Check if log already exists for this habit on this date
    final existingLog = await _habitLogsCollection
        .where('habitId', isEqualTo: habitId)
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .get();

    final logData = {
      'habitId': habitId,
      'date': Timestamp.fromDate(normalizedDate),
      'status': status.name,
      'notes': notes,
      'completedAt':
          status == HabitLogStatus.completed ? Timestamp.now() : null,
      'createdAt': Timestamp.now(),
    };

    if (existingLog.docs.isNotEmpty) {
      // Update existing log
      await existingLog.docs.first.reference.update(logData);
    } else {
      // Create new log
      await _habitLogsCollection.add(logData);
    }
  }

  /// Get habit logs for a specific date
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final snapshot = await _habitLogsCollection
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .get();

    return snapshot.docs.map((doc) => HabitLog.fromFirestore(doc)).toList();
  }

  /// Get logs for a specific habit
  Future<List<HabitLog>> getLogsForHabit(
    String habitId, {
    int? limitDays,
  }) async {
    Query query = _habitLogsCollection
        .where('habitId', isEqualTo: habitId)
        .orderBy('date', descending: true);

    if (limitDays != null) {
      final startDate = DateTime.now().subtract(Duration(days: limitDays));
      query = query.where('date',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(_normalizeDate(startDate)));
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => HabitLog.fromFirestore(doc)).toList();
  }

  /// Stream today's habit logs
  Stream<List<HabitLog>> streamTodayLogs() {
    final today = _normalizeDate(DateTime.now());
    return _habitLogsCollection
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitLog.fromFirestore(doc)).toList());
  }

  // ==================== STREAK CALCULATION ====================

  /// Calculate current streak for a habit
  Future<HabitStreak> calculateStreak(String habitId) async {
    final logs = await getLogsForHabit(habitId, limitDays: 365);

    if (logs.isEmpty) {
      return HabitStreak(
        habitId: habitId,
        currentStreak: 0,
        longestStreak: 0,
      );
    }

    // Sort logs by date (oldest first)
    logs.sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    DateTime? lastCompletedDate;

    for (final log in logs) {
      if (log.status == HabitLogStatus.completed) {
        if (lastDate == null) {
          tempStreak = 1;
        } else {
          final daysDiff = log.date.difference(lastDate).inDays;
          if (daysDiff == 1) {
            tempStreak++;
          } else {
            tempStreak = 1;
          }
        }

        lastDate = log.date;
        lastCompletedDate = log.date;

        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (log.status == HabitLogStatus.skipped) {
        tempStreak = 0;
        lastDate = log.date;
      }
    }

    // Check if current streak is still valid (last completion was yesterday or today)
    if (lastCompletedDate != null) {
      final today = _normalizeDate(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));

      if (lastCompletedDate.isAtSameMomentAs(today) ||
          lastCompletedDate.isAtSameMomentAs(yesterday)) {
        currentStreak = tempStreak;
      } else {
        currentStreak = 0;
      }
    }

    return HabitStreak(
      habitId: habitId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletedDate: lastCompletedDate,
    );
  }

  /// Calculate completion rate for a habit over the last N days
  Future<double> calculateCompletionRate(String habitId, int days) async {
    final logs = await getLogsForHabit(habitId, limitDays: days);
    if (logs.isEmpty) return 0.0;

    final completedCount =
        logs.where((log) => log.status == HabitLogStatus.completed).length;

    return completedCount / days;
  }

  /// Get all streaks for active habits
  Future<Map<String, HabitStreak>> getAllStreaks() async {
    final habitsSnapshot =
        await _habitsCollection.where('archived', isEqualTo: false).get();

    final streaks = <String, HabitStreak>{};

    for (final doc in habitsSnapshot.docs) {
      final habit = Habit.fromFirestore(doc);
      final streak = await calculateStreak(habit.id);
      streaks[habit.id] = streak;
    }

    return streaks;
  }

  // ==================== HELPER METHODS ====================

  /// Normalize date to start of day (00:00:00)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
