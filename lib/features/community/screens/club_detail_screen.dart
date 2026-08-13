import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_ranking_widget.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/features/community/widgets/tag_assign_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/features/community/social/community_social_screen.dart';

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
  bool _isFollowBusy = false;
  bool _isFavoriteBusy = false;
  bool?
  _followOverride; // P2E.2: ghi đè local khi backend chưa trả state follow
  bool? _favoriteOverride; // P2E.2: ghi đè local cho icon yêu thích
  String _tournamentStatusFilter = 'ALL';
  String _tournamentTypeFilter = 'ALL';
  String _tournamentSportFilter = 'ALL';

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
    } catch (e, stack) {
      _log.error('Failed to fetch membership', e, stack);
      if (mounted) setState(() => _myMembership = null);
    }
  }

  // ─── Follow / Favorite (P2E.2) ───

  Widget _buildFollowFavoriteButtons(
    Community club,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final following =
        _followOverride ??
        (ref.watch(isFollowingProvider(club.id)).value ?? false);
    final favorited =
        _favoriteOverride ??
        (ref.watch(isFavoritedProvider(club.id)).value ?? false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isFollowBusy
              ? null
              : () => _toggleClubFollow(club, following),
          tooltip: following ? l10n.club_unfollow : l10n.club_follow,
          icon: _isFollowBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                )
              : Icon(
                  following
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: following ? AppTheme.primary : colors.textMuted,
                  size: 22,
                ),
        ),
        IconButton(
          onPressed: _isFavoriteBusy
              ? null
              : () => _toggleClubFavorite(club, favorited),
          tooltip: favorited ? l10n.club_unfavorite : l10n.club_favorite,
          icon: _isFavoriteBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                )
              : Icon(
                  favorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: favorited ? AppTheme.primary : colors.textMuted,
                  size: 22,
                ),
        ),
      ],
    );
  }

  Future<void> _toggleClubFollow(
    Community club,
    bool currentlyFollowing,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    if (_isFollowBusy) return;
    setState(() => _isFollowBusy = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final ok = currentlyFollowing
          ? await repo.unfollowCommunity(club.id)
          : await repo.followCommunity(club.id);
      if (!mounted) return;
      if (ok) {
        setState(() => _followOverride = !currentlyFollowing);
        ref.invalidate(isFollowingProvider(club.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyFollowing
                  ? l10n.club_unfollowSuccess
                  : l10n.club_followSuccess,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.club_actionError)));
      }
    } catch (e, stack) {
      _log.error('Lỗi đổi trạng thái theo dõi CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.club_actionError)));
      }
    } finally {
      if (mounted) setState(() => _isFollowBusy = false);
    }
  }

  Future<void> _toggleClubFavorite(
    Community club,
    bool currentlyFavorited,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    if (_isFavoriteBusy) return;
    setState(() => _isFavoriteBusy = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final ok = currentlyFavorited
          ? await repo.unfavoriteCommunity(club.id)
          : await repo.favoriteCommunity(club.id);
      if (!mounted) return;
      if (ok) {
        setState(() => _favoriteOverride = !currentlyFavorited);
        ref.invalidate(isFavoritedProvider(club.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyFavorited
                  ? l10n.club_unfavoriteSuccess
                  : l10n.club_favoriteSuccess,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.club_actionError)));
      }
    } catch (e, stack) {
      _log.error('Lỗi đổi trạng thái yêu thích CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.club_actionError)));
      }
    } finally {
      if (mounted) setState(() => _isFavoriteBusy = false);
    }
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
        currentIndex: 1,
        onTabSelected: (index) {
          if (index != 1) context.go('/home?tab=$index');
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
          ),
          centerTitle: true,
          actions: [
            _buildFollowFavoriteButtons(club, colors, l10n),
            if (_myMembership?.role == 'OWNER' ||
                _myMembership?.role == 'ADMIN' ||
                _myMembership?.role == 'MODERATOR') ...[
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  onPressed: () => context.push(
                    '/club/${widget.clubId}/manage',
                    extra: _myMembership?.role == 'OWNER',
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: Text(
                    l10n.club_manageShort,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  onPressed: () => context.push('/club/${widget.clubId}/edit'),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    l10n.infoEdit,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
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
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isJoinLoading
                        ? null
                        : () => _handleJoinAction(),
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
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: colors.textPrimary,
                    ),
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
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            colors: colors,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunitySocialScreen(communityId: club.id, communityName: club.name),
          _buildAboutTab(club, colors),
          _buildTournamentsTab(colors),
          _buildMembersTab(colors),
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
    return Icons.add_rounded;
  }

  String _getJoinLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_isJoinLoading) return l10n.club_joinLoading;
    if (_isMember) return l10n.club_joined;
    if (_isPending) return l10n.club_pendingApproval;
    return l10n.club_joinButton;
  }

  Color? _getJoinBgColor() {
    if (_isMember) return const Color(0xFF059669);
    if (_isPending) return Colors.grey;
    return AppTheme.primary;
  }

  Future<void> _handleJoinAction() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    if (_isMember || _isPending) return;

    setState(() => _isJoinLoading = true);
    try {
      final ok = await ref
          .read(communityRepositoryProvider)
          .joinCommunity(widget.clubId);
      if (ok && mounted) {
        _log.success('Tham gia CLB thành công');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.club_joinSuccess),
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
        final mapped =
            AppConstants.sportNames[sTrim] ??
            AppConstants.sportNames[sTrim.toLowerCase()] ??
            sTrim;
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ...sportTagWidgets,
                    const SizedBox(width: 2),
                    _buildJoinModeBadge(club.joinMode),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                club.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  height: 1.35,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
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
                        Row(
                          children: [
                            Text(
                              l10n.club_label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (club.status == 'ACTIVE')
                              const SizedBox(width: 6),
                            if (club.status == 'ACTIVE')
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: sColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: 0.6), context.colors.bgDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 80,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  Widget _logoSportBg(Color c, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    );
  }

  // ════════════════════════════════════
  //  TAB 1: GIỚI THIỆU
  // ════════════════════════════════════
  Widget _buildAboutTab(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final String sportsDisplay = club.sports.isNotEmpty
        ? club.sports
              .map((s) => AppConstants.sportNames[s.trim()] ?? s.trim())
              .where((s) => s.isNotEmpty && s.toLowerCase() != 'thể thao')
              .join(', ')
        : "Pickleball";
    final finalSportsText = sportsDisplay.isEmpty
        ? "Pickleball"
        : sportsDisplay;

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
                Icons.people_rounded,
                l10n.club_memberInfo,
                "${club.memberCount}",
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
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
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

  String _tournamentSportLabel(String sport) {
    final key = sport.trim().toLowerCase();
    return AppConstants.sportNames[key] ??
        (key.isEmpty ? 'Khác' : key.replaceAll('_', ' '));
  }

  Widget _buildTournamentFilters(
    AppColorsExtension colors,
    List<String> sports,
  ) {
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
              'Lọc giải đấu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          chips(
            const [
              ('ALL', 'Tất cả giải'),
              ('CLUB', 'Nội bộ CLB'),
              ('PUBLIC', 'Mở rộng'),
            ],
            _tournamentTypeFilter,
            (v) => setState(() => _tournamentTypeFilter = v),
          ),
          const SizedBox(height: 4),
          chips(
            const [
              ('ALL', 'Mọi trạng thái'),
              ('UPCOMING', 'Sắp diễn ra'),
              ('ONGOING', 'Đang diễn ra'),
              ('COMPLETED', 'Đã kết thúc'),
            ],
            _tournamentStatusFilter,
            (v) => setState(() => _tournamentStatusFilter = v),
          ),
          if (sports.length > 1) ...[
            const SizedBox(height: 4),
            chips(
              [
                ('ALL', 'Mọi môn'),
                ...sports.map((sport) => (sport, _tournamentSportLabel(sport))),
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
            ),
          );
        }
        final isAdmin =
            _myMembership?.role == 'OWNER' ||
            _myMembership?.role == 'ADMIN' ||
            _myMembership?.role == 'MODERATOR';
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Tạo giải đấu",
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
                                "Quản lý giải",
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
                      'Không có giải phù hợp với bộ lọc',
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
                      child: const Text('Xóa bộ lọc'),
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
                        t.tournamentType == 'CLUB' ? 'Nội bộ CLB' : 'Mở rộng',
                        t.tournamentType == 'CLUB'
                            ? const Color(0xFFD97706)
                            : AppTheme.primary,
                      ),
                      _tournamentBadge(
                        t.isRanked ? 'Xếp hạng ELO' : 'Phong trào',
                        t.isRanked
                            ? const Color(0xFFB45309)
                            : colors.textSecondary,
                      ),
                      if (t.parentId != null)
                        _tournamentBadge('Chuỗi giải', const Color(0xFF2563EB)),
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
                        isQuick ? "Nhanh (Lite)" : l10n.club_advanced,
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

            // Option 2: Giải Nâng Cao (Full) - Direct to Web notice
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
            onPressed: () {
              context.push('/tournaments/create');
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(l10n.club_copyWebLink),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 3: THÀNH VIÊN
  // ════════════════════════════════════
  Widget _buildMembersTab(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(communityMembersProvider(widget.clubId));
    final isAdmin =
        _myMembership?.role == 'OWNER' || _myMembership?.role == 'ADMIN';
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
                ? () => context.push('/profile/user/${m.userId}')
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
                  ? () => context.push('/profile/user/${m.userId}')
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
                  // P2C.5 — pills tag BQT + streak cạnh tên thành viên (text pill, không emoji).
                  if (m.tags.isNotEmpty || !m.streak.isEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...m.tags.map(
                          (tag) => MemberTagChip(
                            label: tag,
                            kind: MemberTagChipKind.bqt,
                          ),
                        ),
                        if (!m.streak.isEmpty)
                          StreakChip(
                            type: m.streak.type,
                            count: m.streak.count,
                            label: m.streak.label,
                          ),
                      ],
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
                        AppConstants.memberTagMenu,
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
            content: Text('${l10n.errorPrefix}: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  /// P2C.5 — Mở bottom sheet gán tag BQT; lưu qua repository rồi đồng bộ member list.
  Future<void> _openTagAssignSheet(CommunityMemberModel m) async {
    final repo = ref.read(communityRepositoryProvider);
    await TagAssignSheet.show(
      context,
      memberName: m.userFullName ?? '',
      currentTags: m.tags,
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
                                    content: Text('${l10n.errorPrefix}: $e'),
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
                      content: Text('${l10n.errorPrefix}: $e'),
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
                      content: Text('${l10n.errorPrefix}: $e'),
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
    final l10n = AppLocalizations.of(context)!;
    final galleryAsync = ref.watch(communityGalleryProvider(widget.clubId));
    return galleryAsync.when(
      data: (images) {
        if (images.isEmpty && club.logoUrl == null && club.bannerUrl == null) {
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
              ],
            ),
          );
        }

        // Collect all club images: logo, banner, and gallery
        final List<Widget> imageWidgets = [];

        // Add club banner first
        if (club.bannerUrl != null && club.bannerUrl!.isNotEmpty) {
          imageWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _showImagePreview(club.bannerUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Image.network(
                      club.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Add club logo
        if (club.logoUrl != null && club.logoUrl!.isNotEmpty) {
          imageWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _showImagePreview(club.logoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.network(
                      club.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (images.isNotEmpty) {
          imageWidgets.add(
            GridView.builder(
              padding: const EdgeInsets.only(top: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: images.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _showImagePreview(images[i].imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    images[i].imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (images.isNotEmpty)
                    Text(
                      l10n.club_imageCount(images.length),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: imageWidgets,
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
        content: Text(
          l10n.club_deleteWarning(club.name),
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
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
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
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorPrefix}: $e'),
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
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3.0,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        isScrollable: true,
        tabs: [
          const Tab(text: 'Bảng tin'),
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
