import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '/controllers/auth_controller.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Column(
        children: [
          const CustomHeader(
            title: 'Halaman',
            subtitle: 'Akun',
          ),

          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  AuthController.logout(context);
                },
                child: const Text('Logout'),
              ),
            ),
          )
        ],
      ),
    );
  }
}