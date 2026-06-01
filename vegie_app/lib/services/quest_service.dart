import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../services/auth_service.dart';

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
  Future<List<Quest>> getDailyQuests() async {
    final token = await AuthService.instance.getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/quests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> items = data['data'];
        return items.map((json) => Quest.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to load quests');
  }

  Future<bool> updateProgress(String questType) async {
    final token = await AuthService.instance.getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/quests/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'quest_type': questType}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data']['updated'] ?? false;
      }
    }
    return false;
  }
}
