import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/menu_model.dart';
import '../../models/category_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CategoryModel> categories = [];
  List<MenuModel> menus = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final categoryData = await ApiService.get(ApiEndpoints.categories);
      final menuData = await ApiService.get(ApiEndpoints.menus);

      if (mounted) {
        setState(() {
          categories = (categoryData as List)
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          menus = (menuData as List)
              .map((json) => MenuModel.fromJson(json))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(
                showIcons: true,
                showSearch: true,
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Gagal menyambung ke database:', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 8),
                        Text(errorMessage!, style: AppTextStyles.caption),
                        TextButton(onPressed: _fetchData, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              isLoading
                  ? _buildCategoryShimmer()
                  : _CategoryList(categories: categories),
              
              const SizedBox(height: 32),
              // Menu Populer
              _SectionHeader(title: 'Menu Populer', onSeeAll: () {}),
              const SizedBox(height: 16),
              isLoading
                  ? _buildFeaturedShimmer()
                  : _FeaturedMenu(menus: menus),
                  
              const SizedBox(height: 32),
              // Menu Terlaris
              _SectionHeader(title: 'Menu Terlaris', onSeeAll: () {}),
              const SizedBox(height: 16),
              isLoading
                  ? _buildGridShimmer()
                  : _MenuGrid(menus: menus),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Column(
          children: [
            ShimmerLoading.rounded(width: 60, height: 60, borderRadius: 12),
            const SizedBox(height: 8),
            const ShimmerLoading.rectangular(width: 40, height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedShimmer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ShimmerLoading.rectangular(height: 200),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: ShimmerLoading.rounded(width: double.infinity, height: 180, borderRadius: 16)),
          const SizedBox(width: 12),
          Expanded(child: ShimmerLoading.rounded(width: double.infinity, height: 180, borderRadius: 16)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8860B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w900, 
                color: AppColors.primary
              )),
            ],
          ),
          InkWell(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text('Lihat semua', style: TextStyle(
                  color: Color(0xFFB8860B), 
                  fontWeight: FontWeight.w700,
                  fontSize: 12
                )),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, color: Color(0xFFB8860B), size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayCategories = [
      {'category_id': 0, 'name': 'Semua', 'icon': Icons.grid_view_rounded},
      ...categories.map((c) => {
            'category_id': c.id,
            'name': c.name,
            'icon': _getIconForCategory(c.name),
          }),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: displayCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isFirst = index == 0;
          return TapScale(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isFirst ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isFirst ? null : Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                    boxShadow: [
                      if (isFirst)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Icon(
                    displayCategories[index]['icon'] as IconData,
                    color: isFirst ? Colors.white : AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayCategories[index]['name'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('nasi')) return Icons.restaurant;
    if (lowerName.contains('tumpeng')) return Icons.rice_bowl_outlined;
    if (lowerName.contains('daging')) return Icons.set_meal;
    if (lowerName.contains('ikan')) return Icons.tsunami;
    if (lowerName.contains('snack')) return Icons.cookie;
    if (lowerName.contains('alat')) return Icons.event;
    return Icons.category_outlined;
  }
}

class _FeaturedMenu extends StatelessWidget {
  final List<MenuModel> menus;
  const _FeaturedMenu({required this.menus});

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) return const SizedBox();
    final menu = menus.first;
    final String? imageUrl = menu.image != null
        ? (menu.image!.startsWith('http')
            ? menu.image
            : 'http://10.0.2.2:8000/storage/${menu.image}')
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TapScale(
        onTap: () {},
        child: Hero(
          tag: 'menu_hero_${menu.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[300]),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB8860B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('TERPOPULER', style: TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900
                            )),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            menu.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final List<MenuModel> menus;
  const _MenuGrid({required this.menus});

  @override
  Widget build(BuildContext context) {
    if (menus.length < 2) return const SizedBox();
    final gridItems = menus.skip(1).take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: gridItems.map((menu) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _MenuCard(menu: menu),
          ),
        )).toList(),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = menu.image != null
        ? (menu.image!.startsWith('http')
            ? menu.image
            : 'http://10.0.2.2:8000/storage/${menu.image}')
        : null;

    return TapScale(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'menu_hero_${menu.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200]),
                ),
              ),
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
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rp 65.000',
                        style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      Icon(Icons.add_circle, color: AppColors.primary.withOpacity(0.8), size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}