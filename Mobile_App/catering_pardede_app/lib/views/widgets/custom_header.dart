import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/helpers.dart';

class CustomHeader extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final bool showIcons;
  final bool showSearch;
  final Function(String)? onSearchChanged;
  final String? searchHint;
  final Widget? action;

  const CustomHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showIcons = true,
    this.showSearch = false,
    this.onSearchChanged,
    this.searchHint,
    this.action,
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {

  @override
  void initState() {
    super.initState();
    // No need to manage local state anymore
    PushNotificationService.updateUnreadCount();
    PushNotificationService.updateUnreadChatCount();
  }

  // Removed local _fetchUnreadCount method as it's now in the service

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo or Title with optional Back Button
              Expanded(
                child: Row(
                  children: [
                    if (canPop) ...[
                      Material(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: widget.title != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title!,
                                  style: AppTextStyles.title.copyWith(
                                    color: Colors.white, 
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: AppTextStyles.subtitle.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                                    overflow: TextOverflow.ellipsis,
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
                    ),
                  ],
                ),
              ),
              if (widget.action != null)
                widget.action!
              else if (widget.showIcons && !canPop)
                Row(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: PushNotificationService.unreadChatCount,
                      builder: (context, chatCount, child) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 26),
                              onPressed: () async {
                                await Helpers.pushNamedSafe(context, '/messages');
                                PushNotificationService.updateUnreadChatCount(); // Refresh when coming back
                              },
                            ),
                            if (chatCount > 0)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: PushNotificationService.unreadCount,
                      builder: (context, count, child) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
                              onPressed: () async {
                                await Helpers.pushNamedSafe(context, '/notifications');
                                PushNotificationService.updateUnreadCount(); // Refresh when coming back
                              },
                            ),
                            if (count > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
          if (widget.showSearch) ...[
            const SizedBox(height: 20),
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: widget.onSearchChanged,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  icon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 26),
                  hintText: widget.searchHint ?? 'Cari Paket atau Menu...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}