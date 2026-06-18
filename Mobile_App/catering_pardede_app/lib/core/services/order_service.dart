import '../constants/api_endpoints.dart';
import 'api_service.dart';

class OrderService {
  static Future<dynamic> submitReview(int orderId, int rating, String comment) async {
    final response = await ApiService.post(
      ApiEndpoints.reviewOrder(orderId),
      {
        'rating': rating,
        'comment': comment,
      },
    );
    return response;
  }

  static Future<dynamic> editReview(int orderId, int rating, String comment) async {
    final response = await ApiService.patch(
      ApiEndpoints.reviewOrder(orderId),
      {
        'rating': rating,
        'comment': comment,
      },
    );
    return response;
  }

  static Future<dynamic> deleteReview(int orderId) async {
    final response = await ApiService.delete(
      ApiEndpoints.reviewOrder(orderId),
    );
    return response;
  }

  static Future<List<dynamic>> getLatestReviews() async {
    final response = await ApiService.get(ApiEndpoints.reviews);
    return response['data'];
  }
}
