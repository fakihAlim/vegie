import 'package:flutter/material.dart';
import '../models/news.dart';
import '../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();

  List<News> _newsList = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;

  List<News> get newsList => _newsList;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNews({bool refresh = false, String? search}) async {
    if (_isLoading) return;

    final targetPage = refresh ? 1 : _currentPage;

    if (!refresh && !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _newsService.getNews(page: targetPage, search: search);
      if (refresh) {
        _newsList = fetched;
        _currentPage = 2;
        _hasMore = fetched.isNotEmpty;
      } else {
        if (fetched.isEmpty) {
          _hasMore = false;
        } else {
          _newsList.addAll(fetched);
          _currentPage++;
        }
      }
    } catch (e) {
      print("Error fetching news: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<News?> getNewsDetail(int id) async {
    return await _newsService.getNewsDetail(id);
  }
}
