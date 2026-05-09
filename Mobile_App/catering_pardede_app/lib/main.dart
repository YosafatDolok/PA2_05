import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import '/views/auth/auth_wrapper.dart';
import '/core/theme/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import '/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: This will fail until google-services.json is added
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA_5sPP7O6VsipvzPVLDzDOQUyKEDqxMbE',
        appId: '1:505343538576:android:082782effaad7074c6af15',
        messagingSenderId: '505343538576',
        projectId: 'pardede-catering-app',
      ),
    );
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catering Pardede App',
      debugShowCheckedModeBanner: false,
      navigatorKey: PushNotificationService.navigatorKey,

      theme: AppTheme.lightTheme,

      home: const AuthWrapper(),

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}