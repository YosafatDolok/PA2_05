import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/tap_scale.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_passwordController.text.length < 8) {
      Helpers.showSnackBar(context, 'Password minimal 8 karakter');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      Helpers.showSnackBar(context, 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        ApiEndpoints.resetPassword,
        {
          'email': widget.email,
          'token': widget.otp, // Backend usually expects 'token' or 'otp'
          'password': _passwordController.text,
          'password_confirmation': _confirmController.text,
        },
      );

      if (mounted) {
        Helpers.showSuccessDialog(
          context, 
          'Berhasil!', 
          'Kata sandi Anda telah diperbarui. Silakan login kembali.',
          onConfirm: () {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "BUAT PASSWORD BARU",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Masukkan password baru untuk akun ${widget.email}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 50),
            _buildTextField(
              controller: _passwordController,
              hint: "Password Baru",
              icon: Icons.lock_outline,
              isObscure: true,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _confirmController,
              hint: "Konfirmasi Password",
              icon: Icons.lock_reset_outlined,
              isObscure: true,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "RESET PASSWORD",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          icon: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}
