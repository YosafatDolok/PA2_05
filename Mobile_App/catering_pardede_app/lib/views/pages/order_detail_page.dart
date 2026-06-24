import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/addition_model.dart';
import '../../models/menu_model.dart';
import '../../models/review_model.dart';
import '../../core/services/order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/custom_header.dart';
import '../widgets/tap_scale.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../widgets/review_sheet.dart';
import '../widgets/star_rating.dart';
import 'order_chat_page.dart';
import '/controllers/admin_controller.dart';
import '/core/services/auth_service.dart';
import '../../core/utils/helpers.dart';
import 'dart:ui';
import '../pages/payment_method_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel? order;
  final int? orderId;

  const OrderDetailPage({super.key, this.order, this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isCancelling = false;
  OrderModel? _currentOrder;
  List<OrderAdditionRequest> _additions = [];
  bool _isLoading = true;
  bool _isLoadingAdditions = false;
  bool _isAdmin = false;
  bool _isDriver = false;
  final AdminController _adminController = AdminController();

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _fetchInitialOrder();
    } else if (widget.order != null) {
      // Even if order is passed, fetch latest to avoid stale data from list
      _currentOrder = widget.order;
      _isLoading = false;
      _checkRoles();
      _fetchAdditions();
      _fetchOrderDetails(); // Background refresh
    }
  }

  Future<void> _fetchInitialOrder() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get("${ApiEndpoints.orders}/${widget.orderId}");
      if (mounted) {
        setState(() {
          _currentOrder = OrderModel.fromJson(response);
          _isLoading = false;
        });
        _checkRoles();
        _fetchAdditions();
      }
    } catch (e) {
      debugPrint("Error fetching initial order: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showSnackBar(context, "Gagal memuat detail pesanan");
      }
    }
  }

  Future<void> _checkRoles() async {
    final statusAdmin = await AuthService.isAdmin();
    final statusDriver = await AuthService.isDriver();
    if (mounted) setState(() {
      _isAdmin = statusAdmin;
      _isDriver = statusDriver;
    });
  }

  Future<void> _fetchAdditions() async {
    setState(() => _isLoadingAdditions = true);
    try {
      final response = await ApiService.get("${ApiEndpoints.orders}/${_currentOrder!.id}/additions");
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
              if (_currentOrder!.items != null) {
                for (var item in _currentOrder!.items!) {
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
      await ApiService.post("${ApiEndpoints.orders}/${_currentOrder!.id}/additions", {
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
          final response = await ApiService.post("${ApiEndpoints.orders}/${_currentOrder!.id}/cancel", {});
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

  Future<void> _submitCancelRequest(String reason) async {
    setState(() => _isCancelling = true);
    try {
      final response = await ApiService.post("${ApiEndpoints.orders}/${_currentOrder!.id}/request-cancel", {
        'reason': reason
      });
      if (mounted) {
        setState(() {
          _currentOrder = OrderModel.fromJson(response['order']);
          _isCancelling = false;
        });
        Helpers.showSnackBar(context, 'Permintaan pembatalan telah dikirim');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        Helpers.showSnackBar(context, 'Gagal mengirim permintaan: $e');
      }
    }
  }

  void _showRequestCancelSheet() {
    String reason = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Minta Pembatalan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text("Pesanan Anda sudah dikonfirmasi. Mohon berikan alasan pembatalan untuk ditinjau Admin.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                onChanged: (v) => reason = v,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Contoh: Acara dibatalkan / Salah pilih menu...",
                  fillColor: Colors.grey[100],
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (reason.length < 5) {
                      Helpers.showSnackBar(context, "Mohon berikan alasan yang lebih jelas");
                      return;
                    }
                    Navigator.pop(context);
                    _submitCancelRequest(reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("KIRIM PERMINTAAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await ApiService.get("${ApiEndpoints.orders}/${_currentOrder!.id}");
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
      builder: (context) => ReviewSheet(orderId: _currentOrder!.id),
    ).then((value) {
      if (value == true) {
        _fetchOrderDetails();
      }
    });
  }

  void _showEditReviewSheet(ReviewModel review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewSheet(
        orderId: _currentOrder!.id,
        existingReview: review,
      ),
    ).then((value) {
      if (value == true) {
        _fetchOrderDetails();
      }
    });
  }

  void _confirmDeleteReview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Ulasan',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus ulasan ini?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _deleteReview();
            },
            child: const Text('HAPUS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    setState(() => _isLoading = true);
    try {
      final result = await OrderService.deleteReview(_currentOrder!.id);
      if (mounted) {
        if (result['success']) {
          Helpers.showSnackBar(context, result['message'] ?? 'Ulasan dihapus');
          _fetchOrderDetails();
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Gagal menghapus ulasan');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentOrder == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    bool isCompleted = _currentOrder!.status?.name.toLowerCase() == 'selesai' || 
                       _currentOrder!.status?.name.toLowerCase() == 'delivered' ||
                       _currentOrder!.status?.name.toLowerCase() == 'paid' ||
                       _currentOrder!.status?.name.toLowerCase() == 'settlement';
    bool hasReview = _currentOrder!.review != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CustomHeader(
            title: "STRUK PESANAN",
            showIcons: true,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchOrderDetails();
                await _fetchAdditions();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: _EntranceAnimation(
                  delay: 0,
                  child: Column(
                    children: [
                      _buildStatusStepper(),
                      const SizedBox(height: 24),
                      _buildReceipt(context),
                      
                      if (isCompleted) ...[
                        const SizedBox(height: 20),
                        if (hasReview)
                          _buildReviewCard()
                        else if (!_isAdmin && !_isDriver)
                          _buildReviewButton(),
                      ],

                      if (_isAdmin) ...[
                        const SizedBox(height: 20),
                        _buildAdminActions(),
                      ],

                      if (_additions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ..._additions.asMap().entries.map((entry) => _buildAdditionReceipt(entry.key + 1, entry.value)),
                      ],

                      if (!_isAdmin && !_isDriver && (_currentOrder!.statusId == 1 || _currentOrder!.statusId == 2)) ...[
                        const SizedBox(height: 24),
                        _buildActionButton(
                          "TAMBAH MENU TAMBAHAN",
                          Icons.add_circle_rounded,
                          AppColors.secondary,
                          () => _showAddMenuSheet(),
                        ),
                      ],
                      if (!_isDriver && _currentOrder!.statusId == 1 && _currentOrder!.totalPaid == 0) ...[
                        const SizedBox(height: 16),
                        TapScale(
                          onTap: _isCancelling ? () {} : () => _cancelOrder(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: _isCancelling
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                                : const Text(
                                    "BATALKAN PESANAN",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                                  ),
                          ),
                        ),
                      ] else if (_currentOrder!.isCancelling) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 28),
                              SizedBox(height: 12),
                              Text(
                                "MENUNGGU PERSETUJUAN PEMBATALAN",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Admin sedang meninjau permintaan Anda.",
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!_isDriver && _currentOrder!.statusId >= 1 && _currentOrder!.statusId <= 3 && !_currentOrder!.isCancelling) ...[
                        const SizedBox(height: 16),
                        TapScale(
                          onTap: () => _showRequestCancelSheet(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "MINTA PEMBATALAN",
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper() {
    final statusName = _currentOrder!.status?.name.toLowerCase() ?? 'pending';
    int currentStep = 0;
    if (statusName == 'preparing') currentStep = 1;
    if (statusName == 'out for delivery') currentStep = 2;
    if (statusName == 'delivered' || statusName == 'selesai' || statusName == 'paid' || statusName == 'settlement') currentStep = 3;

    final List<Map<String, dynamic>> steps = [
      {'label': 'Dipesan', 'icon': Icons.assignment_rounded},
      {'label': 'Diproses', 'icon': Icons.restaurant_rounded},
      {'label': 'Dikirim', 'icon': Icons.delivery_dining_rounded},
      {'label': 'Selesai', 'icon': Icons.check_circle_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentStep;
          final isLast = index == steps.length - 1;
          
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.primary : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                        boxShadow: isCompleted 
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                      ),
                      child: Icon(
                        steps[index]['icon'],
                        size: 16,
                        color: isCompleted ? Colors.white : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index]['label'],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCompleted ? FontWeight.w900 : FontWeight.w700,
                        color: isCompleted ? AppColors.primary : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isCompleted ? AppColors.primary : const Color(0xFFF5F5F5),
                              (index + 1) <= currentStep ? AppColors.primary : const Color(0xFFF5F5F5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReceipt(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  "CATERING PARDEDE",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  "Traditional Luxury Catering",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.brown[200], letterSpacing: 1),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTicketInfo("ID PESANAN", "#ORD-${_currentOrder!.id.toString().padLeft(5, '0')}"),
                    _buildTicketInfo("TANGGAL", "${_currentOrder!.orderDate.day}/${_currentOrder!.orderDate.month}/${_currentOrder!.orderDate.year}"),
                  ],
                ),
              ],
            ),
          ),

          const _DashedDivider(),

          // Menu Items
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DETAIL HIDANGAN",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 24),
                ...?_currentOrder!.items?.map((item) => _buildMenuReceiptRow(item)),
              ],
            ),
          ),

          const _DashedDivider(),

          // Event Info
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildEventDetailRow(Icons.event_available_rounded, "Tanggal Acara",
                    "${_currentOrder!.eventDate.day}/${_currentOrder!.eventDate.month}/${_currentOrder!.eventDate.year}"),
                const SizedBox(height: 20),
                _buildEventDetailRow(Icons.location_on_rounded, "Lokasi Pengiriman", _currentOrder!.eventAddress),
                if (_currentOrder!.locationNotes != null && _currentOrder!.locationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildEventDetailRow(Icons.map_outlined, "Catatan Lokasi (Patokan)", _currentOrder!.locationNotes!),
                ],
                if (_currentOrder!.eventLatitude != null && _currentOrder!.eventLongitude != null) ...[
                  const SizedBox(height: 20),
                  _buildMapCard(),
                ],
                if (_currentOrder!.notes != null && _currentOrder!.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildEventDetailRow(Icons.note_alt_rounded, "Catatan Khusus", _currentOrder!.notes!),
                ],
              ],
            ),
          ),

          // Total Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F7F2),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL TRANSAKSI",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1),
                    ),
                    _buildFinalPrice(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildReceiptActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A))),
      ],
    );
  }

  Widget _buildMenuReceiptRow(OrderItemModel item) {
    final String imageUrl = item.menu?.image != null
        ? (item.menu!.image!.startsWith('http') ? item.menu!.image! : '${ApiEndpoints.baseStorage}/${item.menu!.image}')
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl.isEmpty ? const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 20) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menu?.name ?? "Menu Item", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF2D0A0A))),
                Text("Catering Menu Item", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.brown[200])),
              ],
            ),
          ),
          Text(
            item.finalPrice != null ? "Rp ${item.finalPrice!.toStringAsFixed(0)}" : "Included",
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 14, 
              color: item.finalPrice != null ? AppColors.secondary : Colors.green[400]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.secondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4A4A4A), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 180,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_currentOrder!.eventLatitude!, _currentOrder!.eventLongitude!),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.catering.pardede.app'),
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(_currentOrder!.eventLatitude!, _currentOrder!.eventLongitude!),
                  width: 40, height: 40,
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 30),
                ),
              ]),
            ],
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: TapScale(
              onTap: () => Helpers.launchMap(_currentOrder!.eventLatitude!, _currentOrder!.eventLongitude!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: const Row(
                  children: [
                    Icon(Icons.directions_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text("DIRECTIONS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPrice() {
    return _currentOrder!.totalPayable > 0
        ? Text(
            "Rp ${Helpers.formatNumber(_currentOrder!.totalPayable)}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.secondary),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Text("Menunggu Konfirmasi", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.orange)),
          );
  }

  Widget _buildReceiptActions() {
    return Column(
      children: [
        if (_currentOrder!.totalPayable > 0) ...[
          _buildPaymentSummaryRow(
            "SUDAH DIBAYAR",
            _currentOrder!.totalPaid > 0
                ? "- Rp ${Helpers.formatNumber(_currentOrder!.totalPaid)}"
                : "Rp 0",
            _currentOrder!.totalPaid > 0 ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 12),
          const _DashedDivider(),
          const SizedBox(height: 12),
          _buildPaymentSummaryRow(
            "SISA TAGIHAN",
            "Rp ${Helpers.formatNumber(_currentOrder!.remainingBalance)}",
            AppColors.secondary,
            isBold: true,
          ),
          const SizedBox(height: 24),
        ],
        if (!_isDriver)
          _buildReceiptActionButton(
            _isAdmin ? "DISKUSI DENGAN PELANGGAN" : "DISKUSI DENGAN ADMIN",
            Icons.chat_bubble_rounded,
            AppColors.primary,
            () => Helpers.pushSafe(context, MaterialPageRoute(builder: (context) => OrderChatPage(orderId: _currentOrder!.id))),
            unreadCount: _currentOrder!.unreadMessagesCount,
          ),
        if (!_isAdmin && _currentOrder!.driverId != null) ...[
          const SizedBox(height: 12),
          _buildReceiptActionButton(
            "KOORDINASI PENGIRIMAN",
            Icons.local_shipping_rounded,
            Colors.blue,
            () => Helpers.pushNamedSafe(context, '/delivery-chat', arguments: _currentOrder!.id),
          ),
        ],
        if (!_isDriver && _currentOrder!.remainingBalance > 0 && !_isAdmin && _currentOrder!.statusId != 9 && _currentOrder!.totalPayable > 0) ...[
          const SizedBox(height: 12),
          if (!_currentOrder!.isPriceConfirmed) ...[
            _buildReceiptActionButton(
              "MENUNGGU KONFIRMASI HARGA",
              Icons.lock_clock_rounded,
              Colors.grey.shade500,
              null,
              isFilled: true,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.shade500.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Harga pesanan belum dikonfirmasi oleh Admin. Pelanggan baru dapat melakukan pembayaran setelah harga disetujui.",
                      style: TextStyle(
                        color: Colors.amber.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildReceiptActionButton(
              _currentOrder!.totalPaid > 0 ? "BAYAR SISA TAGIHAN" : "BAYAR SEKARANG",
              Icons.payments_rounded,
              const Color(0xFF8B0000),
              () async {
                final result = await Helpers.pushSafe(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentMethodPage(order: _currentOrder!)),
                );

                if (result == true && mounted) {
                  // Beri jeda 2 detik agar callback Midtrans selesai diproses di server
                  await Future.delayed(const Duration(seconds: 2));
                  _fetchOrderDetails();
                  _fetchAdditions();
                }
              },
              isFilled: true,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPaymentSummaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: Colors.grey, letterSpacing: 1),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildReceiptActionButton(String label, IconData icon, Color color, VoidCallback? onTap, {bool isFilled = false, int unreadCount = 0}) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isFilled ? null : Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: isFilled ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 16, color: isFilled ? Colors.white : color),
                if (unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: isFilled ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions() {
    bool needsProposal = _currentOrder!.statusId == 1 && _currentOrder!.finalPrice <= 0;
    bool needsDriver = _currentOrder!.statusId == 2 && _currentOrder!.driverId == null;

    if (!needsProposal && !needsDriver) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MANAJEMEN ADMIN",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        if (needsProposal)
          _buildActionButton(
            "TETAPKAN HARGA FINAL",
            Icons.payments_outlined,
            AppColors.primary,
            () => _showProposePriceSheet(),
          ),
        if (needsDriver)
          _buildActionButton(
            "TUNJUK DRIVER",
            Icons.local_shipping_outlined,
            AppColors.secondary,
            () => _showAssignDriverSheet(),
          ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TapScale(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProposePriceSheet() {
    final TextEditingController priceController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tetapkan Harga Final", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text("Berikan harga total untuk pesanan ini setelah menimbang detail acara.", style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga Total (Rp)",
                  prefixText: "Rp ",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(priceController.text);
                    if (price == null || price <= 0) {
                      Helpers.showSnackBar(context, "Masukkan harga yang valid");
                      return;
                    }
                    Navigator.pop(context);
                    final success = await _adminController.proposePrice(_currentOrder!.id, price);
                    if (success) {
                      _fetchOrderDetails();
                      Helpers.showSnackBar(context, "Harga berhasil ditetapkan!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("KIRIM PENAWARAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDriverSheet() async {
    final drivers = await _adminController.getAvailableDrivers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Driver", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
            const SizedBox(height: 24),
            Expanded(
              child: drivers.isEmpty
                  ? const Center(child: Text("Tidak ada driver tersedia"))
                  : ListView.builder(
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.person, color: Colors.white)),
                          title: Text(driver['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text("Status: Tersedia"),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await _adminController.assignDriver(_currentOrder!.id, driver['id']);
                            if (success) {
                              _fetchOrderDetails();
                              Helpers.showSnackBar(context, "Driver berhasil ditunjuk!");
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAdditionReceipt(int index, OrderAdditionRequest req) {
    double requestTotal = 0;
    for (var item in req.items) {
      requestTotal += item.finalPrice ?? 0;
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
                      if (req.statusId == 2 || (req.statusId == 1 && item.finalPrice != null && item.finalPrice! > 0))
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
                if (req.statusId == 2 || (req.statusId == 1 && requestTotal > 0)) ...[
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F7F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "ULAS PESANAN ANDA",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const StarRating(rating: 0, isInteractive: false, size: 28),
                  const SizedBox(height: 16),
                  const Text(
                    "Bagikan pengalaman Anda bersama kami",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "TULIS ULASAN",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final review = _currentOrder!.review!;
    final hasBeenEdited = review.updatedAt != null &&
        review.createdAt != null &&
        review.updatedAt!.difference(review.createdAt!).inSeconds.abs() > 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F7F2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "ULASAN ANDA",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (hasBeenEdited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "edited: ${review.updatedAt!.day}/${review.updatedAt!.month}/${review.updatedAt!.year}",
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StarRating(rating: review.rating, isInteractive: false, size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Text(
                    review.comment != null && review.comment!.isNotEmpty
                        ? "\"${review.comment}\""
                        : "\"Tidak ada komentar\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TapScale(
                        onTap: () => _showEditReviewSheet(review),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_rounded, size: 16, color: AppColors.secondary),
                              SizedBox(width: 8),
                              Text(
                                "UBAH",
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TapScale(
                        onTap: _confirmDeleteReview,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                "HAPUS",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
