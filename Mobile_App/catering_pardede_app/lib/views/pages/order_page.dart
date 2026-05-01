import 'package:flutter/material.dart';
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

class OrderPage extends StatefulWidget {
  final VoidCallback? onMenuRequested;
  const OrderPage({super.key, this.onMenuRequested});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<OrderModel> orders = [];
  bool isLoading = true;
  bool isLoggedIn = false;

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

    if (mounted) {
      setState(() {
        isLoggedIn = true;
      });
    }
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.get(ApiEndpoints.orders);
      if (mounted) {
        setState(() {
          orders = (data as List)
              .map((json) => OrderModel.fromJson(json))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CustomHeader(
            showIcons: true,
          ),
          Expanded(
            child: !isLoggedIn
                ? _buildLoginPrompt()
                : isLoading
                    ? _buildShimmerList()
                    : orders.isEmpty
                        ? _buildEmptyState()
                        : _buildOrderList(),
          )
        ],
      ),
      floatingActionButton: isLoggedIn && !isLoading ? _buildFAB() : null,
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _goToMenu,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('PESAN BARU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Akses Terbatas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Silakan login terlebih dahulu untuk melihat riwayat pesanan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TapScale(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('LOGIN SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ShimmerLoading.rounded(width: double.infinity, height: 120, borderRadius: 20),
      ),
    );
  }

  void _goToMenu() {
    if (widget.onMenuRequested != null) {
      widget.onMenuRequested!();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Belum ada pesanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mulai pesanan pertama Anda sekarang!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TapScale(
            onTap: _goToMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('LIHAT MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return TapScale(
      onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#ORD-${order.id.toString().padLeft(5, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                Row(
                  children: [
                    if (order.unreadMessagesCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              order.unreadMessagesCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    _buildStatusBadge(order.status?.name ?? 'Unknown'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.items != null && order.items!.isNotEmpty
                  ? order.items!.map((i) => i.menu?.name ?? 'Menu').join(', ')
                  : 'Menu Pesanan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Event: ${order.eventDate.day}/${order.eventDate.month}/${order.eventDate.year}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.eventAddress,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                order.finalPrice > 0
                    ? Text(
                        'Rp ${order.finalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFB8860B)),
                      )
                    : const Text(
                        'Menunggu Konfirmasi Harga',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                const Text(
                  'Detail >',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = Colors.orange; break;
      case 'preparing': color = Colors.blue; break;
      case 'out for delivery': color = Colors.purple; break;
      case 'delivered': color = Colors.green; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}