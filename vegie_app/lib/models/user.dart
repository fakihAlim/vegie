class User {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final String? bio;
  final String joinDate;
  final Map<String, int>? stats;
  final bool isOnboardingCompleted;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    this.bio,
    required this.joinDate,
    this.stats,
    this.isOnboardingCompleted = false,
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
    };
  }
}
