import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/menu_page.dart';
import '../pages/order_page.dart';
import '../pages/gallery_page.dart';
import '../pages/account_page.dart';
import '../widgets/custom_bottom_navbar.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    MenuPage(),
    OrderPage(),
    GalleryPage(),
    AccountPage(),
  ];

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}