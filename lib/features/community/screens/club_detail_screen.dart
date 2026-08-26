import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_ranking_widget.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/features/community/widgets/tag_assign_sheet.dart';
import 'package:app_quanly_giaidau/features/community/widgets/community_social_settings_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/features/community/social/community_social_screen.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger('ClubDetail');
  late TabController _tabController;
  CommunityMemberModel? _myMembership;
  bool _isJoinLoading = false;
  String _tournamentStatusFilter = 'ALL';
  String _tournamentTypeFilter = 'ALL';
  String _tournamentSportFilter = 'ALL';
  bool _isAddingGalleryImage = false;
  // Cache future cho card Trạng thái nhanh — tránh gọi lại API mỗi lần rebuild.
  Future<CommunitySocialSettings>? _socialSettingsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMembership());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembership() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      setState(() => _myMembership = null);
      return;
    }
    try {
      // P2B.3: dùng my-membership endpoint thay cho việc quét getMembers + fallback (P1.11).
      final membership = await ref
          .read(communityRepositoryProvider)
          .getMyMembership(widget.clubId);
      if (!mounted) return;
      if (membership == null) {
        // 404 (chưa phải member) hoặc lỗi → viewer thuần
        setState(() => _myMembership = null);
        return;
      }
      final profile = ref.read(userProfileProvider).asData?.value;
      setState(() {
        _myMembership = CommunityMemberModel(
          id: membership['memberId']?.toString() ?? '',
          userId: profile?.id ?? '',
          communityId: widget.clubId,
          role: membership['role']?.toString() ?? 'MEMBER',
          status: membership['status']?.toString() ?? 'JOINED',
          joinedAt: membership['joinedAt']?.toString() ?? '',
        );
      });
      if (_myMembership?.status == 'JOINED') {
        _loadNotificationPref();
      }
    } catch (e, stack) {
      _log.error('Failed to fetch membership', e, stack);
      if (mounted) setState(() => _myMembership = null);
    }
  }

  bool _isOpeningClubChat = false;

  Future<void> _openClubChat(Community club) async {
    if (_isOpeningClubChat) return;
    setState(() => _isOpeningClubChat = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/chat/rooms',
        queryParameters: {
          'type': 'CLUB',
          'communityId': club.id,
        },
      );
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      final room = raw is List
          ? (raw.isEmpty ? null : raw.first as Map<String, dynamic>)
          : (raw as Map<String, dynamic>?);
      final roomId = room?['id']?.toString();
      if (roomId == null || roomId.isEmpty) {
        throw Exception('Không tìm thấy phòng chat CLB');
      }

      if (!mounted) return;
      final name = Uri.encodeComponent(club.name);
      final avatar = Uri.encodeComponent(club.logoUrl ?? club.bannerUrl ?? '');
      context.push(
        '/chat/$roomId?name=$name&avatar=$avatar&type=CLUB&communityId=${club.id}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở chat CLB: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningClubChat = false);
    }
  }

  // ─── Follow / Favorite & Notification (P2E.2) ───
  String _notificationPref = 'ALL';

  Future<void> _loadNotificationPref() async {
    try {
      final prefs = await ref
          .read(communityRepositoryProvider)
          .getMyNotificationPreferences();
      final found = prefs
          .where((p) => p.communityId == widget.clubId)
          .firstOrNull;
      if (found != null && mounted) {
        setState(() => _notificationPref = found.notificationPreference);
      }
    } catch (_) {}
  }

  Future<void> _updateNotificationPref(String newPref) async {
    final l10n = AppLocalizations.of(context)!;
    final oldPref = _notificationPref;
    setState(() => _notificationPref = newPref);
    try {
      await ref
          .read(communityRepositoryProvider)
          .updateNotificationPreference(widget.clubId, newPref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPref == 'ALL'
                  ? l10n.clubDetailNotificationsUpdatedAll
                  : newPref == 'MENTIONS_ONLY'
                  ? l10n.clubDetailNotificationsUpdatedMentions
                  : l10n.clubDetailNotificationsUpdatedMuted,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notificationPref = oldPref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubDetailNotificationsUpdateError)),
        );
      }
    }
  }

  void _showNotificationPreferenceSheet(BuildContext context, Community club) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.clubDetailNotificationsTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.clubDetailNotificationsDescription(club.name),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationOptionItem(
                      title: l10n.clubDetailNotificationsAllTitle,
                      subtitle: l10n.clubDetailNotificationsAllSubtitle,
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFF2563EB),
                      value: 'ALL',
                      colors: colors,
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateNotificationPref('ALL');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationOptionItem(
                      title: l10n.clubDetailNotificationsMentionsTitle,
                      subtitle: l10n.clubDetailNotificationsMentionsSubtitle,
                      icon: Icons.alternate_email_rounded,
                      iconColor: const Color(0xFFD97706),
                      value: 'MENTIONS_ONLY',
                      colors: colors,
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateNotificationPref('MENTIONS_ONLY');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationOptionItem(
                      title: l10n.clubDetailNotificationsMutedTitle,
                      subtitle: l10n.clubDetailNotificationsMutedSubtitle,
                      icon: Icons.notifications_off_outlined,
                      iconColor: const Color(0xFF64748B),
                      value: 'MUTED',
                      colors: colors,
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateNotificationPref('MUTED');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationOptionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String value,
    required AppColorsExtension colors,
    required VoidCallback onTap,
  }) {
    final isSelected = _notificationPref == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.08) : colors.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? iconColor.withValues(alpha: 0.4)
                : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowFavoriteButtons(
    Community club,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_myMembership?.status == 'JOINED')
          IconButton(
            onPressed: _isOpeningClubChat ? null : () => _openClubChat(club),
            tooltip: l10n.clubDetailChatTooltip,
            icon: _isOpeningClubChat
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(
                    Icons.forum_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
          ),
        IconButton(
          onPressed: () {
            AppShareModal.show(
              context: context,
              title: club.name,
              subtitle:
                  '${club.locationAddress ?? l10n.vietnam} • ${l10n.club_memberCount(club.memberCount)}',
              webUrl: 'https://sporto.asia/communities/${club.id}',
              imageUrl: club.logoUrl ?? club.bannerUrl,
              badgeText: l10n.club_badge,
            );
          },
          tooltip: l10n.clubDetailShareTooltip,
          icon: Icon(Icons.share_outlined, color: colors.textPrimary, size: 22),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(communityDetailProvider(widget.clubId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: clubAsync.when(
        data: (club) {
          if (club == null) {
            return Scaffold(
              appBar: AppBar(backgroundColor: context.colors.bgDark),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.club_clubNotFound,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildContent(club);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, st) {
          _log.error('Lỗi load club detail', e, st);
          return Scaffold(
            backgroundColor: context.colors.bgDark,
            appBar: AppBar(backgroundColor: context.colors.bgDark),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: context.colors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.club_loadError,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(communityDetailProvider(widget.clubId)),
                    child: Text(l10n.infoRetry),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: 3,
        onTabSelected: (index) {
          if (index != 3) context.go('/home?tab=$index');
        },
        onProfileTap: () => context.go('/profile'),
      ),
    );
  }

  // ─── Helpers ───
  Color _sportColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông'))
      return const Color(0xFF0284C7);
    if (n.contains('tennis')) return const Color(0xFFEA580C);
    if (n.contains('pickleball')) return const Color(0xFF059669);
    return const Color(0xFF0284C7);
  }

  String _sportEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông')) return '🏸';
    if (n.contains('tennis')) return '🎾';
    if (n.contains('pickleball')) return '🏓';
    return '🏆';
  }

  bool get _isMember => _myMembership?.status == 'JOINED';
  bool get _isPending => _myMembership?.status == 'PENDING';
  bool get _isInvited => _myMembership?.status == 'INVITED';

  Widget _buildContent(Community club) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final sportName = club.sports.isNotEmpty
        ? club.sports.first
        : l10n.club_sportFallback;
    final Color sColor = _sportColor(sportName);
    final String emoji = _sportEmoji(sportName);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: colors.bgDark,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgCard.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            club.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: false,
          actions: [
            _buildFollowFavoriteButtons(club, colors, l10n),
            if (_myMembership?.role == 'OWNER' ||
                _myMembership?.role == 'ADMIN' ||
                _myMembership?.role == 'MODERATOR') ...[
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                tooltip: l10n.clubDetailManageTooltip,
                onSelected: (val) {
                  if (val == 'manage') {
                    context.push(
                      '/club/${widget.clubId}/manage',
                      extra: _myMembership?.role == 'OWNER',
                    );
                  } else if (val == 'edit') {
                    context.push('/club/${widget.clubId}/edit');
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'manage',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.club_manageShort,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: colors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.infoEdit,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
        SliverToBoxAdapter(
          child: _buildClubBanner(club, colors, sColor, emoji),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            color: colors.bgCard,
            child: Row(
              children: [
                if (_isMember) ...[
                  // Nút 1: Đã tham gia (Dropdown mở menu tùy chọn/rời CLB)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isJoinLoading
                          ? null
                          : () => _showMemberOptionsSheet(context, club),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.bgSurface,
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isJoinLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  l10n.club_joined,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                  // Nút 2: + Mời (Chỉ hiển thị với CLB Công khai / PUBLIC)
                  if (club.visibility.toUpperCase() == 'PUBLIC') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          AppShareModal.show(
                            context: context,
                            title: club.name,
                            subtitle:
                                '${club.locationAddress ?? l10n.vietnam} • ${l10n.club_memberCount(club.memberCount)}',
                            webUrl:
                                'https://sporto.asia/communities/${club.id}',
                            imageUrl: club.logoUrl ?? club.bannerUrl,
                            badgeText: l10n.club_badge,
                          );
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 16,
                        ),
                        label: Text(
                          l10n.club_inviteButton,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isJoinLoading
                          ? null
                          : () => _handleJoinAction(club),
                      icon: _isJoinLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_getJoinIcon(), size: 18),
                      label: Text(
                        _getJoinLabel(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _getJoinBgColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Không pin tab bar: banner + nút + tab trượt theo nội dung,
        // chỉ giữ app bar (SliverAppBar pinned ở trên) cố định — 1 scroll liền mạch.
        SliverPersistentHeader(
          pinned: false,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            colors: colors,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunitySocialScreen(
            communityId: club.id,
            communityName: club.name,
            showHeader: false,
          ),
          _buildAboutTab(club, colors),
          _buildTournamentsTab(colors),
          _buildMembersTab(club, colors),
          _buildGalleryTab(club, colors),
          _buildRankingsTab(colors, club),
          _buildSettingsTab(club, colors),
        ],
      ),
    );
  }

  // ─── Join button helpers ───
  IconData _getJoinIcon() {
    if (_isMember) return Icons.check_rounded;
    if (_isPending) return Icons.hourglass_empty_rounded;
    if (_isInvited) return Icons.mail_rounded;
    return Icons.add_rounded;
  }

  String _getJoinLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_isJoinLoading) return l10n.club_joinLoading;
    if (_isMember) return l10n.club_joined;
    if (_isPending) return l10n.club_pendingApproval;
    if (_isInvited) return l10n.club_acceptInvite;
    return l10n.club_joinButton;
  }

  void _showMemberOptionsSheet(BuildContext context, Community club) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _notificationPref == 'MUTED'
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_active_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.club_notificationSettings,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  _notificationPref == 'MUTED'
                      ? l10n.club_notificationsMuted
                      : _notificationPref == 'MENTIONS_ONLY'
                      ? l10n.club_notificationsMentionsOnly
                      : l10n.club_notificationsAll,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNotificationPreferenceSheet(context, club);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.club_leaveClub,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  l10n.club_leaveClubDescription,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmLeaveCommunity();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeaveCommunity() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.read(userProfileProvider).asData?.value.id;
    if (userId == null || userId.isEmpty || !_isMember) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubDetailLeaveTitle),
        content: Text(l10n.clubDetailLeaveDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clubDetailLeaveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isJoinLoading = true);
    try {
      final ok = await ref
          .read(communityRepositoryProvider)
          .leaveCommunity(widget.clubId, userId);
      if (!mounted) return;
      if (ok) {
        await _fetchMembership();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailLeftSuccess)));
      }
    } catch (e, stack) {
      _log.error('Lỗi rời CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailLeaveError)));
      }
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _showJoinQuestionsDialog(
    List<String> questions,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controllers = questions
        .map((_) => TextEditingController())
        .toList(growable: false);
    final formKey = GlobalKey<FormState>();
    final answers = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubDetailJoinQuestionsTitle),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.clubDetailJoinQuestionsInstruction),
                const SizedBox(height: 16),
                ...List.generate(
                  questions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controllers[index],
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: questions[index],
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.clubDetailJoinQuestionRequired
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, <String, dynamic>{
                for (var i = 0; i < questions.length; i++)
                  questions[i]: controllers[i].text.trim(),
              });
            },
            child: Text(l10n.clubDetailSubmitJoinRequest),
          ),
        ],
      ),
    );
    for (final controller in controllers) {
      controller.dispose();
    }
    return answers;
  }

  Color? _getJoinBgColor() {
    if (_isMember) return const Color(0xFF059669);
    if (_isPending) return Colors.grey;
    if (_isInvited) return AppTheme.primary;
    return AppTheme.primary;
  }

  Future<void> _handleJoinAction(Community? club) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    if (_isMember || _isPending) return;

    final community =
        club ?? ref.read(communityDetailProvider(widget.clubId)).value;
    if (community?.joinQuestions.isNotEmpty == true) {
      final answers = await _showJoinQuestionsDialog(community!.joinQuestions);
      if (answers == null) return;
      if (!mounted) return;
      setState(() => _isJoinLoading = true);
      try {
        final ok = await ref
            .read(communityRepositoryProvider)
            .joinCommunity(widget.clubId, answers: answers);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? l10n.club_joinSuccess : l10n.club_joinFailed),
            ),
          );
          if (ok) await _fetchMembership();
        }
      } catch (e, stack) {
        // joinCommunity ném lỗi kèm message backend (hết chỗ, riêng tư...) —
        // phải bắt để hiện lý do thay vì crash.
        _log.error('Lỗi khi tham gia CLB (có câu hỏi)', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clubDetailJoinRequestError),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isJoinLoading = false);
      }
      return;
    }

    setState(() => _isJoinLoading = true);
    try {
      if (_isInvited) {
        await ref
            .read(communityRepositoryProvider)
            .respondToInvite(widget.clubId, 'accept');
        _log.success('Chấp nhận lời mời CLB thành công');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clubDetailJoinedSuccess),
              backgroundColor: Color(0xFF059669),
            ),
          );
          await _fetchMembership();
        }
        return;
      }

      final ok = await ref
          .read(communityRepositoryProvider)
          .joinCommunity(widget.clubId);
      if (ok && mounted) {
        _log.success('Tham gia/gửi yêu cầu CLB thành công');
        final isApproval = community?.joinMode.toUpperCase() == 'APPROVAL';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproval
                  ? l10n.club_joinPendingApproval
                  : l10n.club_joinSuccess,
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        await _fetchMembership();
      } else if (mounted) {
        _log.warning('Tham gia CLB thất bại');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.club_joinFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi khi tham gia CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.errorPrefix}: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }

  Widget _buildClubBanner(
    Community club,
    AppColorsExtension colors,
    Color sColor,
    String emoji,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasBanner = club.bannerUrl != null && club.bannerUrl!.isNotEmpty;
    final List<Widget> sportTagWidgets = [];
    if (club.sports.isNotEmpty) {
      for (final s in club.sports) {
        final sTrim = s.trim();
        if (sTrim.isEmpty) continue;
        final mapped = l10n.sportDisplayName(sTrim);
        sportTagWidgets.add(_buildSportTag(mapped, sColor));
        sportTagWidgets.add(const SizedBox(width: 6));
      }
    }
    if (sportTagWidgets.isEmpty) {
      sportTagWidgets.add(
        _buildSportTag(l10n.club_sportFallback.toUpperCase(), sColor),
      );
      sportTagWidgets.add(const SizedBox(width: 6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              color: colors.bgCard,
              child: hasBanner
                  ? Image.network(
                      club.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _bannerGradient(sColor, emoji),
                    )
                  : _bannerGradient(sColor, emoji),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                          ? Image.network(
                              club.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _logoSportBg(sColor, emoji),
                            )
                          : _logoSportBg(sColor, emoji),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              ...sportTagWidgets,
                              if (_myMembership?.role == 'OWNER') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shield_rounded,
                                        size: 11,
                                        color: Color(0xFF6366F1),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        l10n.club_owner,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6366F1),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ] else if (_myMembership?.role == 'ADMIN' ||
                                  _myMembership?.role == 'MODERATOR') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 11,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        l10n.club_admin,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFF59E0B),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              const SizedBox(width: 2),
                              _buildJoinModeBadge(club.joinMode),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          club.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _iconText(
                              Icons.location_on_outlined,
                              club.locationAddress ?? l10n.vietnam,
                              colors,
                            ),
                            _iconText(
                              Icons.group_rounded,
                              l10n.club_memberCount(club.memberCount),
                              colors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((club.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  club.description ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: colors.border, height: 1.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSportTag(String sportName, Color sColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: sColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: sColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        sportName.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: sColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildJoinModeBadge(String mode) {
    final l10n = AppLocalizations.of(context)!;
    String label = l10n.club_joinModeOpen;
    Color color = const Color(0xFF059669);
    if (mode == 'INVITE_ONLY') {
      label = l10n.club_joinModeInvite;
      color = const Color(0xFFE11D48);
    } else if (mode == 'APPROVAL') {
      label = l10n.club_joinModeApproval;
      color = const Color(0xFFF59E0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text, AppColorsExtension colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }

  Widget _bannerGradient(Color c, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Taste: màu phẳng, không gradient.
    return Container(
      color: isDark ? const Color(0xFF16233A) : const Color(0xFFE8EEFB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: SvgPicture.asset(
            AppConstants.logoFullSvg,
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _logoSportBg(Color c, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: SvgPicture.asset(AppConstants.logoFullSvg, fit: BoxFit.contain),
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 1: GIỚI THIỆU
  // ════════════════════════════════════
  Widget _buildAboutTab(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final String sportsDisplay = club.sports.isNotEmpty
        ? club.sports
              .map(l10n.sportDisplayName)
              .where((s) => s.isNotEmpty && s.toLowerCase() != 'thể thao')
              .join(', ')
        : l10n.createClubTournament_sportPickleball;
    final finalSportsText = sportsDisplay.isEmpty
        ? l10n.createClubTournament_sportPickleball
        : sportsDisplay;

    String createdDateText = '';
    if (club.createdAt.isNotEmpty) {
      final parsedDate = DateTime.tryParse(club.createdAt);
      if (parsedDate != null) {
        createdDateText =
            '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (club.description != null && club.description!.isNotEmpty) ...[
          _sectionTitle(l10n.club_aboutSection, colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              club.description!,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _sectionTitle(l10n.club_infoSection, colors),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _infoRow(
                club.visibility.toUpperCase() == 'PRIVATE'
                    ? Icons.lock_outline_rounded
                    : Icons.public_rounded,
                'Quyền riêng tư',
                club.visibility.toUpperCase() == 'PRIVATE'
                    ? 'Riêng tư (Chỉ thành viên xem được hoạt động)'
                    : 'Công khai (Mọi người đều có thể xem)',
                colors,
              ),
              _divider(colors),
              _infoRow(
                Icons.people_rounded,
                l10n.club_memberInfo,
                club.maxMembers != null
                    ? "${club.memberCount} / ${club.maxMembers} thành viên tối đa"
                    : "${club.memberCount} thành viên",
                colors,
              ),
              _divider(colors),
              _infoRow(
                Icons.location_on_rounded,
                l10n.club_location,
                club.locationAddress ?? l10n.notUpdated,
                colors,
              ),
              _divider(colors),
              _infoRow(
                Icons.how_to_reg_rounded,
                l10n.club_joinModeLabel,
                club.joinMode == "OPEN"
                    ? l10n.club_joinModeOpen
                    : club.joinMode == "APPROVAL"
                    ? l10n.club_joinModeApprovalNeeded
                    : l10n.club_joinModeInvite,
                colors,
              ),
              _divider(colors),
              _infoRow(
                Icons.sports_rounded,
                l10n.club_sportLabel,
                finalSportsText,
                colors,
              ),
              if (createdDateText.isNotEmpty) ...[
                _divider(colors),
                _infoRow(
                  Icons.calendar_today_rounded,
                  'Ngày thành lập',
                  createdDateText,
                  colors,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(l10n.clubDetailRulesTitle, colors),
        const SizedBox(height: 10),
        if (club.rules != null && club.rules!.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Điều lệ & Quy chế hoạt động',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  club.rules!.trim(),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CLB chưa cập nhật nội quy riêng. Thành viên vui lòng tuân thủ quy tắc ứng xử chung và tinh thần thể thao văn minh.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_myMembership?.role == 'OWNER' ||
                    _myMembership?.role == 'ADMIN') ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        context.push('/club/${widget.clubId}/edit'),
                    child: const Text('Thêm ngay'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (club.socialLinks.isNotEmpty) ...[
          _sectionTitle(l10n.clubDetailContactTitle, colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: club.socialLinks.entries
                  .where((entry) => entry.value.trim().isNotEmpty)
                  .map(
                    (entry) => ActionChip(
                      avatar: Icon(_socialIcon(entry.key), size: 16),
                      label: Text(_socialLabel(entry.key)),
                      onPressed: () => _openSocialLink(entry.value),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  IconData _socialIcon(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'zalo':
        return Icons.chat_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  String _socialLabel(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return 'Facebook';
      case 'zalo':
        return 'Zalo';
      default:
        return 'Website';
    }
  }

  Future<void> _openSocialLink(String value) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = value.trim();
    final uri = Uri.tryParse(
      raw.startsWith('http://') || raw.startsWith('https://')
          ? raw
          : 'https://$raw',
    );
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailOpenLinkError)));
      }
    }
  }

  Widget _sectionTitle(String title, AppColorsExtension colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: colors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColorsExtension colors) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
  );

  // ════════════════════════════════════
  //  TAB 2: GIẢI ĐẤU
  // ════════════════════════════════════
  bool _matchesTournamentStatus(String status, String filter) {
    if (filter == 'ALL') return true;
    if (filter == 'UPCOMING') {
      return StatusHelper.isTournamentUpcoming(status) ||
          StatusHelper.isTournamentRegistration(status);
    }
    if (filter == 'ONGOING') return StatusHelper.isTournamentInProgress(status);
    if (filter == 'COMPLETED')
      return StatusHelper.isTournamentCompleted(status);
    return true;
  }

  String _tournamentSportLabel(String sport, AppLocalizations l10n) {
    final key = sport.trim().toLowerCase();
    final localized = l10n.sportDisplayName(key);
    return localized.isEmpty ? l10n.clubDetailOtherSport : localized;
  }

  Widget _buildTournamentFilters(
    AppColorsExtension colors,
    List<String> sports,
  ) {
    final l10n = AppLocalizations.of(context)!;
    Widget chips(
      List<(String, String)> options,
      String selected,
      ValueChanged<String> onChanged,
    ) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: options
              .map(
                (option) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      option.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: selected == option.$1,
                    onSelected: (_) => onChanged(option.$1),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.14),
                    side: BorderSide(
                      color: selected == option.$1
                          ? AppTheme.primary
                          : colors.border,
                    ),
                    labelStyle: TextStyle(
                      color: selected == option.$1
                          ? AppTheme.primary
                          : colors.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.clubDetailFilterTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          chips(
            [
              ('ALL', l10n.clubDetailAllTournaments),
              ('CLUB', l10n.clubDetailClubTournaments),
              ('PUBLIC', l10n.clubDetailOpenTournaments),
            ],
            _tournamentTypeFilter,
            (v) => setState(() => _tournamentTypeFilter = v),
          ),
          const SizedBox(height: 4),
          chips(
            [
              ('ALL', l10n.clubDetailAllStatuses),
              ('UPCOMING', l10n.clubDetailUpcoming),
              ('ONGOING', l10n.clubDetailOngoing),
              ('COMPLETED', l10n.clubDetailCompleted),
            ],
            _tournamentStatusFilter,
            (v) => setState(() => _tournamentStatusFilter = v),
          ),
          if (sports.length > 1) ...[
            const SizedBox(height: 4),
            chips(
              [
                ('ALL', l10n.clubDetailAllSports),
                ...sports.map(
                  (sport) => (sport, _tournamentSportLabel(sport, l10n)),
                ),
              ],
              _tournamentSportFilter,
              (v) => setState(() => _tournamentSportFilter = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentsTab(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final tourneysAsync = ref.watch(
      communityTournamentsProvider(widget.clubId),
    );
    final isAdmin =
        _myMembership?.role == 'OWNER' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';
    return tourneysAsync.when(
      data: (tourneys) {
        if (tourneys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: colors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.club_noTournaments,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showCreateTournamentTypeSheet(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.club_createTournament),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        final sports = tourneys
            .map((t) => t.sport)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        final filteredTourneys = tourneys.where((t) {
          if (!isAdmin && StatusHelper.isTournamentDraft(t.status))
            return false;
          if (_tournamentTypeFilter != 'ALL' &&
              t.tournamentType != _tournamentTypeFilter)
            return false;
          if (_tournamentSportFilter != 'ALL' &&
              t.sport != _tournamentSportFilter)
            return false;
          return _matchesTournamentStatus(t.status, _tournamentStatusFilter);
        }).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount:
              filteredTourneys.length +
              (isAdmin ? 2 : 1) +
              (filteredTourneys.isEmpty ? 1 : 0),
          itemBuilder: (context, i) {
            if (isAdmin && i == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showCreateTournamentTypeSheet(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                l10n.club_createTournament,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            context.push('/club/${widget.clubId}/manage'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: colors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: colors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.clubDetailManageTournaments,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final filterIndex = isAdmin ? 1 : 0;
            if (i == filterIndex) {
              return _buildTournamentFilters(colors, sports);
            }
            if (filteredTourneys.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 42,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.clubDetailNoFilteredTournaments,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _tournamentStatusFilter = 'ALL';
                        _tournamentTypeFilter = 'ALL';
                        _tournamentSportFilter = 'ALL';
                      }),
                      child: Text(l10n.clubDetailClearFilters),
                    ),
                  ],
                ),
              );
            }
            final index = i - filterIndex - 1;
            return _buildTourneyCard(filteredTourneys[index], colors);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải giải đấu của CLB', e, st);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.club_loadDataError,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTourneyCard(
    CommunityTournamentModel t,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedStatus = StatusHelper.normalizeTournamentStatus(t.status);
    final statusLabel = StatusHelper.getTournamentStatusLabel(normalizedStatus);
    final statusColor = StatusHelper.getTournamentStatusColor(
      normalizedStatus,
      context,
    );

    final isQuick = t.isLite;
    final badgeColor = isQuick ? const Color(0xFFF59E0B) : AppTheme.primary;

    return InkWell(
      onTap: () => context.push('/intro/${t.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon giải đấu
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isQuick ? Icons.bolt_rounded : Icons.emoji_events_rounded,
                color: badgeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin giải đấu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _tournamentBadge(
                        t.tournamentType == 'CLUB'
                            ? l10n.clubDetailClubTournamentBadge
                            : l10n.clubDetailOpenTournamentBadge,
                        t.tournamentType == 'CLUB'
                            ? const Color(0xFFD97706)
                            : AppTheme.primary,
                      ),
                      _tournamentBadge(
                        t.isRanked
                            ? l10n.clubDetailRankedBadge
                            : l10n.clubDetailCasualBadge,
                        t.isRanked
                            ? const Color(0xFFB45309)
                            : colors.textSecondary,
                      ),
                      if (t.parentId != null)
                        _tournamentBadge(
                          l10n.clubDetailSeriesBadge,
                          const Color(0xFF2563EB),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    t.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        l10n.club_teamCount(t.teamCount, t.maxTeams),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (t.startDate != null && t.startDate!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: colors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.startDate!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Nhãn trạng thái & Thẻ loại giải xếp chồng ngăn nắp bên phải
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isQuick
                            ? Icons.bolt_rounded
                            : Icons.workspace_premium_rounded,
                        size: 10,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isQuick ? l10n.clubDetailLiteBadge : l10n.club_advanced,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tournamentBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showCreateTournamentTypeSheet() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.club_selectTournamentType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.club_selectTournamentDesc,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 20),

            // Option 1: Giải Nhanh (Lite)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/club/${widget.clubId}/create-tournament');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.club_liteTournament,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.club_30sOnApp,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.club_liteDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Tạo nhanh theo luồng Web, vẫn gắn với CLB.
            InkWell(
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse(
                  'https://sporto.asia/organizer/tournaments/create?communityId=${widget.clubId}',
                );
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.clubDetailQuickWebTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.clubDetailQuickWebDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 3: Giải Nâng Cao (Full) - Direct to Web notice
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _showAdvancedTournamentWebDialog(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.club_advancedTournament,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.club_createOnWeb,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.club_advancedDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_browser_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedTournamentWebDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.laptop_chromebook_rounded,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.club_createAdvancedTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          l10n.club_advancedWebDialog,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(
                'https://sporto.asia/organizer/tournaments/create?communityId=${widget.clubId}&mode=advanced',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(l10n.club_copyWebLink),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateLockView({
    required IconData icon,
    required String title,
    required String description,
    required Community club,
    required AppColorsExtension colors,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 38, color: const Color(0xFFD97706)),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            if (!_isMember)
              FilledButton.icon(
                onPressed: _isJoinLoading ? null : () => _handleJoinAction(club),
                icon: Icon(_getJoinIcon(), size: 16),
                label: Text(_getJoinLabel()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 3: THÀNH VIÊN
  // ════════════════════════════════════
  Widget _buildMembersTab(Community club, AppColorsExtension colors) {
    if (club.visibility.toUpperCase() == 'PRIVATE' && !_isMember) {
      return _buildPrivateLockView(
        icon: Icons.people_rounded,
        title: 'Danh sách thành viên riêng tư',
        description:
            'CLB này đặt chế độ riêng tư. Hãy tham gia CLB để xem danh sách thành viên và kết nối giao lưu.',
        club: club,
        colors: colors,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(communityMembersProvider(widget.clubId));
    final isAdmin =
        _myMembership?.role == 'OWNER' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';
    final joinRequestsAsync = isAdmin
        ? ref.watch(joinRequestsProvider(widget.clubId))
        : const AsyncValue.data(<CommunityMemberModel>[]);
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: colors.textMuted),
                const SizedBox(height: 12),
                Text(
                  l10n.club_noMembers,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invite button for admins
            if (isAdmin) ...[
              _buildInviteButton(colors),
              const SizedBox(height: 8),
            ],
            if (isAdmin) _buildJoinRequestsSection(joinRequestsAsync, colors),
            if (members.isEmpty) const SizedBox.shrink(),
            ...members.map((m) => _buildMemberItem(m, colors, isAdmin)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải thành viên CLB', e, st);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.club_loadListError,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberItem(
    CommunityMemberModel m,
    AppColorsExtension colors,
    bool isAdmin,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = m.role == 'OWNER';
    final canViewProfile = m.userId.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: canViewProfile
                ? () => UserProfileBottomSheet.show(
                    context,
                    userId: m.userId,
                    communityId: widget.clubId,
                    initialFullName: m.userFullName,
                    initialAvatarUrl: m.userAvatarUrl,
                  )
                : null,
            child: _buildUserAvatar(
              name: m.userFullName,
              avatarUrl: m.userAvatarUrl,
              radius: 20,
              fallbackColor: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: canViewProfile
                  ? () => UserProfileBottomSheet.show(
                      context,
                      userId: m.userId,
                      communityId: widget.clubId,
                      initialFullName: m.userFullName,
                      initialAvatarUrl: m.userAvatarUrl,
                    )
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.userFullName ?? l10n.club_membersLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (m.role != 'MEMBER')
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOwner ? l10n.club_owner : l10n.club_admin,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isOwner ? Colors.amber.shade800 : Colors.blue,
                        ),
                      ),
                    ),
                  // P2C.5 — pills tag BQT (màu preset, tint như web) + streak cạnh tên.
                  if (m.tags.isNotEmpty || !m.streak.isEmpty) ...[
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final presets = ref
                            .watch(communityTagPresetsProvider(widget.clubId))
                            .asData
                            ?.value;
                        return Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...m.tags.map(
                              (tag) => PresetTagChip(
                                label: tag,
                                color: presets == null
                                    ? null
                                    : resolvePresetColor(presets, tag),
                                style: PresetTagChipStyle.tint,
                              ),
                            ),
                            if (!m.streak.isEmpty)
                              StreakChip(
                                type: m.streak.type,
                                count: m.streak.count,
                                label: m.streak.label,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Menu quản lý (OWNER/ADMIN thấy, nhưng không thể tự kick chính mình)
          if (isAdmin && !isOwner && m.userId != _myMembership?.userId)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.textMuted,
                size: 20,
              ),
              color: colors.bgSurface,
              onSelected: (action) => _handleMemberAction(action, m, colors),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'promote_admin',
                  child: Text(
                    l10n.club_setAdmin,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                PopupMenuItem(
                  value: 'promote_mod',
                  child: Text(
                    l10n.club_setMod,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (m.role != 'MEMBER')
                  PopupMenuItem(
                    value: 'demote',
                    child: Text(
                      l10n.club_demoteToMember,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                PopupMenuItem(
                  value: 'assign_tags',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sell_rounded,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.memberTagMenu,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'kick',
                  child: Text(
                    l10n.club_kickFromClub,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleMemberAction(
    String action,
    CommunityMemberModel m,
    AppColorsExtension colors,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(communityRepositoryProvider);
    try {
      switch (action) {
        case 'promote_admin':
          await repo.updateMemberRole(
            widget.clubId,
            m.id.isNotEmpty ? m.id : m.userId,
            'ADMIN',
          );
          break;
        case 'promote_mod':
          await repo.updateMemberRole(
            widget.clubId,
            m.id.isNotEmpty ? m.id : m.userId,
            'MODERATOR',
          );
          break;
        case 'demote':
          await repo.updateMemberRole(
            widget.clubId,
            m.id.isNotEmpty ? m.id : m.userId,
            'MEMBER',
          );
          break;
        case 'kick':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: colors.bgCard,
              title: Text(l10n.club_deleteMemberTitle),
              content: Text(
                l10n.club_deleteMemberConfirm(m.userFullName ?? ''),
                style: TextStyle(color: colors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.matchesCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    l10n.delete,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
            ),
          );
          if (confirm != true) return;
          await repo.removeMember(widget.clubId, m.userId);
          break;
        case 'assign_tags':
          // P2C.5 — gán tag BQT (bottom sheet tự đồng bộ member list sau khi lưu).
          await _openTagAssignSheet(m);
          break;
      }
      ref.invalidate(communityMembersProvider(widget.clubId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.club_updatedMember),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clubDetailMemberActionError),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  /// P2C.5 — Mở bottom sheet gán tag BQT; lưu qua repository rồi đồng bộ member list.
  Future<void> _openTagAssignSheet(CommunityMemberModel m) async {
    final repo = ref.read(communityRepositoryProvider);
    final presets = await repo.getTagPresets(widget.clubId);
    if (!mounted) return;
    await TagAssignSheet.show(
      context,
      memberName: m.userFullName ?? '',
      currentTags: m.tags,
      presets: presets,
      onSave: (tags) async {
        await repo.updateMemberTags(
          widget.clubId,
          m.userId.isNotEmpty ? m.userId : m.id,
          tags,
        );
        ref.invalidate(communityMembersProvider(widget.clubId));
      },
    );
  }

  Widget _buildInviteButton(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showInviteDialog(colors),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.club_inviteMember,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final searchCtrl = TextEditingController();
    List<dynamic> searchResults = [];
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.bgCard,
          title: Text(
            l10n.club_inviteMember,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.club_searchHint,
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textMuted,
                      size: 20,
                    ),
                    suffixIcon: searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (v) async {
                    if (v.trim().length < 2) return;
                    setDialogState(() => searching = true);
                    try {
                      final dio = ref.read(dioProvider);
                      final response = await dio.get(
                        '/users/search',
                        queryParameters: {'q': v.trim()},
                      );
                      final raw = response.data;
                      final data = raw is Map
                          ? (raw['data'] as List<dynamic>? ?? [])
                          : (raw as List<dynamic>? ?? []);
                      setDialogState(() {
                        searchResults = data;
                        searching = false;
                      });
                    } catch (_) {
                      setDialogState(() => searching = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      itemCount: searchResults.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: colors.borderLight),
                      itemBuilder: (_, i) {
                        final u = searchResults[i] as Map<String, dynamic>;
                        final name = u['fullName'] ?? l10n.dashboard_user;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (name as String).isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            u['email'] ?? '',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              await ref
                                  .read(communityRepositoryProvider)
                                  .inviteMember(
                                    widget.clubId,
                                    u['id'] ?? u['userId'] ?? '',
                                  );
                              ref.invalidate(
                                communityMembersProvider(widget.clubId),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.club_inviteSent),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.clubDetailMemberActionError,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                            }
                          },
                        );
                      },
                    ),
                  ),
                if (searchResults.isEmpty &&
                    searchCtrl.text.trim().length >= 2 &&
                    !searching)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      l10n.club_noUsersFound,
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRequestsSection(
    AsyncValue<List<CommunityMemberModel>> joinRequestsAsync,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return joinRequestsAsync.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == 'PENDING').toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.club_joinRequests(pending.length),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...pending.map((req) => _buildJoinRequestCard(req, colors)),
            const SizedBox(height: 16),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 12),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (context, error) => const SizedBox.shrink(),
    );
  }

  Widget _buildJoinRequestCard(
    CommunityMemberModel req,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            child: Text(
              (req.userFullName?.isNotEmpty == true
                      ? req.userFullName![0]
                      : '?')
                  .toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.userFullName ?? l10n.dashboard_user,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.club_pendingApproval,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await ref
                    .read(communityRepositoryProvider)
                    .reviewJoinRequest(
                      widget.clubId,
                      req.id.isNotEmpty ? req.id : req.userId,
                      'APPROVE',
                    );
                ref.invalidate(joinRequestsProvider(widget.clubId));
                ref.invalidate(communityMembersProvider(widget.clubId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.club_approvedMember),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.clubDetailMemberActionError),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.club_approve,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              try {
                await ref
                    .read(communityRepositoryProvider)
                    .reviewJoinRequest(
                      widget.clubId,
                      req.id.isNotEmpty ? req.id : req.userId,
                      'REJECT',
                    );
                ref.invalidate(joinRequestsProvider(widget.clubId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.club_rejected),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.clubDetailMemberActionError),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                l10n.club_reject,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 4: ẢNH (Gallery)
  // ════════════════════════════════════
  Widget _buildGalleryTab(Community club, AppColorsExtension colors) {
    if (club.visibility.toUpperCase() == 'PRIVATE' && !_isMember) {
      return _buildPrivateLockView(
        icon: Icons.photo_library_rounded,
        title: 'Thư viện hình ảnh riêng tư',
        description:
            'Hình ảnh hoạt động và khoảnh khắc của CLB chỉ dành riêng cho thành viên chính thức.',
        club: club,
        colors: colors,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final galleryAsync = ref.watch(communityGalleryProvider(widget.clubId));
    final isAdmin =
        _myMembership?.role == 'OWNER' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';

    return galleryAsync.when(
      data: (images) {
        // Collect all images with metadata
        final List<({String id, String url, String title, bool isSystem})>
        allItems = [
          if (club.logoUrl != null && club.logoUrl!.isNotEmpty)
            (
              id: 'sys-logo',
              url: club.logoUrl!,
              title: l10n.clubDetailClubLogo,
              isSystem: true,
            ),
          if (club.bannerUrl != null && club.bannerUrl!.isNotEmpty)
            (
              id: 'sys-banner',
              url: club.bannerUrl!,
              title: l10n.clubDetailCoverImage,
              isSystem: true,
            ),
          ...images.map(
            (img) => (
              id: img.id,
              url: img.imageUrl,
              title: l10n.clubDetailActivityImage,
              isSystem: false,
            ),
          ),
        ];

        if (allItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: colors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.club_noImages,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.club_gallerySubtitle,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isAddingGalleryImage ? null : _addGalleryImage,
                    icon: _isAddingGalleryImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.clubDetailAddFirstImage),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.clubDetailGalleryTitle(allItems.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: l10n.clubDetailAddImage,
                      onPressed: _isAddingGalleryImage
                          ? null
                          : _addGalleryImage,
                      icon: _isAddingGalleryImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0, // Ảnh vuông 1:1
                ),
                itemCount: allItems.length,
                itemBuilder: (context, i) {
                  final item = allItems[i];
                  return GestureDetector(
                    onTap: () => _showImagePreview(item.url),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: colors.bgSurface,
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: colors.textMuted,
                                      size: 28,
                                    ),
                                  ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: colors.bgSurface,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Badge label cho Logo / Banner
                            if (item.isSystem)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            // Nút xoá cho ảnh hoạt động nếu là Admin/Owner
                            if (!item.isSystem && isAdmin)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      _confirmDeleteGalleryImage(item.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải gallery', e, st);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.club_loadImagesError,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addGalleryImage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    setState(() => _isAddingGalleryImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final repo = ref.read(communityRepositoryProvider);
      final imageUrl = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(bytes, picked.name);
      await repo.addGalleryItem(widget.clubId, imageUrl: imageUrl);
      ref.invalidate(communityGalleryProvider(widget.clubId));
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailGalleryAdded)));
    } catch (e, stack) {
      _log.error('Lỗi thêm ảnh gallery', e, stack);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailGalleryAddError)));
    } finally {
      if (mounted) setState(() => _isAddingGalleryImage = false);
    }
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGalleryImage(String imageId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.clubDetailDeleteImageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(l10n.clubDetailDeleteImageDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(communityRepositoryProvider);
                await repo.removeGalleryItem(widget.clubId, imageId);
                ref.invalidate(communityGalleryProvider(widget.clubId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.clubDetailGalleryRemoved)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.clubDetailGalleryRemoveError)),
                  );
                }
              }
            },
            child: Text(l10n.clubDetailDeleteAction),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 5: BẢNG XẾP HẠNG (Rankings)
  // ════════════════════════════════════
  Widget _buildRankingsTab(AppColorsExtension colors, Community club) {
    // The ranking widget already contains the podium, Top 4-20 list,
    // search, polling status, and the current user's ELO card.
    // Truyền môn của CLB để bộ lọc Môn chỉ hiện môn CLB đã đăng ký (giống web).
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClubRankingWidget(clubId: widget.clubId, clubSportKeys: club.sports),
      ],
    );
  }

  Widget _buildUserAvatar({
    required String? name,
    required String? avatarUrl,
    required double radius,
    required Color fallbackColor,
  }) {
    final initial = (name?.trim().isNotEmpty == true ? name!.trim()[0] : '?')
        .toUpperCase();
    final url = avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor.withValues(alpha: 0.1),
      child: url == null || url.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: fallbackColor,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.7,
              ),
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: fallbackColor,
                      fontWeight: FontWeight.w800,
                      fontSize: radius * 0.7,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ════════════════════════════════════
  //  TAB 6: CÀI ĐẶT (Settings)
  // ════════════════════════════════════
  Widget _buildSettingsTab(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin =
        _myMembership?.role == 'OWNER' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thông tin CLB
        _settingsSectionHeader(l10n.club_sectionInfo, colors),
        const SizedBox(height: 8),
        _settingsTile(
          icon: Icons.edit_rounded,
          title: l10n.club_editInfo,
          subtitle: l10n.club_editInfoSubtitle,
          color: AppTheme.primary,
          onTap: isAdmin
              ? () => context.push('/club/${widget.clubId}/edit')
              : null,
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.tune_rounded,
            title: l10n.club_manageClub,
            subtitle: l10n.club_manageClubSubtitle,
            color: AppTheme.primary,
            onTap: () => context.push(
              '/club/${widget.clubId}/manage',
              extra: _myMembership?.role == 'OWNER',
            ),
          ),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.forum_outlined,
            title: l10n.clubDetailSocialSettings,
            subtitle: l10n.clubDetailSocialSettingsSubtitle,
            color: AppTheme.primary,
            onTap: () => CommunitySocialSettingsSheet.show(
              context,
              repository: ref.read(communityRepositoryProvider),
              communityId: widget.clubId,
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Hình thức tham gia
        _settingsSectionHeader(l10n.club_joinModeSection, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.club_joinModeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      club.joinMode == 'OPEN'
                          ? l10n.club_joinModeOpen
                          : club.joinMode == 'APPROVAL'
                          ? l10n.club_joinModeApproval
                          : l10n.club_joinModeInvite,
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Trạng thái & Tóm tắt nhanh (đồng bộ sidebar web)
        _settingsSectionHeader(l10n.clubDetailQuickStatus, colors),
        const SizedBox(height: 8),
        _buildQuickStatusCard(club, colors),
        const SizedBox(height: 20),

        // Thống kê
        _settingsSectionHeader(l10n.club_statsSection, colors),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _settingsStatBox(
                l10n.club_membersLabel,
                '${club.memberCount}',
                Icons.people_rounded,
                AppTheme.primary,
                colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _settingsStatBox(
                l10n.club_sportLabel,
                club.sports.isNotEmpty ? club.sports.first : l10n.club_noSport,
                Icons.sports_rounded,
                const Color(0xFF059669),
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _settingsStatBox(
                l10n.club_statusLabel,
                club.status == 'ACTIVE' ? l10n.club_active : l10n.club_pending,
                Icons.circle_rounded,
                club.status == 'ACTIVE'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _settingsStatBox(
                l10n.club_createdAt,
                club.createdAt.isNotEmpty
                    ? club.createdAt.substring(0, 10)
                    : '---',
                Icons.calendar_today_rounded,
                colors.textMuted,
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Hành động nguy hiểm (chỉ OWNER)
        if (_myMembership?.role == 'OWNER') ...[
          _settingsSectionHeader(l10n.club_dangerSection, colors),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.delete_forever_rounded,
            title: l10n.club_deleteClub,
            subtitle: l10n.club_deleteSubtitle,
            color: colors.error,
            onTap: () => _showDeleteClubDialog(club, colors),
          ),
        ],
      ],
    );
  }

  /// Tóm tắt nhanh như sidebar web: trạng thái, chế độ hiển thị, phòng chat.
  Widget _buildQuickStatusCard(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final visibilityLabel = club.visibility == 'PUBLIC'
        ? l10n.rank_public
        : club.visibility == 'RESTRICTED'
        ? l10n.clubDetailRestrictedVisibility
        : l10n.clubDetailPrivateVisibility;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _quickStatusRow(
            colors,
            icon: Icons.bolt_rounded,
            label: l10n.clubDetailStatus,
            value: l10n.clubDetailActiveStatus,
            valueColor: colors.success,
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          _quickStatusRow(
            colors,
            icon: Icons.visibility_outlined,
            label: l10n.clubDetailVisibility,
            value: visibilityLabel,
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          FutureBuilder<CommunitySocialSettings>(
            future: _socialSettingsFuture ??= ref
                .read(communityRepositoryProvider)
                .getSocialSettings(widget.clubId),
            builder: (context, snapshot) {
              final chatEnabled = snapshot.data?.chatEnabled ?? true;
              return _quickStatusRow(
                colors,
                icon: Icons.chat_bubble_outline_rounded,
                label: l10n.clubDetailInternalChat,
                value: chatEnabled
                    ? l10n.clubDetailChatOpen
                    : l10n.clubDetailChatClosed,
                valueColor: chatEnabled ? colors.success : colors.textMuted,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickStatusRow(
    AppColorsExtension colors, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSectionHeader(String title, AppColorsExtension colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: colors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _settingsStatBox(
    String label,
    String value,
    IconData icon,
    Color color,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        ],
      ),
    );
  }

  Future<void> _showDeleteClubDialog(
    Community club,
    AppColorsExtension colors,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.club_deleteConfirmTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.club_deleteWarning(club.name),
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.clubDetailDeleteNameHint,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.clubDetailCurrentClubName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.matchesCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              nameController.text.trim() == club.name.trim(),
            ),
            child: Text(
              l10n.delete,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (confirm == true) {
      try {
        await ref
            .read(communityRepositoryProvider)
            .deleteCommunity(widget.clubId);
        invalidateCommunityCollections(ref);
        ref.invalidate(communityDetailProvider(widget.clubId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.club_deleted),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Deep-link thẳng vào CLB không có stack để pop — về /home an toàn.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clubDetailMemberActionError),
              backgroundColor: colors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

// ═══════════════════════════════════════════
//  TAB BAR DELEGATE
// ═══════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;

  _TabBarDelegate({required this.tabController, required this.colors});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        // Đồng bộ với Web: tab active là pill emerald, không dùng gạch
        // chân xanh riêng của theme mobile.
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 3,
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF475569),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        isScrollable: true,
        tabs: [
          Tab(text: l10n.clubDetailFeedTab),
          Tab(text: l10n.club_tabAbout),
          Tab(text: l10n.club_tabTournaments),
          Tab(text: l10n.club_tabMembers),
          Tab(text: l10n.club_tabGallery),
          Tab(text: l10n.club_tabRankings),
          Tab(text: l10n.club_tabSettings),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48.0;
  @override
  double get minExtent => 48.0;
  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
}
