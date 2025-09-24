import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/points_provider.dart';
import '../models/activity_model.dart';
import 'stats_card.dart';
import 'activity_card.dart';
import 'quick_action_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _pointsAnimationController;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Initialize activities and sync with Firebase when the dashboard loads
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
    _progressAnimationController.dispose();
    _pointsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, ActivityProvider, NotificationProvider,
        PointsProvider>(
      builder: (
        context,
        authProvider,
        activityProvider,
        notificationProvider,
        pointsProvider,
        child,
      ) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section with Daily Goal
              _buildWelcomeSection(
                user,
                authProvider,
                activityProvider,
                pointsProvider,
              ),

              const SizedBox(height: 24),

              // Progress to Next Level
              _buildLevelProgressSection(user, authProvider, pointsProvider),

              const SizedBox(height: 24),

              // Daily Stats Cards
              _buildDailyStatsSection(user, activityProvider, pointsProvider),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActionsSection(),

              const SizedBox(height: 24),

              // Today's Activities
              _buildTodaysActivitiesSection(activityProvider),

              const SizedBox(height: 24),

              // Recommended Activities
              _buildRecommendedActivitiesSection(activityProvider),

              const SizedBox(height: 24),

              // Environmental Impact
              _buildEnvironmentalImpactSection(user, pointsProvider),

              const SizedBox(height: 100), // Bottom padding for navigation
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(
    user,
    AuthProvider authProvider,
    ActivityProvider activityProvider,
    PointsProvider pointsProvider,
  ) {
    final completedToday =
        activityProvider.todayActivities.where((a) => a.isCompleted).length;
    final dailyGoal = 5; // Daily goal of 5 activities

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_getGreeting()}, ${user.name}! 🌱',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to make a positive impact today?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Daily Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$completedToday/$dailyGoal activities',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completedToday / dailyGoal,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completedToday >= dailyGoal
                        ? Colors.green
                        : Theme.of(context).primaryColor,
                  ),
                  minHeight: 8,
                ),
                if (completedToday >= dailyGoal) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Daily goal completed! 🎉',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLevelProgressSection(
    user,
    AuthProvider authProvider,
    PointsProvider pointsProvider,
  ) {
    final pointsForNextLevel =
        _getPointsForNextLevel(pointsProvider.currentLevel);
    final progress = _calculateLevelProgress(pointsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to Level ${pointsProvider.currentLevel + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${pointsProvider.currentLevel}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1500),
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.7 * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pointsProvider.totalPoints} total points',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${pointsProvider.currentPoints} today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                Text(
                  '${pointsForNextLevel} points to go',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildDailyStatsSection(
    user,
    ActivityProvider activityProvider,
    PointsProvider pointsProvider,
  ) {
    final completedToday =
        activityProvider.todayActivities.where((a) => a.isCompleted).length;
    final streak = activityProvider.getCurrentStreak();

    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Today\'s Points',
            value: '${pointsProvider.currentPoints}',
            icon: Icons.star,
            color: Colors.amber,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            title: 'Activities Done',
            value: '$completedToday',
            icon: Icons.check_circle,
            color: Colors.green,
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            title: 'Streak',
            value: '$streak',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
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
              )
                  .animate()
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
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 600.ms)
                  .slideX(begin: 0.2, end: 0),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                title: 'View Profile',
                icon: FontAwesomeIcons.user,
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms)
                  .slideX(begin: -0.2, end: 0),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                title: 'Daily Challenge',
                icon: FontAwesomeIcons.bullseye,
                color: Colors.purple,
                onTap: () {
                  _showDailyChallenge(context);
                },
              )
                  .animate()
                  .fadeIn(delay: 1100.ms, duration: 600.ms)
                  .slideX(begin: 0.2, end: 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysActivitiesSection(ActivityProvider activityProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Activities',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/activities');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final todayActivities = activityProvider.todayActivities;

            if (todayActivities.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.eco, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No activities today yet',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your first eco-friendly activity!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[500]),
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
              );
            }

            return Column(
              children: todayActivities.take(3).map((userActivity) {
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedActivitiesSection(ActivityProvider activityProvider) {
    // Get a simple, static list of recommended activities to avoid performance issues
    final recommendedActivities = _getStaticRecommendedActivities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedActivities.length,
            itemBuilder: (context, index) {
              final activity = recommendedActivities[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(activity.category)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                _getCategoryEmoji(activity.category),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activity.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${activity.points} pts',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                          ),
                          const Spacer(),
                          Text(
                            activity.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                            maxLines: 2,
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
        ),
      ],
    );
  }

  Widget _buildEnvironmentalImpactSection(user, PointsProvider pointsProvider) {
    final co2Saved = (pointsProvider.totalPoints * 0.5).toStringAsFixed(1);
    final waterSaved = (pointsProvider.totalPoints * 2.3).toStringAsFixed(1);
    final treesEquivalent =
        (pointsProvider.totalPoints / 50).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Environmental Impact 🌍',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImpactItem(
                    'CO₂ Saved',
                    '${co2Saved} kg',
                    Icons.cloud,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImpactItem(
                    'Water Saved',
                    '${waterSaved} L',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildImpactItem(
                    'Energy Saved',
                    '${(pointsProvider.totalPoints * 1.2).toStringAsFixed(1)} kWh',
                    Icons.bolt,
                    Colors.yellow[700]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImpactItem(
                    'Trees Equivalent',
                    '${treesEquivalent}',
                    Icons.park,
                    Colors.green[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 1600.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildImpactItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  double _calculateLevelProgress(PointsProvider pointsProvider) {
    final currentPoints = pointsProvider.totalPoints;
    final currentLevel = pointsProvider.currentLevel;

    final levelThresholds = [
      0,
      100,
      300,
      600,
      1000,
      1500,
      2100,
      2800,
      3600,
      4500,
      5500,
    ];

    if (currentLevel >= levelThresholds.length) return 1.0; // Max level reached

    final currentLevelThreshold = levelThresholds[currentLevel - 1];
    final nextLevelThreshold = levelThresholds[currentLevel];

    final progress = (currentPoints - currentLevelThreshold) /
        (nextLevelThreshold - currentLevelThreshold);
    return progress.clamp(0.0, 1.0);
  }

  int _getPointsForNextLevel(int currentLevel) {
    final levelThresholds = [
      0,
      100,
      300,
      600,
      1000,
      1500,
      2100,
      2800,
      3600,
      4500,
      5500,
    ];

    if (currentLevel >= levelThresholds.length) return 0; // Max level reached

    return levelThresholds[currentLevel] - levelThresholds[currentLevel - 1];
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

  String _getCategoryEmoji(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return '🚲';
      case ActivityCategory.energy:
        return '⚡';
      case ActivityCategory.waste:
        return '♻️';
      case ActivityCategory.water:
        return '💧';
      case ActivityCategory.food:
        return '🥗';
      case ActivityCategory.shopping:
        return '🛍️';
      case ActivityCategory.nature:
        return '🌱';
    }
  }

  // Static recommended activities to avoid performance issues
  List<EcoActivity> _getStaticRecommendedActivities() {
    return [
      EcoActivity(
        id: 'rec_1',
        title: 'Walk to Work',
        description: 'Skip the car and walk to your workplace',
        points: 15,
        category: ActivityCategory.transport,
        icon: '🚶‍♂️',
        estimatedTime: const Duration(minutes: 30),
        difficulty: 'easy',
      ),
      EcoActivity(
        id: 'rec_2',
        title: 'Turn Off Lights',
        description: 'Switch off unused lights in your home',
        points: 10,
        category: ActivityCategory.energy,
        icon: '💡',
        estimatedTime: const Duration(minutes: 5),
        difficulty: 'easy',
      ),
      EcoActivity(
        id: 'rec_3',
        title: 'Recycle Paper',
        description: 'Sort and recycle paper waste properly',
        points: 20,
        category: ActivityCategory.waste,
        icon: '♻️',
        estimatedTime: const Duration(minutes: 15),
        difficulty: 'easy',
      ),
      EcoActivity(
        id: 'rec_4',
        title: 'Shorter Shower',
        description: 'Reduce shower time by 2 minutes',
        points: 12,
        category: ActivityCategory.water,
        icon: '🚿',
        estimatedTime: const Duration(minutes: 2),
        difficulty: 'easy',
      ),
      EcoActivity(
        id: 'rec_5',
        title: 'Plant a Tree',
        description: 'Plant a tree in your garden or local park',
        points: 50,
        category: ActivityCategory.nature,
        icon: '🌱',
        estimatedTime: const Duration(minutes: 60),
        difficulty: 'medium',
      ),
    ];
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
                Text('+${userActivity.activity.points} points'),
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

  void _startActivity(BuildContext context, EcoActivity activity) {
    _showActivityStartDialog(context, activity);
  }

  void _showActivityStartDialog(BuildContext context, EcoActivity activity) {
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
              _confirmStartActivity(context, activity);
            },
            child: const Text('Start Activity'),
          ),
        ],
      ),
    );
  }

  void _confirmStartActivity(BuildContext context, EcoActivity activity) async {
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
        ).showSnackBar(SnackBar(
          content: Text('Error starting activity: $e'),
          backgroundColor: Colors.orange[600],
        ));
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final pointsProvider = Provider.of<PointsProvider>(context, listen: false);

    try {
      // Use Firebase-integrated completion method
      await activityProvider.completeActivityWithFirebase(
        userActivity.id,
        authProvider.currentUser!.id,
      );

      // Refresh points from Firebase to get updated values
      await pointsProvider.loadPointsFromFirebase(authProvider.currentUser!.id);

      // Refresh activities to show updated state
      await activityProvider.syncWithFirebase(authProvider.currentUser!.id);

      // Send achievement notification
      await notificationProvider.sendAchievementNotification(
        'Activity Completed! 🎉',
        'You earned ${userActivity.activity.points} points for completing ${userActivity.activity.title}',
      );

      if (context.mounted) {
        _showPointsAnimation(context, userActivity.activity.points);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed! +${userActivity.activity.points} points'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing activity: $e'),
            backgroundColor: Colors.orange[600],
          ),
        );
      }
    }
  }

  void _showPointsAnimation(BuildContext context, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                '+$points Points!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job! 🌱',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDailyChallenge(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Challenge 🌟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Complete 5 eco-friendly activities today to earn bonus points!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Bonus Reward: +50 Points',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                  ),
                ],
              ),
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
              Navigator.of(context).pushNamed('/activities');
            },
            child: const Text('Start Challenge'),
          ),
        ],
      ),
    );
  }
}
