import 'package:flutter/material.dart';
import '/core/services/auth_service.dart';
import '/views/auth/login_page.dart';

class RoleGuard extends StatelessWidget {
  final String role;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        if (user['role'] == null || user['role']['name'] == null) {
          return const Scaffold(
            body: Center(child: Text('Role not found')),
          );
        }

        if (user['role']['name'] != role) {
          return const Scaffold(
            body: Center(child: Text('Unauthorized')),
          );
        }

        return child;
      },
    );
  }
}