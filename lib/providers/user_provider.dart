import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initialize user data from local storage
  Future<void> initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = User.fromJson(userData);
      } else {
        // Create a demo user for initial setup
        _currentUser = User(
          id: 'demo_user_1',
          name: 'Eco Warrior',
          email: 'eco@proplanet.com',
          joinedAt: DateTime.now(),
          totalPoints: 0,
          level: 1,
          badges: [],
          categoryPoints: {},
        );
        await saveUserToLocal(_currentUser!);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize user: ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save user data to local storage
  Future<void> saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      _error = 'Failed to save user data: ';
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateUser(User updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = updatedUser;
      await saveUserToLocal(updatedUser);
      _error = null;
    } catch (e) {
      _error = 'Failed to update user: ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add points to user
  Future<void> addPoints(int points, String category) async {
    if (_currentUser == null) return;

    final updatedCategoryPoints =
        Map<String, int>.from(_currentUser!.categoryPoints);
    updatedCategoryPoints[category] =
        (updatedCategoryPoints[category] ?? 0) + points;

    final newTotalPoints = _currentUser!.totalPoints + points;
    final newLevel = calculateLevel(newTotalPoints);

    final updatedUser = _currentUser!.copyWith(
      totalPoints: newTotalPoints,
      level: newLevel,
      categoryPoints: updatedCategoryPoints,
    );

    await updateUser(updatedUser);
  }

  // Calculate level based on total points
  int calculateLevel(int totalPoints) {
    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    if (totalPoints < 1500) return 5;
    if (totalPoints < 2100) return 6;
    if (totalPoints < 2800) return 7;
    if (totalPoints < 3600) return 8;
    if (totalPoints < 4500) return 9;
    return 10;
  }

  // Get points needed for next level
  int getPointsForNextLevel() {
    if (_currentUser == null) return 0;

    final currentLevel = _currentUser!.level;
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
      5500
    ];

    if (currentLevel >= 10) return 0; // Max level reached

    return levelThresholds[currentLevel] - _currentUser!.totalPoints;
  }

  // Add badge to user
  Future<void> addBadge(String badge) async {
    if (_currentUser == null) return;

    final updatedBadges = List<String>.from(_currentUser!.badges);
    if (!updatedBadges.contains(badge)) {
      updatedBadges.add(badge);

      final updatedUser = _currentUser!.copyWith(badges: updatedBadges);
      await updateUser(updatedUser);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to logout: ';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
