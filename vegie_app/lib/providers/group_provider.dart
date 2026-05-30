import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/api_service.dart'; // 1. Tambahkan import ApiService

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();
  final ApiService _apiService = ApiService(); // 2. Inisialisasi ApiService

  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  bool _isLoadingDiscover = false;
  List<dynamic> _discoverPosts = [];

  // Getters
  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isLoadingDiscover => _isLoadingDiscover;
  List<dynamic> get discoverPosts => _discoverPosts;

  // 3. Hapus garis bawah agar fungsi ini public (bisa dipanggil dari UI)
  Future<void> fetchDiscoverFeed() async {
    _isLoadingDiscover = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/groups/discover', requireAuth: true);
      if (response['success'] == true) {
        _discoverPosts = response['data']; 
      }
    } catch (e) {
      print("Error fetch discover: $e");
    }
    _isLoadingDiscover = false;
    notifyListeners();
  }

  Future<void> toggleLike(int foodLogId) async {
    // 4. Ubah cara pengecekan. Karena data masih berupa dynamic/Map dari JSON, gunakan sintaks p['id']
    final index = _discoverPosts.indexWhere((p) => p['id'] == foodLogId);
    
    if (index != -1) {
      final post = _discoverPosts[index];
      
      // Optimistic UI Update menggunakan Map key
      bool currentLikeStatus = post['is_liked'] == true || post['is_liked'] == 1;
      
      if (currentLikeStatus) {
        post['likes_count'] = (post['likes_count'] ?? 1) - 1;
      } else {
        post['likes_count'] = (post['likes_count'] ?? 0) + 1;
      }
      
      post['is_liked'] = !currentLikeStatus;
      notifyListeners();
    }

    try {
      await _apiService.post('/groups/discover/like', {'food_log_id': foodLogId}, requireAuth: true);
    } catch (e) {
      print("Error toggling like: $e");
    }
  } // <-- 5. Tutup kurung kurawal yang sebelumnya hilang ditambahkan di sini

  // ==========================================
  // Fungsi Grup Lama Anda Tetap Aman di Bawah
  // ==========================================

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