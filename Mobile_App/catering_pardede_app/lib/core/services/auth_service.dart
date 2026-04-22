import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/core/storage/local_storage.dart';

class AuthService {
  // 🔐 Register
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final data = await ApiService.post(ApiEndpoints.register, {
        'name': name,
        'email': email,
        'password': password,
      });

      if (data['token'] != null) {
        await LocalStorage.saveToken(data['token']);
      }

      return {
        'success': true,
        'user': data['user'],
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // 🔐 Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final data = await ApiService.post(ApiEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (data['token'] != null) {
        await LocalStorage.saveToken(data['token']);

        return {
          'success': true,
          'user': data['user'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login gagal',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // 👤 Get current user (FIXED)
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final data = await ApiService.get(ApiEndpoints.user)
          .timeout(const Duration(seconds: 5));

      print("USER DATA: $data");

      if (data != null &&
          (data['id'] != null || data['user_id'] != null)) {
        return data;
      }

      return null;
    } catch (e) {
      print("GET USER ERROR: $e"); // 🔥 shows real issue
      return null;
    }
  }

  // 🚪 Logout
  static Future<void> logout() async {
    try {
      await ApiService.post(ApiEndpoints.logout, {});
    } catch (_) {
      // ignore errors
    }

    await LocalStorage.clearToken();
  }
}