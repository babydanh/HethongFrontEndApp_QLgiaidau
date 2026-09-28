import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

class AppMenuSheet extends ConsumerStatefulWidget {
  const AppMenuSheet({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  static Future<void> show(BuildContext context) {
    final router = GoRouter.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final menuWidth = (screenSize.width * 0.76)
        .clamp(280.0, 360.0)
        .toDouble();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, _, _) => Align(
        // Shift towards center of the 5th nav icon (approx bottom right, 24px from edge)
        alignment: const Alignment(0.42, 0.88),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: SizedBox(
            width: menuWidth,
            child: AppMenuSheet(onNavigate: router.push),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        if (reduceMotion) return child;
        final entrance = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1.0).animate(entrance),
            alignment: const Alignment(0.6, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<AppMenuSheet> createState() => _AppMenuSheetState();
}

class _AppMenuSheetState extends ConsumerState<AppMenuSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _entranceStarted = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _navigate(String route) {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).pop();
    widget.onNavigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final name = profile?.fullName?.trim();
    final displayName = name == null || name.isEmpty
        ? l10n.routerDefaultUser
        : name;
    final avatarUrl = profile?.avatarUrl?.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = isAuthenticated
        ? <_MenuAction>[
            const _MenuAction(
              'Social & Kèo đấu',
              Icons.dynamic_feed_rounded,
              '/home?tab=3&sub=1',
            ),
            _MenuAction(
              l10n.menuMessages,
              Icons.chat_bubble_outline_rounded,
              '/chat',
            ),
            _MenuAction(
              l10n.settingsNotifications,
              Icons.notifications_none_rounded,
              '/notifications',
            ),
            _MenuAction(
              l10n.settingsEloHistory,
              Icons.insights_outlined,
              '/profile/elo',
            ),
            _MenuAction(
              l10n.settingsTitle,
              Icons.tune_rounded,
              '/profile/settings',
            ),
          ]
        : <_MenuAction>[
            const _MenuAction(
              'Social & Kèo đấu',
              Icons.dynamic_feed_rounded,
              '/home?tab=3&sub=1',
            ),
            _MenuAction(
              l10n.profileLoginButton,
              Icons.login_rounded,
              '/login',
            ),
            _MenuAction(
              l10n.settingsTitle,
              Icons.tune_rounded,
              '/profile/settings',
            ),
          ];

    return Material(
      color: colors.bgCard,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIdentityHeader(
            context,
            isAuthenticated: isAuthenticated,
            name: displayName,
            avatarUrl: avatarUrl,
            l10n: l10n,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++)
                  _buildAction(
                    actions[i],
                    i,
                    totalCount: actions.length,
                    reduceMotion: reduceMotion,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickCreateMenu(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 310,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickCreateItem(
                    dialogContext,
                    icon: Icons.sports_tennis_rounded,
                    iconBg: const Color(0xFF10B981).withValues(alpha: 0.14),
                    iconColor: const Color(0xFF10B981),
                    title: 'Tạo kèo giao lưu',
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      if (!ref.read(authProvider).isAuthenticated) {
                        _navigate('/login');
                        return;
                      }
                      Navigator.of(context).pop();
                      final createdSession =
                          await showModalBottomSheet<SocialSessionModel>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            const CreateSocialScreen(clubId: '', clubName: ''),
                      );
                      if (createdSession != null && context.mounted) {
                        widget.onNavigate('/social/${createdSession.id}?isHost=true');
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildQuickCreateItem(
                    dialogContext,
                    icon: Icons.emoji_events_rounded,
                    iconBg: AppTheme.primary.withValues(alpha: 0.14),
                    iconColor: AppTheme.primary,
                    title: 'Tạo giải nhanh',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _navigate('/tournaments/create');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildQuickCreateItem(
                    dialogContext,
                    icon: Icons.groups_rounded,
                    iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Tạo Câu Lạc Bộ',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      final auth = ref.read(authProvider);
                      _navigate(auth.isAuthenticated ? '/club-create' : '/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildQuickCreateItem(
    BuildContext dialogContext, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Material(
      color: colors.bgElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.textMuted.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(
    BuildContext context, {
    required bool isAuthenticated,
    required String name,
    required String? avatarUrl,
    required AppLocalizations l10n,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppTheme.primary.withValues(alpha: 0.16)
          : AppTheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _navigate(isAuthenticated ? '/profile' : '/login'),
              child: _buildAvatar(avatarUrl, colors.textMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _navigate(isAuthenticated ? '/profile' : '/login'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAuthenticated
                          ? l10n.menuProfile
                          : l10n.profileLoginButton,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sleek circular '+' quick-creation button
            Material(
              color: AppTheme.primary,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: AppTheme.primary.withValues(alpha: 0.4),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showQuickCreateMenu(context),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, Color fallbackColor) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return CircleAvatar(
      radius: 19,
      backgroundColor: context.colors.bgCard,
      child: ClipOval(
        child: SizedBox(
          width: 38,
          height: 38,
          child: hasAvatar
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarFallback(fallbackColor),
                )
              : _avatarFallback(fallbackColor),
        ),
      ),
    );
  }

  Widget _avatarFallback(Color color) =>
      Icon(Icons.person_rounded, color: color, size: 22);

  Widget _buildAction(
    _MenuAction action,
    int index, {
    required int totalCount,
    required bool reduceMotion,
  }) {
    final colors = context.colors;
    final row = Semantics(
      button: true,
      label: action.title,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: ValueKey('app-menu-${action.route}'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => _navigate(action.route),
            child: SizedBox(
              height: 42,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        action.icon,
                        color: AppTheme.primary,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textMuted.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) return row;
    // Staggered interval for each action item
    final step = 0.55 / (totalCount > 0 ? totalCount : 1);
    final start = (index * step).clamp(0.0, 0.7).toDouble();
    final end = (start + 0.45).clamp(0.0, 1.0).toDouble();
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.92,
            end: 1.0,
          ).animate(animation),
          child: row,
        ),
      ),
    );
  }
}

class _MenuAction {
  const _MenuAction(this.title, this.icon, this.route);

  final String title;
  final IconData icon;
  final String route;
}
