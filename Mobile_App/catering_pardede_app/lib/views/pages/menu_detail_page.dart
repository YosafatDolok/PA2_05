import 'package:flutter/material.dart';
import 'dart:convert';
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
import '../../core/utils/helpers.dart';

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
    _recordVisit();
  }

  Future<void> _recordVisit() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final menu = ModalRoute.of(context)!.settings.arguments as MenuModel;
      await LocalStorage.addRecentlyViewed(jsonEncode(menu.toJson()));
    });
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
          Helpers.showSnackBar(
            context, 
            'Pesanan berhasil dibuat! Silakan cek di menu Pesanan.'
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
        ? (menu.image!.startsWith('http') ? menu.image! : '${ApiEndpoints.baseStorage}/${menu.image}')
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(menu, imageUrl),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(menu),
                  const SizedBox(height: 32),
                  _buildQuickInfoBar(menu),
                  const SizedBox(height: 32),
                  _buildDescriptionSection(menu),
                  const SizedBox(height: 32), // Reduced space as it's not overlapping now
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomAction(menu)),
    );
  }

  Widget _buildSliverAppBar(MenuModel menu, String imageUrl) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary, // Maroon when collapsed
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'menu_hero_${menu.id}',
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 80)),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(MenuModel menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          menu.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoBar(MenuModel menu) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.category_outlined, menu.category?.name ?? "Menu", "Kategori"),
          _infoItem(
            menu.available == true ? Icons.check_circle_outline : Icons.highlight_off, 
            menu.available == true ? "Tersedia" : "Habis", 
            "Status"
          ),
          _infoItem(Icons.star_outline, "0", "Ulasan"), // Will be synced with real count
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDescriptionSection(MenuModel menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TENTANG MENU",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Text(
          menu.description ?? "Nikmati hidangan spesial dari Catering Pardede yang dibuat dengan bahan berkualitas dan resep tradisional yang otentik. Cocok untuk acara pernikahan, lamaran, dan syukuran keluarga.",
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary.withValues(alpha: 0.8),
            height: 1.8,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(MenuModel menu) {
    if (isAdmin) {
      return Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(color: Colors.white),
        child: const Text(
          "VIEW MODE (ADMIN)",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2),
        ),
      );
    }

    return Container(
      height: 100, // Fixed height to prevent stretching
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Allow buttons to fill the 100px height
        children: [
          Expanded(
            child: TapScale(
              onTap: () {
                CartService().addToCart(menu);
                Helpers.showSnackBar(
                  context,
                  '${menu.name} ditambahkan',
                  actionLabel: 'LIHAT',
                  onAction: _showCartSheet,
                );
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Text("KERANJANG", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TapScale(
              onTap: () async {
                final token = await LocalStorage.getToken();
                if (token == null) {
                  Helpers.pushNamedSafe(context, '/login');
                  return;
                }
                _showOrderBottomSheet(menu);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Text("PESAN SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}