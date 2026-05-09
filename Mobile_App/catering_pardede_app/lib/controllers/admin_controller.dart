import 'package:flutter/material.dart';
import '/core/services/admin_service.dart';
import '/models/admin_stats_model.dart';

class AdminController extends ChangeNotifier {
  AdminStatsModel? stats;
  bool isLoading = false;

  Future<void> fetchStats() async {
    isLoading = true;
    notifyListeners();

    final result = await AdminService.getStats();
    if (result != null) {
      stats = result;
      print('Admin Stats Loaded: Pending=${stats?.pendingProposals}, Unread=${stats?.unreadMessages}');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> proposePrice(int orderId, double price) async {
    final success = await AdminService.proposePrice(orderId, price);
    if (success) fetchStats(); // Refresh stats after action
    return success;
  }

  Future<bool> assignDriver(int orderId, int driverId) async {
    final success = await AdminService.assignDriver(orderId, driverId);
    if (success) fetchStats(); // Refresh stats after action
    return success;
  }

  Future<List<dynamic>> getAvailableDrivers() async {
    return await AdminService.getAvailableDrivers();
  }
}
