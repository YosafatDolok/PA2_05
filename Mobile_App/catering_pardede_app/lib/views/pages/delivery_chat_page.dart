import 'package:flutter/material.dart';
import '/controllers/delivery_chat_controller.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/models/delivery_message_model.dart';
import '/core/services/auth_service.dart';

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
    _chatController.markAsRead(widget.orderId); // Mark as read when entering
    _chatController.addListener(_scrollToAndRead);
  }

  void _scrollToAndRead() {
    _scrollToBottom();
    // If a new message arrives while we are on the page, mark it as read
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
                    return _buildMessageBubble(message, isMe);
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.white,
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
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
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
