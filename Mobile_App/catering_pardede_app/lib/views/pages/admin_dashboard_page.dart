import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => AuthController.logout(context), 
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(child: Text('Selamat Datang, Admin!'),
      ),
    );
  }
}