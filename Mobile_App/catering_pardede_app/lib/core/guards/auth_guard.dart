import 'package:flutter/material.dart';
import '/core/storage/local_storage.dart';
import '/views/auth/login_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  Future<bool> _isLoggedIn() async {
    final token = await LocalStorage.getToken();
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        } else {
          return const LoginPage();
        }
      },
    );
  }
}