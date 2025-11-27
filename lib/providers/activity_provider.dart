import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models/activity_model.dart';
import '../services/daily_activity_service.dart';
import '../services/firebase_service.dart';

class ActivityProvider with ChangeNotifier {
  List<EcoActivity> _availableActivities = [];
  List<UserActivity> _userActivities = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<EcoActivity> get availableActivities => _availableActivities;
  List<UserActivity> get userActivities => _userActivities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Get completed activities
  List<UserActivity> get completedActivities =>
      _userActivities.where((activity) => activity.isCompleted).toList();

  // Get pending activities (including those that can be repeated same day)
  List<UserActivity> get pendingActivities {
    final today = DateTime.now();
    return _userActivities.where((activity) {
      // Show if not completed
      if (!activity.isCompleted) return true;

      // Show if completed but not today (can be repeated)
      if (activity.completedTime != null &&
          !_isSameDay(activity.completedTime!, today)) {
        return true;
      }

      return false;
    }).toList();
  }

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
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _loadAvailableActivities();
      await _loadUserActivities();
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize activities: ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available activities (predefined eco-friendly activities)
  Future<void> _loadAvailableActivities() async {
    final dailyService = DailyActivityService();
    _availableActivities = dailyService.getAllActivities();
    print('Loaded ${_availableActivities.length} available activities');

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
      id: 'user_activity_${DateTime.now().millisecondsSinceEpoch}',
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
    print('Filtering activities for category: $category');
    print('Total available activities: ${_availableActivities.length}');
    final filtered = _availableActivities
        .where((activity) => activity.category == category)
        .toList();
    print('Filtered activities count: ${filtered.length}');
    return filtered;
  }

  // Get recommended activities based on user's history
  List<EcoActivity> getRecommendedActivities({int limit = 5}) {
    // Simple recommendation: return activities not recently completed
    final recentlyCompleted = completedActivities
        .where(
          (ua) =>
              ua.completedTime != null &&
              ua.completedTime!.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
        )
        .map((ua) => ua.activityId)
        .toSet();

    final recommended = _availableActivities
        .where((activity) => !recentlyCompleted.contains(activity.id))
        .take(limit)
        .toList();

    return recommended;
  }

  // Generate daily activities for user
  List<EcoActivity> generateDailyActivities({
    int count = 5,
    List<ActivityCategory>? preferredCategories,
    String difficulty = 'mixed',
  }) {
    final dailyService = DailyActivityService();
    return dailyService.generateDailyActivities(
      count: count,
      preferredCategories: preferredCategories,
      difficulty: difficulty,
    );
  }

  // Get activities for specific time of day
  List<EcoActivity> getActivitiesForTimeOfDay() {
    final dailyService = DailyActivityService();
    final now = DateTime.now();

    // Determine time of day based on hour
    TimeOfDay timeOfDay;
    if (now.hour >= 6 && now.hour < 12) {
      timeOfDay = TimeOfDay.morning;
    } else if (now.hour >= 12 && now.hour < 17) {
      timeOfDay = TimeOfDay.afternoon;
    } else if (now.hour >= 17 && now.hour < 22) {
      timeOfDay = TimeOfDay.evening;
    } else {
      timeOfDay = TimeOfDay.night;
    }

    return dailyService.getActivitiesForTimeOfDay(timeOfDay);
  }

  // Get seasonal activities
  List<EcoActivity> getSeasonalActivities() {
    final dailyService = DailyActivityService();
    return dailyService.getSeasonalActivities();
  }

  // Get challenge activities
  List<EcoActivity> getChallengeActivities() {
    final dailyService = DailyActivityService();
    return dailyService.getChallengeActivities();
  }

  // Get quick activities
  List<EcoActivity> getQuickActivities() {
    final dailyService = DailyActivityService();
    return dailyService.getQuickActivities();
  }

