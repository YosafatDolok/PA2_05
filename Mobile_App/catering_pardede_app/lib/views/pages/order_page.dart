import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/order_model.dart';
import '../../core/storage/local_storage.dart';
import '../../models/menu_model.dart';
import '../widgets/order_form_sheet.dart';
import '../../core/services/auth_service.dart';

class OrderPage extends StatefulWidget {
  final VoidCallback? onMenuRequested;
  const OrderPage({super.key, this.onMenuRequested});

  @override
  State<OrderPage> createState() => OrderPageState();
}

class OrderPageState extends State<OrderPage> {
  List<OrderModel> orders = [];
  List<OrderModel> filteredOrders = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  bool isAdmin = false;
  int activeTabIndex = 0; // 0: Semua, 1: Aktif, 2: Selesai, 3: Batal

  final List<String> filterTabs = ['Semua', 'Aktif', 'Selesai', 'Batal'];

  @override
  void initState() {
    super.initState();
    _checkStatusAndFetch();
  }

  Future<void> _checkStatusAndFetch() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => isLoggedIn = true);

    final adminStatus = await AuthService.isAdmin();
    if (mounted) setState(() => isAdmin = adminStatus);

    _fetchOrders();
  }

  void clearFilter() {
    if (mounted) {
      setState(() {
        activeTabIndex = 0;
        _applyFilters();
      });
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.get(ApiEndpoints.orders);
      if (mounted) {
        setState(() {
          orders = (data as List).map((json) => OrderModel.fromJson(json)).toList();
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      if (activeTabIndex == 0) {
        filteredOrders = orders;
      } else if (activeTabIndex == 1) {
        filteredOrders = orders.where((o) => ['pending', 'preparing', 'out for delivery'].contains(o.status?.name.toLowerCase())).toList();
      } else if (activeTabIndex == 2) {
        filteredOrders = orders.where((o) => o.status?.name.toLowerCase() == 'delivered').toList();
      } else {
        filteredOrders = orders.where((o) => o.status?.name.toLowerCase() == 'cancelled').toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CustomHeader(showIcons: true),
          if (isLoggedIn && !isLoading && orders.isNotEmpty) _buildFilterTabs(),
          Expanded(
            child: !isLoggedIn
                ? _buildLoginPrompt()
                : isLoading
                    ? _buildShimmerList()
                    : filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : _buildOrderList(),
          )
        ],
      ),
      floatingActionButton: isLoggedIn && !isLoading && !isAdmin ? _buildFAB() : null,
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filterTabs.length,
        itemBuilder: (context, index) {
          final isSelected = activeTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TapScale(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => activeTabIndex = index);
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuint,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]) : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: Text(
                    filterTabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2D0A0A),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) => _EntranceAnimation(
          delay: index % 6,
          child: _buildOrderCard(filteredOrders[index]),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final status = order.status?.name ?? 'Unknown';
    
    return TapScale(
      onTap: () async {
        await Navigator.pushNamed(context, '/order-detail', arguments: order);
        _fetchOrders();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
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
                      '#ORD-${order.id.toString().padLeft(5, '0')}',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.brown[300], fontSize: 12, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.items != null && order.items!.isNotEmpty
                          ? order.items!.map((i) => i.menu?.name ?? 'Menu').join(', ')
                          : 'Catering Event',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A), letterSpacing: -0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                _buildStatusBadge(status, order.unreadMessagesCount),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressTimeline(status),
            const Divider(height: 40, thickness: 1, color: Color(0xFFF5F5F5)),
            Row(
              children: [
                _buildInfoChip(Icons.calendar_today_rounded, '${order.eventDate.day}/${order.eventDate.month}'),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoChip(Icons.location_on_rounded, order.eventAddress)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                order.finalPrice > 0
                    ? Text(
                        'Rp ${order.finalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondary),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Menunggu Harga', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange)),
                      ),
                const Row(
                  children: [
                    Text('Lihat Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.brown[200]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.brown[400]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(String status) {
    int activeStep = 0;
    switch (status.toLowerCase()) {
      case 'pending': activeStep = 0; break;
      case 'preparing': activeStep = 1; break;
      case 'out for delivery': activeStep = 2; break;
      case 'delivered': activeStep = 3; break;
      default: activeStep = -1;
    }

    if (activeStep == -1) return const SizedBox.shrink();

    return Row(
      children: List.generate(4, (index) {
        final isCompleted = index <= activeStep;
        final isLast = index == 3;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.secondary : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.secondary.withValues(alpha: 0.3) : Colors.grey[100],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusBadge(String status, int unreadCount) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'pending': color = Colors.orange; icon = Icons.timer_outlined; break;
      case 'preparing': color = Colors.blue; icon = Icons.restaurant_rounded; break;
      case 'out for delivery': color = Colors.purple; icon = Icons.delivery_dining_rounded; break;
      case 'delivered': color = Colors.green; icon = Icons.check_circle_rounded; break;
      case 'cancelled': color = Colors.red; icon = Icons.cancel_rounded; break;
      default: color = Colors.grey; icon = Icons.help_outline_rounded;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildFAB() {
    return TapScale(
      onTap: _goToMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('PESAN BARU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EntranceAnimation(
              delay: 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Akses Terbatas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A))),
            const SizedBox(height: 12),
            Text('Masuk untuk melihat riwayat perjalanan kuliner Anda bersama kami.', textAlign: TextAlign.center, style: TextStyle(color: Colors.brown[300], fontSize: 14, height: 1.5)),
            const SizedBox(height: 40),
            TapScale(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('MASUK SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EntranceAnimation(
            delay: 0,
            child: Icon(Icons.assignment_rounded, size: 80, color: Colors.brown[50]),
          ),
          const SizedBox(height: 24),
          const Text('Belum Ada Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A))),
          const SizedBox(height: 12),
          Text('Wujudkan momen spesial Anda\ndengan hidangan terbaik kami.', textAlign: TextAlign.center, style: TextStyle(color: Colors.brown[200], fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          TapScale(
            onTap: _goToMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Text('LIHAT MENU', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  void _goToMenu() {
    if (widget.onMenuRequested != null) widget.onMenuRequested!();
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ShimmerLoading.rounded(width: double.infinity, height: 160, borderRadius: 28),
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
      duration: Duration(milliseconds: 600 + (delay * 80)),
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