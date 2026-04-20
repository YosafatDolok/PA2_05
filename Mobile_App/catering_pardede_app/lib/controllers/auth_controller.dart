import 'package:catering_pardede_app/controllers/user_controller.dart';

import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';
import 'package:flutter/material.dart';

class AuthController {
  // Login
  static Future<Map<String, dynamic>> login(
    String email, String password) async {
  try {
    final result = await AuthService.login(email, password);

if (result['success']) {
  final user = await AuthService.getUser();

  return {
    'success': true,
    'user': user,
  };
} else {
  return {
    'success': false,
    'message': result['message'],
  };
}
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}
  // Register
  static Future<void> register(
      BuildContext context, String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Helpers.showSnackBar(context, 'Mohon isi setiap bagian');
      return;
    }

    final success = await AuthService.register(name, email, password);

if (success) {
  Helpers.showSnackBar(context, 'Registrasi Berhasil');
  Navigator.pushReplacementNamed(context, '/login');
} else {
  Helpers.showSnackBar(context, 'Registrasi Gagal');
}
      }

  // Logout
  static Future<void> logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
