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
}
