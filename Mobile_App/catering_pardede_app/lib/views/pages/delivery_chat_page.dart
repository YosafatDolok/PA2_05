import 'package:flutter/material.dart';
import '/controllers/delivery_chat_controller.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/models/delivery_message_model.dart';
import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';

class DeliveryChatPage extends StatefulWidget {
  final int orderId;

  const DeliveryChatPage({super.key, required this.orderId});

  @override
  State<DeliveryChatPage> createState() => _DeliveryChatPageState();
}

class _DeliveryChatPageState extends State<DeliveryChatPage> {
  final DeliveryChatController _chatController = DeliveryChatController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _chatController.fetchMessages(widget.orderId);
    _chatController.initPusher(widget.orderId);
    _chatController.markAsRead(widget.orderId); // Tandai sebagai dibaca saat masuk
    _chatController.addListener(_scrollToAndRead);
  }

  void _scrollToAndRead() {
    _scrollToBottom();
    // Jika pesan baru tiba saat kita berada di halaman ini, tandai sebagai dibaca
    if (_chatController.messages.isNotEmpty && !_chatController.messages.last.isRead) {
       _chatController.markAsRead(widget.orderId);
    }
  }

  Future<void> _loadUser() async {
    final userData = await AuthService.getUser();
    if (userData != null) {
      setState(() {
        _currentUserId = userData['user_id'] ?? userData['id'];
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _chatController.disconnectPusher(widget.orderId);
    _chatController.removeListener(_scrollToAndRead);
    _chatController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLongPressMessage(DeliveryMessageModel message, bool isMe) {
    // Hanya pesan belum dibaca milik sendiri yang dapat dihapus
    if (!isMe || message.isRead || message.isDeleted) return;

    if (_chatController.isOffline) {
      Helpers.showSnackBar(context, 'Koneksi internet diperlukan untuk menghapus pesan');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Hapus Pesan',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              subtitle: const Text('Pesan yang belum dibaca dapat dihapus.',
                style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(message);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DeliveryMessageModel message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pesan?',
          style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Pesan akan dihapus untuk semua peserta. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _chatController.deleteMessage(context, widget.orderId, message.messageId!);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showFailedOptions(DeliveryMessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              title: const Text('Kirim Ulang',
                style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _chatController.retrySendMessage(context, widget.orderId, message.messageId!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Hapus dari Daftar',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _chatController.discardFailedMessage(widget.orderId, message.messageId!);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Koordinasi Pengiriman', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Order #${widget.orderId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _chatController,
            builder: (context, _) {
              if (_chatController.isOffline) {
                return Container(
                  width: double.infinity,
                  color: Colors.amber.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Mode Offline. Pesan akan dikirim otomatis saat terhubung.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _chatController,
              builder: (context, _) {
                if (_chatController.isLoading && _chatController.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (_chatController.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('Belum ada pesan.\nHubungi untuk koordinasi pengiriman.', 
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatController.messages.length,
                  itemBuilder: (context, index) {
                    final message = _chatController.messages[index];
                    final isMe = _currentUserId != null && 
                                 message.senderId.toString() == _currentUserId.toString();
                    return GestureDetector(
                      onLongPress: () => _onLongPressMessage(message, isMe),
                      child: _buildMessageBubble(message, isMe),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DeliveryMessageModel message, bool isMe) {
    // Penampung (placeholder) untuk pesan yang dihapus
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Pesan dihapus',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isSending = message.sendStatus == 'sending';
    final isFailed = message.sendStatus == 'failed';

    final bubbleWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withValues(alpha: isSending ? 0.7 : 1.0) : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && message.sender != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.sender!.name,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            message.message ?? '',
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSending) ...[
                const Icon(Icons.access_time_rounded, color: Colors.white70, size: 10),
                const SizedBox(width: 4),
              ],
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isFailed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showFailedOptions(message),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
              ),
            ),
            bubbleWidget,
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubbleWidget,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.subtitle,
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = _messageController.text;
                _chatController.sendMessage(context, widget.orderId, text);
                _messageController.clear();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      return "$hours:$minutes";
    } catch (e) {
      return '';
    }
  }
}
