import 'package:flutter/material.dart';
import '../services/quest_service.dart';

class QuestProvider with ChangeNotifier {
  final QuestService _service = QuestService();

  List<Quest> _quests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Quest> get quests => _quests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchQuests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quests = await _service.getDailyQuests();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateQuestProgress(String questType) async {
    try {
      final success = await _service.updateProgress(questType);
      if (success) {
        // Refresh quests to get updated progress and badges
        await fetchQuests();
        return true;
      }
    } catch (e) {
      debugPrint("Error updating quest progress: $e");
    }
    return false;
  }
}
