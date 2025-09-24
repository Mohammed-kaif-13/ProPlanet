import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../config/google_signin_config.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignInConfig.googleSignIn;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<firebase_auth.UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Create user with email and password
  Future<firebase_auth.UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final firebase_auth.UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _createUserDocument(result.user!, name, email);

      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Google Sign-In
  Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      // Create a new credential
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential result =
          await _auth.signInWithCredential(credential);

      if (result.user == null) {
        throw Exception('Failed to create Firebase user account');
      }

      // Create or update user document in Firestore
      try {
        await _createUserDocument(
          result.user!,
          result.user!.displayName ?? 'User',
          result.user!.email ?? '',
        );
      } catch (e) {
        // Log the error but don't fail the sign-in process
        log('Warning: Failed to create user document: $e');
      }

      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Google Sign-In Error: $e');
      if (e.toString().contains('ApiException: 10')) {
        throw Exception(
            'Google Sign-In configuration error. Please contact support.');
      } else if (e.toString().contains('network_error') ||
          e.toString().contains('network')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('cancelled')) {
        throw Exception('Google sign-in was cancelled');
      } else {
        throw Exception('Google sign-in failed: $e');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      await _updateUserDocument(user.uid, {
        if (displayName != null) 'name': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Get user data from Firestore
  Future<User?> getUserData(String uid) async {
    try {
      // First check and reset streak if needed
      await checkAndResetStreak(uid);

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Use the completely safe User.fromFirestore method
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Error getting user data: $e');
      // Return a default user instead of throwing exception
      return User(
        id: uid,
        name: 'User',
        email: 'user@example.com',
        joinedAt: DateTime.now(),
        totalPoints: 0,
        level: 1,
        streak: 0,
      );
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
      firebase_auth.User user, String name, String email) async {
    try {
      final userData = {
        'uid': user.uid,
        'name': name,
        'email': email,
        'photoURL': user.photoURL ?? '',
        'totalPoints': 0,
        'level': 1,
        'streak': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'preferences': {
          'notifications': true,
          'darkMode': false,
          'language': 'en',
        },
        'achievements': <String>[],
        'badges': <String>[],
        'environmentalImpact': {
          'co2Saved': 0.0,
          'waterSaved': 0.0,
          'energySaved': 0.0,
          'treesEquivalent': 0.0,
        },
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      log('Error creating user document: $e');
      throw Exception('Failed to create user document: $e');
    }
  }

  // Update user document in Firestore
  Future<void> _updateUserDocument(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please check your email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Get user activities from Firestore
  Future<List<Map<String, dynamic>>> getUserActivities(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get user activities: $e');
    }
  }

  // Save user activity to Firestore
  Future<void> saveUserActivity(
    String uid,
    Map<String, dynamic> activityData,
  ) async {
    try {
      activityData['completedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .add(activityData);
    } catch (e) {
      throw Exception('Failed to save activity: $e');
    }
  }

  // Update user points and level
  Future<void> updateUserPoints(String uid, int points, String category) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'totalPoints': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update category points
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('categoryPoints')
          .doc(category)
          .set({
        'category': category,
        'points': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update points: $e');
    }
  }

  // Get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  // ==================== USER ACTIVITIES MANAGEMENT ====================

  // Save user activity to Firebase
  Future<void> saveUserActivityToFirebase(UserActivity userActivity) async {
    try {
      await _firestore
          .collection('users')
          .doc(userActivity.userId)
          .collection('activities')
          .doc(userActivity.id)
          .set(userActivity.toFirestore());

      log('User activity saved: ${userActivity.id}');
    } catch (e) {
      log('Error saving user activity: $e');
      throw Exception('Failed to save activity: $e');
    }
  }

  // Get user activities from Firebase
  Future<List<UserActivity>> getUserActivitiesFromFirebase(
      String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting user activities: $e');
      throw Exception('Failed to get user activities: $e');
    }
  }

  // Get today's activities for a user
  Future<List<UserActivity>> getTodaysActivities(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting today\'s activities: $e');
      throw Exception('Failed to get today\'s activities: $e');
    }
  }

  // Update user activity status
  Future<void> updateUserActivityStatus(
    String userId,
    String activityId,
    ActivityStatus status, {
    String? notes,
    List<String>? photos,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (status == ActivityStatus.completed) {
        updateData['completedTime'] = Timestamp.now();
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (photos != null) {
        updateData['photos'] = photos;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .update(updateData);

      log('User activity status updated: $activityId');
    } catch (e) {
      log('Error updating user activity status: $e');
      throw Exception('Failed to update activity status: $e');
    }
  }

  // ==================== POINTS AND PROGRESS MANAGEMENT ====================

  // Add points to user and update level/streak
  Future<void> addUserPoints(String userId, int points, String category) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = userDoc.data()!;
        final currentPoints = userData['totalPoints'] ?? 0;
        final currentStreak = userData['streak'] ?? 0;
        final categoryPoints =
            Map<String, int>.from(userData['categoryPoints'] ?? {});

        // Calculate new values
        final newTotalPoints = currentPoints + points;
        final newLevel = _calculateLevel(newTotalPoints);

        // Calculate streak based on consecutive days
        final newStreak = await _calculateStreak(userId, currentStreak);

        // Update category points
        categoryPoints[category] = (categoryPoints[category] ?? 0) + points;

        // Update user document
        transaction.update(userRef, {
          'totalPoints': newTotalPoints,
          'level': newLevel,
          'streak': newStreak,
          'categoryPoints': categoryPoints,
          'lastActivityDate': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      });

      // Save daily points separately
      await _saveDailyPointsAfterActivity(userId, points);

      log('Points added: $points to user $userId');
    } catch (e) {
      log('Error adding user points: $e');
      throw Exception('Failed to add points: $e');
    }
  }

  // ==================== DAILY ACTIVITIES MANAGEMENT ====================

  // Save daily activities list to Firebase
  Future<void> saveDailyActivities(
      String userId, List<EcoActivity> activities) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final activitiesData =
          activities.map((activity) => activity.toJson()).toList();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyActivities')
          .doc(dateKey)
          .set({
        'date': Timestamp.fromDate(today),
        'activities': activitiesData,
        'createdAt': Timestamp.now(),
      });

      log('Daily activities saved for: $userId on $dateKey');
    } catch (e) {
      log('Error saving daily activities: $e');
      throw Exception('Failed to save daily activities: $e');
    }
  }

  // Get daily activities for a specific date
  Future<List<EcoActivity>> getDailyActivities(
      String userId, DateTime date) async {
    try {
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyActivities')
          .doc(dateKey)
          .get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data()!;
      final activitiesData = data['activities'] as List<dynamic>? ?? [];

      return activitiesData
          .map((activityJson) =>
              EcoActivity.fromJson(Map<String, dynamic>.from(activityJson)))
          .toList();
    } catch (e) {
      log('Error getting daily activities: $e');
      throw Exception('Failed to get daily activities: $e');
    }
  }

  // Get today's daily activities
  Future<List<EcoActivity>> getTodaysDailyActivities(String userId) async {
    return getDailyActivities(userId, DateTime.now());
  }

  // ==================== USER STATISTICS ====================

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;

      // Get completed activities count
      final completedActivitiesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .get();

      // Get this week's activities
      final weekStart =
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final thisWeekQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      return {
        'totalPoints': userData['totalPoints'] ?? 0,
        'level': userData['level'] ?? 1,
        'streak': userData['streak'] ?? 0,
        'completedActivities': completedActivitiesQuery.docs.length,
        'thisWeekActivities': thisWeekQuery.docs.length,
        'categoryPoints': userData['categoryPoints'] ?? {},
        'environmentalImpact': userData['environmentalImpact'] ?? {},
        'achievements': userData['achievements'] ?? [],
        'badges': userData['badges'] ?? [],
      };
    } catch (e) {
      log('Error getting user statistics: $e');
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  // Calculate user level based on total points
  int _calculateLevel(int totalPoints) {
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

    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (totalPoints >= levelThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  // Save daily points for a specific date
  Future<void> saveDailyPoints(String userId, String date, int points) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPoints')
          .doc(date)
          .set({
        'date': date,
        'points': points,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error saving daily points: $e');
      throw Exception('Failed to save daily points: $e');
    }
  }

  // Save daily points after activity completion (increment existing or create new)
  Future<void> _saveDailyPointsAfterActivity(String userId, int points) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final dailyPointsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPoints')
          .doc(today);

      await _firestore.runTransaction((transaction) async {
        final dailyPointsDoc = await transaction.get(dailyPointsRef);

        if (dailyPointsDoc.exists) {
          // Increment existing daily points
          final currentDailyPoints = dailyPointsDoc.data()?['points'] ?? 0;
          transaction.update(dailyPointsRef, {
            'points': currentDailyPoints + points,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new daily points entry
          transaction.set(dailyPointsRef, {
            'date': today,
            'points': points,
            'timestamp': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      log('Daily points updated: +$points for user $userId on $today');
    } catch (e) {
      log('Error saving daily points after activity: $e');

      // Check if it's a permission error
      if (e.toString().contains('PERMISSION_DENIED')) {
        log('❌ FIRESTORE PERMISSION ERROR: Please update your Firestore security rules!');
        log('📋 See firestore_rules_deployment_guide.md for instructions');
      }

      // Don't throw exception here to avoid breaking the main flow
    }
  }

  // Get daily points for a specific date
  Future<int> getDailyPoints(String userId, String date) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPoints')
          .doc(date)
          .get();

      if (doc.exists) {
        return doc.data()?['points'] ?? 0;
      }
      return 0;
    } catch (e) {
      log('Error getting daily points: $e');

      // Check if it's a permission error
      if (e.toString().contains('PERMISSION_DENIED')) {
        log('❌ FIRESTORE PERMISSION ERROR: Please update your Firestore security rules!');
        log('📋 See firestore_rules_deployment_guide.md for instructions');
      }

      return 0; // Return 0 if there's an error
    }
  }

  // Get daily points history for a date range
  Future<List<Map<String, dynamic>>> getDailyPointsHistory(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPoints')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .orderBy('date')
          .get();

      return query.docs
          .map((doc) => {
                'date': doc.data()['date'],
                'points': doc.data()['points'] ?? 0,
                'timestamp': doc.data()['timestamp'],
              })
          .toList();
    } catch (e) {
      log('Error getting daily points history: $e');
      return [];
    }
  }

  // Calculate streak based on consecutive days of activity
  Future<int> _calculateStreak(String userId, int currentStreak) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Check if user has activity today
      final todayActivityQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPoints')
          .doc(todayStr)
          .get();

      if (todayActivityQuery.exists) {
        // User has activity today, check consecutive days
        int streak = 1;
        DateTime checkDate = today.subtract(const Duration(days: 1));

        while (true) {
          final checkDateStr =
              '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          final dayActivityQuery = await _firestore
              .collection('users')
              .doc(userId)
              .collection('dailyPoints')
              .doc(checkDateStr)
              .get();

          if (dayActivityQuery.exists) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

        return streak;
      } else {
        // No activity today, reset streak
        return 0;
      }
    } catch (e) {
      log('Error calculating streak: $e');
      return currentStreak; // Return current streak if calculation fails
    }
  }

  // Check and reset streak if user missed a day
  Future<void> checkAndResetStreak(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final lastActivityDate = userData['lastActivityDate'] as Timestamp?;
      final currentStreak = userData['streak'] ?? 0;

      if (lastActivityDate != null) {
        final lastActivity = lastActivityDate.toDate();
        final today = DateTime.now();
        final daysDifference = today.difference(lastActivity).inDays;

        // If more than 1 day has passed since last activity, reset streak
        if (daysDifference > 1 && currentStreak > 0) {
          await _firestore.collection('users').doc(userId).update({
            'streak': 0,
            'lastStreakUpdate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      log('Error checking and resetting streak: $e');
    }
  }

  // Update user streak
  Future<void> updateUserStreak(String userId, int newStreak) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'streak': newStreak,
        'lastStreakUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error updating user streak: $e');
      throw Exception('Failed to update streak: $e');
    }
  }

  // Get user points summary
  Future<Map<String, dynamic>> getUserPointsSummary(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {
          'totalPoints': 0,
          'currentLevel': 1,
          'streak': 0,
          'categoryPoints': {},
          'dailyPoints': 0,
          'weeklyPoints': 0,
          'monthlyPoints': 0,
        };
      }

      final userData = userDoc.data()!;
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get daily points
      final dailyPoints = await getDailyPoints(userId, today);

      // Get weekly points
      final weeklyHistory = await getDailyPointsHistory(userId, weekAgo, now);
      final weeklyPoints =
          weeklyHistory.fold(0, (sum, day) => sum + (day['points'] as int));

      // Get monthly points
      final monthlyHistory = await getDailyPointsHistory(userId, monthAgo, now);
      final monthlyPoints =
          monthlyHistory.fold(0, (sum, day) => sum + (day['points'] as int));

      return {
        'totalPoints': userData['totalPoints'] ?? 0,
        'currentLevel': userData['level'] ?? 1,
        'streak': userData['streak'] ?? 0,
        'categoryPoints': userData['categoryPoints'] ?? {},
        'dailyPoints': dailyPoints,
        'weeklyPoints': weeklyPoints,
        'monthlyPoints': monthlyPoints,
      };
    } catch (e) {
      log('Error getting user points summary: $e');
      return {
        'totalPoints': 0,
        'currentLevel': 1,
        'streak': 0,
        'categoryPoints': {},
        'dailyPoints': 0,
        'weeklyPoints': 0,
        'monthlyPoints': 0,
      };
    }
  }

  // ==================== REAL-TIME LISTENERS ====================

  // Listen to user data changes
  Stream<User> listenToUserData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => User.fromFirestore(doc));
  }

  // Listen to user activities changes
  Stream<List<UserActivity>> listenToUserActivities(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserActivity.fromFirestore(doc))
            .toList());
  }

  // Listen to today's activities
  Stream<List<UserActivity>> listenToTodaysActivities(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserActivity.fromFirestore(doc))
            .toList());
  }
}
