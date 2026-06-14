import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/notification_model.dart';
import '../../models/order_model.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/storage/local_storage.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isGuest = true;
        });
      }
      return;
    }

    setState(() {
      isLoading = true;
      isGuest = false;
    });
    try {
      final data = await ApiService.get(ApiEndpoints.notifications);
      if (mounted) {
        setState(() {
          notifications = (data as List).map((json) => NotificationModel.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiService.patch("${ApiEndpoints.notifications}/$id/read", {});
      PushNotificationService.updateUnreadCount(); // Sync global count
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> _handleTap(NotificationModel notification) async {
    if (!notification.isRead) {
      _markAsRead(notification.id);
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            relatedId: notification.relatedId,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }
      });
    }

    if (notification.type == 'order_status' && notification.relatedId != null) {
      // Fetch order detail and navigate
      try {
        final response = await ApiService.get("${ApiEndpoints.orders}/${notification.relatedId}");
        final order = OrderModel.fromJson(response);
        if (mounted) {
          Helpers.pushNamedSafe(context, '/order-detail', arguments: order);
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Gagal memuat detail pesanan: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: Column(
        children: [
          const CustomHeader(
            title: "NOTIFIKASI",
            showIcons: true,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppColors.primary,
              child: isLoading
                  ? _buildShimmerList()
                  : isGuest
                      ? _buildGuestState()
                      : notifications.isEmpty
                          ? _buildEmptyState()
                          : _buildNotificationList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada notifikasi", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Silakan login terlebih dahulu untuk melihat notifikasi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Helpers.pushNamedSafe(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Login Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _notificationCard(notifications[index]),
    );
  }

  Map<String, dynamic> _getSemanticStyle(NotificationModel notification) {
    final title = notification.title.toLowerCase();
    final message = (notification.message ?? '').toLowerCase();
    final bool unread = !notification.isRead;

    IconData iconData = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    Color bgColor = AppColors.primary.withValues(alpha: 0.1);

    if (title.contains('harga') || message.contains('harga') || message.contains('rp')) {
      iconData = Icons.request_quote_rounded;
      iconColor = AppColors.secondary;
      bgColor = AppColors.secondary.withValues(alpha: 0.15);
    } else if (title.contains('batal') || message.contains('batal')) {
      iconData = Icons.cancel_rounded;
      iconColor = const Color(0xFFE53935); // Crimson Red
      bgColor = const Color(0xFFFFEBEE);
    } else if (message.contains('paid') || message.contains('bayar') || message.contains('lunas')) {
      iconData = Icons.payments_rounded;
      iconColor = const Color(0xFF2E7D32); // Emerald Green
      bgColor = const Color(0xFFE8F5E9);
    } else if (message.contains('delivery') || message.contains('kirim') || message.contains('jalan')) {
      iconData = Icons.local_shipping_rounded;
      iconColor = const Color(0xFF1565C0); // Royal Blue
      bgColor = const Color(0xFFE3F2FD);
    } else if (message.contains('preparing') || message.contains('masak') || message.contains('proses') || message.contains('siap')) {
      iconData = Icons.restaurant_rounded;
      iconColor = const Color(0xFFEF6C00); // Orange
      bgColor = const Color(0xFFFFF3E0);
    } else if (notification.type == 'order_status') {
      iconData = Icons.shopping_bag_rounded;
      iconColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.1);
    }

    if (!unread) {
      iconColor = iconColor.withValues(alpha: 0.6);
      bgColor = bgColor.withValues(alpha: 0.4);
    }

    return {
      'icon': iconData,
      'color': iconColor,
      'bg': bgColor,
    };
  }

  Widget _notificationCard(NotificationModel notification) {
    final bool unread = !notification.isRead;
    final semantic = _getSemanticStyle(notification);

    return TapScale(
      onTap: () => _handleTap(notification),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: unread ? Colors.white : const Color(0xFFFCFAF7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: unread ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFEFEFEF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: unread ? 0.05 : 0.02),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: semantic['bg'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                semantic['icon'],
                color: semantic['color'],
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: unread ? FontWeight.w900 : FontWeight.bold,
                            fontSize: 15,
                            color: unread ? AppColors.primary : const Color(0xFF2D0A0A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: unread ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${notification.createdAt.hour.toString().padLeft(2, '0')}:${notification.createdAt.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: 10,
                            color: unread ? AppColors.primary : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message ?? "",
                    style: TextStyle(
                      fontSize: 13,
                      color: unread ? Colors.black87 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.rounded(width: double.infinity, height: 80, borderRadius: 20),
      ),
    );
  }
}
