import 'package:flutter/material.dart';
import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/core/theme/app_colors.dart';
import '/models/chat_inbox_model.dart';
import '/models/order_model.dart';
import '/views/widgets/tap_scale.dart';
import 'package:intl/intl.dart';

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
  }

  Future<void> _fetchInbox() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final data = await ApiService.get(ApiEndpoints.adminInbox);
      
      // The API Resource wraps data in a 'data' key
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pesan Masuk', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchInbox,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : errorMessage != null
              ? _buildErrorState()
              : chats.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchInbox,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: chats.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, color: Color(0xFFF1F1F1)),
                        itemBuilder: (context, index) => _buildChatItem(chats[index]),
                      ),
                    ),
    );
  }

  Widget _buildChatItem(ChatInboxModel chat) {
    return TapScale(
      onTap: () async {
        _markAsReadLocally(chat.orderId);
        
        try {
          final data = await ApiService.get('${ApiEndpoints.orders}/${chat.orderId}');
          final order = OrderModel.fromJson(data);
          if (mounted) {
            Navigator.pushNamed(context, '/order-detail', arguments: order);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka pesanan')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  chat.userName.isNotEmpty ? chat.userName.substring(0, 1).toUpperCase() : 'P',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22),
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
                      Text(
                        chat.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: chat.unreadCount > 0 ? AppColors.primary : Colors.grey,
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Belum ada pesan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: chat.unreadCount > 0 ? Colors.black : Colors.grey.shade600,
                            fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
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
