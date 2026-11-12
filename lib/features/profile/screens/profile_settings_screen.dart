import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart' as tp;
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/app_update_service.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_update_gate.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/utils/best_ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Màn hình Cài đặt (Lavish): thẻ tài khoản, nhóm Ứng dụng, Lối tắt, Đăng xuất.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  static const _log = AppLogger('ProfileSettings');
  late final Future<PackageInfo> _packageInfoFuture;
  bool _checkingUpdate = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = ref.watch(tp.themeProvider) == ThemeMode.dark;

    return LavishScaffold(
      title: l.settingsTitle,
      onBack: () {
        HapticFeedback.lightImpact();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          LavishGroupHeader(l.accountSettingsAccountSection),
          _buildAccountCard(context),
          LavishGroupHeader(l.accountSettingsAppSection),
          _buildAppRows(context, isDark),
          LavishGroupHeader(l.accountSettingsShortcuts),
          _buildShortcuts(context),
          _buildLogoutButton(context),
          _buildAppVersion(context),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, {LavishTone tone = LavishTone.accent}) =>
      LavishIconBox(tone: tone, child: Icon(icon));

  Widget _chevron(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    size: 18,
    color: LavishColors.of(context).faint,
  );

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return LavishRow(
      leading: _icon(icon),
      title: label,
      trailing: [_chevron(context)],
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider);
    return profile.when(
      loading: () => const LavishRowSkeleton(count: 1),
      error: (_, _) => LavishRow(
        leading: _icon(Icons.error_outline_rounded, tone: LavishTone.bad),
        title: l.settingsLvAccountError,
        trailing: [
          LavishChipButton(
            label: l.lavishRetry,
            onPressed: () => ref.invalidate(userProfileProvider),
          ),
        ],
      ),
      data: (user) => _accountRow(context, user),
    );
  }

  Widget _accountRow(BuildContext context, UserProfile user) {
    final name = (user.fullName ?? '').trim();
    final email = (user.email ?? '').trim();
    final title = name.isNotEmpty ? name : email;
    // Same avatar (photo + tier ring) as the profile page and the "Tôi" tab.
    final ranking = bestRankingOf(
      ref.watch(userRankingsProvider).asData?.value ?? const <PlayerRanking>[],
    );
    return LavishRow(
      leading: RankAvatar(
        imageUrl: user.avatarUrl,
        name: title,
        elo: ranking?.eloPoints ?? 0,
        tierName: ranking?.tierName,
        tierSource: ranking?.tierSource,
        tierAvailable: ranking?.tierAvailable,
        matchesPlayed: ranking?.matchesPlayed ?? 0,
        size: 44,
      ),
      title: title,
      subtitle: name.isNotEmpty && email.isNotEmpty ? email : null,
      trailing: [_chevron(context)],
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/profile/edit');
      },
    );
  }

  Widget _buildAppRows(BuildContext context, bool isDark) {
    final l = AppLocalizations.of(context)!;
    final isVi = ref.watch(localeProvider).languageCode == 'vi';
    return Column(
      children: [
        _navRow(
          context,
          icon: Icons.notifications_outlined,
          label: l.settingsNotifications,
          route: '/notifications',
        ),
        LavishRow(
          leading: _icon(Icons.language_rounded),
          title: l.settingsLanguage,
          trailing: [
            LavishChipButton(
              label: 'VI',
              selected: isVi,
              onPressed: () => _changeLocale('vi'),
            ),
            LavishChipButton(
              label: 'EN',
              selected: !isVi,
              onPressed: () => _changeLocale('en'),
            ),
          ],
        ),
        LavishRow(
          leading: _icon(Icons.dark_mode_rounded),
          title: l.settingsDarkMode,
          onTap: () => ref.read(tp.themeProvider.notifier).toggleTheme(),
          trailing: [
            LavishSwitch(
              key: const ValueKey('settings-dark-switch'),
              value: isDark,
              onChanged: (_) =>
                  ref.read(tp.themeProvider.notifier).toggleTheme(),
            ),
          ],
        ),
        LavishRow(
          leading: _icon(Icons.system_update_rounded),
          title: l.coreCheckForUpdate,
          subtitle: _checkingUpdate ? l.coreCheckingForUpdate : null,
          onTap: _checkingUpdate ? null : () => _checkForUpdate(context),
          trailing: [
            if (_checkingUpdate)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              _chevron(context),
          ],
        ),
      ],
    );
  }

  void _changeLocale(String code) {
    if (ref.read(localeProvider).languageCode != code) {
      ref.read(localeProvider.notifier).changeLocale(code);
    }
  }

  Future<void> _checkForUpdate(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checkingUpdate = true);
    try {
      final info = await AppUpdateService(ref.read(dioProvider)).check();
      if (!context.mounted) return;
      if (info != null && info.hasUpdate) {
        await AppUpdateGate.showUpdateDialog(context, info);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.coreAppUpToDate(info?.currentVersion ?? '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi kiểm tra cập nhật', e, stack);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorParser.parse(e, '', l)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Widget _buildShortcuts(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
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
    return Column(
      key: const ValueKey('account-settings-shortcuts'),
      children: [
        for (final item in items)
          _navRow(
            context,
            icon: item.icon,
            label: item.label,
            route: item.route,
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
      child: LavishButton(
        buttonKey: const ValueKey('settings-logout'),
        label: l.settingsLogout,
        kind: LavishButtonKind.danger,
        icon: const Icon(Icons.logout_rounded, size: 18),
        busy: _loggingOut,
        onPressed: () => _confirmLogout(context),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsLvLogoutConfirmTitle),
        content: Text(l.settingsLvLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            key: const ValueKey('settings-logout-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: LavishColors.bad),
            child: Text(l.settingsLogout),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted || _loggingOut) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loggingOut = true);
    try {
      await ref.read(authProvider.notifier).signOut();
      ref.invalidate(userProfileProvider);
      ref.invalidate(userRankingsProvider);
      if (!context.mounted) return;
      context.go('/home');
    } catch (e, stack) {
      _log.error('Lỗi đăng xuất', e, stack);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorParser.parse(e, '', l)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Widget _buildAppVersion(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        final build = snapshot.data?.buildNumber ?? '1';
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: Text(
              l.settingsLvVersion(version, build),
              style: TextStyle(
                fontSize: 11.5,
                color: c.faint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsMenuItem {
  final IconData icon;
  final String label;
  final String route;

  const _SettingsMenuItem(this.icon, this.label, this.route);
}
