import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ApiService {
  // --- OPTIMASI: Cache Token di RAM (Menghindari Disk I/O berulang) ---
  static String? _cachedToken;
  static bool _isTokenLoaded = false;

  Future<void> _loadToken() async {
    if (!_isTokenLoaded) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(Constants.keyToken);
      _isTokenLoaded = true;
    }
  }

  /// Panggil fungsi ini jika User Logout agar cache token dibersihkan
  static void clearTokenCache() {
    _cachedToken = null;
    _isTokenLoaded = false;
  }
  // -------------------------------------------------------------------

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      await _loadToken(); // Cepat karena hanya baca dari memory jika sudah diload
      if (_cachedToken != null) {
        headers['Authorization'] = 'Bearer $_cachedToken';
      }
    }

    final prefs = await SharedPreferences.getInstance();
    headers['X-Diet-Allow-Eggs'] = (prefs.getBool('diet_allow_eggs') ?? false).toString();
    headers['X-Diet-Allow-Milk'] = (prefs.getBool('diet_allow_milk') ?? false).toString();
    headers['X-Diet-Allow-Honey'] = (prefs.getBool('diet_allow_honey') ?? false).toString();
    headers['X-Diet-Restrict-Alliums'] = (prefs.getBool('diet_restrict_alliums') ?? false).toString();

    return headers;
  }

  String _buildUrl(String endpoint) {
    // Check if endpoint already has query params, e.g. /news?page=1
    final parts = endpoint.split('?');
    final path = parts[0].startsWith('/') ? parts[0].substring(1) : parts[0];
    final query = parts.length > 1 ? '&${parts[1]}' : '';
    
    // Convert path to route query param for NGINX compatibility
    return '${Constants.baseUrl}/index.php?route=$path$query';
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    try {
      final response = await http.get(
        Uri.parse(_buildUrl(endpoint)),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    try {
      final response = await http.post(
        Uri.parse(_buildUrl(endpoint)),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    try {
      final response = await http.put(
        Uri.parse(_buildUrl(endpoint)),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    try {
      final response = await http.delete(
        Uri.parse(_buildUrl(endpoint)),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> multipartPost(
    String endpoint,
    Map<String, String> fields,
    String? fileField,
    String? filePath, {
    bool requireAuth = true,
    bool isPut = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    // remove Content-Type as multipart request handles it
    headers.remove('Content-Type');

    try {
      final request = http.MultipartRequest(
        isPut ? 'PUT' : 'POST',
        Uri.parse(_buildUrl(endpoint)),
      );
      request.headers.addAll(headers);
      request.fields.addAll(fields);

      if (fileField != null && filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, filePath),
        );
      }

      // Longer timeout for multipart: server runs AI nutrition analysis on uploaded photos
      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse).timeout(const Duration(seconds: 120));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      Map<String, dynamic> errorBody;
      try {
        errorBody = jsonDecode(response.body);
      } catch (_) {
        errorBody = {'message': 'Unknown error occurred ($statusCode)'};
      }
      throw Exception(errorBody['message'] ?? 'Unknown error occurred');
    }
  }
}