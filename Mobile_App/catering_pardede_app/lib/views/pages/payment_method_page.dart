import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

class PaymentMethodPage extends StatefulWidget {
  final OrderModel order;

  const PaymentMethodPage({super.key, required this.order});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? selectedMethod;

  // 🔴 warna utama (sesuai desain kamu)
  final Color primaryColor = const Color(0xFF8B0000);

  Future<void> _pay() async {
    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih metode pembayaran dulu")),
      );
      return;
    }

    try {
      await ApiService.post(
        ApiEndpoints.payments,
        {
          "order_id": widget.order.id,
          "amount": widget.order.finalPrice
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran berhasil")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal bayar: $e")),
      );
    }
  }

  Widget _buildMethod(String title) {
    bool isSelected = selectedMethod == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            // 🔳 placeholder icon (nanti bisa ganti logo)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            Icon(
              isSelected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: primaryColor,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.order.finalPrice;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Pilih Metode Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          /// LIST METODE
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMethod("Midtrans"),
                  _buildMethod("E-Wallet"),
                  _buildMethod("Transfer Bank"),
                ],
              ),
            ),
          ),

          /// BOTTOM TOTAL + BUTTON
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                /// TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Rp ${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// BUTTON BAYAR
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Bayar Sekarang",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}