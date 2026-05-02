import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/notification_model.dart';
import '../../models/order_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
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
          Navigator.pushNamed(context, '/order-detail', arguments: order);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat detail pesanan: $e")));
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

  Widget _buildNotificationList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _notificationCard(notifications[index]),
    );
  }

  Widget _notificationCard(NotificationModel notification) {
    final bool unread = !notification.isRead;

    return TapScale(
      onTap: () => _handleTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread ? Colors.white : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: unread ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent),
          boxShadow: [
            if (unread) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: unread ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.type == 'order_status' ? Icons.shopping_bag_rounded : Icons.info_rounded,
                color: unread ? AppColors.primary : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 14,
                          color: unread ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      Text(
                        "${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      color: unread ? Colors.black54 : Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
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
