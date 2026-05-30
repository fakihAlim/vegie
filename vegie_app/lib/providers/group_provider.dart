import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _groupService.getGroups();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createGroup(String name, String? description) async {
    try {
      final response = await _groupService.createGroup(name, description);
      if (response['success'] == true) {
        await fetchGroups();
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> joinGroup(String code) async {
    try {
      final response = await _groupService.joinGroup(code);
      if (response['success'] == true) {
        await fetchGroups();
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> leaveGroup(int groupId) async {
    final success = await _groupService.leaveGroup(groupId);
    if (success) {
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
    }
    return success;
  }
}
