import 'package:flutter/material.dart';
import '../../core/services/cart_service.dart';
import '../../core/theme/app_colors.dart';
import 'order_form_sheet.dart';
import 'tap_scale.dart';
import '../../core/utils/helpers.dart';

class CartSheet extends StatefulWidget {
  const CartSheet({super.key});

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final cart = CartService();

  @override
  void initState() {
    super.initState();
    cart.addListener(_update);
  }

  @override
  void dispose() {
    cart.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: cart.items.isEmpty
                ? _buildEmptyState()
                : _buildCartList(),
          ),
          if (cart.items.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Keranjang Saya",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Keranjang masih kosong", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final menu = cart.items[index];
        final bool isAvailable = menu.available ?? true;
        final String imageUrl = menu.image != null
            ? (menu.image!.startsWith('http') ? menu.image! : 'http://10.0.2.2:8000/storage/${menu.image}')
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: isAvailable ? Colors.grey.shade200 : Colors.red.shade200),
            borderRadius: BorderRadius.circular(16),
            color: isAvailable ? Colors.white : Colors.red.withValues(alpha: 0.02),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColorFiltered(
                  colorFilter: isAvailable ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                      : Container(width: 70, height: 70, color: Colors.grey[200]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isAvailable ? Colors.black : Colors.red)),
                    const SizedBox(height: 4),
                    if (!isAvailable)
                      const Text("Tidak Tersedia Saat Ini", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))
                    else
                      const Text("Menu Catering", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => cart.removeFromCart(menu.id),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final bool hasUnavailableItems = cart.items.any((item) => !(item.available ?? true));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: TapScale(
          onTap: hasUnavailableItems ? null : () {
            Navigator.pop(context);
            _showCheckoutForm();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: hasUnavailableItems ? Colors.grey[400] : AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              hasUnavailableItems ? "HAPUS MENU TIDAK TERSEDIA" : "LANJUT KE PEMESANAN",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckoutForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderFormSheet(
        items: cart.items,
        onOrderSuccess: () {
          cart.clearCart();
          // The Success Dialog is already handled inside OrderFormSheet
        },
      ),
    );
  }
}
