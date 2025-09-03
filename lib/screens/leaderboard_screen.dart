import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global', icon: Icon(Icons.public)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalLeaderboardTab(),
          _buildCategoryLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboardTab() {
    return Consumer2<UserProvider, ActivityProvider>(
      builder: (context, userProvider, activityProvider, child) {
        final currentUser = userProvider.currentUser;
        if (currentUser == null) return const SizedBox();

        // For demo purposes, we'll create some mock users
        final mockUsers = _generateMockUsers(currentUser);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Current User Rank Card
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Rank',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ' points  Level ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Top Users Section
              Text(
                'Top Eco Warriors ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              // Top 3 Podium
              _buildPodium(mockUsers.take(3).toList()).animate()
                .fadeIn(delay: 400.ms, duration: 800.ms)
                .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Remaining Rankings
              ...mockUsers.skip(3).take(7).map((user) {
                final rank = mockUsers.indexOf(user) + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildLeaderboardItem(user, rank, user.id == currentUser.id),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryLeaderboardTab() {
    return Consumer2<UserProvider, ActivityProvider>(
      builder: (context, userProvider, activityProvider, child) {
        final currentUser = userProvider.currentUser;
        if (currentUser == null) return const SizedBox();

        final pointsByCategory = activityProvider.pointsByCategory;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Category Performance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(duration: 600.ms),

              const SizedBox(height: 16),

              // Category Stats Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: ActivityCategory.values.length,
                itemBuilder: (context, index) {
                  final category = ActivityCategory.values[index];
                  final points = pointsByCategory[category] ?? 0;
                  
                  return Card(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(category).withOpacity(0.1),
                            _getCategoryColor(category).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 32,
                            color: _getCategoryColor(category),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCategoryName(category),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ' pts',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _getCategoryColor(category),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: (index * 100).ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0);
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Global Category Leaders',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),

              const SizedBox(height: 16),

              // Category Leaders List
              ...ActivityCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCategoryLeaderCard(category),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodium(List<MockUser> topThree) {
    if (topThree.length < 3) return const SizedBox();

    return Container(
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Second place (left)
          Positioned(
            left: 0,
            bottom: 0,
            child: _buildPodiumPosition(topThree[1], 2, 140, Colors.grey[400]!),
          ),
          // First place (center)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPodiumPosition(topThree[0], 1, 160, Colors.amber),
          ),
          // Third place (right)
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildPodiumPosition(topThree[2], 3, 120, Colors.brown[400]!),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(MockUser user, int position, double height, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color,
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          ' pts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '#',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(MockUser user, int rank, bool isCurrentUser) {
    return Card(
      elevation: isCurrentUser ? 4 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isCurrentUser ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          border: isCurrentUser ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(rank).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '#',
                  style: TextStyle(
                    color: _getRankColor(rank),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRankColor(rank),
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  Text(
                    'Level ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getRankColor(rank),
                  ),
                ),
                Text(
                  'points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: (rank * 50).ms, duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildCategoryLeaderCard(ActivityCategory category) {
    // Mock category leader data
    final mockLeader = MockUser(
      id: 'leader_',
      name: _getMockCategoryLeaderName(category),
      points: _getMockCategoryPoints(category),
      level: _getMockCategoryLevel(category),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryName(category),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: _getCategoryColor(category),
                        child: Text(
                          mockLeader.name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mockLeader.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              ' pts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getCategoryColor(category),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: 100.ms, duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  List<MockUser> _generateMockUsers(currentUser) {
    final mockUsers = [
      MockUser(id: 'user1', name: 'EcoChampion', points: 2850, level: 9),
      MockUser(id: 'user2', name: 'GreenWarrior', points: 2650, level: 8),
      MockUser(id: 'user3', name: 'NatureLover', points: 2400, level: 8),
      MockUser(id: 'user4', name: 'EcoFriendly', points: 2200, level: 7),
      MockUser(id: 'user5', name: 'PlantParent', points: 2000, level: 7),
      MockUser(id: 'user6', name: 'SustainableLife', points: 1850, level: 6),
      MockUser(id: 'user7', name: 'CleanEnergy', points: 1700, level: 6),
      MockUser(id: 'user8', name: 'ZeroWaste', points: 1550, level: 5),
      MockUser(id: 'user9', name: 'EcoActivist', points: 1400, level: 5),
      MockUser(id: 'user10', name: 'GreenThumb', points: 1250, level: 4),
    ];

    // Add current user to the list
    mockUsers.add(MockUser(
      id: currentUser.id,
      name: currentUser.name,
      points: currentUser.totalPoints,
      level: currentUser.level,
    ));

    // Sort by points descending
    mockUsers.sort((a, b) => b.points.compareTo(a.points));

    return mockUsers;
  }

  int _getCurrentUserRank(currentUser, List<MockUser> users) {
    for (int i = 0; i < users.length; i++) {
      if (users[i].id == currentUser.id) {
        return i + 1;
      }
    }
    return users.length;
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[400]!;
    if (rank <= 10) return Theme.of(context).primaryColor;
    return Colors.grey[600]!;
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

  IconData _getCategoryIcon(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return Icons.directions_bus;
      case ActivityCategory.energy:
        return Icons.bolt;
      case ActivityCategory.waste:
        return Icons.recycling;
      case ActivityCategory.water:
        return Icons.water_drop;
      case ActivityCategory.food:
        return Icons.restaurant;
      case ActivityCategory.shopping:
        return Icons.shopping_bag;
      case ActivityCategory.nature:
        return Icons.park;
    }
  }

  String _getMockCategoryLeaderName(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return 'BikeRider';
      case ActivityCategory.energy:
        return 'SolarPower';
      case ActivityCategory.waste:
        return 'RecycleKing';
      case ActivityCategory.water:
        return 'WaterSaver';
      case ActivityCategory.food:
        return 'VeganChef';
      case ActivityCategory.shopping:
        return 'LocalBuyer';
      case ActivityCategory.nature:
        return 'TreePlanter';
    }
  }

  int _getMockCategoryPoints(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return 450;
      case ActivityCategory.energy:
        return 380;
      case ActivityCategory.waste:
        return 520;
      case ActivityCategory.water:
        return 340;
      case ActivityCategory.food:
        return 410;
      case ActivityCategory.shopping:
        return 290;
      case ActivityCategory.nature:
        return 480;
    }
  }

  int _getMockCategoryLevel(ActivityCategory category) {
    return (_getMockCategoryPoints(category) / 150).floor() + 1;
  }
}

class MockUser {
  final String id;
  final String name;
  final int points;
  final int level;

  MockUser({
    required this.id,
    required this.name,
    required this.points,
    required this.level,
  });
}
