import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:catering_pardede_app/core/services/api_service.dart';
import 'package:catering_pardede_app/core/constants/api_endpoints.dart';
import 'package:catering_pardede_app/core/storage/local_storage.dart';
import 'package:catering_pardede_app/core/theme/app_colors.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Sumber data tunggal (single source of truth) untuk jumlah notifikasi
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> unreadChatCount = ValueNotifier<int>(0);

  static Future<void> initialize() async {
    // Ambil jumlah notifikasi awal
    updateUnreadCount();
    updateUnreadChatCount();

    // Meminta izin notifikasi untuk Android 13+ dan iOS
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
      // Sinkronisasi token segera setelah izin diberikan
      syncToken();
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('🔔 FCM: Provisional permission granted');
    } else {
      debugPrint('🔔 FCM: Permission denied');
    }

    // Dengarkan pembaruan token (refresh)
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 FCM Token Refreshed: $newToken');
      syncToken();
    });

    // Tangani pesan di latar belakang (background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Tangani pesan di latar depan (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FCM Foreground Message: ${message.notification?.title}');
      debugPrint('📦 Message Data: ${message.data}');

      // Selalu perbarui jumlah notifikasi saat pesan masuk
      updateUnreadCount();
      updateUnreadChatCount();

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
                    final parsedId = int.tryParse(orderId.toString());
                    if (parsedId != null) {
                      if (type == 'driver_assignment') {
                        navigatorKey.currentState?.pushNamed(
                          '/driver-order-detail',
                          arguments: parsedId,
                        );
                      } else if (type == 'order_status' || type == 'order_price') {
                        navigatorKey.currentState?.pushNamed(
                          '/order-detail',
                          arguments: parsedId,
                        );
                      } else if (type == 'order_chat') {
                        navigatorKey.currentState?.pushNamed(
                          '/order-chat',
                          arguments: parsedId,
                        );
                      } else if (type == 'delivery_chat') {
                        navigatorKey.currentState?.pushNamed(
                          '/delivery-chat',
                          arguments: parsedId,
                        );
                      }
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

    // Tangani klik notifikasi saat aplikasi di latar belakang tetapi tidak ditutup sepenuhnya
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked: ${message.data}');
      
      final type = message.data['type'];
      final orderId = message.data['order_id'];

      if (orderId != null) {
        final parsedId = int.tryParse(orderId.toString());
        if (parsedId != null) {
          if (type == 'driver_assignment') {
            navigatorKey.currentState?.pushNamed(
              '/driver-order-detail',
              arguments: parsedId,
            );
          } else if (type == 'order_status' || type == 'order_price') {
            navigatorKey.currentState?.pushNamed(
              '/order-detail',
              arguments: parsedId,
            );
          } else if (type == 'order_chat') {
            navigatorKey.currentState?.pushNamed(
              '/order-chat',
              arguments: parsedId,
            );
          } else if (type == 'delivery_chat') {
            navigatorKey.currentState?.pushNamed(
              '/delivery-chat',
              arguments: parsedId,
            );
          }
        }
      }
    });

    // Tangani klik notifikasi saat aplikasi ditutup sepenuhnya (terminated)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Terminated app launched from notification: ${message.data}');
        final type = message.data['type'];
        final orderId = message.data['order_id'];

        if (orderId != null) {
          final parsedId = int.tryParse(orderId.toString());
          if (parsedId != null) {
            if (type == 'driver_assignment') {
              navigatorKey.currentState?.pushNamed(
                '/driver-order-detail',
                arguments: parsedId,
              );
            } else if (type == 'order_status' || type == 'order_price') {
              navigatorKey.currentState?.pushNamed(
                '/order-detail',
                arguments: parsedId,
              );
            } else if (type == 'order_chat') {
              navigatorKey.currentState?.pushNamed(
                '/order-chat',
                arguments: parsedId,
              );
            } else if (type == 'delivery_chat') {
              navigatorKey.currentState?.pushNamed(
                '/delivery-chat',
                arguments: parsedId,
              );
            }
          }
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
  static Future<void> updateUnreadChatCount() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) return;

      final data = await ApiService.get(ApiEndpoints.unreadChatCount);
      unreadChatCount.value = data['unread_count'] ?? 0;
    } catch (e) {
      debugPrint('Error updating unread chat count: $e');
    }
  }
}

// Handler latar belakang harus merupakan fungsi tingkat atas (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
