enum ActivityCategory {
  transport,
  energy,
  waste,
  water,
  food,
  shopping,
  nature,
}

enum ActivityStatus {
  pending,
  completed,
  verified,
}

class EcoActivity {
  final String id;
  final String title;
  final String description;
  final ActivityCategory category;
  final int points;
  final String icon;
  final Duration estimatedTime;
  final List<String> tags;
  final bool isRepeatable;
  final String difficulty; // easy, medium, hard
  final String instructions;

  EcoActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.points,
    required this.icon,
    required this.estimatedTime,
    this.tags = const [],
    this.isRepeatable = true,
    this.difficulty = 'easy',
    this.instructions = '',
  });

  factory EcoActivity.fromJson(Map<String, dynamic> json) {
    return EcoActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: ActivityCategory.values.firstWhere(
        (e) => e.toString() == 'ActivityCategory.',
        orElse: () => ActivityCategory.transport,
      ),
      points: json['points'] ?? 0,
      icon: json['icon'] ?? '',
      estimatedTime: Duration(minutes: json['estimatedTimeMinutes'] ?? 5),
      tags: List<String>.from(json['tags'] ?? []),
      isRepeatable: json['isRepeatable'] ?? true,
      difficulty: json['difficulty'] ?? 'easy',
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'points': points,
      'icon': icon,
      'estimatedTimeMinutes': estimatedTime.inMinutes,
      'tags': tags,
      'isRepeatable': isRepeatable,
      'difficulty': difficulty,
      'instructions': instructions,
    };
  }
}

class UserActivity {
  final String id;
  final String userId;
  final String activityId;
  final EcoActivity activity;
  final DateTime startTime;
  final DateTime? completedTime;
  final ActivityStatus status;
  final String? notes;
  final List<String> photos;
  final Map<String, dynamic>? metadata;

  UserActivity({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.activity,
    required this.startTime,
    this.completedTime,
    this.status = ActivityStatus.pending,
    this.notes,
    this.photos = const [],
    this.metadata,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      activityId: json['activityId'] ?? '',
      activity: EcoActivity.fromJson(json['activity'] ?? {}),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      completedTime: json['completedTime'] != null 
          ? DateTime.parse(json['completedTime'])
          : null,
      status: ActivityStatus.values.firstWhere(
        (e) => e.toString() == 'ActivityStatus.',
        orElse: () => ActivityStatus.pending,
      ),
      notes: json['notes'],
      photos: List<String>.from(json['photos'] ?? []),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'activity': activity.toJson(),
      'startTime': startTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'photos': photos,
      'metadata': metadata,
    };
  }

  UserActivity copyWith({
    String? id,
    String? userId,
    String? activityId,
    EcoActivity? activity,
    DateTime? startTime,
    DateTime? completedTime,
    ActivityStatus? status,
    String? notes,
    List<String>? photos,
    Map<String, dynamic>? metadata,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      activity: activity ?? this.activity,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isCompleted => status == ActivityStatus.completed || status == ActivityStatus.verified;
  
  Duration get duration {
    if (completedTime != null) {
      return completedTime!.difference(startTime);
    }
    return Duration.zero;
  }
}
