import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';


class MythFact {
  final int id;
  final String title;
  final String type; // 'myth' or 'fact'
  final String description;
  final String? imageUrl;

  MythFact({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    this.imageUrl,
  });

  factory MythFact.fromJson(Map<String, dynamic> json) {
    return MythFact(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      type: json['type'] ?? 'myth',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}

class MythFactService {
  final ApiService _apiService = ApiService();

  Future<List<MythFact>> getMyths() async {
    try {
      final response = await _apiService.get('/myths', requireAuth: true);
      if (response['success'] == true) {
        final List<dynamic> items = response['data'];
        return items.map((json) => MythFact.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching myths: $e');
    }
    throw Exception('Failed to load myths');
  }
}
