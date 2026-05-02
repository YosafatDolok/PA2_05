import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';

class PaymentService {
  static Future<Map<String, dynamic>> checkout(int orderId) async {
    try {
      final response = await ApiService.post(
        '${ApiEndpoints.baseUrl}/orders/$orderId/checkout',
        {},
      );
      
      return {
        'success': true,
        'snap_token': response['snap_token'],
        'client_key': response['client_key'],
        'snap_url': response['snap_url'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
