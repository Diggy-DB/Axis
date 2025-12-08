import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/task_provider.dart';
import 'providers/reflection_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ai_provider.dart';
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
          update: (_, auth, previous) => previous!..updateUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, previous) => previous!..updateUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReflectionProvider>(
          create: (_) => ReflectionProvider(),
          update: (_, auth, previous) => previous!..updateUser(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AIProvider>(
          create: (_) => AIProvider(),
          update: (_, auth, previous) => previous!..updateUser(auth.user?.uid),
        ),
      ],
      child: const AxisApp(),
    ),
  );
}
