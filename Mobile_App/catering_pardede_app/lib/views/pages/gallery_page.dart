import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tap_scale.dart';
import '/core/services/api_service.dart';
import '/core/constants/api_endpoints.dart';
import '/models/gallery_model.dart';
import '../../core/theme/app_colors.dart';

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
          galleries = (data as List)
              .map((item) => GalleryModel.fromJson(item))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CustomHeader(
            showIcons: true,
          ),
          Expanded(
            child: isLoading
                ? _buildShimmerGrid()
                : galleries.isEmpty
                    ? const Center(child: Text("Belum ada gallery"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: galleries.length,
                        itemBuilder: (context, index) {
                          final gallery = galleries[index];
                          return _galleryCard(gallery);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => ShimmerLoading.rounded(width: double.infinity, height: double.infinity, borderRadius: 16),
    );
  }

  Widget _galleryCard(GalleryModel gallery) {
    final String imageUrl = gallery.image.startsWith('http')
        ? gallery.image
        : "http://10.0.2.2:8000/storage/${gallery.image}";

    return TapScale(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/gallery-detail',
          arguments: gallery,
        );
      },
      child: Hero(
        tag: 'gallery_hero_${gallery.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
            ),
          ),
        ),
      ),
    );
  }
}