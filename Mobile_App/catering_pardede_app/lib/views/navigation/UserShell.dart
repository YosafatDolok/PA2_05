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
  State<UserShell> createState() => UserShellState();
}

class UserShellState extends State<UserShell> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _pages => [
    const HomePage(),
    const MenuPage(),
    OrderPage(onMenuRequested: () => setIndex(1)),
    const GalleryPage(),
    const AccountPage(),
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