import 'package:catering_pardede_app/controllers/user_controller.dart';

import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';
import 'package:flutter/material.dart';

class AuthController {
  // Login
  static Future<void> login(
      BuildContext context, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Helpers.showSnackBar(context, 'Mohon isi setiap bagian');
      return;
    }

    final success = await AuthService.login(email, password);

    if (success) {
      final fetchedUser = await UserController.fetchUser();

      if (fetchedUser?.role?.name == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/userDashboard');
      } 
    }
    else {
      Helpers.showSnackBar(context, 'Email atau password invalid');
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
