import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity_model.dart';

class ActivityProvider with ChangeNotifier {
  List<EcoActivity> _availableActivities = [];
  List<UserActivity> _userActivities = [];
  bool _isLoading = false;
  String? _error;

  List<EcoActivity> get availableActivities => _availableActivities;
  List<UserActivity> get userActivities => _userActivities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get completed activities
  List<UserActivity> get completedActivities =>
      _userActivities.where((activity) => activity.isCompleted).toList();

  // Get pending activities
  List<UserActivity> get pendingActivities =>
      _userActivities.where((activity) => !activity.isCompleted).toList();

  // Get today's activities
  List<UserActivity> get todayActivities {
    final today = DateTime.now();
    return _userActivities.where((activity) {
      return activity.startTime.year == today.year &&
          activity.startTime.month == today.month &&
          activity.startTime.day == today.day;
    }).toList();
  }

  // Get total points earned
  int get totalPointsEarned {
    return completedActivities.fold(
      0,
      (total, activity) => total + activity.activity.points,
    );
  }

  // Get points by category
  Map<ActivityCategory, int> get pointsByCategory {
    final Map<ActivityCategory, int> categoryPoints = {};

    for (final activity in completedActivities) {
      final category = activity.activity.category;
      categoryPoints[category] =
          (categoryPoints[category] ?? 0) + activity.activity.points;
    }

    return categoryPoints;
  }

