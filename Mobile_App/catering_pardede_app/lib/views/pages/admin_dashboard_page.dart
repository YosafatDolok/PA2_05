import 'package:flutter/material.dart';
import '/controllers/admin_controller.dart';
import '/controllers/auth_controller.dart';
import '/core/services/auth_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/views/widgets/tap_scale.dart';
import 'package:intl/intl.dart';
import '../../core/utils/helpers.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminController _adminController = AdminController();
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    _adminController.fetchStats();
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _adminName = user['name'] ?? 'Admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => AuthController.logout(context),
            icon: const Icon(Icons.logout, color: AppColors.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _adminController.fetchStats(),
        color: AppColors.primary,
        child: ListenableBuilder(
          listenable: _adminController,
          builder: (context, _) {
            if (_adminController.isLoading && _adminController.stats == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final stats = _adminController.stats;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Greeting
                Text('Halo, $_adminName 👋', style: AppTextStyles.h1),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 30),

                // Urgent Action Row
                Row(
                  children: [
                    Expanded(
                      child: _buildUrgentCard(
                        title: 'Chat Belum Dibaca',
                        count: stats?.unreadMessages ?? 0,
                        icon: Icons.chat_bubble,
                        color: AppColors.secondary,
                        onTap: () => Helpers.pushNamedSafe(context, '/orders', arguments: {'filter': 'unread_chat'}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildUrgentCard(
                  title: 'Pesanan Hari Ini',
                  count: stats?.todayOrders ?? 0,
                  icon: Icons.delivery_dining,
                  color: Colors.blue.shade800,
                  onTap: () => Helpers.pushNamedSafe(context, '/orders'),
                  isWide: true,
                ),

                const SizedBox(height: 40),

                // Quick Actions Grid
                const Text('Aksi Cepat', style: AppTextStyles.h2),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildActionItem(Icons.shopping_bag, 'Pesanan', '/orders'),
                    _buildActionItem(Icons.restaurant_menu, 'Menu', '/menus'),
                    _buildActionItem(Icons.message, 'Pesan', '/messages'),
                  ],
                ),

                const SizedBox(height: 40),

                // Recent Activity
                const Text('Aktivitas Terbaru', style: AppTextStyles.h2),
                const SizedBox(height: 16),
                if (stats?.recentActivity.isEmpty ?? true)
                  const Center(child: Text('Belum ada aktivitas terbaru', style: AppTextStyles.subtitle))
                else
                  ...stats!.recentActivity.map((activity) => _buildActivityItem(activity)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUrgentCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: isWide ? 100 : 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 40),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AppTextStyles.subtitle),
                      Text('$count Pesanan', style: AppTextStyles.h2),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                  Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, String route) {
    return TapScale(
      onTap: () => Helpers.pushNamedSafe(context, route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.background,
            child: Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(activity.message, style: AppTextStyles.subtitle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(
            _formatTime(activity.createdAt),
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }
}