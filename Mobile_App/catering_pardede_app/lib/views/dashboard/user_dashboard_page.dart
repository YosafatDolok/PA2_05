import 'package:flutter/material.dart';
import 'package:catering_pardede_app/controllers/auth_controller.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthController.logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, User!'),
      ),
    );
  }
}