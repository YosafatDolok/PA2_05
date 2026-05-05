import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import 'payment_webview.dart';

class PaymentMethodPage extends StatefulWidget {
  final OrderModel order;

  const PaymentMethodPage({super.key, required this.order});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String selectedMethod = "midtrans";
  bool isLoading = false;

  Future<void> _pay() async {
    setState(() => isLoading = true);

    try {
      // 1. CREATE PAYMENT
      final payment = await ApiService.post(
        ApiEndpoints.payments,
        {
          "order_id": widget.order.id,
          "amount": widget.order.finalPrice,
        },
      );

      final paymentId = payment['id'];

      // 2. REQUEST MIDTRANS TOKEN
      final res = await ApiService.post(
        "${ApiEndpoints.basePayment}/payments/$paymentId/midtrans",
        {},
      );

      final snapToken = res['snap_token'];

      // 3. OPEN WEBVIEW MIDTRANS
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(snapToken: snapToken),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal bayar: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget _buildMethod(String title, String value) {
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedMethod == value
                ? const Color(0xFF8B0000)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Icon(
              selectedMethod == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: const Color(0xFF8B0000),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Metode Pembayaran"),
        backgroundColor: const Color(0xFF8B0000),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMethod("Midtrans (All Payment)", "midtrans"),
            _buildMethod("E-Wallet", "ewallet"),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total"),
                Text("Rp ${widget.order.finalPrice}"),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Bayar Sekarang"),
              ),
            )
          ],
        ),
      ),
    );
  }
}