import 'dart:convert';
import 'package:http/http.dart' as http;
import '/core/constants/api_endpoints.dart';
import '/core/storage/local_storage.dart';

class AuthService {
  // Register new user
static Future<bool> register(
    String name, String email, String password) async {
  try {
    final res = await http
        .post(
          Uri.parse(ApiEndpoints.register),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    // 🔥 DEBUG
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    return res.statusCode == 201;
  } catch (e) {
    print("ERROR: $e");
    return false;
  }
}

  // Login
  static Future<Map<String, dynamic>> login(
    String email, String password) async {
  try {
    final res = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final token = data['token'];
      await LocalStorage.saveToken(token);

      return {
        'success': true,
        'user': data['user'], // ⬅️ penting
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Login gagal'
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
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


