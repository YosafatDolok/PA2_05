import 'user_model.dart';

class OrderMessageModel {
  final int? messageId;
  final int orderId;
  final int senderId;
  final String? message; // bernilai null ketika pesan telah dihapus
  final bool isRead;
  final bool isDeleted;
  final String? createdAt;
  final UserModel? sender;
  final String sendStatus; // 'sending', 'sent', 'failed'

  OrderMessageModel({
    this.messageId,
    required this.orderId,
    required this.senderId,
    this.message,
    this.isRead = false,
    this.isDeleted = false,
    this.createdAt,
    this.sender,
    this.sendStatus = 'sent',
  });

  factory OrderMessageModel.fromJson(Map<String, dynamic> json) {
    return OrderMessageModel(
      messageId: json['message_id'],
      orderId: json['order_id'] is String ? int.parse(json['order_id']) : json['order_id'],
      senderId: json['sender_id'] is String ? int.parse(json['sender_id']) : json['sender_id'],
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      isDeleted: json['is_deleted'] == true,
      createdAt: json['created_at'],
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      sendStatus: json['send_status'] ?? 'sent',
    );
  }

  /// Mengembalikan salinan pesan ini yang ditandai sebagai dihapus (untuk pembaruan optimistik lokal).
  OrderMessageModel copyAsDeleted() {
    return copyWith(
      message: null,
      isDeleted: true,
    );
  }

  OrderMessageModel copyWith({
    int? messageId,
    int? orderId,
    int? senderId,
    String? message,
    bool? isRead,
    bool? isDeleted,
    String? createdAt,
    UserModel? sender,
    String? sendStatus,
  }) {
    return OrderMessageModel(
      messageId: messageId ?? this.messageId,
      orderId: orderId ?? this.orderId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      sendStatus: sendStatus ?? this.sendStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'order_id': orderId,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'created_at': createdAt,
      'send_status': sendStatus,
    };
  }
}
