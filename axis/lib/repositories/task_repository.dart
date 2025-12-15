import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskRepository(this.userId);

  /// Get user's tasks collection reference
  CollectionReference<Map<String, dynamic>> get _tasksCollection => _firestore
      .collection('users')
      .doc(userId)
      .collection(AppConstants.tasksCollection);

  // ==================== TASKS CRUD ====================

  /// Stream all tasks
  Stream<List<Task>> streamTasks() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Stream tasks by status
  Stream<List<Task>> streamTasksByStatus(TaskStatus status) {
    return _tasksCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Stream today's tasks (scheduled for today)
  Stream<List<Task>> streamTodayTasks() {
    final today = _normalizeDate(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    return _tasksCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('scheduledDate', isLessThan: Timestamp.fromDate(tomorrow))
        .orderBy('scheduledDate')
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Stream upcoming tasks (scheduled in the future)
  Stream<List<Task>> streamUpcomingTasks() {
    final tomorrow =
        _normalizeDate(DateTime.now()).add(const Duration(days: 1));

    return _tasksCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow))
        .where('status',
            whereIn: [TaskStatus.pending.name, TaskStatus.inProgress.name])
        .orderBy('scheduledDate')
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Stream tasks by date range
  Stream<List<Task>> streamTasksByDateRange(DateTime start, DateTime end) {
    return _tasksCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Stream tasks by domain
  Stream<List<Task>> streamTasksByDomain(LifeDomain domain) {
    return _tasksCollection
        .where('domain', isEqualTo: domain.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Get a single task
  Future<Task?> getTask(String taskId) async {
    final doc = await _tasksCollection.doc(taskId).get();
    if (!doc.exists) return null;
    return Task.fromFirestore(doc);
  }

  /// Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final nextDay = normalizedDate.add(const Duration(days: 1));

    final snapshot = await _tasksCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedDate))
        .where('scheduledDate', isLessThan: Timestamp.fromDate(nextDay))
        .orderBy('scheduledDate')
        .get();

    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  /// Create a new task
  Future<String> createTask(Task task) async {
    debugPrint('TaskRepository: Creating task for user: $userId');
    debugPrint('TaskRepository: Task data: ${task.title}');
    final data = task.toFirestore();
    debugPrint('TaskRepository: Firestore data prepared');
    final docRef = await _tasksCollection.add(data);
    debugPrint('TaskRepository: Task created with ID: ${docRef.id}');
    debugPrint('TaskRepository: Full path: users/$userId/tasks/${docRef.id}');
    return docRef.id;
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toFirestore());
  }

  /// Mark task as completed
  Future<void> completeTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'status': TaskStatus.completed.name,
      'completedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // ==================== ANALYTICS ====================

  /// Get completion statistics for the last N days
  Future<Map<String, dynamic>> getCompletionStats(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _tasksCollection
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final inProgressTasks =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final pendingTasks =
        tasks.where((t) => t.status == TaskStatus.pending).length;

    // Calculate average tasks per day
    final completedByDay = <String, int>{};
    for (final task in tasks.where((t) => t.status == TaskStatus.completed)) {
      if (task.completedAt != null) {
        final dateKey = _formatDate(task.completedAt!);
        completedByDay[dateKey] = (completedByDay[dateKey] ?? 0) + 1;
      }
    }

    final avgPerDay = completedByDay.values.isEmpty
        ? 0.0
        : completedByDay.values.reduce((a, b) => a + b) / completedByDay.length;

    return {
      'totalTasks': totalTasks,
      'completed': completedTasks,
      'inProgress': inProgressTasks,
      'pending': pendingTasks,
      'completionRate': totalTasks > 0 ? completedTasks / totalTasks : 0.0,
      'avgTasksPerDay': avgPerDay,
    };
  }

  /// Get overdue tasks count
  Future<int> getOverdueTasksCount() async {
    final now = DateTime.now();

    final snapshot = await _tasksCollection
        .where('status',
            whereIn: [TaskStatus.pending.name, TaskStatus.inProgress.name])
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .get();

    return snapshot.docs.length;
  }

  // ==================== HELPER METHODS ====================

  /// Normalize date to start of day (00:00:00)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
