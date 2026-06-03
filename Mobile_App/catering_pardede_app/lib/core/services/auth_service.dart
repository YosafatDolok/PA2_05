import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/core/storage/local_storage.dart';

class AuthService {
  static Future<Map<String, dynamic>> requestRegisterOtp(
      String name, String email, String password) async {
    try {
      final data = await ApiService.post(ApiEndpoints.registerOtp, {
        'name': name,
        'email': email,
        'password': password,
      });

      return {
        'success': true,
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> resendRegisterOtp(String email) async {
    try {
      final data = await ApiService.post(ApiEndpoints.registerResendOtp, {
        'email': email,
      });

      return {
        'success': true,
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> register(
      String email, String otp) async {
    try {
      final data = await ApiService.post(ApiEndpoints.register, {
        'email': email,
        'otp': otp,
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

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final data = await ApiService.get(ApiEndpoints.user);

      if (data != null &&
          (data['id'] != null || data['user_id'] != null)) {
        return data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isAdmin() async {
    final user = await getUser();
    if (user != null) {
      final role = user['role']?['name'] ?? 
                   (user['role_id'] == 1 ? 'admin' : 'customer');
      return role == 'admin';
    }
    return false;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiEndpoints.logout, {});
    } catch (_) {}

    await LocalStorage.clearToken();
  }
}