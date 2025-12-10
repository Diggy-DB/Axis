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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local caching
  await Hive.initFlutter();

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
          update: (_, auth, previous) => previous!..updateUser(auth.user?.id),
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
}
