import 'package:flutter/material.dart';
import '/models/user_model.dart';
import '/core/services/api_service.dart';
import '/core/services/auth_service.dart';
import '/core/constants/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/custom_header.dart';
import '../widgets/tap_scale.dart';
import 'edit_profile_page.dart';
import '../../controllers/auth_controller.dart';
import '../../core/services/push_notification_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  UserModel? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccountData();
  }

  Future<void> _fetchAccountData() async {
    try {
      final data = await ApiService.get(ApiEndpoints.user);

      if (mounted) {
        setState(() {
          user = UserModel.fromJson(data);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          user = null;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                const CustomHeader(showIcons: true),
                Expanded(
                  child: user == null ? _buildGuestView() : _buildUserView(),
                ),
              ],
            ),
    );
  }

  Widget _buildGuestView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          children: [
            _EntranceAnimation(
              delay: 0,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 30)],
                ),
                child: const Icon(Icons.person_outline_rounded, size: 80, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 40),
            const _EntranceAnimation(
              delay: 1,
              child: Text(
                "Selamat Datang",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A)),
              ),
            ),
            const SizedBox(height: 12),
            _EntranceAnimation(
              delay: 2,
              child: Text(
                "Masuk untuk menikmati pengalaman kuliner boutique terbaik bersama kami.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.brown[200], fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 60),
            _EntranceAnimation(
              delay: 3,
              child: _buildGoldButton("MASUK KE AKUN", () => Navigator.pushNamed(context, '/login')),
            ),
            const SizedBox(height: 16),
            _EntranceAnimation(
              delay: 4,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  "Daftar Akun Baru",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserView() {
    return RefreshIndicator(
      onRefresh: _fetchAccountData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EntranceAnimation(delay: 0, child: _buildProfileHeader()),
            const SizedBox(height: 40),
            const _EntranceAnimation(
              delay: 1,
              child: Text(
                "AKTIVITAS SAYA",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuSection([
              if (user?.role?.id != 3)
                _accountTile(Icons.receipt_long_rounded, "Pesanan Saya", () => Navigator.pushNamed(context, '/orders'), delay: 2),
              ValueListenableBuilder<int>(
                valueListenable: PushNotificationService.unreadCount,
                builder: (context, count, child) {
                  return _accountTile(
                    Icons.notifications_active_rounded, 
                    "Notifikasi", 
                    () async {
                      await Navigator.pushNamed(context, '/notifications');
                      PushNotificationService.updateUnreadCount();
                    }, 
                    delay: 3,
                    badgeCount: count,
                  );
                }
              ),
            ]),
            const SizedBox(height: 32),
            const _EntranceAnimation(
              delay: 4,
              child: Text(
                "PENGATURAN",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuSection([
              _accountTile(Icons.person_rounded, "Edit Profil", () async {
                final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(user: user!)));
                if (updated == true) _fetchAccountData();
              }, delay: 5),
              _accountTile(Icons.help_center_rounded, "Pusat Bantuan", () {}, delay: 6),
            ]),
            const SizedBox(height: 32),
            _EntranceAnimation(
              delay: 7,
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: user?.profilePicture != null
                  ? NetworkImage("${ApiEndpoints.baseStorage}/${user!.profilePicture}")
                  : null,
              child: user?.profilePicture == null
                  ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? "User",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D0A0A)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user?.role?.id == 3 ? "MITRA DRIVER" : "PELANGGAN SETIA",
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _accountTile(IconData icon, String title, VoidCallback onTap, {required int delay, int badgeCount = 0}) {
    return _EntranceAnimation(
      delay: delay,
      child: TapScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D0A0A)),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 9 ? "9+" : "$badgeCount",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TapScale(
      onTap: () => AuthController.logout(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Text(
              "KELUAR DARI AKUN",
              style: TextStyle(color: Colors.red.withValues(alpha: 0.8), fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldButton(String text, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.accent]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  const _EntranceAnimation({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}