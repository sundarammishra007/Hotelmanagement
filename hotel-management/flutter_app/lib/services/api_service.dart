import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<String?> _getToken() => _storage.read(key: _tokenKey);

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleUnauthorized(int statusCode) {
    if (statusCode == 401) {
      _storage.delete(key: _tokenKey);
      throw Exception('Session expired. Please login again.');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers());
    _handleUnauthorized(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _handleUnauthorized(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _handleUnauthorized(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _handleUnauthorized(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers(),
    );
    _handleUnauthorized(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<int>> getBytes(String endpoint) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleUnauthorized(response.statusCode);
    if (response.statusCode != 200) {
      throw Exception('Failed to download file');
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    File? file, {
    String fileField = 'id_proof',
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _handleUnauthorized(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
