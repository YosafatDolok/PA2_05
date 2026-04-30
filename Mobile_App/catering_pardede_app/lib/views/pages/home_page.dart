import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/order_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/menu_model.dart';
import '../../models/category_model.dart';
import '../../models/review_model.dart';
import '../widgets/star_rating.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CategoryModel> categories = [];
  List<MenuModel> menus = [];
  List<ReviewModel> reviews = [];
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
      final reviewData = await OrderService.getLatestReviews();

      if (mounted) {
        setState(() {
          categories = (categoryData as List).map((json) => CategoryModel.fromJson(json)).toList();
          menus = (menuData as List).map((json) => MenuModel.fromJson(json)).toList();
          reviews = (reviewData as List).map((json) => ReviewModel.fromJson(json)).toList();
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
      backgroundColor: const Color(0xFFF9F7F2), // Slightly warmer background
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(
                showIcons: true,
                showSearch: true,
              ),
              const SizedBox(height: 24),
              
              // Category Selection
              isLoading ? _buildCategoryShimmer() : _CategoryList(categories: categories),
              
              const SizedBox(height: 32),
              
              // Menu Populer
              _SectionHeader(title: 'Menu Populer', onSeeAll: () {}),
              const SizedBox(height: 16),
              isLoading ? _buildFeaturedShimmer() : _FeaturedMenu(menus: menus),
                  
              const SizedBox(height: 32),
              
              // Menu Terlaris
              _SectionHeader(title: 'Menu Terlaris', onSeeAll: () {}),
              const SizedBox(height: 16),
              isLoading ? _buildGridShimmer() : _MenuGrid(menus: menus),
              
              const SizedBox(height: 32),

              if (reviews.isNotEmpty) ...[
                _SectionHeader(title: 'Apa Kata Mereka?', onSeeAll: () {}),
                const SizedBox(height: 16),
                _ReviewCarousel(reviews: reviews),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => ShimmerLoading.rounded(width: 80, height: 100, borderRadius: 20),
      ),
    );
  }

  Widget _buildFeaturedShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShimmerLoading.rounded(width: double.infinity, height: 200, borderRadius: 24),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: ShimmerLoading.rounded(width: double.infinity, height: 180, borderRadius: 24)),
          const SizedBox(width: 16),
          Expanded(child: ShimmerLoading.rounded(width: double.infinity, height: 180, borderRadius: 24)),
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
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8860B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF420000), // Deep Maroon
              )),
            ],
          ),
          TapScale(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text('Lihat semua', style: TextStyle(
                  color: Color(0xFFB8860B), 
                  fontWeight: FontWeight.bold,
                  fontSize: 13
                )),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB8860B), size: 12),
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
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final name = isAll ? "Semua" : categories[index - 1].name;
          
          return TapScale(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isAll ? const Color(0xFF7A0000) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isAll ? const Color(0xFF7A0000) : Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    isAll ? Icons.grid_view_rounded : _getIconForCategory(name),
                    color: isAll ? Colors.white : const Color(0xFFB8860B),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF7A0000),
                    fontWeight: isAll ? FontWeight.w900 : FontWeight.w700,
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
    if (lowerName.contains('nasi')) return Icons.restaurant_rounded;
    if (lowerName.contains('tumpeng')) return Icons.rice_bowl_rounded;
    if (lowerName.contains('prasmanan')) return Icons.room_service_rounded;
    if (lowerName.contains('snack')) return Icons.bakery_dining_rounded;
    return Icons.category_rounded;
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
        ? (menu.image!.startsWith('http') ? menu.image : 'http://10.0.2.2:8000/storage/${menu.image}')
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TapScale(
        onTap: () => Navigator.pushNamed(context, '/menu-detail', arguments: menu),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('TERPOPULER', style: TextStyle(
                            color: Color(0xFF7A0000), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5
                          )),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          menu.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
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
    );
  }
}

class _ReviewCarousel extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _ReviewCarousel({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        review.userName ?? 'Customer',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF420000)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.verified, size: 10, color: Colors.green),
                          SizedBox(width: 4),
                          Text('VERIFIED', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StarRating(rating: review.rating, isInteractive: false, size: 16),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    review.comment ?? "Tidak ada komentar",
                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
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
        ? (menu.image!.startsWith('http') ? menu.image : 'http://10.0.2.2:8000/storage/${menu.image}')
        : null;

    return TapScale(
      onTap: () => Navigator.pushNamed(context, '/menu-detail', arguments: menu),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF420000)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Catering Quality',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFF9F7F2), shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: Color(0xFFB8860B), size: 18),
                      ),
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