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
  final int? orderId;
  const DriverOrderDetailPage({super.key, this.order, this.orderId});

  @override
  State<DriverOrderDetailPage> createState() => _DriverOrderDetailPageState();
}

class _DriverOrderDetailPageState extends State<DriverOrderDetailPage> {
  bool isUpdating = false;
  bool isLoading = true;
  dynamic _currentOrder;
  final List<String> _checklistItems = [];
  final Map<String, bool> _checklistStates = {};

  @override

  void initState() {
    super.initState();
    if (widget.order != null) {
      _currentOrder = widget.order;
      isLoading = false;
    } else if (widget.orderId != null) {
      _fetchOrderDetails();
    }
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await DriverOrderController.getMyOrders(); // Reuse controller or use API directly
      // Find the specific order in the list (or we could add a getOrderById to the controller)
      final order = response.firstWhere((o) => o['order_id'] == widget.orderId);
      if (mounted) {
        setState(() {
          _currentOrder = order;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pesanan: $e')),
        );
      }
    }
  }

  Future<void> _launchNavigation() async {
    final lat = _currentOrder['event_latitude'];
    final lng = _currentOrder['event_longitude'];
    
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
    final phone = _currentOrder['user']['phone'];
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
        orderId: _currentOrder['order_id'],
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

    if (!mounted) return;

    setState(() => isUpdating = true);
    try {
      await DriverOrderController.updateOrderStatus(
        orderId: _currentOrder['order_id'],
        statusId: 4, // 4 is Delivered
        proofImagePath: image.path,
      );
      LocationService.stopTracking();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan Berhasil Diantar!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_currentOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Pesanan tidak ditemukan")),
      );
    }

    final order = _currentOrder;
    final int statusId = order['status_id'];
    
    final double remainingBalance = double.tryParse((order['remaining_balance'] ?? 0).toString()) ?? 0.0;
    final double totalPayable = double.tryParse((order['total_payable'] ?? 0).toString()) ?? 0.0;

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
                  const SizedBox(height: 12),
                  _buildPaymentCard(remainingBalance, totalPayable),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader("LOKASI PENGANTARAN"),
                  const SizedBox(height: 16),
                  _buildInfoCard("Alamat", order['event_address'], Icons.location_on_outlined, onAction: _launchNavigation, actionIcon: Icons.directions),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader("WAKTU & KAPASITAS"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard("Tanggal", DateFormat('dd MMM yyyy').format(DateTime.parse(order['event_date'])), Icons.calendar_today_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard("Pax", "${order['people']} Orang", Icons.people_outline)),
                    ],
                  ),

                  if (statusId < 3) ...[
                    const SizedBox(height: 32),
                    _buildLoadingChecklist(order),
                  ],

                  const SizedBox(height: 32),
                  _buildSectionHeader("DAFTAR MENU"),
                  const SizedBox(height: 16),
                  _buildMenuList(order['items'] ?? []),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader("CATATAN MASAKAN (KULINER)"),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    "Catatan Chef",
                    (order['notes'] != null && order['notes'].toString().trim().isNotEmpty)
                        ? order['notes']
                        : "Tidak ada catatan masakan khusus",
                    Icons.restaurant_menu_outlined,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader("PETUNJUK LOKASI & PENGIRIMAN"),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    "Catatan Alamat",
                    (order['location_notes'] != null && order['location_notes'].toString().trim().isNotEmpty)
                        ? order['location_notes']
                        : "Tidak ada petunjuk khusus untuk alamat ini",
                    Icons.map_outlined,
                  ),
                  
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

  Widget _buildPaymentCard(double remainingBalance, double totalPayable) {
    final bool isPaid = remainingBalance <= 0;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.monetization_on_outlined,
              color: isPaid ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? "STATUS PEMBAYARAN" : "TAGIHAN COD / SISA BAYAR",
                  style: TextStyle(
                    fontSize: 10,
                    color: isPaid ? Colors.green[800] : Colors.orange[850],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid ? "LUNAS (Paid Online)" : formatter.format(remainingBalance),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isPaid ? Colors.green[900] : Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid 
                      ? "Tidak perlu menagih pembayaran." 
                      : "Harap tagih sisa pembayaran saat serah terima.",
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid ? Colors.green[700] : Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _initChecklist(dynamic order) {
    if (_checklistItems.isNotEmpty) return;
    
    final List<dynamic> items = order['items'] ?? [];
    for (var item in items) {
      final name = item['menu']['name'] ?? 'Menu';
      _checklistItems.add("Menu: $name");
    }
    _checklistItems.add("Peralatan Prasmanan (Pemanas & Meja)");
    _checklistItems.add("Set Alat Makan (${order['people']} Pax)");

    for (var item in _checklistItems) {
      _checklistStates[item] = false;
    }
  }

  Widget _buildLoadingChecklist(dynamic order) {
    _initChecklist(order);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.playlist_add_check, color: AppColors.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CHECKLIST MUATAN (SEBELUM BERANGKAT)",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Pastikan semua barang masuk ke kendaraan sebelum berangkat.",
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._checklistItems.map((item) {
            final isChecked = _checklistStates[item] ?? false;
            return InkWell(
              onTap: () {
                setState(() {
                  _checklistStates[item] = !isChecked;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isChecked ? Colors.green : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isChecked ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: isChecked ? Colors.white : Colors.transparent,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                          color: isChecked ? Colors.green[800] : AppColors.primary,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

