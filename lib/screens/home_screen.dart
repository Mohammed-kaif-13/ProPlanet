import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/food_ordering_provider.dart';
import '../widgets/dashboard_widget.dart';
import '../models/activity_model.dart';
import '../models/notification_model.dart';
import 'profile_screen.dart';
import 'activities_screen.dart';
import 'food/food_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const HomeTab(),
      const ActivitiesTab(),
      const ProfileTab(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [Icons.home, Icons.eco, Icons.person],
        activeIndex: _currentIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.defaultEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: Colors.grey,
        backgroundColor: Colors.white,
        splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
        elevation: 8,
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProPlanet'),
        leading: null, // Remove the back arrow
        automaticallyImplyLeading: false, // Prevent automatic back button
        actions: [
          // Food Ordering Icon with Cart Badge
          Consumer<FoodOrderingProvider>(
            builder: (context, foodProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.restaurant_menu),
                    tooltip: 'Food Ordering',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FoodMenuScreen(),
                        ),
                      );
                    },
                  ),
                  if (foodProvider.cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${foodProvider.cartItemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Notifications Icon
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      _showNotificationsBottomSheet(context);
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<ActivityProvider>(
            context,
            listen: false,
          ).initializeActivities();
        },
        child: const DashboardWidget(),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final notifications = notificationProvider.notifications;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (notifications.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                notificationProvider.markAllAsRead();
                              },
                              child: const Text('Mark all read'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: notification.isRead
                                        ? Colors.grey[300]
                                        : Theme.of(context).primaryColor,
                                    child: Icon(
                                      _getNotificationIcon(notification.type),
                                      color: notification.isRead
                                          ? Colors.grey[600]
                                          : Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(notification.body),
                                  trailing: Text(
                                    _formatNotificationTime(
                                      notification.scheduledTime,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  onTap: () {
                                    notificationProvider.markAsRead(
                                      notification.id,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.milestone:
        return Icons.flag;
      case NotificationType.activityReminder:
        return Icons.alarm;
      case NotificationType.challenge:
        return Icons
            .sports_esports; // Changed from Icons.challenge which doesn't exist
      case NotificationType.social:
        return Icons.people;
      case NotificationType.tips:
        return Icons.lightbulb;
    }
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return 'm ago';
    } else if (difference.inDays < 1) {
      return 'h ago';
    } else {
      return 'd ago';
    }
  }

  void _showActivityDetails(BuildContext context, UserActivity userActivity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userActivity.activity.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userActivity.activity.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(' points'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  userActivity.isCompleted ? Icons.check_circle : Icons.pending,
                  color:
                      userActivity.isCompleted ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  userActivity.isCompleted ? 'Completed' : 'In Progress',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!userActivity.isCompleted)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeActivity(context, userActivity);
              },
              child: const Text('Complete'),
            ),
        ],
      ),
    );
  }

  void _startActivity(BuildContext context, EcoActivity activity) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) return;

    try {
      await activityProvider.startActivity(
        activity,
        userProvider.currentUser!.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started: ${activity.title}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.of(context).pushNamed('/activities');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting activity: $e')));
      }
    }
  }

  void _completeActivity(
    BuildContext context,
    UserActivity userActivity,
  ) async {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    try {
      await activityProvider.completeActivity(userActivity.id);

      // Add points to user
      await userProvider.addPoints(
        userActivity.activity.points,
        userActivity.activity.category.toString().split('.').last,
      );

      // Send achievement notification
      await notificationProvider.sendAchievementNotification(
        'Activity Completed! 🎉',
        'You earned ${userActivity.activity.points} points for completing ${userActivity.activity.title}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed! +${userActivity.activity.points} points'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing activity: $e')),
        );
      }
    }
  }
}

// Placeholder tabs - will be implemented separately
class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ActivitiesScreen();
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
