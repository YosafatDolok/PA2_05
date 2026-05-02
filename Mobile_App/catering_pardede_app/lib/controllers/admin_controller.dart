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
}
