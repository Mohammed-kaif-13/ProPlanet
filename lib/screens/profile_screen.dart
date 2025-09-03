import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../models/activity_model.dart';
import '../models/notification_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    return Consumer2<UserProvider, ActivityProvider>(
      builder: (context, userProvider, activityProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) return const Center(child: CircularProgressIndicator());

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
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email.isNotEmpty ? user.email : 'No email provided',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Level', '', Icons.trending_up, Colors.blue),
                          _buildStatItem('Points', '', Icons.star, Colors.amber),
                          _buildStatItem('Streak', '', Icons.local_fire_department, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

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
                            'Progress to Level ',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' points to go',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _calculateLevelProgress(user, userProvider),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
              ).animate()
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/activities');
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...activityProvider.completedActivities
                          .take(3)
                          .map((activity) => _buildRecentActivityItem(activity))
                          .toList(),
                      if (activityProvider.completedActivities.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No completed activities yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideX(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Environmental Impact
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Environmental Impact ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImpactItem(
                              'CO Saved',
                              ' kg',
                              Icons.cloud,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImpactItem(
                              'Water Saved',
                              ' L',
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
                              ' kWh',
                              Icons.bolt,
                              Colors.yellow[700]!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImpactItem(
                              'Trees Equivalent',
                              '',
                              Icons.park,
                              Colors.green[700]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(delay: 600.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final pointsByCategory = activityProvider.pointsByCategory;
        final completedActivities = activityProvider.completedActivities;

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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: pointsByCategory.isEmpty
                            ? Center(
                                child: Text(
                                  'No data available',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections: pointsByCategory.entries.map((entry) {
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
                                _getCategoryName(entry.key),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Activity Timeline
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Timeline (Last 7 Days)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: _buildActivityTimelineChart(completedActivities),
                      ),
                    ],
                  ),
                ),
              ).animate()
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
                    '',
                    Icons.eco,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'This Week',
                    '',
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
                    '',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ],
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) return const SizedBox();

        // Generate achievement data
        final achievements = _generateAchievements(user);
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
              ).animate()
                .fadeIn(duration: 600.ms),

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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete more activities to earn badges!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 32),

              // Achievements Section
              Text(
                'Achievements ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms),

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
                          color: achievement.isCompleted ? null : Colors.grey[600],
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
                              achievement.isCompleted ? Colors.green : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: achievement.isCompleted ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: (600 + achievements.indexOf(achievement) * 100).ms, duration: 400.ms)
                    .slideX(begin: 0.2, end: 0),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityItem(UserActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            activity.activity.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(activity.completedTime!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
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

  Widget _buildImpactItem(String title, String value, IconData icon, Color color) {
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimelineChart(List<UserActivity> activities) {
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
        
        if (dailyPoints.containsKey(completedDate)) {
          dailyPoints[completedDate] = (dailyPoints[completedDate] ?? 0) + activity.activity.points;
        }
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = last7Days[value.toInt()];
                return Text(
                  '/',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: dailyPoints.entries.map((entry) {
              final index = last7Days.indexOf(entry.key);
              return FlSpot(index.toDouble(), entry.value.toDouble());
            }).toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateLevelProgress(user, UserProvider userProvider) {
    final currentPoints = user.totalPoints;
    final currentLevel = user.level;
    final pointsForNextLevel = userProvider.getPointsForNextLevel();
    
    if (pointsForNextLevel == 0) return 1.0; // Max level reached
    
    final levelThresholds = [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 5500];
    final currentLevelThreshold = levelThresholds[currentLevel - 1];
    final nextLevelThreshold = levelThresholds[currentLevel];
    
    final progress = (currentPoints - currentLevelThreshold) / (nextLevelThreshold - currentLevelThreshold);
    return progress.clamp(0.0, 1.0);
  }

  int _getThisWeekActivities(List<UserActivity> activities) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return activities.where((activity) {
      if (activity.completedTime == null) return false;
      return activity.completedTime!.isAfter(weekStart);
    }).length;
  }

  String _getBestCategory(Map<ActivityCategory, int> pointsByCategory) {
    if (pointsByCategory.isEmpty) return 'None';
    
    final bestEntry = pointsByCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
    return _getCategoryName(bestEntry.key);
  }

  double _getAveragePointsPerDay(List<UserActivity> activities) {
    if (activities.isEmpty) return 0.0;
    
    final totalPoints = activities.fold(0, (sum, activity) => sum + activity.activity.points);
    final daysSinceFirst = DateTime.now().difference(activities.first.startTime).inDays + 1;
    
    return totalPoints / daysSinceFirst;
  }

  List<Achievement> _generateAchievements(user) {
    return [
      Achievement(
        title: 'First Steps',
        description: 'Complete your first eco activity',
        progress: user.totalPoints > 0 ? 1.0 : 0.0,
      ),
      Achievement(
        title: 'Point Collector',
        description: 'Earn 100 points',
        progress: (user.totalPoints / 100).clamp(0.0, 1.0),
      ),
      Achievement(
        title: 'Eco Enthusiast',
        description: 'Earn 500 points',
        progress: (user.totalPoints / 500).clamp(0.0, 1.0),
      ),
      Achievement(
        title: 'Green Champion',
        description: 'Reach level 5',
        progress: (user.level / 5).clamp(0.0, 1.0),
      ),
      Achievement(
        title: 'Eco Master',
        description: 'Reach level 10',
        progress: (user.level / 10).clamp(0.0, 1.0),
      ),
    ];
  }

  String _getCategoryName(ActivityCategory category) {
    return category.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
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
    return '//';
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
                    final newSettings = settings.copyWith(activityReminders: value);
                    notificationProvider.updateSettings(newSettings);
                  },
                ),
                SwitchListTile(
                  title: const Text('Achievements'),
                  value: settings.achievements,
                  onChanged: (value) {
                    final newSettings = settings.copyWith(achievements: value);
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
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
              final updatedUser = user.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              );
              
              await userProvider.updateUser(updatedUser);
              
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
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
      applicationIcon: const Icon(Icons.eco, size: 64, color: Color(0xFF4CAF50)),
      children: [
        const Text('ProPlanet is your companion for making eco-friendly choices and tracking your environmental impact.'),
        const SizedBox(height: 16),
        const Text('Together, we can make a difference for our planet! '),
      ],
    );
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
