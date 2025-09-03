import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize the notification service
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  // Check if notifications are allowed
  Future<bool> isNotificationAllowed() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.areNotificationsEnabled();
      return granted ?? false;
    }
    return false;
  }

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'eco_activities',
      'Eco Activities',
      channelDescription: 'Notifications for eco-friendly activities',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(id, title, body, notificationDetails, payload: payload);
  }

  // Show achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'achievements',
      'Achievements',
      channelDescription: 'Achievement and milestone notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF9800),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(id, title, body, notificationDetails, payload: payload);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
