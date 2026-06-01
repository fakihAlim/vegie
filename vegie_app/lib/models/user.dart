class User {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final String? bio;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;
  double totalCarbonSaved; // Non-final to allow incrementing locally
  final String joinDate;
  final Map<String, int>? stats;
  final bool isOnboardingCompleted;
  final String ttmStage;
  final bool isFeatureLocked;
  int totalPoints; // Non-final to allow incrementing locally
  final List<String> unlockedBadges; // Badges unlocked by user

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    this.bio,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.totalCarbonSaved = 0.0,
    required this.joinDate,
    this.stats,
    this.isOnboardingCompleted = false,
    this.ttmStage = 'precontemplation',
    this.isFeatureLocked = false,
    this.totalPoints = 0,
    this.unlockedBadges = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photo: json['photo'],
      bio: json['bio'],
      age: json['age'] != null ? (json['age'] as num).toInt() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      gender: json['gender'],
      totalCarbonSaved: json['total_carbon_saved'] != null ? (json['total_carbon_saved'] as num).toDouble() : 0.0,
      joinDate: json['join_date'],
      stats: json['stats'] != null 
          ? Map<String, int>.from(json['stats']) 
          : null,
      isOnboardingCompleted: json['is_onboarding_completed'] == true || json['is_onboarding_completed'] == 1,
      ttmStage: json['ttm_stage'] ?? 'precontemplation',
      isFeatureLocked: json['is_feature_locked'] == true || json['is_feature_locked'] == 1,
      totalPoints: json['total_points'] ?? json['points'] ?? 0,
      unlockedBadges: json['unlocked_badges'] != null 
          ? List<String>.from(json['unlocked_badges']) 
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'bio': bio,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'total_carbon_saved': totalCarbonSaved,
      'join_date': joinDate,
      'stats': stats,
      'is_onboarding_completed': isOnboardingCompleted,
      'ttm_stage': ttmStage,
      'is_feature_locked': isFeatureLocked,
      'total_points': totalPoints,
      'unlocked_badges': unlockedBadges,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? photo,
    String? bio,
    int? age,
    double? weight,
    double? height,
    String? gender,
    double? totalCarbonSaved,
    String? joinDate,
    Map<String, int>? stats,
    bool? isOnboardingCompleted,
    String? ttmStage,
    bool? isFeatureLocked,
    int? totalPoints,
    List<String>? unlockedBadges,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      totalCarbonSaved: totalCarbonSaved ?? this.totalCarbonSaved,
      joinDate: joinDate ?? this.joinDate,
      stats: stats ?? this.stats,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      ttmStage: ttmStage ?? this.ttmStage,
      isFeatureLocked: isFeatureLocked ?? this.isFeatureLocked,
      totalPoints: totalPoints ?? this.totalPoints,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  Map<String, double> calculateDailyNutritionTargets() {
    // If any required physical metric is null, return standard balanced targets
    if (weight == null || height == null || age == null || gender == null) {
      return {
        'calories': 2000.0,
        'carbs': 250.0,
        'fat': 66.7,
        'protein': 100.0,
      };
    }

    // Step 1: Calculate BMR using Mifflin-St Jeor
    double bmr = 0.0;
    if (gender!.trim().toLowerCase() == 'male') {
      bmr = (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
    } else {
      bmr = (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
    }

    // Step 2: Calculate TDEE (Total Daily Energy Expenditure)
    // Proposal: default activity factor is 1.375 (Lightly Active / Jarang berolahraga)
    double activityFactor = 1.375;
    double tdee = bmr * activityFactor;

    // Step 3: Calculate Macronutrient targets in grams
    // Karbohidrat: 50% dari total kalori (dibagi 4 = gram)
    // Protein: 20% dari total kalori (dibagi 4 = gram)
    // Lemak: 30% dari total kalori (dibagi 9 = gram)
    double carbs = (tdee * 0.50) / 4.0;
    double protein = (tdee * 0.20) / 4.0;
    double fat = (tdee * 0.30) / 9.0;

    return {
      'calories': tdee,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
    };
  }
}
