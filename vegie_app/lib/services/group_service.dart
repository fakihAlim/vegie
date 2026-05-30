import '../config/constants.dart';
import '../models/group.dart';
import '../models/group_post.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _apiService = ApiService();

  Future<List<Group>> getGroups() async {
    final response = await _apiService.get(Constants.endpointGroups, requireAuth: true);
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => Group.fromJson(json)).toList();
    }
    return [];
  }

  Future<Group?> getGroupDetail(int id) async {
    final response = await _apiService.get('${Constants.endpointGroups}/$id', requireAuth: true);
    if (response['success'] == true) {
      return Group.fromJson(response['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>> createGroup(String name, String? description) async {
    final response = await _apiService.post(
      Constants.endpointGroups,
      {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      },
      requireAuth: true,
    );
    return response;
  }

  Future<Map<String, dynamic>> joinGroup(String code) async {
    final response = await _apiService.post(
      '${Constants.endpointGroups}/join',
      {'code': code},
      requireAuth: true,
    );
    return response;
  }

  Future<bool> leaveGroup(int groupId) async {
    try {
      await _apiService.delete('${Constants.endpointGroups}/$groupId/leave', requireAuth: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<GroupPost>> getPosts(int groupId, {int page = 1}) async {
    final response = await _apiService.get(
      '${Constants.endpointGroups}/$groupId/posts?page=$page',
      requireAuth: true,
    );
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => GroupPost.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createPost(int groupId, String content, String type) async {
    final response = await _apiService.post(
      '${Constants.endpointGroups}/$groupId/posts',
      {'content': content, 'type': type},
      requireAuth: true,
    );
    return response;
  }

  Future<List<GroupMember>> getMembers(int groupId) async {
    final response = await _apiService.get(
      '${Constants.endpointGroups}/$groupId/members',
      requireAuth: true,
    );
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => GroupMember.fromJson(json)).toList();
    }
    return [];
  }
}
