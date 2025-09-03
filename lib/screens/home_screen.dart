import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../models/activity_model.dart';
import '../models/notification_model.dart';

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
      const LeaderboardTab(),
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
        icons: const [
          Icons.home,
          Icons.eco,
          Icons.leaderboard,
          Icons.person,
        ],
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
        actions: [
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
                          '',
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
          await Provider.of<ActivityProvider>(context, listen: false)
              .initializeActivities();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.currentUser;
                  if (user == null) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ! ',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'Ready to make a positive impact today?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ).animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Stats Section
              Consumer2<UserProvider, ActivityProvider>(
                builder: (context, userProvider, activityProvider, child) {
                  final user = userProvider.currentUser;
                  if (user == null) return const SizedBox();

                  return Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Total Points',
                          value: '',
                          icon: Icons.star,
                          color: Colors.amber,
                        ).animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Level',
                          value: '',
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ).animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Streak',
                          value: '',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ).animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 700.ms, duration: 600.ms),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      title: 'Start Activity',
                      icon: FontAwesomeIcons.play,
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).pushNamed('/activities');
                      },
                    ).animate()
                      .fadeIn(delay: 800.ms, duration: 600.ms)
                      .slideX(begin: -0.2, end: 0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      title: 'View Progress',
                      icon: FontAwesomeIcons.chartLine,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                    ).animate()
                      .fadeIn(delay: 900.ms, duration: 600.ms)
                      .slideX(begin: 0.2, end: 0),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Today's Activities
              Text(
                'Today\'s Activities',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 1000.ms, duration: 600.ms),

              const SizedBox(height: 16),

              Consumer<ActivityProvider>(
                builder: (context, activityProvider, child) {
                  final todayActivities = activityProvider.todayActivities;

                  if (todayActivities.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.eco,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activities today yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your first eco-friendly activity!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/activities');
                              },
                              child: const Text('Browse Activities'),
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 1100.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0);
                  }

                  return Column(
                    children: todayActivities.map((userActivity) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ActivityCard(
                          userActivity: userActivity,
                          onTap: () {
                            _showActivityDetails(context, userActivity);
                          },
                        ),
                      );
                    }).toList(),
                  ).animate()
                    .fadeIn(delay: 1100.ms, duration: 600.ms);
                },
              ),

              const SizedBox(height: 24),

              // Recommended Activities
              Text(
                'Recommended for You',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 1200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              Consumer<ActivityProvider>(
                builder: (context, activityProvider, child) {
                  final recommendedActivities = activityProvider.getRecommendedActivities();

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedActivities.length,
                      itemBuilder: (context, index) {
                        final activity = recommendedActivities[index];
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                _startActivity(context, activity);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.icon,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      activity.title,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ' points',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      activity.description,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate()
                    .fadeIn(delay: 1300.ms, duration: 600.ms);
                },
              ),

              const SizedBox(height: 100), // Bottom padding for navigation bar
            ],
          ),
        ),
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
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
                                    _formatNotificationTime(notification.scheduledTime),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  onTap: () {
                                    notificationProvider.markAsRead(notification.id);
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
        return Icons.sports_esports; // Changed from Icons.challenge which doesn't exist
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
                  color: userActivity.isCompleted ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(userActivity.isCompleted ? 'Completed' : 'In Progress'),
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
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    if (userProvider.currentUser == null) return;

    try {
      await activityProvider.startActivity(activity, userProvider.currentUser!.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started: '),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting activity: ')),
        );
      }
    }
  }

  void _completeActivity(BuildContext context, UserActivity userActivity) async {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    try {
      await activityProvider.completeActivity(userActivity.id);
      
      // Add points to user
      await userProvider.addPoints(
        userActivity.activity.points,
        userActivity.activity.category.toString().split('.').last,
      );
      
      // Send achievement notification
      await notificationProvider.sendAchievementNotification(
        ' Activity Completed!',
        'You earned  points for completing ',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed! + points'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing activity: ')),
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
    return const Scaffold(
      body: Center(child: Text('Activities Tab - Coming Soon!')),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Leaderboard Tab - Coming Soon!')),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Tab - Coming Soon!')),
    );
  }
}
