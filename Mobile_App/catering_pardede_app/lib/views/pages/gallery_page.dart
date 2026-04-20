import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Column(
        children: const [
          CustomHeader(
            title: 'Halaman',
            subtitle: 'Gallery',
          ),

          Expanded(
            child: Center(
              child: Text(
                'Ini Halaman Gallery',
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}