import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/memory_optimizer.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Initialize auth state listener
  void initializeAuth() {
    _firebaseService.authStateChanges.listen((firebase_auth.User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Add timeout to prevent infinite loading
      final userData = await _firebaseService.getUserData(uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Return a default user on timeout instead of throwing
          return User(
            id: uid,
            name: 'New User',
            email: 'user@example.com',
            joinedAt: DateTime.now(),
            totalPoints: 0,
            level: 1,
            streak: 0,
          );
        },
      );

      if (userData != null) {
        _currentUser = userData;
      } else {
        // If user data doesn't exist, create a basic user profile
        _currentUser = User(
          id: uid,
          name: 'New User',
          email: 'user@example.com',
          joinedAt: DateTime.now(),
          totalPoints: 0,
          level: 1,
          streak: 0,
        );
      }
    } catch (e) {
      print('Error loading user data: $e');

      // ALWAYS create a fallback user - NO EXCEPTIONS
      _currentUser = User(
        id: uid,
        name: 'New User',
        email: 'user@example.com',
        joinedAt: DateTime.now(),
        totalPoints: 0,
        level: 1,
        streak: 0,
      );

      // Clear any previous errors to prevent UI issues
      _error = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        await _loadUserData(userCredential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create account with email and password
  Future<bool> createAccountWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential =
          await _firebaseService.createUserWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        await _loadUserData(userCredential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      // Extract meaningful error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      _error = errorMessage;
      print('Account Creation Error: $errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _firebaseService.signInWithGoogle();

      if (userCredential?.user != null) {
        await _loadUserData(userCredential!.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      // Extract meaningful error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      _error = errorMessage;
      print('Google Sign-In Error: $errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Reload user data
      if (_currentUser != null) {
        await _loadUserData(_currentUser!.id);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user data in Firestore
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_currentUser == null) return false;

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.updateUserData(_currentUser!.id, data);

      // Reload user data
      await _loadUserData(_currentUser!.id);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add points to user
  Future<bool> addPoints(int points, String category) async {
    try {
      if (_currentUser == null) return false;

      await _firebaseService.updateUserPoints(
        _currentUser!.id,
        points,
        category,
      );

      // Reload user data to get updated points
      await _loadUserData(_currentUser!.id);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Save user activity
  Future<bool> saveUserActivity(Map<String, dynamic> activityData) async {
    try {
      if (_currentUser == null) return false;

      await _firebaseService.saveUserActivity(_currentUser!.id, activityData);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Get user activities
  Future<List<Map<String, dynamic>>> getUserActivities() async {
    try {
      if (_currentUser == null) return [];

      final activities = await _firebaseService
          .getUserActivitiesFromFirebase(_currentUser!.id);
      return activities.map((activity) => activity.toJson()).toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      return await _firebaseService.getLeaderboard(limit: limit);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();

    // Optimize memory usage when clearing errors
    if (MemoryOptimizer.shouldOptimize()) {
      MemoryOptimizer.optimize();
    }
  }
}
