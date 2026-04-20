import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Column(
        children: const [
          CustomHeader(
            title: 'Halaman',
            subtitle: 'Menu',
          ),

          Expanded(
            child: Center(
              child: Text(
                'Ini Halaman Menu',
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}