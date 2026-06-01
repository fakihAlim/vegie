import '../../services/api_service.dart';

class Quest {
  final int userQuestId;
  final int questId;
  final String title;
  final String description;
  final int pointsReward;
  final String questType;
  final int targetCount;
  final int progressCount;
  final bool isCompleted;

  Quest({
    required this.userQuestId,
    required this.questId,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.questType,
    required this.targetCount,
    required this.progressCount,
    required this.isCompleted,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      userQuestId: json['user_quest_id'] is int ? json['user_quest_id'] : int.parse(json['user_quest_id'].toString()),
      questId: json['quest_id'] is int ? json['quest_id'] : int.parse(json['quest_id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pointsReward: json['points_reward'] is int ? json['points_reward'] : int.parse(json['points_reward'].toString()),
      questType: json['quest_type'] ?? '',
      targetCount: json['target_count'] is int ? json['target_count'] : int.parse(json['target_count'].toString()),
      progressCount: json['progress_count'] is int ? json['progress_count'] : int.parse(json['progress_count'].toString()),
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }
}

class QuestService {
  final ApiService _apiService = ApiService();

  Future<List<Quest>> getDailyQuests() async {
    try {
      final response = await _apiService.get('/quests', requireAuth: true);
      if (response['success'] == true) {
        final List<dynamic> items = response['data'];
        return items.map((json) => Quest.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching quests: $e');
    }
    throw Exception('Failed to load quests');
  }

  Future<bool> updateProgress(String questType) async {
    try {
      final response = await _apiService.post(
        '/quests/progress',
        {'quest_type': questType},
        requireAuth: true,
      );
      if (response['success'] == true) {
        return response['data']['updated'] ?? false;
      }
    } catch (e) {
      print('Error updating quest progress: $e');
    }
    return false;
  }
}
