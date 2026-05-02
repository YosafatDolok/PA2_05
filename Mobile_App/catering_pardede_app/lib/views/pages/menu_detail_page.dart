import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../core/storage/local_storage.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/order_form_sheet.dart';
import '../widgets/tap_scale.dart';
import '../../core/services/cart_service.dart';
import '../widgets/cart_sheet.dart';
import '../../core/services/auth_service.dart';

class MenuDetailPage extends StatefulWidget {
  const MenuDetailPage({super.key});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final adminStatus = await AuthService.isAdmin();
    if (mounted) {
      setState(() {
        isAdmin = adminStatus;
      });
    }
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartSheet(),
    );
  }

  void _showOrderBottomSheet(MenuModel menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderFormSheet(
        menu: menu,
        onOrderSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pesanan berhasil dibuat! Silakan cek di menu Pesanan."), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back to List
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = ModalRoute.of(context)!.settings.arguments as MenuModel;
    final String imageUrl = menu.image != null
        ? (menu.image!.startsWith('http') ? menu.image! : 'http://10.0.2.2:8000/storage/${menu.image}')
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Hero(
            tag: 'menu_hero_${menu.id}',
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover)
                : Container(height: 300, color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 80)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(menu.name,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary))),
                    const Text('Hubungi Admin',
                        style: TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFB8860B), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text("Deskripsi",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 8),
                Text(
                  menu.description ??
                      "Nikmati hidangan spesial dari Catering Pardede yang dibuat dengan bahan berkualitas dan resep tradisional yang otentik.",
                  style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.6),
                ),
                const SizedBox(height: 40),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: isAdmin 
                 ? const Center(child: Text("VIEW MODE (ADMIN)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2)))
                 : _buildActionButtons(menu),
        ),
      ),
    );
  }

  Widget _buildActionButtons(MenuModel menu) {
    if (!(menu.available ?? true)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text("TIDAK TERSEDIA",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TapScale(
            onTap: () {
              CartService().addToCart(menu);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${menu.name} ditambahkan ke keranjang"),
                  backgroundColor: AppColors.primary,
                  action: SnackBarAction(
                    label: 'LIHAT',
                    textColor: Colors.white,
                    onPressed: _showCartSheet,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text("KERANJANG",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TapScale(
            onTap: () async {
              final token = await LocalStorage.getToken();
              if (token == null) {
                Navigator.pushNamed(context, '/login');
                return;
              }
              _showOrderBottomSheet(menu);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              alignment: Alignment.center,
              child: const Text("PESAN SEKARANG",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ),
      ],
    );
  }
}