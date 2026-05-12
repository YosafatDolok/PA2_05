import 'package:flutter/material.dart';
import 'dart:convert';
import '/core/storage/local_storage.dart';
import '/models/user_model.dart';
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
  List<MenuModel> recentlyViewed = [];
  UserModel? user;
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
      
      // Fetch User & Recently Viewed
      UserModel? fetchedUser;
      try {
        final userData = await ApiService.get(ApiEndpoints.user);
        fetchedUser = UserModel.fromJson(userData);
      } catch (_) {}

      final historyData = await LocalStorage.getRecentlyViewed();
      final history = historyData.map((json) => MenuModel.fromJson(jsonDecode(json))).toList();

      if (mounted) {
        setState(() {
          categories = (categoryData as List).map((json) => CategoryModel.fromJson(json)).toList();
          menus = (menuData as List).map((json) => MenuModel.fromJson(json)).toList();
          reviews = (reviewData as List).map((json) => ReviewModel.fromJson(json)).toList();
          recentlyViewed = history;
          user = fetchedUser;
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
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                showIcons: true,
                showSearch: true,
                searchHint: 'Cari hidangan favoritmu...',
                onSearchChanged: (q) {},
              ),
              const SizedBox(height: 32),

              // Personalized Greeting (Now inside a subtle fade animation)
              _EntranceAnimation(
                delay: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? "Halo, ${user!.name.split(' ')[0]}! 👋" : "Halo, Selamat Datang! 👋",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D0A0A),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Pardede Catering siap melayani seleramu.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.brown[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Menu Populer (Carousel)
              _SectionHeader(title: 'Menu Populer', onSeeAll: () {}),
              const SizedBox(height: 20),
              isLoading 
                  ? _buildFeaturedShimmer() 
                  : _FeaturedCarousel(menus: menus.take(5).toList()),
                  
              const SizedBox(height: 40),
              
              // Menu Terlaris
              _SectionHeader(title: 'Menu Terlaris', onSeeAll: () {}),
              const SizedBox(height: 20),
              isLoading ? _buildGridShimmer() : _MenuGrid(menus: menus),
              
              const SizedBox(height: 40),

              if (reviews.isNotEmpty) ...[
                _SectionHeader(title: 'Apa Kata Mereka?', onSeeAll: () {}),
                const SizedBox(height: 20),
                _ReviewCarousel(reviews: reviews),
                const SizedBox(height: 40),
              ],
              
              if (recentlyViewed.isNotEmpty) ...[
                _SectionHeader(title: 'Terakhir Dilihat', onSeeAll: () {}),
                const SizedBox(height: 20),
                _RecentlyViewedList(items: recentlyViewed),
                const SizedBox(height: 40),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ShimmerLoading.rounded(width: double.infinity, height: 220, borderRadius: 32),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: ShimmerLoading.rounded(width: double.infinity, height: 220, borderRadius: 28)),
          const SizedBox(width: 20),
          Expanded(child: ShimmerLoading.rounded(width: double.infinity, height: 220, borderRadius: 28)),
        ],
      ),
    );
  }
}

// --- Premium Widgets ---

class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  const _EntranceAnimation({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  final List<MenuModel> menus;
  const _FeaturedCarousel({required this.menus});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: widget.menus.length,
        itemBuilder: (context, index) {
          final menu = widget.menus[index];
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuint,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: index == _currentPage ? 0 : 10),
            child: _FeaturedItem(menu: menu),
          );
        },
      ),
    );
  }
}

class _FeaturedItem extends StatelessWidget {
  final MenuModel menu;
  const _FeaturedItem({required this.menu});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = menu.image != null
        ? (menu.image!.startsWith('http') ? menu.image : '${ApiEndpoints.baseStorage}/${menu.image}')
        : null;

    return TapScale(
      onTap: () => Navigator.pushNamed(context, '/menu-detail', arguments: menu),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15), 
              blurRadius: 25, 
              offset: const Offset(0, 12)
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
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
                    colors: [
                      Colors.transparent, 
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.9)
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Text('TERPOPULER', style: TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2
                      )),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      menu.name,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 26, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        ? (menu.image!.startsWith('http') ? menu.image : '${ApiEndpoints.baseStorage}/${menu.image}')
        : null;

    return TapScale(
      onTap: () => Navigator.pushNamed(context, '/menu-detail', arguments: menu),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Premium Choice',
                        style: TextStyle(
                          color: Colors.brown[300], 
                          fontWeight: FontWeight.w700, 
                          fontSize: 10,
                          letterSpacing: 0.2
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.accent]
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3), 
                              blurRadius: 8, 
                              offset: const Offset(0, 4)
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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

class _RecentlyViewedList extends StatelessWidget {
  final List<MenuModel> items;
  const _RecentlyViewedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final menu = items[index];
          final String? imageUrl = menu.image != null
              ? (menu.image!.startsWith('http') ? menu.image : '${ApiEndpoints.baseStorage}/${menu.image}')
              : null;

          return TapScale(
            onTap: () => Navigator.pushNamed(context, '/menu-detail', arguments: menu),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[100]),
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.secondary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              Text(title, style: const TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF2D0A0A),
                letterSpacing: -0.5,
              )),
            ],
          ),
          TapScale(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Text('Lihat', style: TextStyle(
                    color: AppColors.secondary, 
                    fontWeight: FontWeight.w800,
                    fontSize: 12
                  )),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondary, size: 10),
                ],
              ),
            ),
          ),
        ],
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
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.userName ?? 'Pelanggan',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF2D0A0A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text('Verified Buyer', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    StarRating(rating: review.rating, isInteractive: false, size: 14),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Text(
                    review.comment ?? "Hidangan yang sangat berkesan.",
                    style: TextStyle(color: Colors.brown[400], fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: gridItems.map((menu) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _EntranceAnimation(
              delay: 2,
              child: _MenuCard(menu: menu),
            ),
          ),
        )).toList(),
      ),
    );
  }
}