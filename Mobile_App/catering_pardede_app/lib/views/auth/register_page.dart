import 'package:flutter/material.dart';
import '/controllers/auth_controller.dart';
import '/core/utils/helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void handleRegister() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      Helpers.showSnackBar(context, 'Mohon isi semua data');
      return;
    }

    setState(() => isLoading = true);

    await AuthController.requestOtp(
      context,
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => isLoading = false);
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
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "DAFTAR AKUN",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Bergabung dengan Keluarga Pardede",
              style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: nameController,
              hint: "Nama Lengkap",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: emailController,
              hint: "Email",
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: passwordController,
              hint: "Password",
              icon: Icons.lock_outline,
              isObscure: true,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary, // GOLD
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "DAFTAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sudah punya akun? ", style: AppTextStyles.subtitle),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    "MASUK",
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
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
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          icon: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}