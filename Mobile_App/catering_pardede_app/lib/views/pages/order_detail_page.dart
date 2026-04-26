import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/custom_header.dart';
import '../widgets/tap_scale.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import 'dart:ui';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isCancelling = false;
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Batalkan Pesanan?"),
        content: const Text("Apakah Anda yakin ingin membatalkan pesanan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("TIDAK")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YA, BATALKAN", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      final response = await ApiService.post("${ApiEndpoints.orders}/${_currentOrder.id}/cancel", {});
      if (mounted) {
        setState(() {
          _currentOrder = OrderModel.fromJson(response['order']);
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan berhasil dibatalkan"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membatalkan: $e")));
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
            title: "STRUK PESANAN",
            showIcons: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildReceipt(context),
                  if (_currentOrder.statusId == 1) ...[
                    const SizedBox(height: 24),
                    TapScale(
                      onTap: _isCancelling ? () {} : () => _cancelOrder(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        alignment: Alignment.center,
                        child: _isCancelling
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                            : const Text(
                                "BATALKAN PESANAN",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Section with Logo/Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  "CATERING PARDEDE",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  "Traditional Luxury Catering",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoRow("Order ID", "#ORD-${_currentOrder.id.toString().padLeft(5, '0')}"),
                _buildInfoRow("Tanggal Pesan",
                    "${_currentOrder.orderDate.day}/${_currentOrder.orderDate.month}/${_currentOrder.orderDate.year}"),
                _buildInfoRow("Status", _currentOrder.status?.name.toUpperCase() ?? "PENDING", isStatus: true),
              ],
            ),
          ),

          const _DashedDivider(),

          // Menu Items Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ITEM PESANAN",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ...?_currentOrder.items?.map((item) => _buildItemRow(
                      item.menu?.name ?? "Menu Item",
                      "Catering Menu",
                      item.finalPrice ?? 0,
                    )),
              ],
            ),
          ),

          const _DashedDivider(),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today_outlined, "Tanggal Acara",
                    "${_currentOrder.eventDate.day}/${_currentOrder.eventDate.month}/${_currentOrder.eventDate.year}"),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.location_on_outlined, "Alamat", _currentOrder.eventAddress),
                if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.note_alt_outlined, "Catatan", _currentOrder.notes!),
                ],
              ],
            ),
          ),

          // Total Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL HARGA",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    _currentOrder.finalPrice > 0
                        ? Text(
                            "Rp ${_currentOrder.finalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB8860B),
                            ),
                          )
                        : const Text(
                            "Menunggu Konfirmasi",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                  ],
                ),
                if (_currentOrder.finalPrice <= 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "*Harga final akan ditentukan oleh admin segera.",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    Color statusColor = Colors.orange;
    if (value == "CANCELLED") statusColor = Colors.red;
    if (value == "DELIVERED") statusColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isStatus ? statusColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, String qty, double price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(qty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            price > 0 ? "Rp ${price.toStringAsFixed(0)}" : "-",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }
}


