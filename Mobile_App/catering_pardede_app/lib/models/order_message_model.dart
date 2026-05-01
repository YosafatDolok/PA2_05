import 'user_model.dart';

class OrderMessageModel {
  final int? messageId;
  final int orderId;
  final int senderId;
  final String message;
  final bool isRead;
  final String type; // 'text' or 'proposal'
  final double? proposedPrice;
  final String? proposalStatus; // 'pending', 'accepted', 'rejected'
  final String? createdAt;
  final UserModel? sender;

  OrderMessageModel({
    this.messageId,
    required this.orderId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    this.type = 'text',
    this.proposedPrice,
    this.proposalStatus,
    this.createdAt,
    this.sender,
  });

  factory OrderMessageModel.fromJson(Map<String, dynamic> json) {
    return OrderMessageModel(
      messageId: json['message_id'],
      orderId: json['order_id'] is String ? int.parse(json['order_id']) : json['order_id'],
      senderId: json['sender_id'] is String ? int.parse(json['sender_id']) : json['sender_id'],
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      type: json['type'] ?? 'text',
      proposedPrice: json['proposed_price'] != null ? double.parse(json['proposed_price'].toString()) : null,
      proposalStatus: json['proposal_status'],
      createdAt: json['created_at'],
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'order_id': orderId,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'type': type,
      'proposed_price': proposedPrice,
      'proposal_status': proposalStatus,
      'created_at': createdAt,
    };
  }
}
