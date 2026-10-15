import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart' as tp;
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_update_service.dart';
import 'package:app_quanly_giaidau/core/widgets/app_update_gate.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Màn hình Cài đặt tài khoản: Tài khoản, Ứng dụng, Lối tắt (đóng sẵn) và Đăng xuất.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    final isDark = ref.watch(tp.themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.borderLight,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(
          l.settingsTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(colors, l.accountSettingsAccountSection),
            const SizedBox(height: 10),
            _buildAccountMenu(context),
            const SizedBox(height: 24),
            _sectionLabel(colors, l.accountSettingsAppSection),
            const SizedBox(height: 10),
            _buildAppMenu(context, isDark),
            const SizedBox(height: 24),
            _buildShortcutsMenu(context),
            const SizedBox(height: 24),
            _buildLogoutMenu(context),
            const SizedBox(height: 16),
            _buildAppVersion(colors),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(AppColorsExtension colors, String text) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _menuCard(
    AppColorsExtension colors, {
    required List<Widget> children,
  }) {
    return Material(
      color: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _menuDivider(AppColorsExtension colors) {
    return Divider(height: 1, color: colors.borderLight, indent: 56);
  }

  Widget _menuRow(
    AppColorsExtension colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountMenu(BuildContext context) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    return _menuCard(
      colors,
      children: [
        _menuRow(
          colors,
          icon: Icons.person_outline_rounded,
          label: l.accountSettingsPersonalProfile,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/profile/edit');
          },
        ),
      ],
    );
  }

  Widget _buildAppMenu(BuildContext context, bool isDark) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    return _menuCard(
      colors,
      children: [
        // Thông báo
        _menuRow(
          colors,
          icon: Icons.notifications_outlined,
          label: l.settingsNotifications,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/notifications');
          },
        ),
        _menuDivider(colors),

        // Ngôn ngữ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.settingsLanguage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langSegmentButton(
                      'vi',
                      'VI',
                      ref.watch(localeProvider).languageCode == 'vi',
                    ),
                    _langSegmentButton(
                      'en',
                      'EN',
                      ref.watch(localeProvider).languageCode == 'en',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _menuDivider(colors),

        // Giao diện tối
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.dark_mode_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.settingsDarkMode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: isDark,
                activeThumbColor: AppTheme.primary,
                onChanged: (v) =>
                    ref.read(tp.themeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
        ),
        _menuDivider(colors),

        // Kiểm tra cập nhật ứng dụng
        _menuRow(
          colors,
          icon: Icons.system_update_rounded,
          label: l.coreCheckForUpdate,
          onTap: () => _checkForUpdate(context),
        ),
      ],
    );
  }

  Future<void> _checkForUpdate(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.coreCheckingForUpdate),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final info = await AppUpdateService(ref.read(dioProvider)).check();
      if (!context.mounted) return;
      if (info != null && info.hasUpdate) {
        await AppUpdateGate.showUpdateDialog(context, info);
      } else {
        final current = info?.currentVersion ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.coreAppUpToDate(current)),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildShortcutsMenu(BuildContext context) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    final shortcuts = [
      _SettingsMenuItem(
        Icons.dashboard_rounded,
        l.settingsDashboard,
        '/dashboard',
      ),
      _SettingsMenuItem(Icons.leaderboard_rounded, l.navRankings, '/rankings'),
      _SettingsMenuItem(
        Icons.account_balance_wallet_rounded,
        l.settingsPaymentHistory,
        '/payments',
      ),
      _SettingsMenuItem(
        Icons.emoji_events_rounded,
        l.settingsSeries,
        '/series',
      ),
      _SettingsMenuItem(
        Icons.mail_outline_rounded,
        l.settingsClubInvites,
        '/club-invites',
      ),
      _SettingsMenuItem(
        Icons.insights_outlined,
        l.settingsEloHistory,
        '/profile/elo',
      ),
      _SettingsMenuItem(
        Icons.flag_outlined,
        l.myReportsTitle,
        '/profile/reports',
      ),
    ];

    final rows = <Widget>[];
    for (final item in shortcuts) {
      if (rows.isNotEmpty) rows.add(_menuDivider(colors));
      rows.add(
        _menuRow(
          colors,
          icon: item.icon,
          label: item.label,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(item.route);
          },
        ),
      );
    }

    return _menuCard(
      colors,
      children: [
        ExpansionTile(
          key: const ValueKey('account-settings-shortcuts'),
          initiallyExpanded: false,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          iconColor: AppTheme.primary,
          collapsedIconColor: colors.textMuted,
          textColor: colors.textPrimary,
          collapsedTextColor: colors.textPrimary,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          title: Text(
            l.accountSettingsShortcuts,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          children: rows,
        ),
      ],
    );
  }

  Widget _buildLogoutMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _menuCard(
      context.colors,
      children: [
        InkWell(
          onTap: () async {
            await ref.read(authProvider.notifier).signOut();
            ref.invalidate(userProfileProvider);
            ref.invalidate(userRankingsProvider);
            if (!context.mounted) return;
            context.go('/home');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppTheme.adminColor,
                ),
                const SizedBox(width: 14),
                Text(
                  l.settingsLogout,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.adminColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppVersion(AppColorsExtension colors) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        final build = snapshot.data?.buildNumber ?? '1';
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Phiên bản $version ($build)',
              style: TextStyle(
                fontSize: 12,
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _langSegmentButton(
    String code,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(localeProvider.notifier).changeLocale(code);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuItem {
  final IconData icon;
  final String label;
  final String route;

  const _SettingsMenuItem(this.icon, this.label, this.route);
}
