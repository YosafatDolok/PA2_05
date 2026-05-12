import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/cart_service.dart';
import '../../core/theme/app_colors.dart';
import 'order_form_sheet.dart';
import 'tap_scale.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/api_endpoints.dart';

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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: cart.items.isEmpty
                    ? _buildEmptyState()
                    : _buildCartList(),
              ),
              const SizedBox(height: 120), // Spacer for fixed footer
            ],
          ),
          if (cart.items.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Keranjang Saya",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                "${cart.items.length} Hidangan Terpilih",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.brown[200]),
              ),
            ],
          ),
          TapScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EntranceAnimation(
            delay: 0,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 30)]),
              child: Icon(Icons.shopping_basket_rounded, size: 80, color: Colors.brown[50]),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Keranjang Kosong", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A))),
          const SizedBox(height: 12),
          Text(
            "Mulailah petualangan kuliner Anda\ndengan memilih hidangan terbaik kami.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.brown[200], height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 40),
          TapScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Text("LIHAT MENU", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final menu = cart.items[index];
        final bool isAvailable = menu.available ?? true;

        return _EntranceAnimation(
          delay: index % 6,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Dismissible(
              key: Key('cart_${menu.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                HapticFeedback.mediumImpact();
                cart.removeFromCart(menu.id);
                Helpers.showSnackBar(context, "${menu.name} dihapus");
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.red, Color(0xFF8B0000)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        image: menu.image != null
                            ? DecorationImage(
                                image: NetworkImage(menu.image!.startsWith('http') ? menu.image! : '${ApiEndpoints.baseStorage}/${menu.image}'),
                                fit: BoxFit.cover,
                                colorFilter: isAvailable ? null : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                              )
                            : null,
                      ),
                      child: menu.image == null ? Icon(Icons.fastfood_rounded, color: Colors.brown[50]) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isAvailable ? const Color(0xFF2D0A0A) : Colors.red[300],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAvailable ? "Menu Catering" : "Tidak Tersedia",
                            style: TextStyle(
                              color: isAvailable ? Colors.brown[200] : Colors.red[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "SWIPE TO DELETE",
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.brown[200], letterSpacing: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_left_rounded, color: Colors.brown[100], size: 16),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final bool hasUnavailableItems = cart.items.any((item) => !(item.available ?? true));

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Ringkasan Pesanan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF2D0A0A))),
                    Text("${cart.items.length} Item", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.secondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 20),
                TapScale(
                  onTap: hasUnavailableItems ? null : () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    _showCheckoutForm();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: hasUnavailableItems 
                        ? null 
                        : const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      color: hasUnavailableItems ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: hasUnavailableItems ? null : [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      hasUnavailableItems ? "HAPUS MENU TIDAK TERSEDIA" : "LANJUT KE PEMESANAN",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14),
                    ),
                  ),
                ),
              ],
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
        },
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