  // Get today's recommended activities with intelligent suggestions
  List<EcoActivity> getTodaysRecommendedActivities() {
    // Note: This method should be called from a widget context where Provider is available
    // For now, we'll use the basic implementation without Provider access

    // Get completed activities for intelligent filtering
    final completedToday = completedActivities
        .where(
          (activity) =>
              activity.completedTime != null &&
              _isSameDay(activity.completedTime!, DateTime.now()),
        )
        .map((activity) => activity.activity.id)
        .toList();

    final completedThisWeek = completedActivities
        .where(
          (activity) =>
              activity.completedTime != null &&
              activity.completedTime!.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
        )
        .map((activity) => activity.activity.id)
        .toList();

    // Generate intelligent daily activities
    final dailyService = DailyActivityService();
    final dailyActivities = dailyService.generateDailyActivities(
      count: 3,
      completedToday: completedToday,
      completedThisWeek: completedThisWeek,
      userLevel: 1, // Default level, can be enhanced later
      weatherCondition: _getCurrentWeatherCondition(),
    );

    // Get time-based activities
    final timeBasedActivities = getActivitiesForTimeOfDay().take(2).toList();

    // Get seasonal activities
    final seasonalActivities = getSeasonalActivities().take(2).toList();

    // Get personalized recommendations
    final personalizedActivities = dailyService.getPersonalizedRecommendations(
      completedActivities:
          completedActivities.map((a) => a.activity.id).toList(),
      favoriteCategories: _getFavoriteCategories(),
      userLevel: 1, // Default level, can be enhanced later
      weatherCondition: _getCurrentWeatherCondition(),
      count: 2,
    );

    final allRecommended = <EcoActivity>[];
    allRecommended.addAll(dailyActivities);
    allRecommended.addAll(timeBasedActivities);
    allRecommended.addAll(seasonalActivities);
    allRecommended.addAll(personalizedActivities);

    // Remove duplicates and return unique activities
    final uniqueActivities = <String, EcoActivity>{};
    for (final activity in allRecommended) {
      uniqueActivities[activity.id] = activity;
    }

    return uniqueActivities.values.take(8).toList()..shuffle();
  }

  // Helper methods for intelligent recommendations
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String? _getCurrentWeatherCondition() {
    // This is a placeholder - you can integrate with a weather API
    // For now, return null to skip weather filtering
    return null;
  }

  List<ActivityCategory> _getFavoriteCategories() {
    if (completedActivities.isEmpty) return [];

    final categoryCounts = <ActivityCategory, int>{};
    for (final activity in completedActivities) {
      categoryCounts[activity.activity.category] =
          (categoryCounts[activity.activity.category] ?? 0) + 1;
    }

    // Return top 3 favorite categories
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(3).map((entry) => entry.key).toList();
  }

  // Get daily challenge activities
  List<EcoActivity> getDailyChallengeActivities() {
    final dailyService = DailyActivityService();
    return dailyService.getDailyChallengeActivities();
  }

  // Get streak-building activities
  List<EcoActivity> getStreakBuildingActivities() {
    final dailyService = DailyActivityService();
    return dailyService.getStreakBuildingActivities();
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
    final completedDates = completedActivities
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

  // ==================== FIREBASE INTEGRATION ====================

  final FirebaseService _firebaseService = FirebaseService();

  // Load user activities from Firebase
  Future<void> loadUserActivitiesFromFirebase(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final activities =
          await _firebaseService.getUserActivitiesFromFirebase(userId);
      _userActivities = activities;

      // Also save to local storage for offline access
      await _saveUserActivitiesToLocal();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load activities: $e');
      // Fallback to local storage
      await _loadUserActivitiesFromLocal();
    } finally {
      _setLoading(false);
    }
  }

