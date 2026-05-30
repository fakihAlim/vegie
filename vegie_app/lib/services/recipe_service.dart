import '../config/constants.dart';
import '../models/recipe.dart';
import 'api_service.dart';

class RecipeService {
  final ApiService _apiService = ApiService();

  Future<List<Recipe>> getRecipes({int page = 1, int perPage = 10, String? search}) async {
    String url = '${Constants.endpointRecipes}?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    final response = await _apiService.get(url, requireAuth: true);
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => Recipe.fromJson(json)).toList();
    }
    return [];
  }

  Future<Recipe?> getRecipeDetail(int id) async {
    final response = await _apiService.get('${Constants.endpointRecipes}/$id', requireAuth: true);
    if (response['success'] == true) {
      return Recipe.fromJson(response['data']);
    }
    return null;
  }
}
