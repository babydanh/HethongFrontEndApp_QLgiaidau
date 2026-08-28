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
        offset.dx + 220,
        offset.dy + size.height + 400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: context.colors.bgSurface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      items: items.map((item) {
        final isSelected = item.$1 == widget.activeSport;
        return PopupMenuItem<String>(
          value: item.$1,
          height: 44,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Nền xám nhạt hiện đại
        border: Border(
          bottom: BorderSide(
            color: context.colors.border.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // ─── Nút Dropdown Thể loại nhỏ gọn bé bé, không viền ───
          Semantics(
            button: true,
            label: l10n.filterSport,
            child: GestureDetector(
              key: _buttonKey,
              onTap: () => _showCategoryDropdown(context, items),
              child: Container(
                height: 36,
                padding: const EdgeInsets.only(left: 14, right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.webPrimary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.webPrimary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ─── Nút Chuông Thông Báo (Không viền) ───
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.webPrimary,
                      size: 19,
                    ),
                    if (notificationsCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 7,
                          height: 7,
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

          // ─── Avatar Người Dùng / Đăng Nhập (Không viền) ───
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
                                size: 19,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline_rounded,
                              color: AppTheme.webPrimary,
                              size: 19,
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
