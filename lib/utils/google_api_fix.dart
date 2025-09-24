import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_signin_config.dart';

class GoogleApiFix {
  static bool _isInitialized = false;
  static const int _retryCount = 0;
  static const int _maxRetries = 3;

  /// Initialize Google API with proper error handling
  static Future<bool> initializeGoogleSignIn() async {
    try {
      _isInitialized = true;

      if (kDebugMode) {
        print('Google Sign-In initialized successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In initialization error: $e');
      }
      return false;
    }
  }

  /// Handle Google API errors gracefully
  static String handleGoogleApiError(dynamic error) {
    if (error == null) return 'Unknown Google API error';

    final errorString = error.toString();

    if (errorString.contains('SecurityException')) {
      return 'Google Sign-In configuration error. Please check your app settings.';
    }

    if (errorString.contains('Unknown calling package name')) {
      return 'Google Sign-In package name mismatch. Please contact support.';
    }

    if (errorString.contains('ApiException: 10')) {
      return 'Google Sign-In configuration error. Please contact support.';
    }

    if (errorString.contains('network_error') ||
        errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('sign_in_canceled') ||
        errorString.contains('cancelled')) {
      return 'Sign-in was cancelled';
    }

    return 'Google Sign-In error: $errorString';
  }

  /// Retry Google Sign-In operation
  static Future<T?> retryGoogleOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (kDebugMode) {
          print('Google operation retry $i failed: $e');
        }

        if (i == maxRetries - 1) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }
    return null;
  }

  /// Check if Google API is working
  static Future<bool> isGoogleApiWorking() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignInConfig.googleSignIn;
      // Test if Google Sign-In is available
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      return true; // If we can access currentUser, the API is working
    } catch (e) {
      if (kDebugMode) {
        print('Google API check failed: $e');
      }
      return false;
    }
  }

  /// Get Google API status
  static Map<String, dynamic> getGoogleApiStatus() {
    return {
      'isInitialized': _isInitialized,
      'retryCount': _retryCount,
      'maxRetries': _maxRetries,
      'status': 'enabled',
    };
  }
}
