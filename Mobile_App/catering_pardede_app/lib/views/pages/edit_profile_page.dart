import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/user_model.dart';
import '../widgets/tap_scale.dart';
import '../../core/utils/helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      setState(() {
        _image = File(selected.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.postMultipart(
        ApiEndpoints.updateProfile,
        {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text,
        },
        filePath: _image?.path,
      );

      if (mounted) {
        Helpers.showSnackBar(context, 'Profil berhasil diperbarui!');
        Navigator.pop(context, true); // Return true to indicate data changed
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showSnackBar(context, 'Gagal memperbarui profil: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profil", 
          style: TextStyle(color: Color(0xFF2D0A0A), fontWeight: FontWeight.w900, fontSize: 18)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EntranceAnimation(delay: 0, child: _buildAvatarSection()),
              const SizedBox(height: 48),
              _EntranceAnimation(delay: 1, child: _buildLabel("NAMA LENGKAP")),
              _EntranceAnimation(delay: 2, child: _buildBoutiqueField(_nameController, "Contoh: Budi Santoso", Icons.person_rounded)),
              const SizedBox(height: 24),
              _EntranceAnimation(delay: 3, child: _buildLabel("ALAMAT EMAIL")),
              _EntranceAnimation(delay: 4, child: _buildBoutiqueField(_emailController, "budi@example.com", Icons.email_rounded, keyboardType: TextInputType.emailAddress, isVerified: true)),
              const SizedBox(height: 24),
              _EntranceAnimation(delay: 5, child: _buildLabel("NOMOR TELEPON")),
              _EntranceAnimation(delay: 6, child: _buildBoutiqueField(_phoneController, "08123456789", Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
              const SizedBox(height: 24),
              _EntranceAnimation(
                delay: 7,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _showChangePasswordSheet(context),
                    icon: const Icon(Icons.lock_reset_rounded, color: AppColors.secondary, size: 20),
                    label: const Text(
                      "GANTI PASSWORD",
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              _EntranceAnimation(delay: 8, child: _buildSaveButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: TapScale(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (widget.user.profilePicture != null
                          ? NetworkImage("${ApiEndpoints.baseStorage}/${widget.user.profilePicture}")
                          : null) as ImageProvider?,
                  child: _image == null && widget.user.profilePicture == null
                      ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 60)
                      : null,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 4, right: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        text, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildBoutiqueField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, bool isVerified = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF2D0A0A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: isVerified ? const Icon(Icons.verified_rounded, color: Colors.green, size: 18) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) => value == null || value.isEmpty ? "Bidang ini tidak boleh kosong" : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return TapScale(
      onTap: _isLoading ? null : _updateProfile,
      child: Container(
        width: double.infinity,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text(
                "SIMPAN PERUBAHAN", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)
              ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final sheetFormKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSheetLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext statefulContext, StateSetter setSheetState) {
            Future<void> submitPasswordChange() async {
              if (!sheetFormKey.currentState!.validate()) return;

              setSheetState(() => isSheetLoading = true);
              try {
                await ApiService.post(
                  ApiEndpoints.updatePassword,
                  {
                    'current_password': currentPasswordController.text,
                    'new_password': newPasswordController.text,
                    'new_password_confirmation': confirmPasswordController.text,
                  },
                );
                if (context.mounted) {
                  Navigator.pop(sheetContext);
                  Helpers.showSnackBar(context, 'Password berhasil diperbarui!');
                }
              } catch (e) {
                setSheetState(() => isSheetLoading = false);
                if (context.mounted) {
                  Helpers.showSnackBar(context, 'Gagal: $e');
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(statefulContext).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: sheetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 12),
                        Text(
                          "GANTI PASSWORD",
                          style: TextStyle(
                            color: Color(0xFF2D0A0A),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "PASSWORD SAAT INI",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordField(currentPasswordController, "Masukkan password saat ini"),
                    const SizedBox(height: 20),
                    const Text(
                      "PASSWORD BARU",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordField(newPasswordController, "Minimal 8 karakter"),
                    const SizedBox(height: 20),
                    const Text(
                      "KONFIRMASI PASSWORD BARU",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      confirmPasswordController,
                      "Ulangi password baru",
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Bidang ini tidak boleh kosong";
                        if (value != newPasswordController.text) return "Konfirmasi password tidak cocok";
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    TapScale(
                      onTap: isSheetLoading ? null : submitPasswordChange,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: isSheetLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text(
                                "PERBARUI PASSWORD",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        currentPasswordController.dispose();
        newPasswordController.dispose();
        confirmPasswordController.dispose();
      });
    });
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, {FormFieldValidator<String>? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D0A0A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) return "Bidang ini tidak boleh kosong";
          if (controller.text.length < 8) return "Password minimal terdiri dari 8 karakter";
          return null;
        },
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
