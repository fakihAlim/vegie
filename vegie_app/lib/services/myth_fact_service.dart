import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../services/auth_service.dart';

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
  Future<List<MythFact>> getMyths() async {
    final token = await AuthService.instance.getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/myths'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> items = data['data'];
        return items.map((json) => MythFact.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to load myths');
  }
}
