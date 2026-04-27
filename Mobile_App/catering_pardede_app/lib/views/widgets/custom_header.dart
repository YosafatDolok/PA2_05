import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CustomHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showIcons;
  final bool showSearch;
  final Function(String)? onSearchChanged;
  final String? searchHint;

  const CustomHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showIcons = true,
    this.showSearch = false,
    this.onSearchChanged,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
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
                          size: 38,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pardede',
                              style: AppTextStyles.title.copyWith(
                                color: const Color(0xFFFFD700),
                                fontSize: 22,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'CATERING',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFFFD700),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                fontSize: 11,
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
                      icon: const Icon(Icons.group_rounded, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                  ],
                ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 20),
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  icon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 26),
                  hintText: searchHint ?? 'Cari Paket atau Menu...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}