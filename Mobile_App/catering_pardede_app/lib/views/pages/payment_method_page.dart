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
import 'payment_instruction_page.dart';

class PaymentMethodPage extends StatefulWidget {
  final OrderModel order;

  const PaymentMethodPage({super.key, required this.order});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String paymentType = "full"; // full atau partial
  final TextEditingController _amountController = TextEditingController();
  
  String selectedPaymentMethod = "bank_transfer"; // bank_transfer, gopay, shopeepay
  String selectedBank = "bca"; // bca, mandiri, bni, bri, permata
  bool isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> paymentBody = {
        "order_id": widget.order.id,
      };

      if (paymentType == "partial") {
        final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (amountText.isEmpty) {
          Helpers.showSnackBar(context, "Masukkan nominal pembayaran DP terlebih dahulu.");
          setState(() => isLoading = false);
          return;
        }
        
        final parsedAmount = int.parse(amountText);
        final minDpAmount = (widget.order.totalPayable * 0.5).toInt();
        
        if (parsedAmount < minDpAmount && widget.order.remainingBalance >= minDpAmount) {
          Helpers.showSnackBar(context, "Minimal pembayaran DP adalah Rp ${Helpers.formatNumber(minDpAmount)} (50% dari total).");
          setState(() => isLoading = false);
          return;
        }
        
        paymentBody['amount'] = parsedAmount;
      }

      // 1. Buat data pembayaran di microservice pembayaran
      final payment = await ApiService.post(
        ApiEndpoints.payments,
        paymentBody,
      );

      final paymentId = payment['id'];

      // 2. Minta Transaksi Native Midtrans dari microservice pembayaran
      final res = await ApiService.post(
        "${ApiEndpoints.basePayment}/payments/$paymentId/midtrans",
        {
          "payment_type": selectedPaymentMethod,
          "bank": selectedPaymentMethod == 'bank_transfer' ? selectedBank : null
        },
      );

      // 3. Buka halaman instruksi pembayaran Native
      if (mounted) {
        final result = await Helpers.pushSafe(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentInstructionPage(paymentResult: res),
          ),
        );

        // Jika user mengklik "Saya sudah bayar"
        if (result == true && mounted) {
          Navigator.pop(context, true); // Kembali ke rincian pesanan dan segarkan halaman
        }
      }
    } catch (e) {
      Helpers.showSnackBar(context, "Gagal bayar: $e");
    }

    setState(() => isLoading = false);
  }

  Widget _buildPaymentOption(String title, String type, String bank, IconData icon) {
    bool isSelected = selectedPaymentMethod == type && (type != 'bank_transfer' || selectedBank == bank);
    return TapScale(
      onTap: () {
        setState(() {
          selectedPaymentMethod = type;
          if (type == 'bank_transfer') selectedBank = bank;
        });
      },
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
                    "PILIH METODE PEMBAYARAN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Virtual Accounts
                  const Text("Virtual Account Bank", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildPaymentOption("BCA Virtual Account", "bank_transfer", "bca", Icons.account_balance),
                  _buildPaymentOption("Mandiri Virtual Account", "bank_transfer", "mandiri", Icons.account_balance),
                  _buildPaymentOption("BNI Virtual Account", "bank_transfer", "bni", Icons.account_balance),
                  _buildPaymentOption("BRI Virtual Account", "bank_transfer", "bri", Icons.account_balance),
                  _buildPaymentOption("Permata Virtual Account", "bank_transfer", "permata", Icons.account_balance),
                  

                  
                  const SizedBox(height: 24),
                  const Text(
                    "PILIH JUMLAH PEMBAYARAN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bayar Penuh
                  TapScale(
                    onTap: () => setState(() => paymentType = "full"),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: paymentType == "full" ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: paymentType == "full" ? AppColors.primary : Colors.grey[200]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            paymentType == "full" ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: paymentType == "full" ? AppColors.primary : Colors.grey[400],
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Bayar Penuh",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            "Rp ${Helpers.formatNumber(widget.order.remainingBalance)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: paymentType == "full" ? AppColors.primary : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bayar Sebagian
                  TapScale(
                    onTap: () => setState(() => paymentType = "partial"),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: paymentType == "partial" ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: paymentType == "partial" ? AppColors.primary : Colors.grey[200]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                paymentType == "partial" ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: paymentType == "partial" ? AppColors.primary : Colors.grey[400],
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Bayar Sebagian (DP)",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (paymentType == "partial") ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                String cleanStr = value.replaceAll(RegExp(r'[^0-9]'), '');
                                if (cleanStr.isEmpty) {
                                  _amountController.value = const TextEditingValue(
                                    text: '',
                                    selection: TextSelection.collapsed(offset: 0),
                                  );
                                  return;
                                }
                                int val = int.parse(cleanStr);
                                String formatted = Helpers.formatNumber(val);
                                _amountController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              },
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                prefixText: "Rp ",
                                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                hintText: "Min. Rp ${Helpers.formatNumber((widget.order.totalPayable * 0.5).toInt())}",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  
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
                              paymentType == "full" 
                                ? "Rp ${Helpers.formatNumber(widget.order.remainingBalance)}"
                                : "Sesuai Input Nominal",
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