import 'package:flutter/material.dart';
import '../../controllers/driver_order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';
import '../../core/services/location_service.dart';
import '../widgets/tap_scale.dart';
import '../../core/services/push_notification_service.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool isLoading = true;
  int activeTab = 0; // 0: Active, 1: History
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final data = await DriverOrderController.getMyOrders();
      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil pesanan: $e')),
        );
      }
    }
  }

  List<dynamic> get filteredOrders {
    if (activeTab == 0) {
      return orders.where((o) => o['status_id'] < 4).toList();
    } else {
      return orders.where((o) => o['status_id'] >= 4).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: _EntranceAnimation(delay: 0, child: _buildStatsBar()),
            ),
            SliverToBoxAdapter(
              child: _EntranceAnimation(delay: 1, child: _buildTabSwitcher()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              sliver: isLoading
                  ? SliverToBoxAdapter(child: _buildShimmer())
                  : filteredOrders.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _EntranceAnimation(
                                  delay: index + 2,
                                  child: _OrderCard(order: filteredOrders[index]),
                                ),
                              );
                            },
                            childCount: filteredOrders.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: const Text(
          "DASHBOARD DRIVER",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
            // Subtle Map Overlay Pattern (Simplified with Icons)
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.map_rounded, size: 200, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ValueListenableBuilder<int>(
          valueListenable: PushNotificationService.unreadCount,
          builder: (context, count, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => PushNotificationService.updateUnreadCount()),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final activeCount = orders.where((o) => o['status_id'] < 4).length;
    final doneCount = orders.where((o) => o['status_id'] >= 4).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Row(
        children: [
          _statsCard("AKTIF", activeCount.toString(), Icons.local_shipping_rounded, Colors.blue),
          const SizedBox(width: 16),
          _statsCard("SELESAI", doneCount.toString(), Icons.check_circle_rounded, Colors.green),
          const SizedBox(width: 16),
          _statsCard("TOTAL", orders.length.toString(), Icons.assignment_rounded, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _statsCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _tabButton(0, "TUGAS AKTIF"),
            _tabButton(1, "RIWAYAT"),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final isSelected = activeTab == index;
    return Expanded(
      child: TapScale(
        onTap: () => setState(() => activeTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSelected ? AppColors.primary : Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ShimmerLoading.rounded(width: double.infinity, height: 160, borderRadius: 32),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)]),
          child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey[200]),
        ),
        const SizedBox(height: 24),
        Text(
          activeTab == 0 ? "Tidak ada tugas aktif" : "Belum ada riwayat pengantaran",
          style: TextStyle(color: Colors.brown[200], fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          "Tetap stand-by untuk pesanan baru.",
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusId = order['status_id'];
    final statusName = order['status']['status_name'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 25, offset: const Offset(0, 12)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/driver-order-detail', arguments: order),
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ORD-${order['order_id'].toString().padLeft(5, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18, letterSpacing: -0.5),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.parse(order['event_date'])),
                          style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    _buildStatusBadge(statusId, statusName),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Color(0xFFF5F5F5), thickness: 1.5),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      order['user']['name'],
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF2D0A0A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        order['event_address'],
                        style: TextStyle(color: Colors.brown[400], fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text("DETAIL PESANAN", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.accent]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int id, String name) {
    Color color;
    switch (id) {
      case 3: color = Colors.blue; break;
      case 4: color = Colors.green; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  const _EntranceAnimation({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
