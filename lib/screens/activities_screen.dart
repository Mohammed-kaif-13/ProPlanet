import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/points_provider.dart';
import '../services/firebase_service.dart';
import '../models/activity_model.dart';
import '../widgets/activity_card.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ActivityCategory? _selectedCategory;

  final List<ActivityCategory> _categories = ActivityCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize activities and sync with Firebase when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activityProvider =
          Provider.of<ActivityProvider>(context, listen: false);
      final pointsProvider =
          Provider.of<PointsProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        // Sync with Firebase
        activityProvider.syncWithFirebase(authProvider.currentUser!.id);
        // Load points from Firebase
        pointsProvider.loadPointsFromFirebase(authProvider.currentUser!.id);
        // Reset activities for new day if needed
        activityProvider.resetActivitiesForNewDay(authProvider.currentUser!.id);
      } else {
        // Fallback to local initialization
        activityProvider.initializeActivities();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Activities'),
        leading: null, // Remove the back arrow
        automaticallyImplyLeading: false, // Prevent automatic back button
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.eco)),
            Tab(text: 'In Progress', icon: Icon(Icons.pending)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableActivitiesTab(),
          _buildInProgressActivitiesTab(),
          _buildCompletedActivitiesTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableActivitiesTab() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final availableActivities = _selectedCategory == null
            ? activityProvider.availableActivities
            : activityProvider.getActivitiesByCategory(_selectedCategory!);

        return Column(
          children: [
            // Category Filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                    );
                  }

                  final category = _categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getCategoryName(category)),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    ),
                  );
                },
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

            // Activities List
            Expanded(
              child: availableActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No activities available',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: availableActivities.length,
                      itemBuilder: (context, index) {
                        final activity = availableActivities[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAvailableActivityCard(activity),
                        );
                      },
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInProgressActivitiesTab() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final inProgressActivities = activityProvider.pendingActivities;

        if (inProgressActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No activities in progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start an activity to see it here!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: const Text('Browse Activities'),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inProgressActivities.length,
          itemBuilder: (context, index) {
            final userActivity = inProgressActivities[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityCard(
                userActivity: userActivity,
                onTap: () => _showActivityDetails(userActivity),
              ),
            );
          },
        ).animate().fadeIn(duration: 600.ms);
      },
    );
  }

  Widget _buildCompletedActivitiesTab() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final completedActivities = activityProvider.completedActivities;

        if (completedActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No completed activities yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete activities to see your achievements!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedActivities.length,
          itemBuilder: (context, index) {
            final userActivity = completedActivities[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityCard(
                userActivity: userActivity,
                onTap: () => _showCompletedActivityDetails(userActivity),
              ),
            );
          },
        ).animate().fadeIn(duration: 600.ms);
      },
    );
  }

  Widget _buildAvailableActivityCard(EcoActivity activity) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showActivityStartDialog(activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Activity Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        activity.category,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        activity.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Activity Title and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              activity.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getCategoryName(activity.category),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getCategoryColor(activity.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Difficulty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        activity.difficulty,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.difficulty.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(activity.difficulty),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                activity.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.points} points',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.amber[700],
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.estimatedTime.inMinutes} min',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }

  void _showActivityStartDialog(EcoActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(activity.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(activity.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.description),
              const SizedBox(height: 16),
              if (activity.instructions.isNotEmpty) ...[
                Text(
                  'Instructions:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(activity.instructions),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text('${activity.points} points'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                      'Estimated: ${activity.estimatedTime.inMinutes} minutes'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: _getCategoryColor(activity.category),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(_getCategoryName(activity.category)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startActivity(activity);
            },
            child: const Text('Start Activity'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(UserActivity userActivity) {
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
                Icon(Icons.play_arrow, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text('Started: '),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(' points'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeActivity(userActivity);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showCompletedActivityDetails(UserActivity userActivity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(userActivity.activity.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userActivity.activity.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text('Started: ${_formatDateTime(userActivity.startTime)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                    'Completed: ${_formatDateTime(userActivity.completedTime!)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('Earned: ${userActivity.activity.points} points'),
              ],
            ),
            if (userActivity.duration.inMinutes > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text('Duration: ${userActivity.duration.inMinutes} minutes'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startActivity(EcoActivity activity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser == null) return;

    try {
      await activityProvider.startActivityWithFirebase(
        activity,
        authProvider.currentUser!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started: '),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                _tabController.animateTo(1); // Switch to In Progress tab
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting activity: ')));
      }
    }
  }

  void _completeActivity(UserActivity userActivity) async {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final pointsProvider = Provider.of<PointsProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser == null) return;

    try {
      await activityProvider.completeActivityWithFirebase(
        userActivity.id,
        authProvider.currentUser!.id,
      );

      // Points are already added in completeActivityWithFirebase
      // Update PointsProvider with the new values from Firebase
      final firebaseService = FirebaseService();
      final userData =
          await firebaseService.getUserData(authProvider.currentUser!.id);
      if (userData != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final dailyPoints = await firebaseService.getDailyPoints(
            authProvider.currentUser!.id, today);

        pointsProvider.updatePointsFromFirebase(
          totalPoints: userData.totalPoints,
          dailyPoints: dailyPoints,
          categoryPoints: userData.categoryPoints,
        );
      }

      // Send achievement notification
      await notificationProvider.sendAchievementNotification(
        '${userActivity.activity.title} Activity Completed!',
        'You earned ${userActivity.activity.points} points for completing ${userActivity.activity.title}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🎉 Completed! +${userActivity.activity.points} points earned!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View All',
              textColor: Colors.white,
              onPressed: () {
                _tabController.animateTo(2); // Switch to Completed tab
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing activity: ')));
      }
    }
  }

  String _getCategoryName(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return 'Transport';
      case ActivityCategory.energy:
        return 'Energy';
      case ActivityCategory.waste:
        return 'Waste';
      case ActivityCategory.water:
        return 'Water';
      case ActivityCategory.food:
        return 'Food';
      case ActivityCategory.shopping:
        return 'Shopping';
      case ActivityCategory.nature:
        return 'Nature';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getCategoryColor(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return Colors.blue;
      case ActivityCategory.energy:
        return Colors.yellow[700]!;
      case ActivityCategory.waste:
        return Colors.green;
      case ActivityCategory.water:
        return Colors.cyan;
      case ActivityCategory.food:
        return Colors.orange;
      case ActivityCategory.shopping:
        return Colors.purple;
      case ActivityCategory.nature:
        return Colors.teal;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
