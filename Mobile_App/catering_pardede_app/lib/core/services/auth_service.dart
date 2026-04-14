import 'dart:convert';
import 'package:http/http.dart' as http;
import '/core/constants/api_endpoints.dart';
import '/core/storage/local_storage.dart';

class AuthService {
  // Register new user
  static Future<bool> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return res.statusCode == 201;
  }

  // Login
  static Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final token = data['token'];
      await LocalStorage.saveToken(token);
      return true;
    } else {
      return false;
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getUser() async {
    final token = await LocalStorage.getToken();
    if (token == null) return null;

    final res = await http.get(
      Uri.parse(ApiEndpoints.user),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    final token = await LocalStorage.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse(ApiEndpoints.logout),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    await LocalStorage.clearToken();
  }
}
