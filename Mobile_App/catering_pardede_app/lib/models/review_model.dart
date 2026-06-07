class ReviewModel {
  final int? reviewId;
  final int orderId;
  final int userId;
  final int rating;
  final String? comment;
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userName;

  ReviewModel({
    this.reviewId,
    required this.orderId,
    required this.userId,
    required this.rating,
    this.comment,
    this.isVisible = true,
    this.createdAt,
    this.updatedAt,
    this.userName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['review_id'],
      orderId: json['order_id'],
      userId: json['user_id'],
      rating: json['rating'],
      comment: json['comment'],
      isVisible: json['is_visible'] == 1 || json['is_visible'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      userName: json['user'] != null ? json['user']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'is_visible': isVisible ? 1 : 0,
    };
  }
}
