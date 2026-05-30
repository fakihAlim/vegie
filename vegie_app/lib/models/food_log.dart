class FoodLog {
  final int? id; // Nullable because local insert doesn't have ID yet
  final int? localId; // Local SQLite ID
  final String? photoPath; // Local file path
  final String? photoUrl; // Server URL
  final String foodName;
  final DateTime mealTime;
  final String category; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String? nutritionNotes;
  final double? calories;
  final double? carbs;
  final double? fat;
  final double? protein;
  final bool isSynced;
  final DateTime createdAt;

  FoodLog({
    this.id,
    this.localId,
    this.photoPath,
    this.photoUrl,
    required this.foodName,
    required this.mealTime,
    required this.category,
    this.nutritionNotes,
    this.calories,
    this.carbs,
    this.fat,
    this.protein,
    this.isSynced = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'],
      photoUrl: json['photo'],
      foodName: json['food_name'] ?? 'Tidak Dikenali',
      mealTime: DateTime.parse(json['meal_time']),
      category: json['category'],
      nutritionNotes: json['nutrition_notes'],
      calories: json['calories'] != null ? (json['calories'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      protein: json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      isSynced: true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  factory FoodLog.fromLocalMap(Map<String, dynamic> map) {
    return FoodLog(
      localId: map['local_id'],
      id: map['server_id'],
      photoPath: map['photo_path'],
      photoUrl: map['photo_url'],
      foodName: map['food_name'],
      mealTime: DateTime.parse(map['meal_time']),
      category: map['category'],
      nutritionNotes: map['nutrition_notes'],
      calories: map['calories'] != null ? (map['calories'] as num).toDouble() : null,
      carbs: map['carbs'] != null ? (map['carbs'] as num).toDouble() : null,
      fat: map['fat'] != null ? (map['fat'] as num).toDouble() : null,
      protein: map['protein'] != null ? (map['protein'] as num).toDouble() : null,
      isSynced: map['is_synced'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'local_id': localId,
      'server_id': id,
      'photo_path': photoPath,
      'photo_url': photoUrl,
      'food_name': foodName,
      'meal_time': mealTime.toIso8601String(),
      'category': category,
      'nutrition_notes': nutritionNotes,
      'calories': calories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'local_id': localId,
      'food_name': foodName,
      'meal_time': mealTime.toIso8601String(),
      'category': category,
      'nutrition_notes': nutritionNotes,
      'calories': calories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
    };
  }

  /// Whether this food log has AI-analyzed nutrition data
  bool get hasNutrition => calories != null && carbs != null && fat != null && protein != null;

  /// Create a copy with updated fields
  FoodLog copyWith({
    int? id,
    int? localId,
    String? photoPath,
    String? photoUrl,
    String? foodName,
    DateTime? mealTime,
    String? category,
    String? nutritionNotes,
    double? calories,
    double? carbs,
    double? fat,
    double? protein,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return FoodLog(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      foodName: foodName ?? this.foodName,
      mealTime: mealTime ?? this.mealTime,
      category: category ?? this.category,
      nutritionNotes: nutritionNotes ?? this.nutritionNotes,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      protein: protein ?? this.protein,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
