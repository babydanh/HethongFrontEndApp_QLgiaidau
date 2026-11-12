import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/widgets/image_crop_dialog.dart';

import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/organized_tournaments_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/organized_tournaments_section.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/ranked_user_avatar_tap.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/profile/screens/achievements_tab.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/features/profile/utils/edit_profile_payload.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:dio/dio.dart';

/// Friend request calls against the real Backend routes
/// (`friendships.controller.ts`): PATCH `/social/friend-requests/:id` with
/// `{action}` to answer, DELETE `/social/friendships/:id` to cancel/remove.
/// Errors propagate so the caller can show them.
class FriendRequestActions {
  const FriendRequestActions(this._dio);

  final Dio _dio;

  Future<void> accept(String friendshipId) =>
      _respond(friendshipId, 'ACCEPTED');

  Future<void> reject(String friendshipId) =>
      _respond(friendshipId, 'REJECTED');

  Future<void> remove(String friendshipId) async {
    await _dio.delete('/social/friendships/$friendshipId');
  }

  Future<void> _respond(String friendshipId, String action) async {
    await _dio.patch(
      '/social/friend-requests/$friendshipId',
      data: {'action': action},
    );
  }
}

// ─── PROFILE SCREEN ──────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger('Profile');
  bool _uploading = false;
  bool _uploadingCover = false;
  late TabController _tabController;
  int _friendsSubTabIndex = 0; // 0: friends, 1: incoming, 2: sent
  final Set<String> _busyFriendships = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── IMAGE PICKER ────────────────────────────────────────────────────
  Future<void> _pickImage(bool isCover) async {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                isCover ? l10n.profileChangeCover : l10n.profileChangeAvatar,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(
                  l10n.profileTakePhoto,
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(
                  l10n.profileChooseFromGallery,
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'camera_access_denied'
          ? l10n.profileCameraPermissionDenied
          : e.code == 'photo_access_denied'
          ? l10n.profileGalleryPermissionDenied
          : l10n.profileImagePickerError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileImagePickerError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    final fileName = pickedFile.name;

    if (isCover) {
      setState(() => _uploadingCover = true);
      try {
        final repo = ref.read(userRepositoryProvider);
        await repo.uploadCover(bytes, fileName);
        ref.invalidate(userProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileCoverUpdated),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        _log.error('Lỗi tải ảnh bìa', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorParser.parse(e, '', l10n)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _uploadingCover = false);
      }
    } else {
      final croppedBytes = await ImageCropDialog.show(
        context,
        bytes: bytes,
        title: l10n.profileChangeAvatar,
      );
      if (croppedBytes == null || !mounted) return;
      setState(() => _uploading = true);
      try {
        final repo = ref.read(userRepositoryProvider);
        await repo.uploadAvatar(croppedBytes, 'profile_avatar.png');
        ref.invalidate(userProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileAvatarUpdated),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        _log.error('Lỗi tải ảnh đại diện', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorParser.parse(e, '', l10n)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() => _pickImage(false);
  Future<void> _pickAndUploadCover() => _pickImage(true);

  /// Nhãn giới tính để hiển thị; null khi rỗng hoặc không nhận diện được.
  String? _formatGender(BuildContext context, String? rawGender) {
    final l10n = AppLocalizations.of(context);
    return switch (normalizeGenderLabel(rawGender)) {
      genderLabelMale => l10n?.genderMale ?? 'Nam',
      genderLabelFemale => l10n?.genderFemale ?? 'Nữ',
      genderLabelOther => l10n?.genderOther ?? 'Khác',
      _ => null,
    };
  }

  // ─── FRIEND ACTIONS ──────────────────────────────────────────────────
  Future<void> _runFriendAction(
    String friendshipId,
    Future<void> Function(FriendRequestActions actions) op,
  ) async {
    if (_busyFriendships.contains(friendshipId)) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.lightImpact();
    setState(() => _busyFriendships.add(friendshipId));
    try {
      await op(FriendRequestActions(ref.read(dioProvider)));
      ref.invalidate(userFriendsProvider);
    } catch (e, stack) {
      _log.error('Lỗi thao tác kết bạn $friendshipId', e, stack);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorParser.parse(e, '', l10n)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyFriendships.remove(friendshipId));
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LavishColors.of(context).surface,
      body: profileAsync.when(
        data: (profile) => _buildNestedBody(context, profile),
        loading: () => const ProfileShimmerLoading(),
        error: (err, _) => SafeArea(
          child: LavishErrorState(
            message: l10n.profLvLoadError,
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) context.go('/home?tab=$index');
        },
        onMenuTap: () => AppMenuSheet.show(context),
      ),
    );
  }

  Widget _coverButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool busy = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: busy
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed();
            },
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
      ),
      icon: busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
    );
  }

  Widget _buildNestedBody(BuildContext context, UserProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final rankingsAsync = ref.watch(userRankingsProvider);
    final followedAsync = ref.watch(followedTournamentsProvider);
    final rankings = rankingsAsync.asData?.value ?? const <PlayerRanking>[];
    // Lỗi/đang tải khác "0 thật": hiện — thay vì số 0.
    final rankingsReady = rankingsAsync.hasValue;
    final followedCount = followedAsync.asData?.value.length;
    final statsFailed =
        (rankingsAsync.hasError && !rankingsAsync.hasValue) ||
        (followedAsync.hasError && !followedAsync.hasValue);

    final totalPlayed = rankings.fold<int>(0, (s, r) => s + r.matchesPlayed);
    final totalWon = rankings.fold<int>(0, (s, r) => s + r.matchesWon);
    final winRate = totalPlayed > 0
        ? (totalWon / totalPlayed * 100).round()
        : 0;
    final bestElo = rankings.isNotEmpty
        ? rankings.map((r) => r.eloPoints).reduce((a, b) => a > b ? a : b)
        : (profile.eloPoints ?? 0);

    final eligibleRankings =
        rankings
            .where((r) => r.isLeaderboardEligible && r.eloPoints > 0)
            .toList()
          ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));
    final bestRanking = eligibleRankings.isNotEmpty
        ? eligibleRankings.first
        : (rankings.isNotEmpty ? rankings.first : null);

    final isAdmin = profile.hasRole('ADMIN');
    final isOrganizer = profile.hasRole('ORGANIZER');
    final roleLabel = isAdmin
        ? l10n.profLvRoleAdmin
        : (isOrganizer ? l10n.profLvRoleOrganizer : l10n.profLvRoleAthlete);
    final roleTone = isAdmin
        ? LavishTone.warn
        : (isOrganizer ? LavishTone.accent : LavishTone.neutral);
    final metaParts = <String>[
      ?_formatGender(context, profile.gender),
      if (profile.address != null && profile.address!.isNotEmpty)
        profile.address!,
    ];

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          elevation: 0,
          backgroundColor: c.surface,
          leading: _coverButton(
            icon: Icons.arrow_back_rounded,
            tooltip: l10n.lavishBack,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          actions: [
            _coverButton(
              icon: Icons.camera_alt_outlined,
              tooltip: l10n.profileChangeCover,
              busy: _uploadingCover,
              onPressed: _pickAndUploadCover,
            ),
            _coverButton(
              icon: Icons.settings_outlined,
              tooltip: l10n.profLvSettings,
              onPressed: () => context.push('/profile/settings'),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (profile.coverUrl != null &&
                    profile.coverUrl!.trim().isNotEmpty)
                  Image.network(
                    profile.coverUrl!.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => _buildArtisticCover(),
                  )
                else
                  _buildArtisticCover(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        c.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ColoredBox(
            color: c.surface,
            child: Column(
              children: [
                Tooltip(
                  message: l10n.profileChangeAvatar,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickAndUploadAvatar();
                    },
                    child: _uploading
                        ? const SizedBox.square(
                            dimension: 96,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : RankAvatar(
                            imageUrl: profile.avatarUrl,
                            name:
                                (profile.fullName != null &&
                                    profile.fullName!.isNotEmpty)
                                ? profile.fullName!
                                : 'SportO',
                            elo: bestRanking?.eloPoints ?? 0,
                            tierName: bestRanking?.tierName,
                            matchesPlayed: bestRanking?.matchesPlayed ?? 0,
                            size: 96,
                            ringWidth: 3,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.fullName ?? l10n.profLvUser,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                      ),
                      if (profile.isEmailVerified == true) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: LavishColors.accent,
                        ),
                      ],
                    ],
                  ),
                ),
                if (profile.email != null)
                  Text(
                    '@${profile.email!.split('@').first}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: c.muted,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LavishPill(roleLabel, tone: roleTone),
                    for (final r in eligibleRankings.take(3))
                      RankTierBadge(
                        tierName: r.tierName,
                        elo: r.eloPoints,
                        sportName: r.categoryName,
                        showLabel: false,
                        tierSource: r.tierSource,
                        tierAvailable: r.tierAvailable,
                      ),
                  ],
                ),
                if (metaParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      metaParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: c.muted),
                    ),
                  ),
                if (profile.bio != null && profile.bio!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                    child: Text(
                      profile.bio!.trim(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: c.muted,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _retryOnTap(
                  enabled: statsFailed,
                  onTap: () {
                    if (!rankingsReady) ref.invalidate(userRankingsProvider);
                    if (followedCount == null) {
                      ref.invalidate(followedTournamentsProvider);
                    }
                  },
                  child: LavishStatGrid(
                    items: [
                      LavishStat(
                        label: l10n.profLvStatElo,
                        value: bestElo > 0
                            ? _formatNumberWithCommas(bestElo)
                            : '—',
                        tone: LavishTone.accent,
                      ),
                      LavishStat(
                        label: l10n.profLvStatMatches,
                        value: rankingsReady ? '$totalPlayed' : '—',
                      ),
                      LavishStat(
                        label: l10n.profLvStatWinRate,
                        value: rankingsReady ? '$winRate%' : '—',
                        tone: LavishTone.ok,
                      ),
                      LavishStat(
                        label: l10n.profLvStatTournaments,
                        value: followedCount == null ? '—' : '$followedCount',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            backgroundColor: c.surface,
            tabBar: TabBar(
              controller: _tabController,
              indicatorColor: LavishColors.accent,
              indicatorWeight: 3,
              labelColor: LavishColors.accent,
              unselectedLabelColor: c.muted,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              dividerColor: c.line,
              labelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
              tabs: [
                _tab(Icons.dynamic_feed_rounded, l10n.profLvTabActivity),
                _tab(Icons.emoji_events_rounded, l10n.profLvTabTournaments),
                _tab(Icons.people_alt_rounded, l10n.profLvTabFriends),
                _tab(Icons.military_tech_rounded, l10n.profLvTabAchievements),
              ],
            ),
          ),
        ),
      ],
      body: ColoredBox(
        color: c.surface,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActivityTab(context, profile),
            _buildTournamentsTab(context),
            _buildFriendsTab(context),
            _buildAchievementsTab(context, profile, eligibleRankings),
          ],
        ),
      ),
    );
  }

  /// Bọc [child] để chạm là thử lại khi [enabled] (thống kê đang lỗi).
  Widget _retryOnTap({
    required bool enabled,
    required VoidCallback onTap,
    required Widget child,
  }) => enabled ? InkWell(onTap: onTap, child: child) : child;

  Tab _tab(IconData icon, String label) => Tab(
    height: 56,
    icon: Icon(icon, size: 20),
    iconMargin: const EdgeInsets.only(bottom: 2),
    // Co chữ vừa tab (320dp, chữ lớn) thay vì cắt bằng ellipsis.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    ),
  );

  Widget _seeAll(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      foregroundColor: LavishColors.accent,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    child: Text(label),
  );

  EdgeInsets get _tabPadding => const EdgeInsets.only(bottom: 120);

  // ─── TAB 1: HOẠT ĐỘNG ────────────────────────────────────────────────
  Widget _buildActivityTab(BuildContext context, UserProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: _tabPadding,
      children: [
        LavishGroupHeader(
          l10n.profLvRecentMatches,
          trailing: _seeAll(
            l10n.profLvSeeAll,
            () => _tabController.animateTo(3),
          ),
        ),
        _matchesSection(context, profile.id, take: 4, withAction: true),
        LavishGroupHeader(
          l10n.profLvUpcoming,
          trailing: _seeAll(
            l10n.profLvSeeAll,
            () => _tabController.animateTo(1),
          ),
        ),
        _upcomingTournaments(context, take: 2),
      ],
    );
  }

  Widget _matchesSection(
    BuildContext context,
    String userId, {
    required int take,
    bool withAction = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(publicUserMatchesProvider(userId));
    return matchesAsync.when(
      loading: () => const LavishRowSkeleton(count: 3),
      error: (e, s) => LavishErrorState(
        message: l10n.profLvMatchesLoadError,
        onRetry: () => ref.invalidate(publicUserMatchesProvider(userId)),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return LavishEmptyState(
            icon: Icons.sports_tennis_outlined,
            title: l10n.profLvEmptyMatches,
            action: withAction ? l10n.profLvCreateSession : null,
            onAction: withAction
                ? () => context.push('/social/match-sessions/create')
                : null,
          );
        }
        return Column(
          children: [for (final m in matches.take(take)) _matchRow(m)],
        );
      },
    );
  }

  Widget _upcomingTournaments(BuildContext context, {required int take}) {
    final l10n = AppLocalizations.of(context)!;
    final followedAsync = ref.watch(followedTournamentsProvider);
    return followedAsync.when(
      loading: () => const LavishRowSkeleton(count: 2),
      error: (e, s) => LavishErrorState(
        onRetry: () => ref.invalidate(followedTournamentsProvider),
      ),
      data: (followed) {
        final active = followed
            .where((t) => !StatusHelper.isTournamentCompleted(t.status))
            .take(take)
            .toList();
        if (active.isEmpty) {
          return LavishEmptyState(
            icon: Icons.emoji_events_outlined,
            title: l10n.profLvEmptyTournaments,
            action: l10n.profLvExplore,
            onAction: () => context.go('/dashboard'),
          );
        }
        return Column(children: [for (final t in active) _tournamentRow(t)]);
      },
    );
  }

  // ─── TAB 2: GIẢI ĐẤU ─────────────────────────────────────────────────
  Widget _buildTournamentsTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final followedAsync = ref.watch(followedTournamentsProvider);
    return followedAsync.when(
      loading: () => ListView(
        padding: _tabPadding,
        children: const [LavishRowSkeleton(count: 5)],
      ),
      error: (e, s) => LavishErrorState(
        onRetry: () => ref.invalidate(followedTournamentsProvider),
      ),
      data: (followed) {
        final active =
            followed
                .where((t) => !StatusHelper.isTournamentCompleted(t.status))
                .toList()
              ..sort(
                (a, b) => (b.startDate ?? b.createdAt).compareTo(
                  a.startDate ?? a.createdAt,
                ),
              );
        final completed =
            followed
                .where((t) => StatusHelper.isTournamentCompleted(t.status))
                .toList()
              ..sort(
                (a, b) => (b.endDate ?? b.updatedAt).compareTo(
                  a.endDate ?? a.updatedAt,
                ),
              );
        final organizedAsync = ref.watch(organizedTournamentsProvider);
        final hasOrganized =
            organizedAsync.isLoading ||
            (organizedAsync.asData?.value.items.isNotEmpty ?? false);
        if (followed.isEmpty && !hasOrganized) {
          return LavishEmptyState(
            icon: Icons.emoji_events_outlined,
            title: l10n.profLvEmptyTournaments,
            action: l10n.profLvExplore,
            onAction: () => context.go('/dashboard'),
          );
        }
        return ListView(
          padding: _tabPadding,
          children: [
            OrganizedTournamentsSection(rowBuilder: _tournamentRow),
            if (active.isNotEmpty) LavishGroupHeader(l10n.profLvUpcoming),
            for (final t in active) _tournamentRow(t),
            if (completed.isNotEmpty) LavishGroupHeader(l10n.profLvCompleted),
            for (final t in completed.take(15)) _tournamentRow(t),
          ],
        );
      },
    );
  }

  // ─── TAB 3: BẠN BÈ ───────────────────────────────────────────────────
  Widget _buildFriendsTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friendsAsync = ref.watch(userFriendsProvider);
    return friendsAsync.when(
      loading: () => ListView(
        padding: _tabPadding,
        children: const [LavishRowSkeleton(count: 5)],
      ),
      error: (e, s) => LavishErrorState(
        message: l10n.profLvFriendsLoadError,
        onRetry: () => ref.invalidate(userFriendsProvider),
      ),
      data: (items) {
        final accepted = items.where((i) => i.status == 'ACCEPTED').toList();
        final incoming = items
            .where((i) => i.status == 'PENDING' && i.direction == 'INCOMING')
            .toList();
        final outgoing = items
            .where((i) => i.status == 'PENDING' && i.direction == 'OUTGOING')
            .toList();
        final labels = [
          l10n.profLvFriendsCount(accepted.length),
          l10n.profLvIncomingCount(incoming.length),
          l10n.profLvOutgoingCount(outgoing.length),
        ];
        final Widget body = switch (_friendsSubTabIndex) {
          0 =>
            accepted.isEmpty
                ? LavishEmptyState(
                    icon: Icons.people_alt_outlined,
                    title: l10n.profLvEmptyFriends,
                    action: l10n.profLvFindFriends,
                    onAction: () => context.push('/social'),
                  )
                : Column(children: [for (final f in accepted) _friendRow(f)]),
          1 =>
            incoming.isEmpty
                ? LavishEmptyState(
                    icon: Icons.mark_email_read_outlined,
                    title: l10n.profLvEmptyIncoming,
                  )
                : Column(children: [for (final f in incoming) _incomingRow(f)]),
          _ =>
            outgoing.isEmpty
                ? LavishEmptyState(
                    icon: Icons.outbox_rounded,
                    title: l10n.profLvEmptyOutgoing,
                  )
                : Column(children: [for (final f in outgoing) _outgoingRow(f)]),
        };
        return ListView(
          padding: _tabPadding,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    LavishChipButton(
                      label: labels[i],
                      selected: _friendsSubTabIndex == i,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _friendsSubTabIndex = i);
                      },
                    ),
                ],
              ),
            ),
            body,
          ],
        );
      },
    );
  }

  // FriendshipItem has no ELO, so the ring is looked up by friend id.
  Widget _friendAvatar(FriendshipItem item, String fallbackName) =>
      RankedUserAvatarTap(
        userId: item.friendId,
        name: item.friendName ?? fallbackName,
        imageUrl: item.friendAvatar,
        size: 40,
      );

  Widget _friendRow(FriendshipItem item) {
    final l10n = AppLocalizations.of(context)!;
    return LavishRow(
      leading: _friendAvatar(item, l10n.profLvAthlete),
      title: item.friendName ?? l10n.profLvAthlete,
      trailing: [
        IconButton(
          tooltip: l10n.profLvChat,
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 20,
            color: LavishColors.accent,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/chat/${item.friendId}');
          },
        ),
      ],
    );
  }

  Widget _incomingRow(FriendshipItem item) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _busyFriendships.contains(item.friendshipId);
    return LavishRow(
      leading: _friendAvatar(item, l10n.profLvUser),
      title: item.friendName ?? l10n.profLvUser,
      subtitle: l10n.profLvWantsToConnect,
      trailing: [
        LavishButton(
          label: l10n.profLvAccept,
          dense: true,
          busy: busy,
          onPressed: () => _runFriendAction(
            item.friendshipId,
            (a) => a.accept(item.friendshipId),
          ),
        ),
        LavishButton(
          label: l10n.profLvReject,
          dense: true,
          kind: LavishButtonKind.outline,
          onPressed: busy
              ? null
              : () => _runFriendAction(
                  item.friendshipId,
                  (a) => a.reject(item.friendshipId),
                ),
        ),
      ],
    );
  }

  Widget _outgoingRow(FriendshipItem item) {
    final l10n = AppLocalizations.of(context)!;
    return LavishRow(
      leading: _friendAvatar(item, l10n.profLvUser),
      title: item.friendName ?? l10n.profLvUser,
      subtitle: l10n.profLvPending,
      trailing: [
        LavishButton(
          label: l10n.profLvCancel,
          dense: true,
          kind: LavishButtonKind.outline,
          busy: _busyFriendships.contains(item.friendshipId),
          onPressed: () => _runFriendAction(
            item.friendshipId,
            (a) => a.remove(item.friendshipId),
          ),
        ),
      ],
    );
  }

  // ─── TAB 4: THÀNH TÍCH ───────────────────────────────────────────────
  Widget _buildAchievementsTab(
    BuildContext context,
    UserProfile profile,
    List<PlayerRanking> eligibleRanks,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: _tabPadding,
      children: [
        LavishGroupHeader(
          l10n.profLvRanks,
          trailing: _seeAll(
            l10n.profLvEloDetail,
            () => context.push('/profile/elo'),
          ),
        ),
        if (eligibleRanks.isEmpty)
          LavishEmptyState(
            icon: Icons.sports_tennis_outlined,
            title: l10n.profLvEmptyRanks,
            action: l10n.profLvJoinTournament,
            onAction: () => context.go('/dashboard'),
          )
        else
          for (final r in eligibleRanks.take(3)) _rankRow(r),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: AchievementsTab(),
        ),
        LavishGroupHeader(l10n.profLvHistory),
        _matchesSection(context, profile.id, take: 8),
      ],
    );
  }

  // ─── ROWS ────────────────────────────────────────────────────────────
  Widget _rankRow(PlayerRanking rank) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final winRate = rank.matchesPlayed > 0
        ? (rank.matchesWon / rank.matchesPlayed * 100).round()
        : 0;
    return LavishRow(
      leading: const LavishIconBox(child: Icon(Icons.sports_tennis_rounded)),
      title: rank.categoryName ?? l10n.profLvSport,
      subtitle: l10n.profLvMatchesWinRate(rank.matchesPlayed, winRate),
      trailing: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatNumberWithCommas(rank.eloPoints),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LavishColors.accent,
              ),
            ),
            Text(
              rank.tierName.isEmpty ? 'ELO' : rank.tierName,
              style: TextStyle(fontSize: 10.5, color: c.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _matchRow(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    final done =
        match.status.toLowerCase() == 'completed' || match.completedAt != null;
    return LavishRow(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(
          NavigationHelper.getLiveMatchRoute(
            match.tournamentId ?? '',
            match.id,
          ),
        );
      },
      leading: LavishIconBox(
        tone: done ? LavishTone.ok : LavishTone.accent,
        child: Icon(
          done ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
        ),
      ),
      title: '${matchSideLabel(match, 1)} vs ${matchSideLabel(match, 2)}',
      subtitle:
          match.tournamentName ??
          (done ? l10n.profLvMatchDone : l10n.profLvMatchUpcoming),
      subtitleMaxLines: 1,
      trailing: [
        LavishPill(
          '${match.score1} - ${match.score2}',
          tone: LavishTone.neutral,
        ),
      ],
    );
  }

  Widget _tournamentRow(Tournament t) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final done = StatusHelper.isTournamentCompleted(t.status);
    final tone = done
        ? LavishTone.ok
        : (StatusHelper.isTournamentInProgress(t.status)
              ? LavishTone.accent
              : LavishTone.neutral);
    final date = t.endDate ?? t.startDate;
    return LavishRow(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/intro/${t.id}');
      },
      leading: _tournamentLogo(t.logoUrl, t.bannerUrl, c),
      title: t.name.isNotEmpty ? t.name : '—',
      subtitle: date != null ? '${date.day}/${date.month}/${date.year}' : null,
      trailing: [
        LavishPill(
          done
              ? l10n.profLvCompleted
              : StatusHelper.getTournamentStatusLabel(t.status),
          tone: tone,
        ),
      ],
    );
  }

  Widget _tournamentLogo(String? logoUrl, String? bannerUrl, LavishColors c) {
    final url = (logoUrl != null && logoUrl.isNotEmpty)
        ? logoUrl
        : ((bannerUrl != null && bannerUrl.isNotEmpty) ? bannerUrl : null);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: LavishColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => _defaultLogo(),
            )
          : _defaultLogo(),
    );
  }

  Widget _defaultLogo() => Padding(
    padding: const EdgeInsets.all(5),
    child: Image.asset(
      'assets/images/sporto_v1_with_text.png',
      fit: BoxFit.contain,
    ),
  );

  Widget _buildArtisticCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.4,
          child: SvgPicture.asset(
            'assets/images/sporto.svg',
            width: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  String _formatNumberWithCommas(int n) {
    final s = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  // ─── LOGIN PROMPT ─────────────────────────────────────────────────────
  Widget _buildLoginPrompt(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          l10n.profileTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: colors.textMuted,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.profileLoginGreeting,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.profileLoginDescription,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.go('/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
                child: Text(l10n.profileLoginButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  '${l10n.noAccount} ${l10n.registerNow}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) context.go('/home?tab=$index');
        },
        onMenuTap: () => AppMenuSheet.show(context),
      ),
    );
  }
}

// ─── SHIMMER ─────────────────────────────────────────────────────────────────
class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.border,
      highlightColor: colors.bgSurface,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 220, color: colors.border),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DATA CLASSES ────────────────────────────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  const _SliverTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
