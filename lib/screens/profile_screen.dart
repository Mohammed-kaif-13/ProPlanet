import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/points_provider.dart';
import '../models/activity_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize PointsProvider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pointsProvider =
          Provider.of<PointsProvider>(context, listen: false);
      final activityProvider =
          Provider.of<ActivityProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        pointsProvider.loadPointsFromFirebase(authProvider.currentUser!.id);
        activityProvider.syncWithFirebase(authProvider.currentUser!.id);
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
        title: const Text('Profile'),
        leading: null, // Remove the back arrow
        automaticallyImplyLeading: false, // Prevent automatic back button
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Statistics', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Achievements', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStatisticsTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer3<AuthProvider, ActivityProvider, PointsProvider>(
      builder:
          (context, authProvider, activityProvider, pointsProvider, child) {
        final user = authProvider.currentUser;
        if (user == null)
          return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Card(
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
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email.isNotEmpty
                            ? user.email
                            : 'No email provided',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            'Level',
                            '${pointsProvider.currentLevel}',
                            Icons.trending_up,
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'Total Points',
                            '${pointsProvider.totalPoints}',
                            Icons.star,
                            Colors.amber,
                          ),
                          _buildStatItem(
                            'Streak',
                            '${pointsProvider.currentStreak}',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Progress to Next Level
              Card(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_getPointsForNextLevel(pointsProvider.currentLevel)} points to go',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _calculateLevelProgress(pointsProvider),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideX(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Recent Activities
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activities',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed('/activities');
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...activityProvider.completedActivities
                          .take(3)
                          .map(
                            (activity) => _buildRecentActivityItem(activity),
                          )
                          .toList(),
                      if (activityProvider.completedActivities.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No completed activities yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideX(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Environmental Impact
              _buildEnvironmentalImpactSection(pointsProvider)
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer2<ActivityProvider, PointsProvider>(
      builder: (context, activityProvider, pointsProvider, child) {
        final pointsByCategory = pointsProvider.categoryPoints;
        final completedActivities = activityProvider.completedActivities;

        // Refresh activities when statistics tab is opened
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.currentUser != null) {
            activityProvider.syncWithFirebase(authProvider.currentUser!.id);
            activityProvider
                .refreshCompletedActivities(authProvider.currentUser!.id);
          }
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Distribution Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points by Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: pointsByCategory.isEmpty
                            ? Center(
                                child: Text(
                                  'No data available',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections:
                                      pointsByCategory.entries.map((entry) {
                                    return PieChartSectionData(
                                      color: _getCategoryColor(entry.key),
                                      value: entry.value.toDouble(),
                                      title: '',
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: pointsByCategory.entries.map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.key.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Activity Timeline
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity Timeline (Last 7 Days)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);
                              if (authProvider.currentUser != null) {
                                activityProvider.refreshCompletedActivities(
                                    authProvider.currentUser!.id);
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh timeline',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Activity Summary
                      _buildActivitySummary(completedActivities),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: _buildActivityTimelineChart(
                          completedActivities,
                          pointsProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideX(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Statistics Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Activities',
                    '${completedActivities.length}',
                    Icons.eco,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'This Week',
                    '${_getThisWeekActivities(completedActivities)}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Best Category',
                    _getBestCategory(pointsByCategory),
                    Icons.category,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    'Avg. Points/Day',
                    '${_getAveragePointsPerDay(pointsProvider)}',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer2<AuthProvider, PointsProvider>(
      builder: (context, authProvider, pointsProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox();

        // Generate achievement data
        final achievements = _generateAchievements(pointsProvider);
        final badges = user.badges;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges Section
              Text(
                'Your Badges ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 16),

              badges.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No badges earned yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete more activities to earn badges!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getBadgeIcon(badge),
                                  size: 32,
                                  color: _getBadgeColor(badge),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  badge,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 32),

              // Achievements Section
              Text(
                'Achievements ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 16),

              ...achievements.map((achievement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: achievement.isCompleted
                            ? Colors.green
                            : Colors.grey[300],
                        child: Icon(
                          achievement.isCompleted ? Icons.check : Icons.lock,
                          color: achievement.isCompleted
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        achievement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              achievement.isCompleted ? null : Colors.grey[600],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(achievement.description),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: achievement.progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement.isCompleted
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: achievement.isCompleted
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay:
                            (600 + achievements.indexOf(achievement) * 100).ms,
                        duration: 400.ms,
                      )
                      .slideX(begin: 0.2, end: 0),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecentActivityItem(UserActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(activity.activity.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activity.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatDate(activity.completedTime!),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '+',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
      ),
    );
  }

  Widget _buildActivitySummary(List<UserActivity> activities) {
    final last7Days = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - index));
    });

    final dailyPoints = <DateTime, int>{};
    for (final day in last7Days) {
      dailyPoints[day] = 0;
    }

    for (final activity in activities) {
      if (activity.completedTime != null) {
        final completedDate = DateTime(
          activity.completedTime!.year,
          activity.completedTime!.month,
          activity.completedTime!.day,
        );

        // Check if this date matches any of the last 7 days
        for (final day in last7Days) {
          if (completedDate.year == day.year &&
              completedDate.month == day.month &&
              completedDate.day == day.day) {
            dailyPoints[day] =
                (dailyPoints[day] ?? 0) + activity.activity.points;
            break; // Found the matching day, no need to check further
          }
        }
      }
    }

    final totalPoints =
        dailyPoints.values.fold(0, (sum, points) => sum + points);
    final activeDays = dailyPoints.values.where((points) => points > 0).length;
    final avgPointsPerDay =
        activeDays > 0 ? (totalPoints / activeDays).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Points',
              '$totalPoints',
              Icons.star,
              Colors.amber,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildSummaryItem(
              'Active Days',
              '$activeDays/7',
              Icons.calendar_today,
              Colors.blue,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildSummaryItem(
              'Avg/Day',
              '$avgPointsPerDay',
              Icons.trending_up,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimelineChart(
      List<UserActivity> activities, PointsProvider pointsProvider) {
    final last7Days = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - index));
    });

    final dailyPoints = <DateTime, int>{};

    // Initialize all days with 0 points
    for (final day in last7Days) {
      dailyPoints[day] = 0;
    }

    // Calculate daily points from completed activities
    for (final activity in activities) {
      if (activity.completedTime != null) {
        final completedDate = DateTime(
          activity.completedTime!.year,
          activity.completedTime!.month,
          activity.completedTime!.day,
        );

        // Check if this date is within the last 7 days
        final now = DateTime.now();
        final daysDifference = now.difference(completedDate).inDays;
        if (daysDifference >= 0 && daysDifference < 7) {
          dailyPoints[completedDate] =
              (dailyPoints[completedDate] ?? 0) + activity.activity.points;
        }
      }
    }

    // Debug: Print the activities and daily points for troubleshooting
    print('=== Activity Timeline Debug ===');
    print('Total activities: ${activities.length}');
    print(
        'Completed activities: ${activities.where((a) => a.isCompleted).length}');
    print('Last 7 days: $last7Days');

    for (final activity in activities.where((a) => a.isCompleted)) {
      print('Activity: ${activity.activity.title}');
      print('  - Completed: ${activity.completedTime}');
      print('  - Points: ${activity.activity.points}');
      if (activity.completedTime != null) {
        final completedDate = DateTime(
          activity.completedTime!.year,
          activity.completedTime!.month,
          activity.completedTime!.day,
        );
        print('  - Date only: $completedDate');
      }
    }

    print('Daily points: $dailyPoints');
    print('Has data: ${dailyPoints.values.any((points) => points > 0)}');
    print('===============================');

    // Check if there's any data to show
    final hasData = dailyPoints.values.any((points) => points > 0);

    // If no data from activities, try to use today's points as a fallback
    if (!hasData && pointsProvider.currentPoints > 0) {
      print(
          'No activity data found, using today\'s points: ${pointsProvider.currentPoints}');
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Find today in the last7Days list and add the current points
      for (final day in last7Days) {
        if (day.year == todayDate.year &&
            day.month == todayDate.month &&
            day.day == todayDate.day) {
          dailyPoints[day] = pointsProvider.currentPoints;
          break;
        }
      }
    }

    // Check again if we have data after fallback
    final finalHasData = dailyPoints.values.any((points) => points > 0);

    if (!finalHasData) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No activities completed in the last 7 days',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete some activities to see your progress!',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate max points for better chart scaling
    final maxPoints = dailyPoints.values.isEmpty
        ? 50
        : dailyPoints.values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxPoints == 0 ? 50 : (maxPoints * 1.2).round();

    print('Final chart data: $dailyPoints');
    print('Max points: $maxPoints, Chart max: $chartMax');

    return Container(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: chartMax.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMax / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                    final date = last7Days[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 10 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          barGroups: last7Days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final points = dailyPoints[day] ?? 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points.toDouble(),
                  color: points > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMax.toDouble(),
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = last7Days[group.x];
                final points = dailyPoints[day] ?? 0;
                return BarTooltipItem(
                  '${day.day}/${day.month}\n$points points',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateLevelProgress(PointsProvider pointsProvider) {
    final currentPoints = pointsProvider.totalPoints;
    final currentLevel = pointsProvider.currentLevel;
    final pointsForNextLevel = _getPointsForNextLevel(currentLevel);

    if (pointsForNextLevel == 0) return 1.0; // Max level reached

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

  String _getBestCategory(Map<String, int> pointsByCategory) {
    if (pointsByCategory.isEmpty) return 'None';

    final bestEntry = pointsByCategory.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return bestEntry.key;
  }

  int _getThisWeekActivities(List<UserActivity> completedActivities) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return completedActivities.where((activity) {
      final completedTime = activity.completedTime;
      if (completedTime == null) return false;
      return completedTime.isAfter(weekStart) &&
          completedTime.isBefore(weekEnd.add(const Duration(days: 1)));
    }).length;
  }

  String _getAveragePointsPerDay(PointsProvider pointsProvider) {
    final totalPoints = pointsProvider.totalPoints;

    // Calculate days since first activity (approximate)
    final daysActive = (totalPoints / 50).clamp(1, 30); // Rough estimate
    final avgPoints = (totalPoints / daysActive).round();

    return avgPoints.toString();
  }

  Widget _buildEnvironmentalImpactSection(PointsProvider pointsProvider) {
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
    );
  }

  List<Achievement> _generateAchievements(PointsProvider pointsProvider) {
    return [
      Achievement(
        title: 'First Steps',
        description: 'Complete your first eco activity',
        progress: pointsProvider.totalPoints > 0 ? 1.0 : 0.0,
      ),
      Achievement(
        title: 'Point Collector',
        description: 'Earn 100 points',
        progress: (pointsProvider.totalPoints / 100).clamp(0.0, 1.0),
      ),
      Achievement(
        title: 'Eco Enthusiast',
        description: 'Earn 500 points',
        progress: (pointsProvider.totalPoints / 500).clamp(0.0, 1.0),
      ),
      Achievement(
        title: 'Green Champion',
        description: 'Reach level 5',
        progress: (pointsProvider.currentLevel / 5).clamp(0.0, 1.0),
      ),
      Achievement(
        title: 'Eco Master',
        description: 'Reach level 10',
        progress: (pointsProvider.currentLevel / 10).clamp(0.0, 1.0),
      ),
    ];
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transport':
        return Colors.blue;
      case 'energy':
        return Colors.yellow[700]!;
      case 'waste':
        return Colors.green;
      case 'water':
        return Colors.cyan;
      case 'food':
        return Colors.orange;
      case 'shopping':
        return Colors.purple;
      case 'nature':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getBadgeIcon(String badge) {
    // Simple mapping for demo purposes
    if (badge.contains('First')) return Icons.star;
    if (badge.contains('Level')) return Icons.trending_up;
    if (badge.contains('Streak')) return Icons.local_fire_department;
    return Icons.emoji_events;
  }

  Color _getBadgeColor(String badge) {
    // Simple mapping for demo purposes
    if (badge.contains('First')) return Colors.amber;
    if (badge.contains('Level')) return Colors.blue;
    if (badge.contains('Streak')) return Colors.orange;
    return Colors.purple;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.of(context).pop();
                _showNotificationSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditProfileDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                _showAboutDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showLogoutConfirmation();
              },
            ),
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

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final settings = notificationProvider.settings;

          return AlertDialog(
            title: const Text('Notification Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Activity Reminders'),
                  value: settings.activityReminders,
                  onChanged: (value) {
                    final newSettings = settings.copyWith(
                      activityReminders: value,
                    );
                    notificationProvider.updateSettings(newSettings);
                  },
                ),
                SwitchListTile(
                  title: const Text('Achievements'),
                  value: settings.achievements,
                  onChanged: (value) {
                    final newSettings = settings.copyWith(
                      achievements: value,
                    );
                    notificationProvider.updateSettings(newSettings);
                  },
                ),
                SwitchListTile(
                  title: const Text('Tips & Suggestions'),
                  value: settings.tips,
                  onChanged: (value) {
                    final newSettings = settings.copyWith(tips: value);
                    notificationProvider.updateSettings(newSettings);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.updateUserData({
                'name': nameController.text,
                'email': emailController.text,
              });

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'ProPlanet',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.eco,
        size: 64,
        color: Color(0xFF4CAF50),
      ),
      children: [
        const Text(
          'ProPlanet is your companion for making eco-friendly choices and tracking your environmental impact.',
        ),
        const SizedBox(height: 16),
        const Text('Together, we can make a difference for our planet! '),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get the auth provider and perform logout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to login screen and clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class Achievement {
  final String title;
  final String description;
  final double progress;

  Achievement({
    required this.title,
    required this.description,
    required this.progress,
  });

  bool get isCompleted => progress >= 1.0;
}
