import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
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
  Future<void> _showCategoryPicker(
    BuildContext context,
    List<(String, String)> items,
  ) async {
    final selectedSlug = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var localSport = widget.activeSport;
        final l10n = AppLocalizations.of(sheetContext)!;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.filterSport,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items.map((item) {
                        final isSelected = item.$1 == localSport;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => localSport = item.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.webPrimary
                                  : context.colors.bgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.webPrimary
                                    : context.colors.border,
                              ),
                            ),
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : context.colors.textPrimary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setSheetState(() => localSport = 'all'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colors.textSecondary,
                              side: BorderSide(color: context.colors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(l10n.filterReset),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext, localSport),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.webPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(l10n.filterApply),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      decoration: BoxDecoration(color: context.colors.bgDark),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.filterSport,
              child: GestureDetector(
                onTap: () => _showCategoryPicker(context, items),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.webPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sports_rounded,
                        color: AppTheme.webSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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
          ),
          const SizedBox(width: 10),
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
                decoration: const BoxDecoration(
                  color: AppTheme.webPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.webPrimary,
                      size: 19,
                    ),
                    if (notificationsCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
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
          const SizedBox(width: 8),
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
                            size: 20,
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          color: authState.isAuthenticated
                              ? AppTheme.webSecondary
                              : AppTheme.webPrimary,
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
