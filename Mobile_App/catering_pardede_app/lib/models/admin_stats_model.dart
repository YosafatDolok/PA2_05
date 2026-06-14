class AdminStatsModel {
  final int unreadMessages;
  final int todayOrders;
  final List<AdminActivity> recentActivity;

  AdminStatsModel({
    required this.unreadMessages,
    required this.todayOrders,
    required this.recentActivity,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      unreadMessages: json['unread_messages'] ?? 0,
      todayOrders: json['today_orders'] ?? 0,
      recentActivity: (json['recent_activity'] as List?)
              ?.map((e) => AdminActivity.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AdminActivity {
  final String title;
  final String message;
  final String createdAt;

  AdminActivity({
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
