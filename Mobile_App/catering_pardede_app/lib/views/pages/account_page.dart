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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const CustomHeader(
                  showIcons: true,
                ),
                Expanded(
                  child: user == null ? _buildGuestView() : _buildUserView(),
                ),
              ],
            ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text("Belum Masuk Akun", style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(
              "Masuk untuk mengakses pesanan dan riwayat kuliner Anda.",
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            _buildGoldButton("MASUK SEKARANG", () => Navigator.pushNamed(context, '/login')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                "Daftar Akun Baru",
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(),
          const SizedBox(height: 30),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: user?.profilePicture != null
                ? NetworkImage("${ApiEndpoints.baseStorage}/${user!.profilePicture}")
                : null,
            child: user?.profilePicture == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 35)
                : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? "User", style: AppTextStyles.bodyBold),
              Text(
                user?.email ?? "",
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _accountTile(Icons.shopping_bag_outlined, "Pesanan Saya", () {}),
          _accountTile(Icons.person_outline, "Edit Profil", () async {
            if (user != null) {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage(user: user!)),
              );
              if (updated == true) _fetchAccountData();
            }
          }),
          _accountTile(Icons.notifications_none_outlined, "Notifikasi", () {}),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          _accountTile(Icons.logout, "Keluar", () => AuthController.logout(context), color: Colors.red),
        ],
      ),
    );
  }

  Widget _accountTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return TapScale(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
        title: Text(
          title,
          style: AppTextStyles.subtitle.copyWith(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  Widget _buildGoldButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TapScale(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}