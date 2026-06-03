import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();

  List<Recipe> _recipesList = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;

  List<int> _savedRecipeIds = [];
  List<int> _triedRecipeIds = [];

  List<Recipe> get recipesList => _recipesList;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<int> get savedRecipeIds => _savedRecipeIds;
  List<int> get triedRecipeIds => _triedRecipeIds;

  RecipeProvider() {
    loadSavedAndTriedRecipes();
  }

  Future<void> loadSavedAndTriedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('saved_recipes') ?? [];
      final tried = prefs.getStringList('tried_recipes') ?? [];
      _savedRecipeIds = saved.map((id) => int.tryParse(id)).whereType<int>().toList();
      _triedRecipeIds = tried.map((id) => int.tryParse(id)).whereType<int>().toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading saved and tried recipes: $e");
    }
  }

  void clearRecipes() {
    _savedRecipeIds = [];
    _triedRecipeIds = [];
    _recipesList = [];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }

  bool isRecipeSaved(int recipeId) {
    return _savedRecipeIds.contains(recipeId);
  }

  bool isRecipeTried(int recipeId) {
    return _triedRecipeIds.contains(recipeId);
  }

  Future<void> toggleSaveRecipe(int recipeId) async {
    if (_savedRecipeIds.contains(recipeId)) {
      _savedRecipeIds.remove(recipeId);
    } else {
      _savedRecipeIds.add(recipeId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_recipes', _savedRecipeIds.map((id) => id.toString()).toList());
    } catch (e) {
      debugPrint("Error saving recipe: $e");
    }
  }

  Future<void> setRecipeTried(int recipeId) async {
    if (!_triedRecipeIds.contains(recipeId)) {
      _triedRecipeIds.add(recipeId);
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('tried_recipes', _triedRecipeIds.map((id) => id.toString()).toList());
      } catch (e) {
        debugPrint("Error setting recipe tried: $e");
      }
    }
  }

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
      debugPrint("Error fetching recipes: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Recipe?> getRecipeDetail(int id) async {
    return await _recipeService.getRecipeDetail(id);
  }
}