  // Load today's activities from Firebase
  Future<void> loadTodaysActivitiesFromFirebase(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final todaysActivities =
          await _firebaseService.getTodaysActivities(userId);

      // Merge with existing activities, avoiding duplicates
      for (final activity in todaysActivities) {
        if (!_userActivities.any((existing) => existing.id == activity.id)) {
          _userActivities.add(activity);
        }
      }

      // Sort by start time
      _userActivities.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Save to local storage
      await _saveUserActivitiesToLocal();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load today\'s activities: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save user activity to Firebase
  Future<void> saveUserActivityToFirebase(UserActivity userActivity) async {
    try {
      await _firebaseService.saveUserActivityToFirebase(userActivity);

      // Add to local list if not already present
      if (!_userActivities.any((existing) => existing.id == userActivity.id)) {
        _userActivities.add(userActivity);
        _userActivities.sort((a, b) => b.startTime.compareTo(a.startTime));
        notifyListeners();
      }

      // Save to local storage
      await _saveUserActivitiesToLocal();
    } catch (e) {
      _setError('Failed to save activity: $e');
      throw e;
    }
  }

  // Complete activity and sync with Firebase
  Future<void> completeActivityWithFirebase(String activityId, String userId,
      {String? notes}) async {
    try {
      _setLoading(true);
      _clearError();

      // Find the activity
      final activityIndex =
          _userActivities.indexWhere((a) => a.id == activityId);
      if (activityIndex == -1) {
        throw Exception('Activity not found');
      }

      final activity = _userActivities[activityIndex];

      // Update status in Firebase
      await _firebaseService.updateUserActivityStatus(
        userId,
        activityId,
        ActivityStatus.completed,
        notes: notes,
      );

      // Add points to user
      await _firebaseService.addUserPoints(
        userId,
        activity.activity.points,
        activity.activity.category.toString().split('.').last,
      );

      // Update local activity
      final updatedActivity = activity.copyWith(
        status: ActivityStatus.completed,
        completedTime: DateTime.now(),
        notes: notes,
      );

      _userActivities[activityIndex] = updatedActivity;

      // Save to local storage
      await _saveUserActivitiesToLocal();

      // Refresh daily activities to show new ones
      await _refreshDailyActivities(userId);

      // Force refresh completed activities
      await _refreshCompletedActivities(userId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to complete activity: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh completed activities from Firebase
  Future<void> _refreshCompletedActivities(String userId) async {
    try {
      // Load all user activities from Firebase to get the latest completed ones
      await loadUserActivitiesFromFirebase(userId);
      print('Refreshed completed activities: ${completedActivities.length}');
    } catch (e) {
      print('Error refreshing completed activities: $e');
    }
  }

  // Public method to refresh completed activities
  Future<void> refreshCompletedActivities(String userId) async {
    await _refreshCompletedActivities(userId);
  }

  // Refresh daily activities after completion
  Future<void> _refreshDailyActivities(String userId) async {
    try {
      // Load fresh daily activities from Firebase
      await loadTodaysActivitiesFromFirebase(userId);

      // If no activities available, generate new ones
      if (_userActivities.isEmpty) {
        await _generateNewDailyActivities(userId);
      }
    } catch (e) {
      print('Error refreshing daily activities: $e');
    }
  }

  // Generate new daily activities
  Future<void> _generateNewDailyActivities(String userId) async {
    try {
      // Get available activities that haven't been completed today
      final today = DateTime.now();
      final completedToday = _userActivities
          .where((activity) =>
              activity.isCompleted &&
              activity.completedTime != null &&
              _isSameDay(activity.completedTime!, today))
          .map((activity) => activity.activity.id)
          .toList();

      // Filter out activities completed today
      final availableActivities = _availableActivities
          .where((activity) => !completedToday.contains(activity.id))
          .toList();

      // Select random activities for today (limit to 5-8)
      final random = math.Random();
      final selectedActivities = availableActivities.toList()..shuffle(random);

      final dailyCount = math.min(6, selectedActivities.length);
      final todaysActivities = selectedActivities.take(dailyCount).toList();

      // Create UserActivity instances for today
      final newUserActivities = todaysActivities.map((activity) {
        return UserActivity(
          id: '${activity.id}_${today.millisecondsSinceEpoch}',
          userId: userId,
          activityId: activity.id,
          activity: activity,
          status: ActivityStatus.pending,
          startTime: DateTime.now(),
        );
      }).toList();

      // Add to user activities
      _userActivities.addAll(newUserActivities);

      // Save to Firebase
      await saveDailyActivitiesToFirebase(userId, todaysActivities);
      await _saveUserActivitiesToLocal();

      print('Generated ${newUserActivities.length} new daily activities');
    } catch (e) {
      print('Error generating new daily activities: $e');
    }
  }

  // Reset activities for new day (keep completed activities visible)
  Future<void> resetActivitiesForNewDay(String userId) async {
    try {
      final today = DateTime.now();

      // Mark activities from previous days as available for repetition
      for (int i = 0; i < _userActivities.length; i++) {
        final activity = _userActivities[i];
        if (activity.completedTime != null &&
            !_isSameDay(activity.completedTime!, today)) {
          // Reset completed activities from previous days
          _userActivities[i] = activity.copyWith(
            status: ActivityStatus.pending,
            completedTime: null,
            notes: null,
          );
        }
      }

      // Generate new daily activities
      await _generateNewDailyActivities(userId);

      // Save to Firebase
      await saveDailyActivitiesToFirebase(
          userId, _availableActivities.take(6).toList());
      await _saveUserActivitiesToLocal();

      notifyListeners();
      print('Activities reset for new day');
    } catch (e) {
      print('Error resetting activities for new day: $e');
    }
  }

  // Start activity and sync with Firebase
  Future<void> startActivityWithFirebase(
      EcoActivity ecoActivity, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final userActivity = UserActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        activityId: ecoActivity.id,
        activity: ecoActivity,
        startTime: DateTime.now(),
        status: ActivityStatus.pending,
      );

      // Save to Firebase
      await _firebaseService.saveUserActivityToFirebase(userActivity);

      // Add to local list
      _userActivities.add(userActivity);
      _userActivities.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Save to local storage
      await _saveUserActivitiesToLocal();

      notifyListeners();
    } catch (e) {
      _setError('Failed to start activity: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Load daily activities from Firebase
  Future<void> loadDailyActivitiesFromFirebase(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Load daily activities from Firebase (but don't override available activities)
      await _firebaseService.getTodaysDailyActivities(userId);

      // Don't override available activities with daily activities
      // Daily activities are separate from available activities
      // Available activities should always contain all possible activities for filtering

      notifyListeners();
    } catch (e) {
      _setError('Failed to load daily activities: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save daily activities to Firebase
  Future<void> saveDailyActivitiesToFirebase(
      String userId, List<EcoActivity> activities) async {
    try {
      await _firebaseService.saveDailyActivities(userId, activities);
      print('Daily activities saved to Firebase');
    } catch (e) {
      _setError('Failed to save daily activities: $e');
      throw e;
    }
  }

  // Sync all data with Firebase
  Future<void> syncWithFirebase(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Load user activities
      await loadUserActivitiesFromFirebase(userId);

      // Load daily activities
      await loadDailyActivitiesFromFirebase(userId);

      // Always ensure available activities are loaded
      if (_availableActivities.isEmpty) {
        await _loadAvailableActivities();
      }

      print('Data synced with Firebase successfully');
    } catch (e) {
      _setError('Failed to sync with Firebase: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== HELPER METHODS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // ==================== LOCAL STORAGE METHODS ====================

  // Save user activities to local storage
  Future<void> _saveUserActivitiesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson =
          _userActivities.map((activity) => activity.toJson()).toList();
      await prefs.setString('user_activities', jsonEncode(activitiesJson));
    } catch (e) {
      print('Error saving user activities to local storage: $e');
    }
  }

  // Load user activities from local storage
  Future<void> _loadUserActivitiesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesString = prefs.getString('user_activities');

      if (activitiesString != null) {
        final List<dynamic> activitiesJson = jsonDecode(activitiesString);
        _userActivities = activitiesJson
            .map((json) =>
                UserActivity.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user activities from local storage: $e');
    }
  }
}
