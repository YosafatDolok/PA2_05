import 'package:flutter/material.dart';
import '/controllers/chat_controller.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/models/order_message_model.dart';
import '/core/storage/local_storage.dart';
import '/core/services/auth_service.dart';

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
  String? _userRole;

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
        _userRole = userData['role']?['name'] ?? (userData['role_id'] == 1 ? 'admin' : 'customer');
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
            const Text('Diskusi Harga', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                        Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
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
                    final isMe = message.sender?.role?.name != 'admin'; 

                    if (message.type == 'proposal') {
                      return _buildProposalCard(message, isMe);
                    }
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

  Widget _buildMessageBubble(OrderMessageModel message, bool isMe) {
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_userRole == 'admin')
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: _showProposalDialog,
              ),
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

  void _showProposalDialog() {
    final priceController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kirim Penawaran Harga"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Harga Baru (Rp)", hintText: "Contoh: 5000000"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Catatan Penawaran", hintText: "Contoh: Harga setelah diskon menu."),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price != null) {
                _chatController.sendProposal(widget.orderId, noteController.text, price);
                Navigator.pop(context);
              }
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(OrderMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade300, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.request_quote_outlined, color: Colors.amber, size: 40),
            const SizedBox(height: 8),
            const Text("PENAWARAN HARGA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Text(message.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const Divider(height: 24),
            Text(
              "Rp ${message.proposedPrice?.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            if (message.proposalStatus == 'pending' && !isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _chatController.acceptProposal(context, widget.orderId, message.messageId!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("TERIMA PENAWARAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            else if (message.proposalStatus == 'accepted')
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text("DITERIMA", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _formatTime(message.createdAt),
              style: const TextStyle(color: Colors.black38, fontSize: 10),
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
