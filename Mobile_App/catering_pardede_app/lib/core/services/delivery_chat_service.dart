import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/models/delivery_message_model.dart';

class DeliveryChatService {
  static Future<List<DeliveryMessageModel>> getMessages(int orderId) async {
    try {
      final response = await ApiService.get(ApiEndpoints.deliveryMessages(orderId));
      if (response is List) {
        return response.map((m) => DeliveryMessageModel.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching delivery messages: $e');
      return [];
    }
  }

  static Future<DeliveryMessageModel?> sendMessage(int orderId, String message) async {
    try {
      final response = await ApiService.post(ApiEndpoints.deliveryMessages(orderId), {
        'message': message,
      });
      if (response != null) {
        return DeliveryMessageModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error sending delivery message: $e');
      return null;
    }
  }

  static Future<bool> markMessagesAsRead(int orderId) async {
    try {
      final response = await ApiService.post('${ApiEndpoints.deliveryMessages(orderId)}/read', {});
      return response != null;
    } catch (e) {
      print('Error marking delivery messages as read: $e');
      return false;
    }
  }
}
