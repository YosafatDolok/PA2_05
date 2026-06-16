import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/models/order_message_model.dart';

class ChatService {
  static Future<List<OrderMessageModel>> getOrderMessages(int orderId) async {
    try {
      final response = await ApiService.get(ApiEndpoints.orderMessages(orderId));
      if (response is List) {
        return response.map((m) => OrderMessageModel.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  static Future<OrderMessageModel?> sendMessage(int orderId, String message) async {
    try {
      final response = await ApiService.post(ApiEndpoints.orderMessages(orderId), {
        'message': message,
      });
      if (response != null) {
        return OrderMessageModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Soft-deletes a message. Throws with a user-friendly message on failure (e.g. 403).
  static Future<bool> deleteMessage(int orderId, int messageId) async {
    final response = await ApiService.delete(
      ApiEndpoints.deleteOrderMessage(orderId, messageId),
    );
    return response != null;
  }

  static Future<Map<String, dynamic>> authorizeChannel(String url, String channelName, String socketId) async {
    try {
      final response = await ApiService.post(url, {
        'channel_name': channelName,
        'socket_id': socketId,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error authorizing channel: $e');
      return {};
    }
  }

  static Future<bool> markMessagesAsRead(int orderId) async {
    try {
      final response = await ApiService.post('${ApiEndpoints.orderMessages(orderId)}/read', {});
      return response != null;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
}

