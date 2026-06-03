import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/custom_header.dart';
import '../widgets/tap_scale.dart';
import '../../core/utils/helpers.dart';
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
      // 1. Buat data pembayaran di microservice pembayaran
      final payment = await ApiService.post(
        ApiEndpoints.payments,
        {
          "order_id": widget.order.id,
        },
      );

      final paymentId = payment['id'];

      // 2. Minta Snap Token Midtrans dari microservice pembayaran
      final res = await ApiService.post(
        "${ApiEndpoints.basePayment}/payments/$paymentId/midtrans",
        {},
      );

      final snapToken = res['snap_token'];

      // 3. Buka halaman pembayaran Midtrans di WebView
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(snapToken: snapToken),
          ),
        );

        // Jika WebView berhasil (pembayaran diselesaikan)
        if (result == true && mounted) {
          Navigator.pop(context, true); // Kembali ke rincian pesanan dan segarkan halaman
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal bayar: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget _buildMethod(String title, String value, IconData icon) {
    bool isSelected = selectedMethod == value;
    return TapScale(
      onTap: () => setState(() => selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : Colors.grey[300],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CustomHeader(
            title: "PILIH METODE BAYAR",
            showIcons: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INSTRUKSI PEMBAYARAN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMethod("Midtrans (All Payment)", "midtrans", Icons.payments_rounded),
                  _buildMethod("E-Wallet", "ewallet", Icons.account_balance_wallet_rounded),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Tagihan",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              "Rp ${Helpers.formatNumber(widget.order.remainingBalance)}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TapScale(
                          onTap: isLoading ? null : _pay,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    "BAYAR SEKARANG",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}