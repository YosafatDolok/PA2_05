import 'package:http/http.dart' as http;
import 'dart:convert';
import '/core/storage/local_storage.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await LocalStorage.getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    // 🔥 Handle expired token
    if (response.statusCode == 401) {
      LocalStorage.clearToken();
      throw Exception('Session expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }
}