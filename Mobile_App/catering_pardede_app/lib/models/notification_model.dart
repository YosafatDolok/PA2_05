class NotificationModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String? message;
  final int? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      relatedId: json['related_id'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
