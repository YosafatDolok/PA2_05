import 'package:flutter/material.dart';
import '/models/gallery_model.dart';
import '../../core/theme/app_colors.dart';

class GalleryDetailPage extends StatelessWidget {
  const GalleryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = ModalRoute.of(context)!.settings.arguments as GalleryModel;
    final String imageUrl = gallery.image.startsWith('http')
        ? gallery.image
        : "http://10.0.2.2:8000/storage/${gallery.image}";

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Detail Galeri", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'gallery_hero_${gallery.id}',
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8860B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    gallery.description ?? "Dokumentasi acara spesial yang menggunakan jasa Catering Pardede. Kami menjamin kualitas hidangan dan pelayanan terbaik untuk setiap momen berharga Anda.",
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
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