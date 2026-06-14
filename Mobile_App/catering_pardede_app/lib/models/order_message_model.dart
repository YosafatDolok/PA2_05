import 'user_model.dart';

class OrderMessageModel {
  final int? messageId;
  final int orderId;
  final int senderId;
  final String message;
  final bool isRead;

  final String? createdAt;
  final UserModel? sender;

  OrderMessageModel({
    this.messageId,
    required this.orderId,
    required this.senderId,
    required this.message,
    this.isRead = false,
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

      'created_at': createdAt,
    };
  }
}
