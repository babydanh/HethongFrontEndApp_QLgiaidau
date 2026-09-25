import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

class AppMenuSheet extends ConsumerStatefulWidget {
  const AppMenuSheet({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  static Future<void> show(BuildContext context) {
    final router = GoRouter.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final menuWidth = (screenSize.width * 0.72)
        .clamp(0.0, screenSize.width - 32)
        .toDouble();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.bottomLeft,
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: SizedBox(
            width: menuWidth,
            child: AppMenuSheet(onNavigate: router.go),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        if (reduceMotion) return child;
        final entrance = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: entrance,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(entrance),
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
              l10n.settingsPaymentHistory,
              Icons.receipt_long_outlined,
              '/payments',
            ),
            _MenuAction(
              l10n.settingsTitle,
              Icons.tune_rounded,
              '/profile/settings',
            ),
          ]
        : <_MenuAction>[
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
                    reduceMotion: reduceMotion,
                  ),
              ],
            ),
          ),
        ],
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
      child: InkWell(
        onTap: () => _navigate(isAuthenticated ? '/profile' : '/login'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(avatarUrl, colors.textMuted),
              const SizedBox(width: 10),
              Expanded(
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
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: l10n.settingsTitle,
                onPressed: () => _navigate('/profile/settings'),
                icon: Icon(
                  Icons.settings_outlined,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
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
    final start = (index * 0.05).clamp(0.0, 0.5).toDouble();
    final end = (start + 0.35).clamp(0.0, 1.0).toDouble();
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: row,
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
