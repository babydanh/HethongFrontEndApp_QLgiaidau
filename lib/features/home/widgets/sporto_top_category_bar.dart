import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class SportoTopCategoryBar extends ConsumerStatefulWidget {
  final String activeSport;
  final ValueChanged<String> onSportSelected;
  final VoidCallback? onNotificationTap;

  const SportoTopCategoryBar({
    super.key,
    required this.activeSport,
    required this.onSportSelected,
    this.onNotificationTap,
  });

  @override
  ConsumerState<SportoTopCategoryBar> createState() =>
      _SportoTopCategoryBarState();
}

class _SportoTopCategoryBarState extends ConsumerState<SportoTopCategoryBar> {
  final GlobalKey _buttonKey = GlobalKey();

  Future<void> _showCategoryDropdown(
    BuildContext context,
    List<(String, String)> items,
  ) async {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    HapticFeedback.lightImpact();

    final selectedSlug = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 6,
        offset.dx + size.width,
        offset.dy + size.height + 450,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: context.colors.bgSurface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      items: items.map((item) {
        final isSelected = item.$1 == widget.activeSport;
        return PopupMenuItem<String>(
          value: item.$1,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.webPrimary
                        : context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.webPrimary,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
    );

    if (selectedSlug != null && selectedSlug != widget.activeSport) {
      HapticFeedback.selectionClick();
      widget.onSportSelected(selectedSlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final notificationsCount = ref.watch(unreadCountProvider).value ?? 0;
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];

    // Chỉ lấy các môn thể thao đang kích hoạt trong Admin
    final items = <(String, String)>[
      ('all', l10n.filterAll),
      ...categories
          .where((category) => category.isActive)
          .map((category) => (category.slug, category.name)),
    ];

    final selectedLabel = items
        .firstWhere(
          (item) => item.$1 == widget.activeSport,
          orElse: () => items.first,
        )
        .$2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.border.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // ─── Nút Dropdown Thể loại (Bỏ icon môn, chỉ hiện tên + mũi tên trỏ xuống) ───
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.filterSport,
              child: GestureDetector(
                key: _buttonKey,
                onTap: () => _showCategoryDropdown(context, items),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.webPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.webPrimary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Tên môn thể thao
                      Expanded(
                        child: Text(
                          selectedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Mũi tên trỏ xuống sát bên phải
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ─── Nút Chuông Thông Báo ───
          Semantics(
            button: true,
            label: l10n.notification_title,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onNotificationTap != null
                    ? widget.onNotificationTap!()
                    : context.push('/notifications');
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.webPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.webPrimary,
                      size: 21,
                    ),
                    if (notificationsCount > 0)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ─── Avatar Người Dùng / Đăng Nhập ───
          Semantics(
            button: true,
            label: 'Profile',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (authState.isAuthenticated) {
                  context.push('/profile');
                } else {
                  context.push('/auth/login');
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.webPrimaryLight,
                  border: authState.isAuthenticated
                      ? Border.all(color: AppTheme.webSecondary, width: 1.5)
                      : null,
                ),
                child: ClipOval(
                  child:
                      userProfile?.avatarUrl != null &&
                              userProfile!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              userProfile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                color: AppTheme.webPrimary,
                                size: 21,
                              ),
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              color: authState.isAuthenticated
                                  ? AppTheme.webSecondary
                                  : AppTheme.webPrimary,
                              size: 21,
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
