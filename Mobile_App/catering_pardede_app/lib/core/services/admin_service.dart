import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/models/admin_stats_model.dart';

class AdminService {
  static Future<AdminStatsModel?> getStats() async {
    try {
      final response = await ApiService.get(ApiEndpoints.adminStats);
      if (response != null) {
        return AdminStatsModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('AdminService Error: $e');
      return null;
    }
  }

  static Future<bool> proposePrice(int orderId, double price) async {
    try {
      await ApiService.post('${ApiEndpoints.orders}/$orderId/proposal', {
        'final_price': price,
      });
      return true;
    } catch (e) {
      print('AdminService proposePrice Error: $e');
      return false;
    }
  }

  static Future<bool> assignDriver(int orderId, int driverId) async {
    try {
      await ApiService.post('${ApiEndpoints.orders}/$orderId/assign-driver', {
        'driver_id': driverId,
      });
      return true;
    } catch (e) {
      print('AdminService assignDriver Error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAvailableDrivers() async {
    try {
      final response = await ApiService.get('${ApiEndpoints.baseUrl}/admin/drivers/available');
      return response as List;
    } catch (e) {
      print('AdminService getAvailableDrivers Error: $e');
      return [];
    }
  }
}
