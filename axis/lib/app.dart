import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

class AxisApp extends StatefulWidget {
  const AxisApp({super.key});

  @override
  State<AxisApp> createState() => _AxisAppState();
}

class _AxisAppState extends State<AxisApp> {
  late final AppRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();
    _routerDelegate = AppRouterDelegate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final authProvider = context.watch<AuthProvider>();

        // Wait for auth initialization
        if (authProvider.isLoading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final router = _routerDelegate.getRouter(context);

        return MaterialApp.router(
          title: 'Axis',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
