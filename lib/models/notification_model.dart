import 'package:flutter/material.dart';

enum NotificationType {
  activityReminder,
  achievement,
  milestone,
  challenge,
  social,
  tips,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime scheduledTime;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? imageUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
    this.isRead = false,
    this.data,
    this.actionUrl,
    this.imageUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.',
        orElse: () => NotificationType.tips,
      ),
      scheduledTime: DateTime.parse(
        json['scheduledTime'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
      data: json['data'],
      actionUrl: json['actionUrl'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? scheduledTime,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class NotificationSettings {
  final bool activityReminders;
  final bool achievements;
  final bool milestones;
  final bool challenges;
  final bool social;
  final bool tips;
  final TimeOfDay reminderTime;
  final List<int> reminderDays; // 0 = Sunday, 1 = Monday, etc.

  NotificationSettings({
    this.activityReminders = true,
    this.achievements = true,
    this.milestones = true,
    this.challenges = true,
    this.social = true,
    this.tips = true,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.reminderDays = const [1, 2, 3, 4, 5, 6, 7], // All days
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      activityReminders: json['activityReminders'] ?? true,
      achievements: json['achievements'] ?? true,
      milestones: json['milestones'] ?? true,
      challenges: json['challenges'] ?? true,
      social: json['social'] ?? true,
      tips: json['tips'] ?? true,
      reminderTime: TimeOfDay(
        hour: json['reminderHour'] ?? 9,
        minute: json['reminderMinute'] ?? 0,
      ),
      reminderDays: List<int>.from(json['reminderDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityReminders': activityReminders,
      'achievements': achievements,
      'milestones': milestones,
      'challenges': challenges,
      'social': social,
      'tips': tips,
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
      'reminderDays': reminderDays,
    };
  }

  NotificationSettings copyWith({
    bool? activityReminders,
    bool? achievements,
    bool? milestones,
    bool? challenges,
    bool? social,
    bool? tips,
    TimeOfDay? reminderTime,
    List<int>? reminderDays,
  }) {
    return NotificationSettings(
      activityReminders: activityReminders ?? this.activityReminders,
      achievements: achievements ?? this.achievements,
      milestones: milestones ?? this.milestones,
      challenges: challenges ?? this.challenges,
      social: social ?? this.social,
      tips: tips ?? this.tips,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
    );
  }
}