  // Initialize activities
  Future<void> initializeActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadAvailableActivities();
      await _loadUserActivities();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize activities: ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available activities (predefined eco-friendly activities)
  Future<void> _loadAvailableActivities() async {
    _availableActivities = [
      // Transport Activities
      EcoActivity(
        id: 'transport_1',
        title: 'Walk or Bike Instead of Drive',
        description:
            'Choose walking or biking for short trips instead of using a car',
        category: ActivityCategory.transport,
        points: 20,
        icon: '',
        estimatedTime: const Duration(minutes: 30),
        tags: ['transport', 'health', 'carbon-reduction'],
        difficulty: 'easy',
        instructions:
            'For trips under 2 miles, try walking or biking instead of driving.',
      ),
      EcoActivity(
        id: 'transport_2',
        title: 'Use Public Transportation',
        description:
            'Take the bus, train, or other public transport instead of driving',
        category: ActivityCategory.transport,
        points: 15,
        icon: '',
        estimatedTime: const Duration(minutes: 45),
        tags: ['transport', 'community', 'carbon-reduction'],
        difficulty: 'easy',
        instructions: 'Plan your route using public transportation apps.',
      ),
      EcoActivity(
        id: 'transport_3',
        title: 'Carpool or Rideshare',
        description:
            'Share a ride with others to reduce individual carbon footprint',
        category: ActivityCategory.transport,
        points: 12,
        icon: '',
        estimatedTime: const Duration(minutes: 60),
        tags: ['transport', 'social', 'carbon-reduction'],
        difficulty: 'easy',
        instructions: 'Coordinate with friends, family, or use rideshare apps.',
      ),

      // Energy Activities
      EcoActivity(
        id: 'energy_1',
        title: 'Switch to LED Bulbs',
        description:
            'Replace traditional bulbs with energy-efficient LED bulbs',
        category: ActivityCategory.energy,
        points: 25,
        icon: '',
        estimatedTime: const Duration(minutes: 15),
        tags: ['energy', 'home', 'savings'],
        difficulty: 'easy',
        instructions:
            'Replace one or more incandescent bulbs with LED alternatives.',
      ),
      EcoActivity(
        id: 'energy_2',
        title: 'Unplug Electronics When Not in Use',
        description: 'Reduce phantom energy consumption by unplugging devices',
        category: ActivityCategory.energy,
        points: 10,
        icon: '',
        estimatedTime: const Duration(minutes: 10),
        tags: ['energy', 'home', 'savings'],
        difficulty: 'easy',
        instructions:
            'Unplug chargers, TVs, and other electronics when not actively using them.',
      ),
      EcoActivity(
        id: 'energy_3',
        title: 'Adjust Thermostat by 2 Degrees',
        description:
            'Lower heating or raise cooling by 2 degrees to save energy',
        category: ActivityCategory.energy,
        points: 15,
        icon: '',
        estimatedTime: const Duration(minutes: 2),
        tags: ['energy', 'home', 'comfort'],
        difficulty: 'easy',
        instructions:
            'Adjust your thermostat 2 degrees lower in winter, higher in summer.',
      ),

      // Waste Activities
      EcoActivity(
        id: 'waste_1',
        title: 'Start Composting',
        description: 'Begin composting organic waste to reduce landfill impact',
        category: ActivityCategory.waste,
        points: 30,
        icon: '',
        estimatedTime: const Duration(minutes: 20),
        tags: ['waste', 'composting', 'gardening'],
        difficulty: 'medium',
        instructions:
            'Set up a compost bin and start collecting organic waste.',
      ),
      EcoActivity(
        id: 'waste_2',
        title: 'Use Reusable Bags for Shopping',
        description: 'Bring reusable bags instead of using plastic bags',
        category: ActivityCategory.waste,
        points: 8,
        icon: '',
        estimatedTime: const Duration(minutes: 5),
        tags: ['waste', 'shopping', 'plastic-reduction'],
        difficulty: 'easy',
        instructions:
            'Remember to bring reusable bags for your next shopping trip.',
      ),
      EcoActivity(
        id: 'waste_3',
        title: 'Recycle Properly',
        description: 'Sort and recycle materials according to local guidelines',
        category: ActivityCategory.waste,
        points: 12,
        icon: '',
        estimatedTime: const Duration(minutes: 15),
        tags: ['waste', 'recycling', 'sorting'],
        difficulty: 'easy',
        instructions:
            'Check local recycling guidelines and sort materials correctly.',
      ),

      // Water Activities
      EcoActivity(
        id: 'water_1',
        title: 'Take Shorter Showers',
        description: 'Reduce shower time by 2-3 minutes to conserve water',
        category: ActivityCategory.water,
        points: 15,
        icon: '',
        estimatedTime: const Duration(minutes: 10),
        tags: ['water', 'conservation', 'daily-habit'],
        difficulty: 'easy',
        instructions: 'Set a timer and aim to reduce your shower time.',
      ),
      EcoActivity(
        id: 'water_2',
        title: 'Fix Leaky Faucets',
        description: 'Repair dripping faucets to prevent water waste',
        category: ActivityCategory.water,
        points: 20,
        icon: '',
        estimatedTime: const Duration(minutes: 30),
        tags: ['water', 'maintenance', 'home'],
        difficulty: 'medium',
        instructions: 'Check all faucets and repair any leaks you find.',
      ),
      EcoActivity(
        id: 'water_3',
        title: 'Collect Rainwater',
        description: 'Set up a rain collection system for garden watering',
        category: ActivityCategory.water,
        points: 25,
        icon: '',
        estimatedTime: const Duration(minutes: 45),
        tags: ['water', 'gardening', 'conservation'],
        difficulty: 'medium',
        instructions: 'Install a rain barrel or collection system.',
      ),

      // Food Activities
      EcoActivity(
        id: 'food_1',
        title: 'Eat a Plant-Based Meal',
        description:
            'Choose a vegetarian or vegan meal to reduce carbon footprint',
        category: ActivityCategory.food,
        points: 18,
        icon: '',
        estimatedTime: const Duration(minutes: 45),
        tags: ['food', 'plant-based', 'health'],
        difficulty: 'easy',
        instructions:
            'Try a delicious plant-based recipe for one of your meals today.',
      ),
      EcoActivity(
        id: 'food_2',
        title: 'Buy Local Produce',
        description:
            'Purchase fruits and vegetables from local farmers or markets',
        category: ActivityCategory.food,
        points: 22,
        icon: '',
        estimatedTime: const Duration(minutes: 60),
        tags: ['food', 'local', 'community'],
        difficulty: 'easy',
        instructions: 'Visit a farmers market or buy locally-grown produce.',
      ),
      EcoActivity(
        id: 'food_3',
        title: 'Reduce Food Waste',
        description: 'Plan meals and use leftovers to minimize food waste',
        category: ActivityCategory.food,
        points: 16,
        icon: '',
        estimatedTime: const Duration(minutes: 30),
        tags: ['food', 'planning', 'waste-reduction'],
        difficulty: 'easy',
        instructions:
            'Plan your meals for the week and use up leftovers creatively.',
      ),

      // Nature Activities
      EcoActivity(
        id: 'nature_1',
        title: 'Plant a Tree or Flower',
        description: 'Plant something green to help the environment',
        category: ActivityCategory.nature,
        points: 35,
        icon: '',
        estimatedTime: const Duration(minutes: 60),
        tags: ['nature', 'planting', 'carbon-absorption'],
        difficulty: 'medium',
        instructions:
            'Plant a tree, flower, or herb in your garden or a suitable location.',
      ),
      EcoActivity(
        id: 'nature_2',
        title: 'Clean Up Litter',
        description: 'Pick up trash in your neighborhood or a natural area',
        category: ActivityCategory.nature,
        points: 20,
        icon: '',
        estimatedTime: const Duration(minutes: 30),
        tags: ['nature', 'cleanup', 'community'],
        difficulty: 'easy',
        instructions: 'Spend time cleaning up litter in your local area.',
      ),
      EcoActivity(
        id: 'nature_3',
        title: 'Create Wildlife Habitat',
        description: 'Set up bird feeders, bee houses, or plant native species',
        category: ActivityCategory.nature,
        points: 28,
        icon: '',
        estimatedTime: const Duration(minutes: 45),
        tags: ['nature', 'wildlife', 'habitat'],
        difficulty: 'medium',
        instructions:
            'Create a small habitat for local wildlife in your yard or balcony.',
      ),
    ];

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = _availableActivities.map((a) => a.toJson()).toList();
    await prefs.setString('available_activities', jsonEncode(activitiesJson));
  }

