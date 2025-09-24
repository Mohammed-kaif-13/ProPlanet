import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/firebase_service.dart';

class PointsProvider with ChangeNotifier {
  int _currentPoints = 0;
  int _totalPoints = 0;
  int _currentLevel = 1;
  int _pointsToNextLevel = 100;
  int _currentStreak = 0;
  bool _isAnimating = false;
  String? _userId;
  DateTime? _lastResetDate;
  Map<String, int> _categoryPoints = {};

  // Real-time points animation
  Timer? _pointsAnimationTimer;
  int _animatedPoints = 0;
  int _targetPoints = 0;

  // Firebase service
  final FirebaseService _firebaseService = FirebaseService();

  // Getters
  int get currentPoints => _currentPoints;
  int get totalPoints => _totalPoints;
  int get currentLevel => _currentLevel;
  int get pointsToNextLevel => _pointsToNextLevel;
  int get currentStreak => _currentStreak;
  bool get isAnimating => _isAnimating;
  int get animatedPoints => _animatedPoints;
  Map<String, int> get categoryPoints => _categoryPoints;
  DateTime? get lastResetDate => _lastResetDate;

  // Level thresholds
  static const List<int> _levelThresholds = [
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

  // Initialize points system with Firebase integration
  Future<void> initializePoints({
    required String userId,
    required int totalPoints,
    required int currentStreak,
    Map<String, int>? categoryPoints,
  }) async {
    _userId = userId;
    _totalPoints = totalPoints;
    _currentStreak = currentStreak;
    _categoryPoints = categoryPoints ?? {};
    _calculateLevel();
    _animatedPoints = _totalPoints;

    // Check if we need to reset daily points
    await _checkAndResetDailyPoints();

    notifyListeners();
  }

  // Load points from Firebase
  Future<void> loadPointsFromFirebase(String userId) async {
    try {
      _userId = userId;

      // Get user data from Firebase
      final userData = await _firebaseService.getUserData(userId);
      if (userData != null) {
        _totalPoints = userData.totalPoints;
        _currentStreak = userData.streak;
        _categoryPoints = userData.categoryPoints;
        _calculateLevel();
        _animatedPoints = _totalPoints;

        // Load today's daily points from Firebase
        await _loadTodaysDailyPoints();

        // Check if we need to reset daily points
        await _checkAndResetDailyPoints();

        // Refresh streak calculation to ensure accuracy
        await _refreshStreakFromFirebase(userId);
      }

      notifyListeners();
    } catch (e) {
      print('Error loading points from Firebase: $e');
      // Initialize with default values if Firebase fails
      _totalPoints = 0;
      _currentStreak = 0;
      _categoryPoints = {};
      _currentPoints = 0;
      _calculateLevel();
      _animatedPoints = _totalPoints;
      notifyListeners();
    }
  }

  // Load today's daily points from Firebase
  Future<void> _loadTodaysDailyPoints() async {
    if (_userId == null) {
      print('Cannot load daily points: userId is null');
      return;
    }

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      print('Loading daily points for date: $today, userId: $_userId');
      final dailyPoints =
          await _firebaseService.getDailyPoints(_userId!, today);
      _currentPoints = dailyPoints;
      print('Loaded today\'s daily points: $dailyPoints');
    } catch (e) {
      print('Error loading today\'s daily points: $e');
      _currentPoints = 0;
    }
  }

