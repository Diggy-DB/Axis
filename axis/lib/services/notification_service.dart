import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    InitializationSettings settings;

    if (Platform.isAndroid) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      settings = const InitializationSettings(android: androidSettings);
    } else if (Platform.isIOS) {
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      settings = const InitializationSettings(iOS: iosSettings);
    } else if (Platform.isMacOS) {
      const macosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      settings = const InitializationSettings(macOS: macosSettings);
    } else {
      // Fallback for other platforms
      settings = const InitializationSettings();
    }

    await _notifications.initialize(settings);

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Request permissions for macOS
    if (Platform.isMacOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    NotificationDetails notificationDetails;

    if (Platform.isAndroid) {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'axis_reminders',
          'Axis Reminders',
          channelDescription: 'Notifications for schedules and habits',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
    } else if (Platform.isIOS) {
      notificationDetails = const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else if (Platform.isMacOS) {
      notificationDetails = const NotificationDetails(
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else {
      notificationDetails = const NotificationDetails();
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Schedule daily morning motivation notification at 8:00 AM
  Future<void> scheduleDailyMorningNotification(String message) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 8, 0); // 8:00 AM

    // If it's already past 8 AM today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: 999999, // Special ID for morning motivation
      title: '☀️ Good Morning!',
      body: message,
      scheduledTime: scheduledTime,
    );
  }

  /// Cancel the daily morning motivation notification
  Future<void> cancelMorningNotification() async {
    await cancelNotification(999999);
  }

  /// Schedule daily reflection reminder notification at 8:00 PM
  Future<void> scheduleDailyReflectionReminder() async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 20, 0); // 8:00 PM

    // If it's already past 8 PM today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: 999998, // Special ID for reflection reminder
      title: '📝 Time to Reflect',
      body: 'How was your day? Take a moment to write your daily reflection.',
      scheduledTime: scheduledTime,
    );
  }

  /// Schedule recurring daily reflection reminder (repeats every day)
  Future<void> scheduleRecurringReflectionReminder({
    int hour = 20, // Default 8:00 PM
    int minute = 0,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If it's already past the scheduled time today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    NotificationDetails notificationDetails;

    if (Platform.isAndroid) {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'axis_reflection_reminders',
          'Reflection Reminders',
          channelDescription: 'Daily reminders to write your reflection',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
    } else if (Platform.isIOS) {
      notificationDetails = const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else if (Platform.isMacOS) {
      notificationDetails = const NotificationDetails(
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else {
      notificationDetails = const NotificationDetails();
    }

    await _notifications.zonedSchedule(
      999998, // Special ID for reflection reminder
      '📝 Time to Reflect',
      'How was your day? Take a moment to write your daily reflection.',
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
    );
  }

  /// Cancel the daily reflection reminder notification
  Future<void> cancelReflectionReminder() async {
    await cancelNotification(999998);
  }
}
