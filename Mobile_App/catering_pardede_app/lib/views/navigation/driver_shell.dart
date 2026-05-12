import 'package:flutter/material.dart';
import '../driver/driver_home_page.dart';
import '../pages/account_page.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../../core/services/push_notification_service.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    PushNotificationService.syncToken();
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _pages = [
    const DriverHomePage(),
    const AccountPage(),
  ];

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
        items: [
          CustomBottomNavBar.buildNavItemStatic(Icons.dashboard_rounded, 'Dashboard', 0, _currentIndex),
          CustomBottomNavBar.buildNavItemStatic(Icons.person_rounded, 'Profil', 1, _currentIndex),
        ],
      ),
    );
  }
}