  // Check if daily points need to be reset (new day)
  Future<void> _checkAndResetDailyPoints() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      // Only reset if we haven't loaded today's points yet
      if (_currentPoints == 0) {
        _currentPoints = 0;
        _lastResetDate = today;

        // Save the reset to Firebase
        if (_userId != null) {
          await _saveDailyPointsToFirebase();
        }
      } else {
        // Update the reset date without changing points
        _lastResetDate = today;
      }
    }
  }

  // Save daily points to Firebase
  Future<void> _saveDailyPointsToFirebase() async {
    if (_userId == null) return;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firebaseService.saveDailyPoints(_userId!, today, _currentPoints);
    } catch (e) {
      print('Error saving daily points to Firebase: $e');
    }
  }

  // Add points with real-time animation and Firebase sync
  Future<void> addPoints(
    int points, {
    String category = 'general',
    Duration animationDuration = const Duration(milliseconds: 1500),
  }) async {
    if (points <= 0) return;

    _isAnimating = true;
    _targetPoints = _totalPoints + points;
    _currentPoints += points;

    // Update category points
    _categoryPoints[category] = (_categoryPoints[category] ?? 0) + points;

    notifyListeners();

    // Start smooth animation
    _startPointsAnimation(animationDuration);

    // Check for level up
    final oldLevel = _currentLevel;
    _calculateLevel();

    // Save to Firebase
    if (_userId != null) {
      try {
        await _firebaseService.addUserPoints(_userId!, points, category);
        await _saveDailyPointsToFirebase();
      } catch (e) {
        print('Error saving points to Firebase: $e');
      }
    }

    if (_currentLevel > oldLevel) {
      // Level up animation will be handled by the UI
      await Future.delayed(animationDuration);
    }

    _isAnimating = false;
    notifyListeners();
  }

  // Update points without Firebase sync (for when points are already saved)
  void updatePointsFromFirebase({
    required int totalPoints,
    required int dailyPoints,
    required Map<String, int> categoryPoints,
  }) {
    _totalPoints = totalPoints;
    _currentPoints = dailyPoints;
    _categoryPoints = categoryPoints;
    _calculateLevel();
    _animatedPoints = _totalPoints;
    notifyListeners();
  }

  // Start smooth points animation
  void _startPointsAnimation(Duration duration) {
    _pointsAnimationTimer?.cancel();

    const int steps = 60; // 60 steps for smooth animation
    final int stepDuration = duration.inMilliseconds ~/ steps;
    final int pointsPerStep = (_targetPoints - _totalPoints) ~/ steps;

    int currentStep = 0;

    _pointsAnimationTimer = Timer.periodic(
      Duration(milliseconds: stepDuration),
      (timer) {
        currentStep++;

        if (currentStep >= steps) {
          _totalPoints = _targetPoints;
          _animatedPoints = _totalPoints;
          timer.cancel();
          _isAnimating = false;
          notifyListeners();
        } else {
          _totalPoints += pointsPerStep;
          _animatedPoints = _totalPoints;
          notifyListeners();
        }
      },
    );
  }

  // Calculate current level based on total points
  void _calculateLevel() {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (_totalPoints >= _levelThresholds[i]) {
        _currentLevel = i + 1;
        _pointsToNextLevel = i + 1 < _levelThresholds.length
            ? _levelThresholds[i + 1] - _totalPoints
            : 0;
        break;
      }
    }
  }

  // Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    if (_currentLevel >= _levelThresholds.length) return 1.0;

    final currentThreshold = _levelThresholds[_currentLevel - 1];
    final nextThreshold = _levelThresholds[_currentLevel];
    final progress =
        (_totalPoints - currentThreshold) / (nextThreshold - currentThreshold);

    return progress.clamp(0.0, 1.0);
  }

  // Get points needed for next level
  int get pointsNeededForNextLevel {
    if (_currentLevel >= _levelThresholds.length) return 0;
    return _levelThresholds[_currentLevel] - _totalPoints;
  }

  // Refresh streak from Firebase to ensure accuracy
  Future<void> _refreshStreakFromFirebase(String userId) async {
    try {
      // Get fresh user data to get updated streak
      final userData = await _firebaseService.getUserData(userId);
      if (userData != null) {
        _currentStreak = userData.streak;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing streak from Firebase: $e');
    }
  }

  // Update streak
  void updateStreak(int newStreak) {
    _currentStreak = newStreak;
    notifyListeners();
  }

  // Add to streak
  void addStreakDay() {
    _currentStreak++;
    notifyListeners();
  }

  // Reset daily points (call at start of new day)
  void resetDailyPoints() {
    _currentPoints = 0;
    notifyListeners();
  }

  // Get daily goal progress
  double getDailyGoalProgress(int dailyGoal) {
    return (_currentPoints / dailyGoal).clamp(0.0, 1.0);
  }

  // Check if daily goal is completed
  bool isDailyGoalCompleted(int dailyGoal) {
    return _currentPoints >= dailyGoal;
  }

  // Get points breakdown by category
  Map<String, int> getPointsBreakdown(List<dynamic> completedActivities) {
    final breakdown = <String, int>{};

    for (final activity in completedActivities) {
      final category = activity.category.toString().split('.').last;
      breakdown[category] =
          (breakdown[category] ?? 0) + (activity.points as int);
    }

    return breakdown;
  }

  // Get weekly points total
  int getWeeklyPoints(List<dynamic> weeklyActivities) {
    return weeklyActivities.fold(
      0,
      (sum, activity) => sum + (activity.points as int),
    );
  }

  // Get monthly points total
  int getMonthlyPoints(List<dynamic> monthlyActivities) {
    return monthlyActivities.fold(
      0,
      (sum, activity) => sum + (activity.points as int),
    );
  }

  // Get environmental impact based on points
  Map<String, double> getEnvironmentalImpact() {
    return {
      'co2Saved': _totalPoints * 0.5, // kg of CO2 saved per point
      'waterSaved': _totalPoints * 2.3, // liters of water saved per point
      'energySaved': _totalPoints * 1.2, // kWh of energy saved per point
      'treesEquivalent': _totalPoints / 50.0, // trees equivalent per 50 points
    };
  }

  // Get achievement progress
  Map<String, dynamic> getAchievementProgress() {
    return {
      'firstActivity': _totalPoints > 0 ? 1.0 : 0.0,
      'hundredPoints': (_totalPoints / 100).clamp(0.0, 1.0),
      'fiveHundredPoints': (_totalPoints / 500).clamp(0.0, 1.0),
      'thousandPoints': (_totalPoints / 1000).clamp(0.0, 1.0),
      'levelFive': (_currentLevel / 5).clamp(0.0, 1.0),
      'levelTen': (_currentLevel / 10).clamp(0.0, 1.0),
      'sevenDayStreak': (_currentStreak / 7).clamp(0.0, 1.0),
      'thirtyDayStreak': (_currentStreak / 30).clamp(0.0, 1.0),
    };
  }

  // Get motivational message based on progress
  String getMotivationalMessage() {
    if (_currentLevel >= 10) {
      return "You're an Eco Master! 🌟";
    } else if (levelProgress > 0.8) {
      return "Almost at the next level! Keep going! 🚀";
    } else if (_currentStreak >= 7) {
      return "Amazing streak! You're on fire! 🔥";
    } else if (_currentPoints >= 50) {
      return "Great progress today! 💪";
    } else if (_totalPoints >= 1000) {
      return "You're making a real difference! 🌱";
    } else {
      return "Every action counts! Keep it up! ⭐";
    }
  }

  // Get next milestone
  Map<String, dynamic> getNextMilestone() {
    final milestones = [
      {
        'points': 100,
        'title': 'First Hundred',
        'description': 'Earn your first 100 points',
      },
      {
        'points': 500,
        'title': 'Eco Enthusiast',
        'description': 'Reach 500 points',
      },
      {
        'points': 1000,
        'title': 'Green Champion',
        'description': 'Reach 1000 points',
      },
      {
        'points': 2000,
        'title': 'Eco Warrior',
        'description': 'Reach 2000 points',
      },
      {
        'points': 5000,
        'title': 'Eco Master',
        'description': 'Reach 5000 points',
      },
    ];

    for (final milestone in milestones) {
      final milestonePoints = milestone['points'] as int;
      if (_totalPoints < milestonePoints) {
        return {
          'points': milestonePoints,
          'title': milestone['title'],
          'description': milestone['description'],
          'progress': _totalPoints / milestonePoints,
          'pointsNeeded': milestonePoints - _totalPoints,
        };
      }
    }

    return {
      'points': 0,
      'title': 'Max Level Reached!',
      'description': 'You\'ve achieved the highest level!',
      'progress': 1.0,
      'pointsNeeded': 0,
    };
  }

  @override
  void dispose() {
    _pointsAnimationTimer?.cancel();
    super.dispose();
  }
}
