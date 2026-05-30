import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_quote.dart';
import 'api_service.dart';
import '../config/constants.dart';

class QuoteService {
  final ApiService _apiService = ApiService();
  
  static const String _cacheKeyQuote = 'cached_quote_text';
  static const String _cacheKeyAuthor = 'cached_quote_author';
  static const String _cacheKeyDate = 'cached_quote_date';

  /// Fetch today's quote. Uses SharedPreferences cache
  /// to avoid re-fetching on the same day.
  Future<DailyQuote> getTodayQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    final cachedDate = prefs.getString(_cacheKeyDate);

    // Return cache if same day
    if (cachedDate == today) {
      final cachedText = prefs.getString(_cacheKeyQuote);
      final cachedAuthor = prefs.getString(_cacheKeyAuthor);
      if (cachedText != null && cachedText.isNotEmpty) {
        return DailyQuote(quoteText: cachedText, author: cachedAuthor ?? 'Anonim');
      }
    }

    // Fetch from server
    try {
      final response = await _apiService.get(Constants.endpointQuoteToday, requireAuth: false);
      if (response['success'] == true && response['data'] != null) {
        final quote = DailyQuote.fromJson(response['data']);
        
        // Cache it
        await prefs.setString(_cacheKeyQuote, quote.quoteText);
        await prefs.setString(_cacheKeyAuthor, quote.author);
        await prefs.setString(_cacheKeyDate, today);
        
        return quote;
      }
    } catch (e) {
      // If network fails, try returning cached (even if old)
      final cachedText = prefs.getString(_cacheKeyQuote);
      if (cachedText != null && cachedText.isNotEmpty) {
        return DailyQuote(
          quoteText: cachedText,
          author: prefs.getString(_cacheKeyAuthor) ?? 'Anonim',
        );
      }
    }

    // Ultimate fallback
    return DailyQuote(
      quoteText: 'Setiap hari adalah kesempatan baru untuk hidup lebih sehat.',
      author: 'LovingHarmony',
    );
  }
}
