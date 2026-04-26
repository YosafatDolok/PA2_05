import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CustomHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showIcons;
  final bool showSearch;

  const CustomHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showIcons = true,
    this.showSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.92),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo or Title
                  title != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: AppTextStyles.subtitle.copyWith(color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFFFD700), // Gold
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pardede',
                                  style: AppTextStyles.title.copyWith(
                                    color: const Color(0xFFFFD700),
                                    fontSize: 18,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  'CATERING',
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFFFFD700),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  if (showIcons)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.group_outlined, color: Colors.white.withOpacity(0.9), size: 28),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_none_outlined, color: Colors.white.withOpacity(0.9), size: 28),
                          onPressed: () {},
                        ),
                      ],
                    ),
                ],
              ),
              if (showSearch) ...[
                const SizedBox(height: 20),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[400]),
                      const SizedBox(width: 10),
                      Text(
                        'Cari Paket atau Menu...',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}