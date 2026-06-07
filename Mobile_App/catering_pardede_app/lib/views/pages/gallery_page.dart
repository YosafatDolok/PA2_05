import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/models/gallery_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<GalleryModel> galleries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGalleries();
  }

  Future<void> fetchGalleries() async {
    try {
      final data = await ApiService.get(ApiEndpoints.galleries);

      if (mounted) {
        setState(() {
          galleries = (data as List).map((item) => GalleryModel.fromJson(item)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Sync with premium background
      body: Column(
        children: [
          const CustomHeader(
            showIcons: true,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchGalleries,
              color: AppColors.primary,
              child: isLoading
                  ? _buildShimmerGrid()
                  : galleries.isEmpty
                      ? _buildEmptyState()
                      : _buildGalleryGrid(),
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
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada koleksi foto", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: galleries.length,
      itemBuilder: (context, index) => _galleryCard(galleries[index], index),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => ShimmerLoading.rounded(width: double.infinity, height: double.infinity, borderRadius: 24),
    );
  }

  Widget _galleryCard(GalleryModel gallery, int index) {
    final String imageUrl = gallery.image.startsWith('http') ? gallery.image : "${ApiEndpoints.baseStorage}/${gallery.image}";

    return TapScale(
      onTap: () => _openLightbox(context, imageUrl, gallery.description, gallery.id),
      child: Hero(
        tag: 'gallery_hero_${gallery.id}',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
                if (gallery.description != null && gallery.description!.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      gallery.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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

  void _openLightbox(BuildContext context, String imageUrl, String? description, int id) {
    Helpers.pushSafe(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, _, __) => Stack(
          children: [
            InteractiveViewer(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Hero(
                    tag: 'gallery_hero_$id',
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            if (description != null && description.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 50,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}