import 'package:flutter/material.dart';
import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/core/theme/app_colors.dart';
import '/models/chat_inbox_model.dart';
import '/models/order_model.dart';
import '/views/widgets/tap_scale.dart';
import 'package:intl/intl.dart';
import '../../core/utils/helpers.dart';
import '../widgets/custom_header.dart';
import '/core/services/push_notification_service.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  List<ChatInboxModel> chats = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
    // Refresh inbox in real-time when new chat notifications arrive via FCM
    PushNotificationService.unreadChatCount.addListener(_onUnreadChatCountChanged);
  }

  void _onUnreadChatCountChanged() {
    if (mounted) {
      _refreshInboxInBackground();
    }
  }

  @override
  void dispose() {
    PushNotificationService.unreadChatCount.removeListener(_onUnreadChatCountChanged);
    super.dispose();
  }

  Future<void> _fetchInbox() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final data = await ApiService.get(ApiEndpoints.adminInbox);
      final List list = (data is Map && data.containsKey('data')) ? data['data'] : (data as List);
      
      if (mounted) {
        setState(() {
          chats = list.map((json) => ChatInboxModel.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat pesan: $e';
          isLoading = false;
        });
      }
    }
  }

  // Refreshes the inbox silently without showing the loading spinner or hiding the list
  Future<void> _refreshInboxInBackground() async {
    try {
      final data = await ApiService.get(ApiEndpoints.adminInbox);
      final List list = (data is Map && data.containsKey('data')) ? data['data'] : (data as List);
      
      if (mounted) {
        setState(() {
          chats = list.map((json) => ChatInboxModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Ignore background errors
    }
  }

  void _markAsReadLocally(int orderId) {
    setState(() {
      int index = chats.indexWhere((c) => c.orderId == orderId);
      if (index != -1) {
        final old = chats[index];
        chats[index] = ChatInboxModel(
          orderId: old.orderId,
          userName: old.userName,
          lastMessage: old.lastMessage,
          unreadCount: 0,
          lastMessageTime: old.lastMessageTime,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: Column(
        children: [
          CustomHeader(
            title: 'PESAN MASUK',
            showIcons: false,
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : errorMessage != null
                    ? _buildErrorState()
                    : chats.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchInbox,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: chats.length,
                              itemBuilder: (context, index) => _buildChatItem(chats[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatInboxModel chat) {
    final bool hasUnread = chat.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasUnread ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFEFEFEF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: hasUnread ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TapScale(
        onTap: () async {
          _markAsReadLocally(chat.orderId);
          
          try {
            final data = await ApiService.get('${ApiEndpoints.orders}/${chat.orderId}');
            final order = OrderModel.fromJson(data);
            if (mounted) {
              Helpers.pushNamedSafe(context, '/order-detail', arguments: order);
            }
          } catch (e) {
            if (mounted) {
              Helpers.showSnackBar(context, 'Gagal membuka pesanan: $e');
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      chat.userName.isNotEmpty ? chat.userName.substring(0, 1).toUpperCase() : 'P',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
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
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Order #${chat.orderId} ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold,
                                    color: const Color(0xFF2D0A0A),
                                  ),
                                ),
                                TextSpan(
                                  text: '• ${chat.userName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(chat.lastMessageTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread ? AppColors.secondary : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'Belum ada pesan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          const Text('Tidak ada percakapan aktif', 
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 8),
          const Text('Pesan dari pelanggan akan muncul di sini', 
            style: TextStyle(color: Colors.grey, fontSize: 14)
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInbox,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }
}
