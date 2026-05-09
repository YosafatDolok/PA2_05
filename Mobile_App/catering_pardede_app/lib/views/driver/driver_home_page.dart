import 'package:flutter/material.dart';
import '../../controllers/driver_order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';
import '../../core/services/location_service.dart';

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
      backgroundColor: const Color(0xFFF9F7F2),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: _buildStatsBar(),
            ),
            SliverToBoxAdapter(
              child: _buildTabSwitcher(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: isLoading
                  ? SliverToBoxAdapter(child: _buildShimmer())
                  : filteredOrders.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _OrderCard(order: filteredOrders[index]),
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
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            const Text(
              "DASHBOARD DRIVER",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            if (LocationService.isTracking) ...[
              const SizedBox(width: 8),
              ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.2).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primary, Color(0xFF600000)],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Icon(Icons.local_shipping, size: 200, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => AuthController.logout(context),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final activeCount = orders.where((o) => o['status_id'] < 4).length;
    final doneCount = orders.where((o) => o['status_id'] >= 4).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          _statsCard("Aktif", activeCount.toString(), Icons.directions_car, Colors.blue),
          const SizedBox(width: 12),
          _statsCard("Selesai", doneCount.toString(), Icons.check_circle, Colors.green),
          const SizedBox(width: 12),
          _statsCard("Total", orders.length.toString(), Icons.assignment, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _statsCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
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
      child: GestureDetector(
        onTap: () => setState(() => activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSelected ? AppColors.primary : Colors.grey,
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
        padding: const EdgeInsets.only(bottom: 16),
        child: ShimmerLoading.rounded(width: double.infinity, height: 120, borderRadius: 24),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          activeTab == 0 ? "Tidak ada tugas aktif" : "Belum ada riwayat pengantaran",
          style: AppTextStyles.subtitle.copyWith(color: Colors.grey),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/driver-order-detail', arguments: order),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ORD-${order['order_id'].toString().padLeft(5, '0')}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusBadge(statusId, statusName),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      order['user']['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['event_address'],
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(order['event_date'])),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.secondary, size: 20),
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
      case 3: color = Colors.blue; break; // Out for delivery
      case 4: color = Colors.green; break; // Delivered
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
