import 'package:flutter/material.dart';
import '/views/auth/login_page.dart';
import '/views/auth/register_page.dart';
import '/views/dashboard/admin_dashboard_page.dart';
import '/views/dashboard/user_dashboard_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/admin-dashboard': (context) => const AdminDashboardPage(),
  '/user-dashboard': (context) => const UserDashboardPage(),
};
}