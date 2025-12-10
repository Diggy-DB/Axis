import 'package:flutter/material.dart';
import '../constants/enums.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Purple

  // Domain Colors
  static const Color health = Color(0xFF10B981); // Green
  static const Color wealth = Color(0xFFF59E0B); // Gold
  static const Color relationships = Color(0xFFEC4899); // Pink
  static const Color career = Color(0xFF3B82F6); // Blue
  static const Color growth = Color(0xFF8B5CF6); // Purple
  static const Color spirituality = Color(0xFF6366F1); // Indigo

  // Neutrals (Light Mode)
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Neutrals (Dark Mode)
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// Get color for a life domain
  static Color forDomain(LifeDomain domain) {
    return Color(domain.colorValue);
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

class AppConstants {
  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Navigation
  static const int navigationItemCount = 5;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // API
  static const String aiBackendUrl =
      'https://axis-ai.example.com'; // Replace with actual URL
  static const Duration apiTimeout = Duration(seconds: 30);

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String habitsCollection = 'habits';
  static const String habitLogsCollection = 'habit_logs';
  static const String tasksCollection = 'tasks';
  static const String reflectionsCollection = 'reflections';
  static const String aiRecommendationsCollection = 'ai_recommendations';

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'MMM d, yyyy';
  static const String timeFormat = 'h:mm a';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Streaks
  static const int minimumStreakDays = 3;

  // AI Recommendations
  static const int aiLookbackDays = 14;
  static const int maxRecommendedHabits = 6;
}
