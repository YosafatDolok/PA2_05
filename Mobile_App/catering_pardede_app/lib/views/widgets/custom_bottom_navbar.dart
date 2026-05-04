import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFFFFD700), // Yellow/Gold for active
        unselectedItemColor: Colors.white.withValues(alpha: 0.7),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary, // Maroon
        onTap: onTap,
        items: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.grid_view, 'Menu', 1),
          _buildNavItem(Icons.assignment, 'Order', 2),
          _buildNavItem(Icons.image, 'Galeri', 3),
          _buildNavItem(Icons.account_circle, 'Akun', 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: isActive ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}