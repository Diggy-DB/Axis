import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import '../../screens/habits/habits_screen.dart';
import '../../screens/reflection/reflection_screen.dart';
import '../../widgets/navigation/main_scaffold.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TasksScreen(),
            ),
          ),
          GoRoute(
            path: '/habits',
            name: 'habits',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HabitsScreen(),
            ),
          ),
          GoRoute(
            path: '/reflection',
            name: 'reflection',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReflectionScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
