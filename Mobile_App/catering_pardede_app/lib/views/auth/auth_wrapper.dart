import 'package:flutter/material.dart';
import '/core/services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    try {
      final user = await AuthService.getUser().timeout(const Duration(seconds: 5));

      if (!mounted) return;

      // Ensure user is not null, not empty, and has a valid ID
      if (user != null && user.isNotEmpty && (user['user_id'] != null || user['id'] != null)) {
        final role = user['role']?['name'];

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } else {
        // If data is missing or empty, force them to Landing
        Navigator.pushReplacementNamed(context, '/landing');
      }
    } catch (e) {
      debugPrint("AUTH WRAPPER ERROR: $e");
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}