class Recipe {
  final int id;
  final String title;
  final String? photo;
  final String? description;
  final int? calories;
  final int? prepTimeMinutes;
  final DateTime publishedAt;
  final List<RecipeIngredient>? ingredients;
  final List<RecipeStep>? steps;
  final List<String>? tags;
  final int? protein;
  final int? carbs;
  final int? fat;
  final String? tips;

  Recipe({
    required this.id,
    required this.title,
    this.photo,
    this.description,
    this.calories,
    this.prepTimeMinutes,
    required this.publishedAt,
    this.ingredients,
    this.steps,
    this.tags,
    this.protein,
    this.carbs,
    this.fat,
    this.tips,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      photo: json['photo'],
      description: json['description'],
      calories: json['calories'],
      prepTimeMinutes: json['prep_time_minutes'],
      publishedAt: DateTime.parse(json['published_at']),
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List).map((i) => RecipeIngredient.fromJson(i)).toList()
          : null,
      steps: json['steps'] != null
          ? (json['steps'] as List).map((s) => RecipeStep.fromJson(s)).toList()
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as List).map((t) => t.toString()).toList()
          : null,
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      tips: json['tips'],
    );
  }
}

class RecipeIngredient {
  final String ingredient;
  final String? amount;

  RecipeIngredient({required this.ingredient, this.amount});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredient: json['ingredient'],
      amount: json['amount'],
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String description;

  RecipeStep({required this.stepNumber, required this.description});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'],
      description: json['description'],
    );
  }
}
