import 'package:flutter/material.dart';
import '/controllers/auth_controller.dart';

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
    setState(() => isLoading = true);

    await AuthController.register(
      context,
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1E1E),
      body: Stack(
        children: [

          // ================= HEADER =================
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 30),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Pardede",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "CATERING",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================= FORM =================
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7DF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NAME
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      prefixIcon:
                          const Icon(Icons.person, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // EMAIL
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // PASSWORD
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon:
                          const Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // BUTTON REGISTER
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A017),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "Daftar",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ================= LOGIN LINK =================
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      "Sudah punya akun? Login sekarang",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}