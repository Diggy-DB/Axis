import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/reflection_provider.dart';
import '../../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          const _SectionHeader(title: 'Appearance'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeName(themeProvider.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeProvider),
              );
            },
          ),
          const Divider(),

          // Notifications Section
          const _SectionHeader(title: 'Notifications'),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              if (user == null) return const SizedBox.shrink();

              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('All Notifications'),
                    subtitle: const Text('Enable or disable all notifications'),
                    value: user.preferences.notificationsEnabled,
                    onChanged: (value) => _updatePreference(
                      context,
                      user.preferences.copyWith(notificationsEnabled: value),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.edit_note),
                    title: const Text('Reflection Reminders'),
                    subtitle: const Text('Daily reminder to write your reflection'),
                    value: user.preferences.reflectionReminderEnabled,
                    onChanged: user.preferences.notificationsEnabled
                        ? (value) {
                            _updatePreference(
                              context,
                              user.preferences.copyWith(
                                reflectionReminderEnabled: value,
                              ),
                            );
                          }
                        : null,
                  ),
                  if (user.preferences.reflectionReminderEnabled)
                    ListTile(
                      leading: const SizedBox(width: 40),
                      title: const Text('Reminder Time'),
                      subtitle: Text(
                        '${user.preferences.reflectionReminderHour.toString().padLeft(2, '0')}:${user.preferences.reflectionReminderMinute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTimePickerDialog(context, user),
                    ),
                ],
              );
            },
          ),
          const Divider(),

          // Calendar Section
          const _SectionHeader(title: 'Calendar'),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              if (user == null) return const SizedBox.shrink();

              return ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('First Day of Week'),
                subtitle: Text(_getWeekdayName(user.preferences.firstDayOfWeek)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFirstDayOfWeekDialog(context, user),
              );
            },
          ),
          const Divider(),

          // About Section
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy - Coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to terms of service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of Service - Coming soon')),
              );
            },
          ),
          const Divider(),

          // Account Section
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  String _getWeekdayName(int firstDay) {
    switch (firstDay) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 6:
        return 'Saturday';
      default:
        return 'Monday';
    }
  }

  Future<void> _updatePreference(
    BuildContext context,
    UserPreferences newPreferences,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) return;

    try {
      final updatedUser = user.copyWith(preferences: newPreferences);
      await authProvider.updateUserProfile(updatedUser);

      // Update reflection reminder if it changed
      if (newPreferences.reflectionReminderEnabled != 
          user.preferences.reflectionReminderEnabled ||
          newPreferences.reflectionReminderHour != 
          user.preferences.reflectionReminderHour ||
          newPreferences.reflectionReminderMinute != 
          user.preferences.reflectionReminderMinute) {
        if (mounted) {
          final reflectionProvider = context.read<ReflectionProvider>();
          await reflectionProvider.updateReflectionReminderSettings(
            enabled: newPreferences.reflectionReminderEnabled,
            hour: newPreferences.reflectionReminderHour,
            minute: newPreferences.reflectionReminderMinute,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e')),
        );
      }
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFirstDayOfWeekDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('First Day of Week'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('Sunday'),
              value: 0,
              groupValue: user.preferences.firstDayOfWeek,
              onChanged: (value) {
                if (value != null) {
                  _updatePreference(
                    context,
                    user.preferences.copyWith(firstDayOfWeek: value),
                  );
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Monday'),
              value: 1,
              groupValue: user.preferences.firstDayOfWeek,
              onChanged: (value) {
                if (value != null) {
                  _updatePreference(
                    context,
                    user.preferences.copyWith(firstDayOfWeek: value),
                  );
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Saturday'),
              value: 6,
              groupValue: user.preferences.firstDayOfWeek,
              onChanged: (value) {
                if (value != null) {
                  _updatePreference(
                    context,
                    user.preferences.copyWith(firstDayOfWeek: value),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePickerDialog(BuildContext context, UserModel user) async {
    final currentTime = TimeOfDay(
      hour: user.preferences.reflectionReminderHour,
      minute: user.preferences.reflectionReminderMinute,
    );

    final newTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: 'Select Reflection Reminder Time',
    );

    if (newTime != null && mounted) {
      _updatePreference(
        context,
        user.preferences.copyWith(
          reflectionReminderHour: newTime.hour,
          reflectionReminderMinute: newTime.minute,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
