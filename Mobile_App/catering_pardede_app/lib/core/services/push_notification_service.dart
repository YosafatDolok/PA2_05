import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      // You can show a local notification here if needed
    });

    // Handle notification click when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked: ${message.data}');
      // Navigate to chat page based on message.data['order_id']
    });
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  static Future<void> syncToken() async {
    try {
      String? token = await getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await ApiService.post('${ApiEndpoints.baseUrl}/user/fcm-token', {
          'fcm_token': token,
        });
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }
}

// Background handler must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
