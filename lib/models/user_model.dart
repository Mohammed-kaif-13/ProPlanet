class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int totalPoints;
  final int level;
  final List<String> badges;
  final DateTime joinDate;
  final Map<String, int> categoryPoints;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.totalPoints = 0,
    this.level = 1,
    this.badges = const [],
    required this.joinDate,
    this.categoryPoints = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      level: json['level'] ?? 1,
      badges: List<String>.from(json['badges'] ?? []),
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
      categoryPoints: Map<String, int>.from(json['categoryPoints'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'level': level,
      'badges': badges,
      'joinDate': joinDate.toIso8601String(),
      'categoryPoints': categoryPoints,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? totalPoints,
    int? level,
    List<String>? badges,
    DateTime? joinDate,
    Map<String, int>? categoryPoints,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      joinDate: joinDate ?? this.joinDate,
      categoryPoints: categoryPoints ?? this.categoryPoints,
    );
  }
}
