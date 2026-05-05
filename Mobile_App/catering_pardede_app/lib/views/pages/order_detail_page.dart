import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/addition_model.dart';
import '../../models/menu_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/custom_header.dart';
import '../widgets/tap_scale.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../widgets/review_sheet.dart';
import '../widgets/star_rating.dart';
import 'order_chat_page.dart';
import '../../core/utils/helpers.dart';
import 'dart:ui';
import '../pages/payment_method_page.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isCancelling = false;
  late OrderModel _currentOrder;
  List<OrderAdditionRequest> _additions = [];
  bool _isLoadingAdditions = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _fetchAdditions();
  }

  Future<void> _fetchAdditions() async {
    setState(() => _isLoadingAdditions = true);
    try {
      final response = await ApiService.get("${ApiEndpoints.orders}/${_currentOrder.id}/additions");
      if (mounted) {
        setState(() {
          _additions = (response as List).map((e) => OrderAdditionRequest.fromJson(e)).toList();
          _isLoadingAdditions = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching additions: $e");
      if (mounted) setState(() => _isLoadingAdditions = false);
    }
  }

  Future<void> _showAddMenuSheet() async {
    List<MenuModel> allMenus = [];
    List<int> selectedMenuIds = [];
    String notes = "";
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (loading && allMenus.isEmpty) {
            ApiService.get(ApiEndpoints.menus).then((res) {
              // 1. Identify all menu IDs already in the order or additions
              final Set<int> existingIds = {};
              if (_currentOrder.items != null) {
                for (var item in _currentOrder.items!) {
                  existingIds.add(item.menuId);
                }
              }
              for (var req in _additions) {
                // Ignore rejected additions if you want to allow re-ordering them
                if (req.statusId != 3) {
                  for (var item in req.items) {
                    existingIds.add(item.menuId);
                  }
                }
              }

              setSheetState(() {
                allMenus = (res as List)
                    .map((m) => MenuModel.fromJson(m))
                    .where((m) => !existingIds.contains(m.id)) // 2. Filter out duplicates
                    .toList();
                loading = false;
              });
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tambah Menu", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          Text("Pesanan Tambahan (Pax-Sync)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                Expanded(
                  child: loading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: allMenus.length,
                        itemBuilder: (context, index) {
                          final menu = allMenus[index];
                          final isSelected = selectedMenuIds.contains(menu.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                            ),
                            child: CheckboxListTile(
                              title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text("Tambahkan menu ini ke pesanan"),
                              value: isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setSheetState(() {
                                  if (val!) {
                                    selectedMenuIds.add(menu.id);
                                  } else {
                                    selectedMenuIds.remove(menu.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => notes = v,
                        decoration: InputDecoration(
                          hintText: "Catatan khusus (opsional)...",
                          fillColor: Colors.grey[100],
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: selectedMenuIds.isEmpty ? null : () async {
                            Navigator.pop(context);
                            _submitAdditions(selectedMenuIds, notes);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("MINTA ${selectedMenuIds.length} MENU TAMBAHAN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _submitAdditions(List<int> menuIds, String notes) async {
    setState(() => _isLoadingAdditions = true);
    try {
      await ApiService.post("${ApiEndpoints.orders}/${_currentOrder.id}/additions", {
        'menu_ids': menuIds,
        'notes': notes,
      });
      _fetchAdditions();
      Helpers.showSnackBar(context, 'Permintaan tambahan dikirim!');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdditions = false);
        Helpers.showSnackBar(context, 'Gagal mengirim: $e');
      }
    }
  }

  Future<void> _cancelAddition(int additionId) async {
    Helpers.showConfirmDialog(
      context,
      title: 'Batalkan Tambahan?',
      message: 'Apakah Anda yakin ingin membatalkan permintaan menu tambahan ini?',
      confirmText: 'Ya, Batalkan',
      onConfirm: () async {
        setState(() => _isLoadingAdditions = true);
        try {
          await ApiService.delete("${ApiEndpoints.orders}/additions/$additionId");
          _fetchAdditions();
          if (mounted) {
            Helpers.showSnackBar(context, 'Permintaan tambahan dibatalkan');
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoadingAdditions = false);
            Helpers.showSnackBar(context, 'Gagal membatalkan: $e');
          }
        }
      },
    );
  }

  Future<void> _cancelOrder() async {
    Helpers.showConfirmDialog(
      context,
      title: 'Batalkan Pesanan?',
      message: 'Apakah Anda yakin ingin membatalkan pesanan ini?',
      confirmText: 'Ya, Batalkan',
      onConfirm: () async {
        setState(() => _isCancelling = true);
        try {
          final response = await ApiService.post("${ApiEndpoints.orders}/${_currentOrder.id}/cancel", {});
          if (mounted) {
            setState(() {
              _currentOrder = OrderModel.fromJson(response['order']);
              _isCancelling = false;
            });
            Helpers.showSnackBar(context, 'Pesanan berhasil dibatalkan');
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isCancelling = false);
            Helpers.showSnackBar(context, 'Gagal membatalkan: $e');
          }
        }
      },
    );
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await ApiService.get("${ApiEndpoints.orders}/${_currentOrder.id}");
      if (mounted) {
        setState(() {
          _currentOrder = OrderModel.fromJson(response);
        });
      }
    } catch (e) {
      debugPrint("Error fetching order details: $e");
    }
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewSheet(orderId: _currentOrder.id),
    ).then((value) {
      if (value == true) {
        _fetchOrderDetails();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = _currentOrder.status?.name.toLowerCase() == 'selesai' || 
                       _currentOrder.status?.name.toLowerCase() == 'delivered';
    bool hasReview = _currentOrder.review != null;

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
                  
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    if (hasReview)
                      _buildReviewCard()
                    else
                      _buildReviewButton(),
                  ],

                  // The "Addition Stack"
                  if (_additions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._additions.asMap().entries.map((entry) => _buildAdditionReceipt(entry.key + 1, entry.value)),
                  ],
                  // ... rest of the build logic

                  if (_currentOrder.statusId == 1 || _currentOrder.statusId == 2) ...[
                    const SizedBox(height: 24),
                    TapScale(
                      onTap: () => _showAddMenuSheet(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "TAMBAH MENU TAMBAHAN",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
            color: Colors.black.withValues(alpha: 0.08),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
              color: AppColors.primary.withValues(alpha: 0.05),
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
                    Builder(
                      builder: (context) {
                        double totalAdditions = 0;
                        for (var req in _additions) {
                          if (req.statusId == 2) {
                            for (var item in req.items) {
                              totalAdditions += item.finalPrice ?? 0;
                            }
                          }
                        }
                        double finalTotal = _currentOrder.finalPrice + totalAdditions;

                        return finalTotal > 0
                            ? Text(
                                "Rp ${finalTotal.toStringAsFixed(0)}",
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
                              );
                      },
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
                const SizedBox(height: 16),
                TapScale(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderChatPage(orderId: _currentOrder.id)),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "DISKUSI HARGA DENGAN ADMIN",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                 // 🔥 TOMBOL BAYAR
    if (_currentOrder.finalPrice > 0 && _currentOrder.statusId == 1)
      TapScale(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentMethodPage(order: _currentOrder),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            "BAYAR SEKARANG",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
                    ),
          ),
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

  Widget _buildAdditionReceipt(int index, OrderAdditionRequest req) {
    double requestTotal = 0;
    if (req.statusId == 2) {
      for (var item in req.items) {
        requestTotal += item.finalPrice ?? 0;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      "PENAMBAHAN #$index",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppColors.primary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: req.statusId == 1 ? Colors.orange.withValues(alpha: 0.1) : (req.statusId == 2 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.statusName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: req.statusId == 1 ? Colors.orange : (req.statusId == 2 ? Colors.green : Colors.red),
                        ),
                      ),
                    ),
                    if (req.statusId == 1) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => _cancelAddition(req.id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const _DashedDivider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...req.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.menuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (req.statusId == 2)
                        Text(
                          "Rp ${item.finalPrice?.toStringAsFixed(0) ?? '-'}",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB8860B), fontSize: 14),
                        ),
                    ],
                  ),
                )),
                if (req.notes != null && req.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "\"${req.notes}\"",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
                if (req.statusId == 2) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("SUBTOTAL TAMBAHAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        "Rp ${requestTotal.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildReviewButton() {
    return TapScale(
      onTap: _showReviewSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
            StarRating(rating: 0, isInteractive: false, size: 24),
            SizedBox(height: 12),
            Text(
              "ULAS PESANAN ANDA",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Bagikan pengalaman Anda bersama kami",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final review = _currentOrder.review!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StarRating(rating: review.rating, isInteractive: false, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment ?? "Tidak ada komentar",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "TERIMA KASIH ATAS ULASAN ANDA!",
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
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
