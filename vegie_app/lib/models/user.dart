class User {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final String? bio;
  final String joinDate;
  final Map<String, int>? stats;
  final bool isOnboardingCompleted;
  final String ttmStage;
  final bool isFeatureLocked;
  int totalPoints; // Non-final to allow incrementing locally

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    this.bio,
    required this.joinDate,
    this.stats,
    this.isOnboardingCompleted = false,
    this.ttmStage = 'precontemplation',
    this.isFeatureLocked = false,
    this.totalPoints = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photo: json['photo'],
      bio: json['bio'],
      joinDate: json['join_date'],
      stats: json['stats'] != null 
          ? Map<String, int>.from(json['stats']) 
          : null,
      isOnboardingCompleted: json['is_onboarding_completed'] == true || json['is_onboarding_completed'] == 1,
      ttmStage: json['ttm_stage'] ?? 'precontemplation',
      isFeatureLocked: json['is_feature_locked'] == true || json['is_feature_locked'] == 1,
      totalPoints: json['total_points'] ?? json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'bio': bio,
      'join_date': joinDate,
      'stats': stats,
      'is_onboarding_completed': isOnboardingCompleted,
      'ttm_stage': ttmStage,
      'is_feature_locked': isFeatureLocked,
      'total_points': totalPoints,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? photo,
    String? bio,
    String? joinDate,
    Map<String, int>? stats,
    bool? isOnboardingCompleted,
    String? ttmStage,
    bool? isFeatureLocked,
    int? totalPoints,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      bio: bio ?? this.bio,
      joinDate: joinDate ?? this.joinDate,
      stats: stats ?? this.stats,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      ttmStage: ttmStage ?? this.ttmStage,
      isFeatureLocked: isFeatureLocked ?? this.isFeatureLocked,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}
