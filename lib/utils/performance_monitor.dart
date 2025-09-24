import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static bool _isMonitoring = false;
  static int _frameCount = 0;
  static int _lastFrameTime = 0;
  static final List<int> _frameTimes = [];

  static void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrame);

    if (kDebugMode) {
      print('Performance monitoring started');
    }
  }

  static void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrame);

    if (kDebugMode) {
      print('Performance monitoring stopped');
      _printPerformanceStats();
    }
  }

  static void _onFrame(List<FrameTiming> timings) {
    if (!_isMonitoring) return;

    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds;
      _frameTimes.add(frameTime);
      _frameCount++;

      // Keep only last 50 frame times to reduce memory usage
      if (_frameTimes.length > 50) {
        _frameTimes.removeAt(0);
      }

      // Check for performance issues - only log severe issues
      if (frameTime > 50000) {
        // More than 50ms (severe performance issue)
        if (kDebugMode) {
          print('SEVERE: Slow frame detected: ${frameTime / 1000}ms');
        }
      } else if (frameTime > 16667) {
        // More than 16.67ms (60fps threshold)
        // Only log occasionally to reduce spam
        if (_frameCount % 20 == 0 && kDebugMode) {
          print('Slow frame detected: ${frameTime / 1000}ms');
        }
      }
    }
  }

  static void _printPerformanceStats() {
    if (_frameTimes.isEmpty) return;

    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);

    print('Performance Stats:');
    print('  Frames analyzed: $_frameCount');
    print(
        '  Average frame time: ${(avgFrameTime / 1000).toStringAsFixed(2)}ms');
    print('  Max frame time: ${(maxFrameTime / 1000).toStringAsFixed(2)}ms');
    print('  Min frame time: ${(minFrameTime / 1000).toStringAsFixed(2)}ms');
    print('  Average FPS: ${(1000000 / avgFrameTime).toStringAsFixed(1)}');
  }

  static void logMemoryUsage() {
    if (kDebugMode) {
      // This is a placeholder - in a real app you might use a memory monitoring package
      print('Memory usage logged at ${DateTime.now()}');
    }
  }
}
