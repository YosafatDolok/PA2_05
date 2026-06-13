import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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
import '../../core/utils/helpers.dart';

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
      Helpers.pushNamedSafe(context, '/login');
      return;
    }

    HapticFeedback.mediumImpact();
    cart.addToCart(menu);
    
    Helpers.showSnackBar(
      context, 
      '${menu.name} ditambahkan ke keranjang',
      actionLabel: 'LIHAT',
      onAction: _showCart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomHeader(
            showIcons: true,
            showSearch: true,
            searchHint: "Cari hidangan...",
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
    if (isLoading) return const SizedBox(height: 70);

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final categoryId = isAll ? 0 : category!.id;
          final isSelected = selectedCategoryId == categoryId;
          final name = isAll ? "Semua" : category!.name;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TapScale(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => selectedCategoryId = categoryId);
                _filterMenus();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuint,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]
                  ) : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2D0A0A),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
                    ),
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
            Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.brown[100]),
            const SizedBox(height: 16),
            Text("Hidangan belum tersedia", style: TextStyle(color: Colors.brown[200], fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 0.58,
      ),
      itemCount: filteredMenus.length,
      itemBuilder: (context, index) => _EntranceAnimation(
        delay: index % 6,
        child: _menuCard(filteredMenus[index]),
      ),
    );
  }

  Widget _menuCard(MenuModel menu) {
    final String? imageUrl = menu.image != null
        ? (menu.image!.startsWith('http') ? menu.image : '${ApiEndpoints.baseStorage}/${menu.image}')
        : null;

    return TapScale(
      onTap: () => Helpers.pushNamedSafe(context, '/menu-detail', arguments: menu),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            ),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(color: Colors.grey[100]),
                    ),
                  ),
                ),
                if (menu.category != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            menu.category!.name.toUpperCase(), 
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 15, 
                        color: Color(0xFF2D0A0A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.description ?? "Quality Catering Pardede",
                      style: TextStyle(fontSize: 11, color: Colors.brown[300], height: 1.4, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    _buildAddButton(menu),
                  ],
                ),
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
          gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.accent]
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.2), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text(
              "Tambah",
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark]
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 30),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Text(
                  "${cart.totalItems}",
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: ShimmerLoading.rounded(width: double.infinity, height: double.infinity, borderRadius: 28),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading.rounded(width: 100, height: 16, borderRadius: 6),
                    const SizedBox(height: 8),
                    ShimmerLoading.rounded(width: 140, height: 12, borderRadius: 4),
                    const Spacer(),
                    ShimmerLoading.rounded(width: double.infinity, height: 40, borderRadius: 14),
                  ],
                ),
              ),
            )
          ],
        ),
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