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
      final user = await AuthService.getUser()
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (user != null) {
        final role = user['role']?['name'];

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/landing');
      }
    } catch (e) {
      print("AUTH WRAPPER ERROR: $e");

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