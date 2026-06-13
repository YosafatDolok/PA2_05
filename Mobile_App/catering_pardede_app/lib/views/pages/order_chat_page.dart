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
        _userRole = userData['role']?['name'] ?? (userData['role_id'] == 1 ? 'admin' : 'customer');
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
        margin: const EdgeInsets.only(bottom: 6, top: 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
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
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
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
            if (_userRole == 'admin')
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: GestureDetector(
                  onTap: _showProposalDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.request_quote_rounded, color: AppColors.primary, size: 22),
                  ),
                ),
              ),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
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
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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
