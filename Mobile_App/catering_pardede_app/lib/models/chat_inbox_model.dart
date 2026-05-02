class ChatInboxModel {
  final int orderId;
  final String userName;
  final String? lastMessage;
  final int unreadCount;
  final DateTime lastMessageTime;

  ChatInboxModel({
    required this.orderId,
    required this.userName,
    this.lastMessage,
    required this.unreadCount,
    required this.lastMessageTime,
  });

  factory ChatInboxModel.fromJson(Map<String, dynamic> json) {
    try {
      return ChatInboxModel(
        orderId: json['order_id'] ?? 0,
        userName: json['user']?['name'] ?? 'Pelanggan',
        lastMessage: json['latest_message']?['message'] ?? '...',
        unreadCount: json['unread_count'] ?? 0,
        lastMessageTime: json['latest_message']?['created_at'] != null 
            ? DateTime.parse(json['latest_message']['created_at'])
            : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now()),
      );
    } catch (e) {
      // Fallback if parsing fails for one item, so the whole list doesn't break
      return ChatInboxModel(
        orderId: json['order_id'] ?? 0,
        userName: 'User',
        unreadCount: 0,
        lastMessageTime: DateTime.now(),
      );
    }
  }
}
