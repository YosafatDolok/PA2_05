import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import 'tap_scale.dart';
import '../../core/services/cart_service.dart';
import '../../core/utils/helpers.dart';

class OrderFormSheet extends StatefulWidget {
  final MenuModel? menu;
  final List<MenuModel>? items;
  final VoidCallback? onOrderSuccess;

  const OrderFormSheet({super.key, this.menu, this.items, this.onOrderSuccess});

  @override
  State<OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<OrderFormSheet> {
  final _addressController = TextEditingController();
  final _peopleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;

  Future<void> _pickOnMap() async {
    final result = await Navigator.pushNamed(context, '/map-picker');
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _addressController.text = result['address'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Konfirmasi Pesanan",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      Text(
                        widget.items != null && widget.items!.length > 1
                            ? "${widget.items!.length} Menu Terpilih"
                            : (widget.menu?.name ?? widget.items?.first.name ?? "Menu"),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel("Alamat Acara"),
                TextButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text("Pilih di Peta", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            _buildTextField(_addressController, "Masukkan atau pilih alamat...", maxLines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Tanggal"),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null
                                    ? "Pilih Tanggal"
                                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Jumlah Orang"),
                      _buildTextField(_peopleController, "Contoh: 100", keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel("Catatan Khusus (Opsional)"),
            _buildTextField(_notesController, "Alergi, request saus, dll...", maxLines: 2),
            const SizedBox(height: 30),
            TapScale(
              onTap: _submitOrder,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                alignment: Alignment.center,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        "KONFIRMASI PESANAN",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_addressController.text.isEmpty || _selectedDate == null || _peopleController.text.isEmpty || _latitude == null) {
      Helpers.showSnackBar(context, 'Mohon pilih lokasi di peta');
      return;
    }

    List<Map<String, dynamic>> orderItems = [];
    if (widget.items != null) {
      orderItems = widget.items!.map((item) => {
        'menu_id': item.id,
      }).toList();
    } else if (widget.menu != null) {
      orderItems = [{
        'menu_id': widget.menu!.id,
      }];
    }

    if (orderItems.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService.post(ApiEndpoints.orders, {
        'event_address': _addressController.text,
        'event_latitude': _latitude,
        'event_longitude': _longitude,
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'people': int.parse(_peopleController.text),
        'notes': _notesController.text,
        'items': orderItems,
      });

      if (mounted) {
        Navigator.pop(context); // Close sheet
        
        Helpers.showSuccessDialog(
          context, 
          'Pesanan Terkirim!', 
          'Pesanan Anda telah diterima. Tim kami akan segera meninjau dan menghubungi Anda.',
          onConfirm: () {
            if (widget.onOrderSuccess != null) {
              widget.onOrderSuccess!();
            } else {
              Navigator.pushNamed(context, '/order');
            }
          }
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Gagal membuat pesanan: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
