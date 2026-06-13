import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import '/core/services/push_notification_service.dart';

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
          await AuthService.logout();
          Helpers.showSnackBar(context, 'Login admin via aplikasi dinonaktifkan sementara.');
          return;
        } else if (role == 'driver') {
          Navigator.pushNamedAndRemoveUntil(context, '/driver-dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/user-dashboard', (route) => false);
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

  // Register Step 1: Request OTP
  static Future<void> requestOtp(
      BuildContext context, String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Helpers.showSnackBar(context, 'Mohon isi setiap bagian');
      return;
    }

    final result = await AuthService.requestRegisterOtp(name, email, password);

    if (result['success']) {
      Helpers.showSnackBar(context, result['message'] ?? 'Kode verifikasi telah dikirim');
      if (context.mounted) {
        Helpers.pushNamedSafe(context, '/registration-otp', arguments: {
          'email': email,
        });
      }
    } else {
      final msg = result['message']?.toString().replaceAll('Exception: ', '') ?? 'Registrasi Gagal';
      Helpers.showSnackBar(context, msg);
    }
  }

  // Register: Resend OTP
  static Future<bool> resendRegisterOtp(BuildContext context, String email) async {
    try {
      final result = await AuthService.resendRegisterOtp(email);
      if (result['success']) {
        Helpers.showSnackBar(context, result['message'] ?? 'Kode verifikasi baru telah dikirim');
        return true;
      } else {
        final msg = result['message']?.toString().replaceAll('Exception: ', '') ?? 'Gagal mengirim ulang OTP';
        Helpers.showSnackBar(context, msg);
        return false;
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Error: $e');
      return false;
    }
  }

  // Register Step 2: Verify & Finalize
  static Future<void> verifyOtpAndRegister(
      BuildContext context, String email, String otp) async {
    final result = await AuthService.register(email, otp);

    if (result['success']) {
      final user = result['user'];
      final role = user?['role']?['name'];

      Helpers.showSnackBar(context, 'Registrasi Berhasil');

      // Sync FCM token with backend
      PushNotificationService.syncToken();

      if (role == 'admin') {
        await AuthService.logout();
        Helpers.showSnackBar(context, 'Akses admin via aplikasi dinonaktifkan.');
        return;
      } else if (role == 'driver') {
        Navigator.pushNamedAndRemoveUntil(context, '/driver-dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/user-dashboard', (route) => false);
      }
    } else {
      final msg = result['message']?.toString().replaceAll('Exception: ', '') ?? 'Verifikasi Gagal';
      Helpers.showSnackBar(context, msg);
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
        await AuthService.logout();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
        }
      },
    );
  }
}