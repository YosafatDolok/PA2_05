import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/models/menu_model.dart';
import '/models/category_model.dart';
import '/core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cart_service.dart';
import '../widgets/cart_sheet.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<MenuModel> allMenus = [];
  List<MenuModel> filteredMenus = [];
  List<CategoryModel> categories = [];
  int selectedCategoryId = 0; // 0 for "All"
  String searchQuery = "";
  bool isLoading = true;
  final cart = CartService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInitialData();
    cart.addListener(_update);
  }

  @override
  void dispose() {
    cart.removeListener(_update);
    _searchController.dispose();
    super.dispose();
  }

  void _update() => setState(() {});

  Future<void> fetchInitialData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get(ApiEndpoints.menus),
        ApiService.get(ApiEndpoints.categories),
      ]);

      if (mounted) {
        setState(() {
          allMenus = (results[0] as List).map((item) => MenuModel.fromJson(item)).toList();
          categories = (results[1] as List).map((item) => CategoryModel.fromJson(item)).toList();
          filteredMenus = allMenus;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterMenus() {
    setState(() {
      filteredMenus = allMenus.where((menu) {
        final matchesCategory = selectedCategoryId == 0 || menu.category?.id == selectedCategoryId;
        final matchesSearch = menu.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (menu.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> handleAddToCart(MenuModel menu) async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    HapticFeedback.mediumImpact();
    cart.addToCart(menu);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${menu.name} ditambahkan ke keranjang"),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: _showCart,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Sync background with Home
      body: Column(
        children: [
          CustomHeader(
            showIcons: true,
            showSearch: true,
            searchHint: "Cari hidangan favoritmu...",
            onSearchChanged: (val) {
              searchQuery = val;
              _filterMenus();
            },
          ),
          _buildCategoryBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchInitialData,
              color: AppColors.primary,
              child: isLoading ? _buildShimmerGrid() : _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingCart(),
    );
  }

  Widget _buildCategoryBar() {
    if (isLoading) return const SizedBox(height: 60);

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final categoryId = isAll ? 0 : category!.id;
          final isSelected = selectedCategoryId == categoryId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TapScale(
              onTap: () {
                setState(() => selectedCategoryId = categoryId);
                _filterMenus();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Text(
                  isAll ? "Semua" : category!.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (filteredMenus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Menu tidak ditemukan", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: filteredMenus.length,
      itemBuilder: (context, index) => _menuCard(filteredMenus[index]),
    );
  }

  Widget _menuCard(MenuModel menu) {
    final String? imageUrl = menu.image != null
        ? (menu.image!.startsWith('http') ? menu.image : 'http://10.0.2.2:8000/storage/${menu.image}')
        : null;

    return TapScale(
      onTap: () {
        Navigator.pushNamed(context, '/menu-detail', arguments: menu);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'menu_hero_${menu.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                    ),
                  ),
                ),
                if (menu.category != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: Text(menu.category!.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF2D3436)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu.description ?? "Catering Pardede Quality",
                    style: TextStyle(fontSize: 10, color: Colors.grey[500], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildAddButton(menu),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(MenuModel menu) {
    return TapScale(
      onTap: () => handleAddToCart(menu),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          "+ Tambah",
          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildFloatingCart() {
    if (cart.totalItems == 0) return const SizedBox.shrink();

    return TapScale(
      onTap: _showCart,
      child: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 28),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Text(
                  "${cart.totalItems}",
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartSheet(),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            ShimmerLoading.rounded(width: double.infinity, height: 140, borderRadius: 24),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ShimmerLoading.rounded(width: 80, height: 15, borderRadius: 4),
                  const SizedBox(height: 10),
                  ShimmerLoading.rounded(width: 120, height: 10, borderRadius: 4),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}