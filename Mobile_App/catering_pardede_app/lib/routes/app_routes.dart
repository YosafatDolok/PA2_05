import 'package:flutter/material.dart';

import '/views/auth/login_page.dart';
import '/views/auth/register_page.dart';
import '/views/landing/landing_page.dart';
import '/views/pages/admin_dashboard_page.dart';
import '/views/navigation/userShell.dart';
import '/views/pages/menu_detail_page.dart';
import '/views/pages/gallery_detail_page.dart';
import '/views/pages/order_detail_page.dart';
import '/views/pages/notification_page.dart';
import '/views/auth/forgot_password/forgot_password_page.dart';
import '/views/auth/forgot_password/otp_verification_page.dart';
import '/views/auth/forgot_password/reset_password_page.dart';
import '/views/pages/order_page.dart';
import '/views/pages/menu_page.dart';
import '/views/pages/chat_inbox_page.dart';

import '/core/guards/role_guard.dart';
import '/models/menu_model.dart';
import '/models/gallery_model.dart';
import '/models/order_model.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      // ================= Authentication =================
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      // ================= Landing =================
      case '/landing':
        return MaterialPageRoute(builder: (_) => const LandingPage());

      // ================= User Navigation =================
      case '/user-dashboard':
        return MaterialPageRoute(builder: (_) => const UserShell());

      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationPage());

      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case '/otp-verify':
        final email = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OtpVerificationPage(email: email));

      case '/password-reset':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            email: args['email'],
            otp: args['otp'],
          ),
        );

      // ================= Admin =================
      case '/admin-dashboard':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            role: 'admin',
            child: AdminDashboardPage(),
          ),
        );

      case '/orders':
        return MaterialPageRoute(builder: (_) => const OrderPage());

      case '/menus':
        return MaterialPageRoute(builder: (_) => const MenuPage());

      case '/messages':
        return MaterialPageRoute(builder: (_) => const ChatInboxPage());

      // ================= Menu Detail =================
      case '/menu-detail':
        final args = settings.arguments;

        if (args is MenuModel) {
          return MaterialPageRoute(
            builder: (_) => const MenuDetailPage(),
            settings: settings,
          );
        }

        return _errorRoute("Menu data not found");

      // ================= Order Detail =================
      case '/order-detail':
        final args = settings.arguments;
        if (args is OrderModel) {
          return MaterialPageRoute(
            builder: (_) => OrderDetailPage(order: args),
          );
        }
        return _errorRoute("Order data not found");

      // ================= Gallery Detail =================
      case '/gallery-detail':
        final args = settings.arguments;

        if (args is GalleryModel) {
          return MaterialPageRoute(
            builder: (_) => const GalleryDetailPage(),
            settings: settings,
          );
        }

        return _errorRoute("Gallery data not found");

      // ================= Fallback =================
      default:
        return _errorRoute("Page not found");
    }
  }

  // ================= Error Page =================
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(message)),
      ),
    );
  }
}