import '../config/constants.dart';
import 'api_service.dart';

class QuizService {
  final ApiService _apiService = ApiService();

  /// Fetch the active daily quiz from the API
  Future<Map<String, dynamic>?> getDailyQuiz() async {
    try {
      final response = await _apiService.get(Constants.endpointDailyQuiz, requireAuth: true);
      if (response['success'] == true) {
        return response['data'];
      }
    } catch (e) {
      print("Error fetching daily quiz: $e");
    }
    return null;
  }

  /// Submit the answer for a specific quiz
  Future<Map<String, dynamic>?> submitAnswer(int quizId, String answer) async {
    try {
      final response = await _apiService.post(
        '${Constants.endpointQuizzes}/$quizId/submit',
        {'answer': answer},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      print("Error submitting answer: $e");
    }
    return null;
  }
}
