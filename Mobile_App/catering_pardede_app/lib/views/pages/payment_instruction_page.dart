import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/utils/helpers.dart';
import '/core/theme/app_colors.dart';

class PaymentInstructionPage extends StatelessWidget {
  final Map<String, dynamic> paymentResult;

  const PaymentInstructionPage({Key? key, required this.paymentResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paymentType = paymentResult['payment_type'] ?? '';
    final grossAmount = paymentResult['gross_amount'] ?? '0';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Instruksi Pembayaran", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountCard(grossAmount),
            const SizedBox(height: 24),
            if (paymentType == 'bank_transfer' || paymentType == 'echannel' || paymentType == 'permata')
              _buildVirtualAccountSection(context, paymentType)

            else
              _buildFallbackSection(context),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Return success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("SAYA SUDAH BAYAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(String amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text("Total Pembayaran", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            "Rp ${Helpers.formatNumber(double.tryParse(amount.toString()) ?? 0)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualAccountSection(BuildContext context, String paymentType) {
    String bankName = "Bank";
    String vaNumber = "";

    if (paymentType == 'echannel') {
      bankName = "Mandiri";
      final billKey = paymentResult['bill_key'] ?? '';
      final billerCode = paymentResult['biller_code'] ?? '';
      vaNumber = "$billerCode $billKey";
    } else if (paymentType == 'permata') {
      bankName = "Permata";
      vaNumber = paymentResult['permata_va_number'] ?? '';
    } else {
      // bank_transfer
      final vaNumbersList = paymentResult['va_numbers'] as List?;
      if (vaNumbersList != null && vaNumbersList.isNotEmpty) {
        bankName = (vaNumbersList[0]['bank'] ?? '').toString().toUpperCase();
        vaNumber = vaNumbersList[0]['va_number'] ?? '';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Transfer Virtual Account $bankName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Nomor Virtual Account", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vaNumber,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: vaNumber));
                  Helpers.showSnackBar(context, "Nomor VA berhasil disalin");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackSection(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text("Metode pembayaran diproses. Silakan periksa status pesanan Anda."),
      ),
    );
  }
}
