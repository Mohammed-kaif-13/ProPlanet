import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('Error: $error');
      print('Stack trace: $stackTrace');
    }

    // Log error to console in debug mode
    debugPrint('Error occurred: $error');
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static String getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    String errorString = error.toString();

    // Clean up common error message patterns
    if (errorString.contains('Exception: ')) {
      errorString = errorString.replaceFirst('Exception: ', '');
    }

    // Handle specific Firebase errors
    if (errorString.contains('network_error') ||
        errorString.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (errorString.contains('sign_in_canceled') ||
        errorString.contains('cancelled')) {
      return 'Sign-in was cancelled';
    }

    if (errorString.contains('user-not-found')) {
      return 'No account found with this email address.';
    }

    if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }

    if (errorString.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    }

    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    }

    if (errorString.contains('invalid-email')) {
      return 'Invalid email address. Please check your email.';
    }

    if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    if (errorString.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled.';
    }

    return errorString;
  }
}
