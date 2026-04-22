import 'package:flutter/material.dart';
import '/views/auth/login_page.dart';
import '/views/auth/register_page.dart';
import '../views/pages/admin_dashboard_page.dart';
import '../views/navigation/UserShell.dart';
import '/views/landing/landing_page.dart';
import '/core/guards/role_guard.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
    '/landing': (context) => const LandingPage(),

    '/admin-dashboard': (context) =>
        const RoleGuard(role: 'admin', child: AdminDashboardPage()),

    '/user-dashboard': (context) =>
        const UserShell(),
  };
}