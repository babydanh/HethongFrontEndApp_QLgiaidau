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
        offset.dy + size.height + 4,
        offset.dx + 220,
        offset.dy + size.height + 400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, // Header màu trắng
        border: Border(
          bottom: BorderSide(
            color: context.colors.border.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // ─── Nút Dropdown Thể loại: Màu trắng / Không viền / Chỉ là chữ + mũi tên ───
          Semantics(
            button: true,
            label: l10n.filterSport,
            child: GestureDetector(
              key: _buttonKey,
              onTap: () => _showCategoryDropdown(context, items),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedLabel,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.textPrimary,
                      size: 24,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.colors.border.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: context.colors.textPrimary,
                      size: 20,
                    ),
                    if (notificationsCount > 0)
                      Positioned(
                        top: 7,
                        right: 7,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.border.withValues(alpha: 0.25),
                ),
                child: ClipOval(
                  child:
                      userProfile?.avatarUrl != null &&
                              userProfile!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              userProfile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.person,
                                color: context.colors.textPrimary,
                                size: 20,
                              ),
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              color: context.colors.textPrimary,
                              size: 20,
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
