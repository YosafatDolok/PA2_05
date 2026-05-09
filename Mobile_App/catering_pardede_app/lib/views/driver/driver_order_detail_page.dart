import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/driver_order_controller.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class DriverOrderDetailPage extends StatefulWidget {
  final dynamic order;
  const DriverOrderDetailPage({super.key, required this.order});

  @override
  State<DriverOrderDetailPage> createState() => _DriverOrderDetailPageState();
}

class _DriverOrderDetailPageState extends State<DriverOrderDetailPage> {
  bool isUpdating = false;

  Future<void> _launchNavigation() async {
    final lat = widget.order['event_latitude'];
    final lng = widget.order['event_longitude'];
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat lokasi tidak tersedia')),
      );
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer() async {
    final phone = widget.order['user']['phone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak tersedia')),
      );
      return;
    }
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _startDelivery() async {
    setState(() => isUpdating = true);
    try {
      await DriverOrderController.updateOrderStatus(
        orderId: widget.order['order_id'],
        statusId: 3, // Out for Delivery
      );
      LocationService.startTracking();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip dimulai. GPS Tracking Aktif.')),
        );
      }
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completeDelivery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (image == null) return;

    setState(() => isUpdating = true);
    try {
      await DriverOrderController.updateOrderStatus(
        orderId: widget.order['order_id'],
        statusId: 4, // Delivered
        proofImagePath: image.path,
      );
      LocationService.stopTracking();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan Berhasil Diantar!')),
        );
      }
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final int statusId = order['status_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(order),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("DETAIL PELANGGAN"),
                  const SizedBox(height: 16),
                  _buildInfoCard("Customer", order['user']['name'], Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    "Telepon", 
                    order['user']['phone'] ?? "Tidak tersedia", 
                    Icons.phone_outlined, 
                    onAction: (order['user']['phone'] != null && order['user']['phone'].toString().isNotEmpty) ? _callCustomer : null, 
                    actionIcon: Icons.call
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader("LOKASI PENGANTARAN"),
                  const SizedBox(height: 16),
                  _buildInfoCard("Alamat", order['event_address'], Icons.location_on_outlined, onAction: _launchNavigation, actionIcon: Icons.directions),
                  
                  _buildSectionHeader("WAKTU & KAPASITAS"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard("Tanggal", DateFormat('dd MMM yyyy').format(DateTime.parse(order['event_date'])), Icons.calendar_today_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard("Pax", "${order['people']} Orang", Icons.people_outline)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader("DAFTAR MENU"),
                  const SizedBox(height: 16),
                  _buildMenuList(order['items'] ?? []),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader("CATATAN TAMBAHAN"),
                  const SizedBox(height: 16),
                  _buildInfoCard("Notes", order['notes'] ?? "Tidak ada catatan khusus", Icons.note_alt_outlined),
                  
                  const SizedBox(height: 120), // Space for bottom action
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomAction(statusId)),
    );
  }

  Widget _buildMenuList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Text("Detail menu tidak tersedia", style: TextStyle(color: Colors.grey, fontSize: 13));
    }
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: AppColors.secondary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['menu']['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliverAppBar(dynamic order) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          "ORD-${order['order_id'].toString().padLeft(5, '0')}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.primary),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.receipt_long, size: 150, color: Colors.white.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {VoidCallback? onAction, IconData? actionIcon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              icon: Icon(actionIcon, color: AppColors.secondary),
              onPressed: onAction,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(int statusId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: statusId < 3 
        ? _actionButton("MULAI PENGANTARAN", AppColors.primary, _startDelivery)
        : statusId == 3
          ? _actionButton("KONFIRMASI TERKIRIM", Colors.green, _completeDelivery)
          : const SizedBox(
              width: double.infinity,
              height: 54,
              child: Center(child: Text("PESANAN SELESAI", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 2))),
            ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isUpdating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isUpdating 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
