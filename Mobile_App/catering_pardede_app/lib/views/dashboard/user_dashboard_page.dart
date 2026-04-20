import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/menu_page.dart';
import '../pages/order_page.dart';
import '../pages/gallery_page.dart';
import '../pages/account_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),      // ✅ ini UI utama kamu
    MenuPage(),
    OrderPage(),
    GalleryPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Galeri'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}