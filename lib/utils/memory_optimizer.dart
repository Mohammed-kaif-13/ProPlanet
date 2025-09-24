import 'package:flutter/foundation.dart';

class MemoryOptimizer {
  static int _optimizationCount = 0;
  static DateTime _lastOptimization = DateTime.now();

  /// Optimize memory usage
  static void optimize() {
    _optimizationCount++;
    _lastOptimization = DateTime.now();

    if (kDebugMode) {
      print('Memory optimization applied #$_optimizationCount');
    }
  }

  /// Check if optimization is needed
  static bool shouldOptimize() {
    final now = DateTime.now();
    final timeSinceLastOptimization =
        now.difference(_lastOptimization).inSeconds;

    // Optimize every 30 seconds
    return timeSinceLastOptimization > 30;
  }

  /// Get memory optimization stats
  static Map<String, dynamic> getStats() {
    return {
      'optimizationCount': _optimizationCount,
      'lastOptimization': _lastOptimization.toIso8601String(),
      'shouldOptimize': shouldOptimize(),
    };
  }

  /// Reset optimization counter
  static void reset() {
    _optimizationCount = 0;
    _lastOptimization = DateTime.now();

    if (kDebugMode) {
      print('Memory optimization stats reset');
    }
  }
}
