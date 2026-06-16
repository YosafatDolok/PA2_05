import 'package:flutter/material.dart';
import '/controllers/chat_controller.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/models/order_message_model.dart';
import '/core/services/auth_service.dart';
import '/core/utils/helpers.dart';

class OrderChatPage extends StatefulWidget {
  final int orderId;

  const OrderChatPage({super.key, required this.orderId});

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  final ChatController _chatController = ChatController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _chatController.fetchMessages(widget.orderId).then((_) => _scrollToBottom());
    _chatController.initPusher(widget.orderId);
    _chatController.markAsRead(widget.orderId); // Mark as read when entering
    
    // Safely trigger scroll when controller says so
    _chatController.onNewMessage = () {
      if (mounted) _scrollToBottom();
    };
  }

  Future<void> _loadUser() async {
    final userData = await AuthService.getUser();
    if (userData != null) {
      setState(() {
        // Use user_id specifically as it matches the sender_id in messages
        _currentUserId = userData['user_id'] ?? userData['id'];
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatController.disconnectPusher(widget.orderId);
    _chatController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLongPressMessage(OrderMessageModel message, bool isMe) {
    // Only own unread messages may be deleted
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

  void _confirmDelete(OrderMessageModel message) {
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

  void _showFailedOptions(OrderMessageModel message) {
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
            const Text('Diskusi Harga', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                        Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('Belum ada pesan.\nMulai diskusi tentang harga di sini.', 
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
                    // Strict ID comparison for correct alignment
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

  Widget _buildMessageBubble(OrderMessageModel message, bool isMe) {
    // Deleted message placeholder
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6, top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
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
      margin: const EdgeInsets.only(bottom: 6, top: 2),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        minWidth: 80,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withValues(alpha: isSending ? 0.7 : 1.0) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Text(
            message.message ?? '',
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.textPrimary,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSending) ...[
                  const Icon(Icons.access_time_rounded, color: Colors.white70, size: 10),
                  const SizedBox(width: 4),
                ],
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: GestureDetector(
                onTap: () {
                  final text = _messageController.text;
                  _chatController.sendMessage(context, widget.orderId, text);
                  _messageController.clear();
                },
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
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
