import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

/// Notifications screen displaying user notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    // Simulated notifications - replace with actual data from provider
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _notifications.addAll([
          NotificationItem(
            id: '1',
            title: 'Morning Meditation Complete! 🎉',
            body: 'Great job completing your morning meditation habit.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            type: NotificationType.achievement,
            isRead: false,
          ),
          NotificationItem(
            id: '2',
            title: 'Reminder: Weekly Review',
            body: 'Time for your weekly reflection. Review your progress.',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            type: NotificationType.reminder,
            isRead: false,
          ),
          NotificationItem(
            id: '3',
            title: '7-Day Streak! 🔥',
            body: 'You\'ve maintained your workout habit for 7 days straight!',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            type: NotificationType.achievement,
            isRead: true,
          ),
          NotificationItem(
            id: '4',
            title: 'Task Due Soon',
            body: 'Complete project proposal is due in 2 hours.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            type: NotificationType.taskReminder,
            isRead: true,
          ),
        ]);
        _isLoading = false;
      });
    }
  }

  List<NotificationItem> _getFilteredNotifications(int tabIndex) {
    switch (tabIndex) {
      case 0: // All
        return _notifications;
      case 1: // Unread
        return _notifications.where((n) => !n.isRead).toList();
      case 2: // Achievements
        return _notifications
            .where((n) => n.type == NotificationType.achievement)
            .toList();
      default:
        return _notifications;
    }
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(0),
                _buildNotificationsList(1),
                _buildNotificationsList(2),
              ],
            ),
    );
  }

  Widget _buildNotificationsList(int tabIndex) {
    final notifications = _getFilteredNotifications(tabIndex);

    if (notifications.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () => _markAsRead(notification.id),
        );
      },
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String message;
    IconData icon;

    switch (tabIndex) {
      case 1: // Unread
        message = 'All caught up!\nNo unread notifications';
        icon = Icons.check_circle_outline;
        break;
      case 2: // Achievements
        message = 'Complete habits and tasks\nto earn achievements';
        icon = Icons.emoji_events_outlined;
        break;
      default:
        message =
            'No notifications yet\nWe\'ll notify you of important updates';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Card(
      elevation: isUnread ? 2 : 0,
      color: isUnread ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        side: BorderSide(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(
                  notification.type.icon,
                  color: notification.type.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}

// Models
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum NotificationType {
  achievement,
  reminder,
  taskReminder,
  habitReminder,
  system;

  IconData get icon {
    switch (this) {
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.reminder:
        return Icons.notifications_active;
      case NotificationType.taskReminder:
        return Icons.task_alt;
      case NotificationType.habitReminder:
        return Icons.repeat;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.achievement:
        return const Color(0xFFF59E0B); // Gold
      case NotificationType.reminder:
        return AppColors.primary;
      case NotificationType.taskReminder:
        return AppColors.career;
      case NotificationType.habitReminder:
        return AppColors.health;
      case NotificationType.system:
        return AppColors.textSecondaryLight;
    }
  }
}
