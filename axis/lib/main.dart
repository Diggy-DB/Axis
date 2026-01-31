import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/task_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/reflection_provider.dart';
import 'providers/daily_summary_provider.dart';
import 'providers/category_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/daily_summary_repository.dart';
import 'repositories/category_repository.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Initialize Hive for local caching
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    debugPrint('Hive initialized successfully');

    // Initialize Notification Service
    debugPrint('Initializing Notification Service...');
    await NotificationService().initialize();
    debugPrint('Notification Service initialized successfully');

    debugPrint('Starting app...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProxyProvider<AuthProvider, HabitProvider>(
            create: (_) => HabitProvider(),
            update: (_, auth, previous) => previous!..updateUser(auth.user?.id),
          ),
          ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
            create: (_) => TaskProvider(),
            update: (_, auth, previous) => previous!..updateUser(auth.user?.id),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ScheduleProvider>(
            create: (_) => ScheduleProvider(),
            update: (_, auth, previous) => previous!..updateUser(auth.user?.id),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ReflectionProvider>(
            create: (_) => ReflectionProvider(),
            update: (_, auth, previous) => previous!..updateUser(auth.user?.id, user: auth.user),
          ),
          ChangeNotifierProxyProvider<AuthProvider, DailySummaryProvider>(
            create: (_) => DailySummaryProvider(
              repository: DailySummaryRepository(userId: ''),
            ),
            update: (_, auth, previous) {
              if (auth.user?.id != null) {
                return DailySummaryProvider(
                  repository: DailySummaryRepository(userId: auth.user!.id),
                );
              }
              return previous ??
                  DailySummaryProvider(
                    repository: DailySummaryRepository(userId: ''),
                  );
            },
          ),
          ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
            create: (_) => CategoryProvider(
              repository: CategoryRepository(userId: ''),
            ),
            update: (_, auth, previous) {
              if (auth.user?.id != null) {
                return CategoryProvider(
                  repository: CategoryRepository(userId: auth.user!.id),
                );
              }
              return previous ??
                  CategoryProvider(
                    repository: CategoryRepository(userId: ''),
                  );
            },
          ),
          ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ],
        child: const AxisApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show a basic error app instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App failed to start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
