import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();

  List<Recipe> _recipesList = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;

  List<Recipe> get recipesList => _recipesList;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecipes({bool refresh = false, String? search}) async {
    if (_isLoading) return;

    final targetPage = refresh ? 1 : _currentPage;

    if (!refresh && !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _recipeService.getRecipes(page: targetPage, search: search);
      if (refresh) {
        _recipesList = fetched;
        _currentPage = 2;
        _hasMore = fetched.isNotEmpty;
      } else {
        if (fetched.isEmpty) {
          _hasMore = false;
        } else {
          _recipesList.addAll(fetched);
          _currentPage++;
        }
      }
    } catch (e) {
      print("Error fetching recipes: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Recipe?> getRecipeDetail(int id) async {
    return await _recipeService.getRecipeDetail(id);
  }
}
