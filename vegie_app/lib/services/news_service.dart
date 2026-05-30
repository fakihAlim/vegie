import '../config/constants.dart';
import '../models/news.dart';
import 'api_service.dart';

class NewsService {
  final ApiService _apiService = ApiService();

  Future<List<News>> getNews({int page = 1, int perPage = 10, String? search}) async {
    String url = '${Constants.endpointNews}?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    // Requires auth context but practically accessible by valid users
    final response = await _apiService.get(url, requireAuth: true);
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => News.fromJson(json)).toList();
    }
    return [];
  }

  Future<News?> getNewsDetail(int id) async {
    final response = await _apiService.get('${Constants.endpointNews}/$id', requireAuth: true);
    if (response['success'] == true) {
      return News.fromJson(response['data']);
    }
    return null;
  }
}
