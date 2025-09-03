import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  NotificationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get unread notifications
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  // Get notifications count
  int get unreadCount => unreadNotifications.length;

  // Initialize notifications
  Future<void> initializeNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadNotifications();
      await _loadSettings();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize notifications: ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('app_notifications');
      
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications = notificationsList
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
    } catch (e) {
      _notifications = [];
    }
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('app_notifications', jsonEncode(notificationsJson));
    } catch (e) {
      _error = 'Failed to save notifications: ';
      notifyListeners();
    }
  }

  // Load settings from local storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null) {
        final settingsData = jsonDecode(settingsJson);
        _settings = NotificationSettings.fromJson(settingsData);
      }
    } catch (e) {
      _settings = NotificationSettings();
    }
  }

  // Save settings to local storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', jsonEncode(_settings.toJson()));
    } catch (e) {
      _error = 'Failed to save settings: ';
      notifyListeners();
    }
  }

  // Update notification settings
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();

    // Show the notification
    await _showNotification(notification);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _saveNotifications();
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // Show notification using flutter_local_notifications
  Future<void> _showNotification(AppNotification notification) async {
    try {
      final notificationService = NotificationService();
      
      if (notification.type == NotificationType.achievement || 
          notification.type == NotificationType.milestone) {
        await notificationService.showAchievementNotification(
          title: notification.title,
          body: notification.body,
          id: notification.id.hashCode,
          payload: notification.data != null ? jsonEncode(notification.data) : null,
        );
      } else {
        await notificationService.showNotification(
          title: notification.title,
          body: notification.body,
          id: notification.id.hashCode,
          payload: notification.data != null ? jsonEncode(notification.data) : null,
        );
      }
    } catch (e) {
      debugPrint('Error showing notification: ');
    }
  }

  // Get random eco tip
  String _getRandomEcoTip() {
    final tips = [
      'Did you know? LED bulbs use 75% less energy than incandescent bulbs!',
      'Tip: A 5-minute shower saves about 25 gallons of water compared to a bath.',
      'Fun fact: Composting can reduce your household waste by up to 30%!',
      'Remember: Bringing reusable bags can save hundreds of plastic bags per year.',
      'Eco tip: Adjusting your thermostat by just 2 degrees can save 2000 pounds of CO2 annually.',
      'Did you know? Eating one plant-based meal per day can save 200,000 gallons of water per year.',
      'Tip: Walking or biking for short trips reduces carbon emissions and improves your health!',
      'Fun fact: Recycling one aluminum can saves enough energy to run a TV for 3 hours.',
    ];
    
    return tips[Random().nextInt(tips.length)];
  }

  // Send achievement notification
  Future<void> sendAchievementNotification(String title, String body, {Map<String, dynamic>? data}) async {
    if (!_settings.achievements) return;

    final notification = AppNotification(
      id: 'achievement_',
      title: title,
      body: body,
      type: NotificationType.achievement,
      scheduledTime: DateTime.now(),
      data: data,
    );

    await addNotification(notification);
  }

  // Send milestone notification
  Future<void> sendMilestoneNotification(String title, String body, {Map<String, dynamic>? data}) async {
    if (!_settings.milestones) return;

    final notification = AppNotification(
      id: 'milestone_',
      title: title,
      body: body,
      type: NotificationType.milestone,
      scheduledTime: DateTime.now(),
      data: data,
    );

    await addNotification(notification);
  }

  // Send activity reminder notification
  Future<void> sendActivityReminderNotification(String activityTitle) async {
    if (!_settings.activityReminders) return;

    final notification = AppNotification(
      id: 'reminder_',
      title: ' Activity Reminder',
      body: 'Don\'t forget to complete: ',
      type: NotificationType.activityReminder,
      scheduledTime: DateTime.now(),
    );

    await addNotification(notification);
  }

  // Check and send level up notification
  Future<void> checkAndSendLevelUpNotification(int newLevel, int oldLevel) async {
    if (newLevel > oldLevel) {
      await sendAchievementNotification(
        ' Level Up!',
        'Congratulations! You\'ve reached level . Keep up the great eco work!',
        data: {'level': newLevel},
      );
    }
  }

  // Check and send streak notification
  Future<void> checkAndSendStreakNotification(int streak) async {
    if (streak > 0 && streak % 7 == 0) { // Weekly streak milestones
      await sendMilestoneNotification(
        ' Amazing Streak!',
        'You\'ve completed eco activities for  days in a row! You\'re making a real difference!',
        data: {'streak': streak},
      );
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      final notificationService = NotificationService();
      return await notificationService.requestPermissions();
    } catch (e) {
      _error = 'Failed to request notification permissions: ';
      notifyListeners();
      return false;
    }
  }

  // Check if notifications are allowed
  Future<bool> isNotificationAllowed() async {
    try {
      final notificationService = NotificationService();
      return await notificationService.isNotificationAllowed();
    } catch (e) {
      return false;
    }
  }
}