  // Load user activities from local storage
  Future<void> _loadUserActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userActivitiesJson = prefs.getString('user_activities');

      if (userActivitiesJson != null) {
        final List<dynamic> activitiesList = jsonDecode(userActivitiesJson);
        _userActivities =
            activitiesList.map((json) => UserActivity.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle error silently and start with empty list
      _userActivities = [];
    }
  }

  // Save user activities to local storage
  Future<void> _saveUserActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = _userActivities.map((a) => a.toJson()).toList();
      await prefs.setString('user_activities', jsonEncode(activitiesJson));
    } catch (e) {
      _error = 'Failed to save activities: ';
      notifyListeners();
    }
  }

  // Start an activity
  Future<UserActivity> startActivity(
    EcoActivity activity,
    String userId,
  ) async {
    final userActivity = UserActivity(
      id: 'user_activity_',
      userId: userId,
      activityId: activity.id,
      activity: activity,
      startTime: DateTime.now(),
      status: ActivityStatus.pending,
    );

    _userActivities.add(userActivity);
    await _saveUserActivities();
    notifyListeners();

    return userActivity;
  }

  // Complete an activity
  Future<void> completeActivity(
    String activityId, {
    String? notes,
    List<String>? photos,
  }) async {
    final index = _userActivities.indexWhere((a) => a.id == activityId);
    if (index != -1) {
      _userActivities[index] = _userActivities[index].copyWith(
        completedTime: DateTime.now(),
        status: ActivityStatus.completed,
        notes: notes,
        photos: photos ?? [],
      );

      await _saveUserActivities();
      notifyListeners();
    }
  }

  // Get activity by ID
  EcoActivity? getActivityById(String id) {
    try {
      return _availableActivities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get user activity by ID
  UserActivity? getUserActivityById(String id) {
    try {
      return _userActivities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get activities by category
  List<EcoActivity> getActivitiesByCategory(ActivityCategory category) {
    return _availableActivities
        .where((activity) => activity.category == category)
        .toList();
  }

  // Get recommended activities based on user's history
  List<EcoActivity> getRecommendedActivities({int limit = 5}) {
    // Simple recommendation: return activities not recently completed
    final recentlyCompleted =
        completedActivities
            .where(
              (ua) =>
                  ua.completedTime != null &&
                  ua.completedTime!.isAfter(
                    DateTime.now().subtract(const Duration(days: 7)),
                  ),
            )
            .map((ua) => ua.activityId)
            .toSet();

    final recommended =
        _availableActivities
            .where((activity) => !recentlyCompleted.contains(activity.id))
            .take(limit)
            .toList();

    return recommended;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get streak (consecutive days with completed activities)
  int getCurrentStreak() {
    if (completedActivities.isEmpty) return 0;

    final today = DateTime.now();
    final completedDates =
        completedActivities
            .where((activity) => activity.completedTime != null)
            .map(
              (activity) => DateTime(
                activity.completedTime!.year,
                activity.completedTime!.month,
                activity.completedTime!.day,
              ),
            )
            .toSet()
            .toList();

    completedDates.sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime currentDate = DateTime(today.year, today.month, today.day);

    for (final date in completedDates) {
      if (date.isAtSameMomentAs(currentDate) ||
          date.isAtSameMomentAs(
            currentDate.subtract(const Duration(days: 1)),
          )) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}
