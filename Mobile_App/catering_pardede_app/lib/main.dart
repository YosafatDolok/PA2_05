import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import '/views/auth/auth_wrapper.dart';
import '/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catering Pardede App',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const AuthWrapper(),

      routes: AppRoutes.routes,
    );
  }
}