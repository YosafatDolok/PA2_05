import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';
import 'package:flutter/material.dart';

class AuthController {
  // Login
  static Future<void> login(
      BuildContext context, String email, String password) async {
    try {
      final result = await AuthService.login(email, password);

      if (result['success']) {
        final user = result['user'];

        final role = user['role']?['name'];

        Helpers.showSnackBar(context, 'Login Berhasil');

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } else {
        Helpers.showSnackBar(
            context, result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Error: $e');
    }
  }

  // Register
  static Future<void> register(
      BuildContext context, String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Helpers.showSnackBar(context, 'Mohon isi setiap bagian');
      return;
    }

    final result =
        await AuthService.register(name, email, password);

    if (result['success']) {
      final user = result['user'];
      final role = user?['role']?['name'];

      Helpers.showSnackBar(
          context, result['message'] ?? 'Registrasi Berhasil');

      // 🔀 If token returned → go to dashboard
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    } else {
      Helpers.showSnackBar(
          context, result['message'] ?? 'Registrasi Gagal');
    }
  }

  // Logout
  static Future<void> logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
}