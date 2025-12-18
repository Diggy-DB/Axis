import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final String userId;
  late final CollectionReference _schedulesCollection;

  ScheduleRepository(this.userId) {
    _schedulesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('schedules');
  }

  /// Create a new schedule with optional recurrence
  Future<String> createSchedule(Schedule schedule) async {
    try {
      // For recurring schedules, use the base schedule's ID as recurrenceId
      final recurrenceId =
          (schedule.recurrence != null && schedule.recurrence != 'none')
              ? _schedulesCollection.doc().id
              : null;

      final scheduleWithRecurrenceId = schedule.copyWith(
        recurrenceId: recurrenceId,
      );

      final data = scheduleWithRecurrenceId.toFirestore();
      final docRef = await _schedulesCollection.add(data);

      // If schedule has recurrence, create future occurrences
      if (schedule.recurrence != null && schedule.recurrence != 'none') {
        await _createRecurringSchedules(
            scheduleWithRecurrenceId, recurrenceId!);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  /// Create recurring schedules based on recurrence pattern
  Future<void> _createRecurringSchedules(
      Schedule schedule, String recurrenceId) async {
    final recurrence = schedule.recurrence;

    if (recurrence == null || recurrence == 'none') {
      return;
    }

    // Determine number of occurrences based on recurrence type
    int occurrences;
    switch (recurrence) {
      case 'daily':
        occurrences = 30; // 30 days ahead
        break;
      case 'weekly':
        occurrences = 12; // 12 weeks ahead
        break;
      case 'biweekly':
        occurrences = 12; // 12 biweekly periods (24 weeks)
        break;
      case 'monthly':
        occurrences = 12; // 12 months ahead
        break;
      default:
        return;
    }

    for (int i = 1; i <= occurrences; i++) {
      DateTime nextDate;

      switch (recurrence) {
        case 'daily':
          nextDate = schedule.scheduledDate.add(Duration(days: i));
          break;
        case 'weekly':
          nextDate = schedule.scheduledDate.add(Duration(days: i * 7));
          break;
        case 'biweekly':
          nextDate = schedule.scheduledDate.add(Duration(days: i * 14));
          break;
        case 'monthly':
          final originalDate = schedule.scheduledDate;
          nextDate = DateTime(
            originalDate.year,
            originalDate.month + i,
            originalDate.day,
          );
          break;
        default:
          return;
      }

      // Calculate new start and end times
      final duration = schedule.endTime.difference(schedule.startTime);
      final newStartTime = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        schedule.startTime.hour,
        schedule.startTime.minute,
      );
      final newEndTime = newStartTime.add(duration);

      // Create recurring schedule instance with same recurrenceId
      final recurringSchedule = Schedule(
        id: '',
        userId: schedule.userId,
        title: schedule.title,
        description: schedule.description,
        scheduledDate: nextDate,
        startTime: newStartTime,
        endTime: newEndTime,
        category: schedule.category,
        location: schedule.location,
        recurrence: recurrence,
        recurrenceId: recurrenceId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _schedulesCollection.add(recurringSchedule.toFirestore());
    }
  }

  /// Update an existing schedule
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _schedulesCollection.doc(schedule.id).update(
            schedule.toFirestore(),
          );
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// Update this schedule and all future occurrences in the recurring series
  Future<void> updateScheduleAndFuture(Schedule schedule) async {
    try {
      if (schedule.recurrenceId == null) {
        // If not a recurring schedule, just update this one
        await updateSchedule(schedule);
        return;
      }

      // Get all schedules in this recurrence group that are on or after this date
      final snapshot = await _schedulesCollection
          .where('recurrenceId', isEqualTo: schedule.recurrenceId)
          .where('scheduledDate',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(schedule.scheduledDate))
          .get();

      // Update all matching schedules
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        final existingSchedule = Schedule.fromFirestore(doc);

        // Apply the same time of day from the edited schedule to each future date
        final updatedStartTime = DateTime(
          existingSchedule.scheduledDate.year,
          existingSchedule.scheduledDate.month,
          existingSchedule.scheduledDate.day,
          schedule.startTime.hour,
          schedule.startTime.minute,
        );

        final updatedEndTime = DateTime(
          existingSchedule.scheduledDate.year,
          existingSchedule.scheduledDate.month,
          existingSchedule.scheduledDate.day,
          schedule.endTime.hour,
          schedule.endTime.minute,
        );

        final updatedSchedule = existingSchedule.copyWith(
          title: schedule.title,
          description: schedule.description,
          category: schedule.category,
          location: schedule.location,
          startTime: updatedStartTime,
          endTime: updatedEndTime,
          updatedAt: DateTime.now(),
        );

        batch.update(doc.reference, updatedSchedule.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update schedule series: $e');
    }
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      print('Repository: Deleting schedule document with ID: $scheduleId');
      await _schedulesCollection.doc(scheduleId).delete();
      print('Repository: Successfully deleted schedule document: $scheduleId');
    } catch (e) {
      print('Repository: Error deleting schedule $scheduleId: $e');
      throw Exception('Failed to delete schedule: $e');
    }
  }

  /// Delete this schedule and all future occurrences in the recurring series
  Future<void> deleteScheduleAndFuture(Schedule schedule) async {
    try {
      print('Repository: deleteScheduleAndFuture called for schedule ${schedule.id} with recurrenceId: ${schedule.recurrenceId}');
      
      if (schedule.recurrenceId == null) {
        // If not a recurring schedule, just delete this one
        print('Repository: Non-recurring schedule, deleting single schedule');
        await deleteSchedule(schedule.id);
        return;
      }

      print('Repository: Querying for recurring schedules with recurrenceId: ${schedule.recurrenceId}');
      // Get all schedules in this recurrence group that are on or after this date
      final snapshot = await _schedulesCollection
          .where('recurrenceId', isEqualTo: schedule.recurrenceId)
          .where('scheduledDate',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(schedule.scheduledDate))
          .get();

      print('Repository: Found ${snapshot.docs.length} schedules to delete');

      if (snapshot.docs.isEmpty) {
        print('Repository: No schedules found to delete');
        return;
      }

      // Delete all matching schedules
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        print('Repository: Adding schedule ${doc.id} to batch delete');
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Repository: Successfully deleted ${snapshot.docs.length} schedules');
    } catch (e) {
      print('Repository: Error in deleteScheduleAndFuture: $e');
      throw Exception('Failed to delete schedule series: $e');
    }
  }

  /// Get a single schedule by ID
  Future<Schedule?> getSchedule(String scheduleId) async {
    try {
      final doc = await _schedulesCollection.doc(scheduleId).get();
      if (!doc.exists) return null;
      return Schedule.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get schedule: $e');
    }
  }

  /// Stream schedules for a specific date
  Stream<List<Schedule>> streamSchedulesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _schedulesCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final schedules =
          snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
      // Sort by startTime in memory
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      return schedules;
    });
  }

  /// Stream schedules for a date range
  Stream<List<Schedule>> streamSchedulesForRange(DateTime start, DateTime end) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _schedulesCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final schedules =
          snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
      // Sort by scheduledDate and startTime in memory
      schedules.sort((a, b) {
        final dateCompare = a.scheduledDate.compareTo(b.scheduledDate);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
      return schedules;
    });
  }

  /// Stream schedules for current month (more efficient than streaming all)
  Stream<List<Schedule>> streamCurrentMonthSchedules() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _schedulesCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('scheduledDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) {
      final schedules =
          snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
      // Sort by scheduledDate and startTime in memory
      schedules.sort((a, b) {
        final dateCompare = a.scheduledDate.compareTo(b.scheduledDate);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
      return schedules;
    });
  }

  /// Get schedules for a specific date (one-time fetch)
  Future<List<Schedule>> getSchedulesForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _schedulesCollection
          .where('scheduledDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final schedules =
          snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();

      // Sort by startTime in memory
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      return schedules;
    } catch (e) {
      throw Exception('Failed to get schedules for date: $e');
    }
  }

  /// Check and regenerate recurring schedules that are ending soon
  Future<void> checkAndRegenerateRecurringSchedules() async {
    try {
      // Get all schedules with recurrence
      final snapshot = await _schedulesCollection
          .where('recurrence', isNotEqualTo: null)
          .get();

      // Group schedules by recurrenceId
      final Map<String, List<Schedule>> recurrenceGroups = {};
      for (final doc in snapshot.docs) {
        final schedule = Schedule.fromFirestore(doc);
        if (schedule.recurrence != null &&
            schedule.recurrence != 'none' &&
            schedule.recurrenceId != null) {
          recurrenceGroups.putIfAbsent(schedule.recurrenceId!, () => []);
          recurrenceGroups[schedule.recurrenceId!]!.add(schedule);
        }
      }

      // For each recurrence group, check if we need to generate more
      final now = DateTime.now();
      final regenerationThreshold =
          now.add(const Duration(days: 14)); // 2 weeks ahead

      for (final entry in recurrenceGroups.entries) {
        final recurrenceId = entry.key;
        final schedules = entry.value;

        if (schedules.isEmpty) continue;

        // Find the last occurrence
        schedules.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
        final lastSchedule = schedules.first;

        // If the last occurrence is within 2 weeks, generate more
        if (lastSchedule.scheduledDate.isBefore(regenerationThreshold)) {
          await _createRecurringSchedules(lastSchedule, recurrenceId);
        }
      }
    } catch (e) {
      // Don't throw - this is a background operation
    }
  }
}
