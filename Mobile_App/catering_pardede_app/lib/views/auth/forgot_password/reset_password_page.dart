import 'package:flutter/material.dart';
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
  bool _isObscured = true;

  Future<void> _resetPassword() async {
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal 8 karakter")));
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak cocok")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        "${ApiEndpoints.baseUrl}/password/reset",
        {
          'email': widget.email,
          'otp': widget.otp,
          'password': _passwordController.text,
          'password_confirmation': _confirmController.text,
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text("Berhasil!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Kata sandi Anda telah diperbarui. Silakan login kembali.", textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TapScale(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Text("LOGIN SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Password Baru",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              "Hampir selesai! Silakan buat kata sandi baru yang kuat untuk akun Anda.",
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 40),
            
            _inputField(_passwordController, "Password Baru", Icons.lock_outline),
            const SizedBox(height: 20),
            _inputField(_confirmController, "Konfirmasi Password Baru", Icons.lock_reset),
            
            const SizedBox(height: 40),
            
            TapScale(
              onTap: _isLoading ? () {} : _resetPassword,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        "PERBARUI PASSWORD",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: _isObscured,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary),
          hintText: hint,
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          ),
        ),
      ),
    );
  }
}
