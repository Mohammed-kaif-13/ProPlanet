import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? photoURL;
  final int totalPoints;
  final int level;
  final int streak;
  final DateTime joinedAt;
  final Map<String, dynamic> preferences;
  final List<String> achievements;
  final List<String> badges;
  final Map<String, dynamic> environmentalImpact;
  final Map<String, int> categoryPoints;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    this.totalPoints = 0,
    this.level = 1,
    this.streak = 0,
    required this.joinedAt,
    this.preferences = const {},
    this.achievements = const [],
    this.badges = const [],
    this.environmentalImpact = const {},
    this.categoryPoints = const {},
  });

  // Create User from Firestore document - COMPLETELY SAFE VERSION
  factory User.fromFirestore(DocumentSnapshot doc) {
    try {
      // Get data safely without type casting
      final data = doc.data();
      if (data == null) {
        return _createDefaultUser(doc.id);
      }

      // Convert to Map safely - NO TYPE CASTING
      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        userData = data;
      } else if (data is Map) {
        userData = Map<String, dynamic>.from(data);
      } else {
        print('Warning: Firestore data is not a Map, creating default user');
        return _createDefaultUser(doc.id);
      }

      return User(
        id: doc.id,
        name: _safeString(userData['name'], 'User'),
        email: _safeString(userData['email'], ''),
        photoURL: _safeString(userData['photoURL'], ''),
        totalPoints: _safeInt(userData['totalPoints'], 0),
        level: _safeInt(userData['level'], 1),
        streak: _safeInt(userData['streak'], 0),
        joinedAt: _safeDateTime(userData['joinedAt']),
        preferences: _safeMap(userData['preferences']),
        achievements: _safeStringList(userData['achievements']),
        badges: _safeStringList(userData['badges']),
        environmentalImpact: _safeMap(userData['environmentalImpact']),
        categoryPoints: _safeIntMap(userData['categoryPoints']),
      );
    } catch (e) {
      print('Error creating User from Firestore: $e');
      return _createDefaultUser(doc.id);
    }
  }

  // Create User from JSON - COMPLETELY SAFE VERSION
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: _safeString(json['id'], ''),
        name: _safeString(json['name'], 'User'),
        email: _safeString(json['email'], ''),
        photoURL: _safeString(json['photoURL'], ''),
        totalPoints: _safeInt(json['totalPoints'], 0),
        level: _safeInt(json['level'], 1),
        streak: _safeInt(json['streak'], 0),
        joinedAt: _safeDateTimeFromString(json['joinedAt']),
        preferences: _safeMap(json['preferences']),
        achievements: _safeStringList(json['achievements']),
        badges: _safeStringList(json['badges']),
        environmentalImpact: _safeMap(json['environmentalImpact']),
        categoryPoints: _safeIntMap(json['categoryPoints']),
      );
    } catch (e) {
      print('Error creating User from JSON: $e');
      return _createDefaultUser('');
    }
  }

  // Create default user when data is invalid
  static User _createDefaultUser(String id) {
    return User(
      id: id,
      name: 'User',
      email: '',
      photoURL: '',
      totalPoints: 0,
      level: 1,
      streak: 0,
      joinedAt: DateTime.now(),
      preferences: {},
      achievements: [],
      badges: [],
      environmentalImpact: {},
      categoryPoints: {},
    );
  }

  // Safe string conversion - NO TYPE CASTING
  static String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  // Safe int conversion - NO TYPE CASTING
  static int _safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Safe DateTime conversion from Timestamp - NO TYPE CASTING
  static DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  // Safe DateTime conversion from String - NO TYPE CASTING
  static DateTime _safeDateTimeFromString(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Safe Map conversion - NO TYPE CASTING
  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  // Safe String List conversion - NO TYPE CASTING
  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List) {
      try {
        return value.map((e) => e?.toString() ?? '').toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Safe Int Map conversion - NO TYPE CASTING
  static Map<String, int> _safeIntMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, int>) return value;
    if (value is Map) {
      try {
        return Map<String, int>.from(
          value.map((key, val) => MapEntry(key.toString(), _safeInt(val, 0))),
        );
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  // Convert User to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'totalPoints': totalPoints,
      'level': level,
      'streak': streak,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'preferences': preferences,
      'achievements': achievements,
      'badges': badges,
      'environmentalImpact': environmentalImpact,
      'categoryPoints': categoryPoints,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'totalPoints': totalPoints,
      'level': level,
      'streak': streak,
      'joinedAt': joinedAt.toIso8601String(),
      'preferences': preferences,
      'achievements': achievements,
      'badges': badges,
      'environmentalImpact': environmentalImpact,
      'categoryPoints': categoryPoints,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoURL,
    int? totalPoints,
    int? level,
    int? streak,
    DateTime? joinedAt,
    Map<String, dynamic>? preferences,
    List<String>? achievements,
    List<String>? badges,
    Map<String, dynamic>? environmentalImpact,
    Map<String, int>? categoryPoints,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      joinedAt: joinedAt ?? this.joinedAt,
      preferences: preferences ?? this.preferences,
      achievements: achievements ?? this.achievements,
      badges: badges ?? this.badges,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      categoryPoints: categoryPoints ?? this.categoryPoints,
    );
  }
}
