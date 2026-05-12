import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:catering_pardede_app/core/services/api_service.dart';
import 'package:catering_pardede_app/core/constants/api_endpoints.dart';
import 'package:catering_pardede_app/core/storage/local_storage.dart';
import 'package:catering_pardede_app/core/theme/app_colors.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Single source of truth for notification count
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static Future<void> initialize() async {
    // Fetch initial count
    updateUnreadCount();

    // Request permission for Android 13+ and iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 FCM: Permission granted');
      // Sync token immediately after permission is granted
      syncToken();
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('🔔 FCM: Provisional permission granted');
    } else {
      debugPrint('🔔 FCM: Permission denied');
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 FCM Token Refreshed: $newToken');
      syncToken();
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FCM Foreground Message: ${message.notification?.title}');
      debugPrint('📦 Message Data: ${message.data}');

      // Always update count when message arrives
      updateUnreadCount();

      if (message.notification != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final type = message.data['type'];
                  final orderId = message.data['order_id'];
                  
                  if (orderId != null) {
                    if (type == 'driver_assignment') {
                      navigatorKey.currentState?.pushNamed(
                        '/driver-order-detail',
                        arguments: int.parse(orderId.toString()),
                      );
                    } else if (type == 'order_status' || type == 'order_price') {
                      navigatorKey.currentState?.pushNamed(
                        '/order-detail',
                        arguments: int.parse(orderId.toString()),
                      );
                    }
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.notification!.title ?? 'Notifikasi Baru', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          Text(
                            message.notification!.body ?? '',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                  ],
                ),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    });

    // Handle notification click when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked: ${message.data}');
      
      final type = message.data['type'];
      final orderId = message.data['order_id'];

      if (orderId != null) {
        if (type == 'driver_assignment') {
          navigatorKey.currentState?.pushNamed(
            '/driver-order-detail',
            arguments: int.parse(orderId.toString()),
          );
        } else if (type == 'order_status') {
          navigatorKey.currentState?.pushNamed(
            '/order-detail',
            arguments: int.parse(orderId.toString()),
          );
        }
      }
    });
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  static Future<void> syncToken() async {
    try {
      debugPrint('🔔 FCM: Starting token sync...');
      String? token = await getToken();
      if (token != null) {
        debugPrint('🔔 FCM Token: $token');
        final response = await ApiService.post('${ApiEndpoints.baseUrl}/user/fcm-token', {
          'fcm_token': token,
        });
        debugPrint('🔔 FCM: Sync result: $response');
      } else {
        debugPrint('🔔 FCM: Token is NULL');
      }
    } catch (e) {
      debugPrint('🔔 FCM: Error syncing token: $e');
    }
  }
  static Future<void> updateUnreadCount() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) return;

      final data = await ApiService.get(ApiEndpoints.notifications + '/unread-count');
      unreadCount.value = data['unread_count'] ?? 0;
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }
}

// Background handler must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
