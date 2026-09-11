import 'dart:io' show Platform;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/club_network_image.dart';
import 'package:app_quanly_giaidau/core/widgets/image_crop_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
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
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/features/community/widgets/tag_assign_sheet.dart';
import 'package:app_quanly_giaidau/features/community/widgets/community_social_settings_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/features/community/social/community_social_screen.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_activity_tab.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_elo_adjust_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_tier_badge.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_sessions_screen.dart';

part '../widgets/club_detail_tab_delegate.dart';
part '../widgets/club_detail_lazy_tab.dart';
part '../widgets/club_detail_banner_painter.dart';
part '../widgets/club_detail_join_questions_dialog.dart';
part '../widgets/club_detail_join_actions.dart';
part '../widgets/club_detail_header_app_bar.dart';
part '../widgets/club_detail_header_info.dart';
part '../widgets/club_detail_header_helpers.dart';
part '../widgets/club_detail_header_fullscreen.dart';
part '../widgets/club_detail_about_tab.dart';
part '../widgets/club_detail_about_helpers.dart';
part '../widgets/club_detail_tournament_overview.dart';
part '../widgets/club_detail_tournament_session_card.dart';
part '../widgets/club_detail_tournament_session_banner.dart';
part '../widgets/club_detail_tournament_card.dart';
part '../widgets/club_detail_tournament_badge.dart';
part '../widgets/club_detail_private_view.dart';
part '../widgets/club_detail_members_overview.dart';
part '../widgets/club_detail_member_profile.dart';
part '../widgets/club_detail_member_item.dart';
part '../widgets/club_detail_member_actions.dart';
part '../widgets/club_detail_member_management.dart';
part '../widgets/club_detail_gallery_tab.dart';
part '../widgets/club_detail_gallery_add.dart';
part '../widgets/club_detail_gallery_preview.dart';
part '../widgets/club_detail_gallery_avatar.dart';
part '../widgets/club_detail_settings_tab.dart';
part '../widgets/club_detail_settings_helpers.dart';
part '../widgets/club_detail_settings_delete.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  final _log = AppLogger('ClubDetail');
  late TabController _tabController;
  CommunityMemberModel? _myMembership;
  bool _isJoinLoading = false;

  // Khóa toàn bộ luồng tham gia, kể cả lúc đang mở dialog câu hỏi. Nút có
  // thể nhận 2 lần tap trước khi frame loading đầu tiên được vẽ.
  bool _isJoinFlowActive = false;
  String _tournamentStatusFilter = 'ALL';
  String _tournamentSportFilter = 'ALL';
  bool _isAddingGalleryImage = false;
  bool _isAboutDescExpanded = false;
  bool _isAboutRulesExpanded = false;
  String _memberSortMode = 'role'; // 'role' (mặc định) | 'elo'
  // Cache future cho card Trạng thái nhanh — tránh gọi lại API mỗi lần rebuild.
  Future<CommunitySocialSettings>? _socialSettingsFuture;
  late final ScrollController _scrollController;
  bool _isCollapsed = false;
  final double _bannerHeight = 90.0;
  final double _avatarOverlap = 8.0;

  void _updateClubState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMembership());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final collapsed = _scrollController.offset >= 96.0;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
      // A successful join changes several conditional tab subtrees at once.
      // Apply that structural update on the next frame, after the current
      // route/API callback has finished, so inherited dependents can detach
      // cleanly instead of being deactivated mid-build.
      await _waitForUiFrame();
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
        queryParameters: {'type': 'CLUB', 'communityId': club.id},
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
    if (n.contains('badminton') || n.contains('cầu lông')) {
      return const Color(0xFF0284C7);
    }
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

  /// Chờ hết frame hiện tại trước khi dựng lại các subtree phụ thuộc vào
  /// membership hoặc vừa được đóng khỏi một dialog route.
  Future<void> _waitForUiFrame() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Widget _buildContent(Community club) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final sportName = club.sports.isNotEmpty
        ? club.sports.first
        : l10n.club_sportFallback;
    final Color sColor = _sportColor(sportName);
    final String emoji = _sportEmoji(sportName);
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id;
    final isCreator = club.ownerId != null && club.ownerId == currentUserId;
    final isOwner =
        isCreator || club.myRole == 'OWNER' || _myMembership?.role == 'OWNER';
    final isClubAdmin =
        isOwner ||
        club.myRole == 'ADMIN' ||
        club.myRole == 'MODERATOR' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';

    final topPadding = MediaQuery.of(context).padding.top;
    final logoUrl = _resolveImageUrl(club.logoUrl);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityDetailProvider(widget.clubId));
            ref.invalidate(communityMembersFeedProvider(widget.clubId));
            ref.invalidate(communityRankingsProvider(widget.clubId));
            await _fetchMembership();
          },
          child: NestedScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(
                club,
                colors,
                sColor,
                emoji,
                topPadding,
                l10n,
                isClubAdmin: isClubAdmin,
              ),
              SliverToBoxAdapter(
                child: _buildClubInfoSection(
                  club,
                  colors,
                  sColor,
                  emoji,
                  isClubAdmin: isClubAdmin,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  colors: colors,
                  onMoreSelected: (val) {
                    if (val == 'tourneys') {
                      _showClubTournamentsFullScreen(club, colors);
                    } else if (val == 'gallery') {
                      _showClubGalleryFullScreen(club, colors);
                    } else if (val == 'settings') {
                      _showClubSettingsFullScreen(club, colors);
                    }
                  },
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _LazyClubTab(
                  controller: _tabController,
                  index: 0,
                  builder: (_) => CommunitySocialScreen(
                    communityId: club.id,
                    communityName: club.name,
                    showHeader: false,
                  ),
                ),
                _LazyClubTab(
                  controller: _tabController,
                  index: 1,
                  builder: (_) =>
                      ClubActivityTab(communityId: club.id, club: club),
                ),
                _LazyClubTab(
                  controller: _tabController,
                  index: 2,
                  builder: (_) => _buildMembersTab(club, colors),
                ),
              ],
            ),
          ),
        ),
        // Avatar CLB — luôn nổi trên banner, không còn bị pinned SliverAppBar đè
        AnimatedBuilder(
          animation: _scrollController,
          builder: (context, _) {
            final offset = _scrollController.hasClients
                ? _scrollController.offset
                : 0.0;
            final top = topPadding + _bannerHeight - _avatarOverlap - offset;
            return Positioned(
              top: top,
              left: 16,
              child: IgnorePointer(
                ignoring: _isCollapsed,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isCollapsed ? 0 : 1,
                  child: _buildClubAvatar(
                    logoUrl: logoUrl,
                    colors: colors,
                    sColor: sColor,
                    emoji: emoji,
                    isClubAdmin: isClubAdmin,
                    club: club,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Change Avatar / Cover Photo (Yêu cầu 1) ───
  Future<void> _showChangePhotoOptions({
    required Community club,
    required bool isLogo,
  }) async {
    final colors = context.colors;
    final title = isLogo ? 'Chỉnh sửa ảnh đại diện CLB' : 'Chỉnh sửa ảnh bìa CLB';

    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                title: const Text(
                  'Chọn ảnh có sẵn trong Thư viện',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Chọn từ thư viện hình ảnh của câu lạc bộ',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () => Navigator.pop(ctx, 1),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                title: const Text(
                  'Tải ảnh lên',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Lấy ảnh từ thiết bị điện thoại của bạn',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () => Navigator.pop(ctx, 2),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    if (choice == 1) {
      await _pickFromClubGallery(club: club, isLogo: isLogo);
    } else if (choice == 2) {
      await _pickFromPhone(club: club, isLogo: isLogo);
    }
  }

  Future<void> _pickFromClubGallery({
    required Community club,
    required bool isLogo,
  }) async {
    final colors = context.colors;
    final galleryAsync =
        await ref.read(communityGalleryProvider(club.id).future);

    final List<String> availableUrls = [
      if (club.logoUrl != null && club.logoUrl!.isNotEmpty) club.logoUrl!,
      if (club.bannerUrl != null && club.bannerUrl!.isNotEmpty) club.bannerUrl!,
      ...galleryAsync.map((img) => img.imageUrl),
    ].where((u) => u.trim().isNotEmpty).toSet().toList();

    if (!mounted) return;

    if (availableUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thư viện CLB chưa có ảnh nào. Vui lòng chọn tải ảnh từ điện thoại.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chọn từ Thư viện CLB',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${availableUrls.length} ảnh',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: availableUrls.length,
                      itemBuilder: (context, idx) {
                        final rawUrl = availableUrls[idx];
                        final resolved = _resolveImageUrl(rawUrl);
                        return GestureDetector(
                          onTap: () => Navigator.pop(ctx, rawUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ClubNetworkImage(
                              resolved,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: colors.bgSurface,
                                child: const Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedUrl == null || !mounted) return;

    try {
      await ref.read(communityRepositoryProvider).updateCommunity(
        club.id,
        {isLogo ? 'logoUrl' : 'bannerUrl': selectedUrl},
      );
      ref.invalidate(communityDetailProvider(club.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLogo
                  ? 'Đã cập nhật ảnh đại diện CLB thành công'
                  : 'Đã cập nhật ảnh bìa CLB thành công',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật ảnh: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickFromPhone({
    required Community club,
    required bool isLogo,
  }) async {
    final colors = context.colors;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Chọn từ bộ sưu tập điện thoại'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    Uint8List? uploadBytes = bytes;
    if (isLogo) {
      uploadBytes = await ImageCropDialog.show(
        context,
        bytes: bytes,
        title: 'Chỉnh sửa ảnh đại diện CLB',
      );
      if (uploadBytes == null || !mounted) return;
    }

    try {
      final url = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(uploadBytes, isLogo ? 'club_logo.png' : picked.name);
      await ref.read(communityRepositoryProvider).updateCommunity(
        club.id,
        {isLogo ? 'logoUrl' : 'bannerUrl': url},
      );
      ref.invalidate(communityDetailProvider(club.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLogo
                  ? 'Đã tải lên và cập nhật ảnh đại diện thành công'
                  : 'Đã tải lên và cập nhật ảnh bìa thành công',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh lên: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════
