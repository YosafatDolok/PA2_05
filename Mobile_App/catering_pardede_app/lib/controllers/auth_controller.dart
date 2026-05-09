import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import '/core/services/push_notification_service.dart';
import '/core/services/location_service.dart';

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

        // Sync FCM token with backend
        PushNotificationService.syncToken();

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } else {
        Helpers.showSnackBar(
            context, result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      Helpers.showSnackBar(context, 'Gagal: $msg');
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

      // Sync FCM token with backend
      PushNotificationService.syncToken();

      // 🔀 If token returned → go to dashboard
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (role == 'driver') {
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
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
    Helpers.showConfirmDialog(
      context,
      title: 'Keluar Akun?',
      message: 'Apakah Anda yakin ingin keluar dari akun Anda?',
      confirmText: 'Ya, Keluar',
      onConfirm: () async {
        LocationService.stopTracking();
        await AuthService.logout();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      },
    );
  }
}