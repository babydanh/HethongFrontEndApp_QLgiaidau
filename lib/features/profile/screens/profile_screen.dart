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

import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
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
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/profile/screens/achievements_tab.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';

// ─── PROFILE SCREEN ──────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _uploading = false;
  bool _uploadingCover = false;
  late TabController _tabController;
  int _friendsSubTabIndex = 0; // 0: Bạn bè, 1: Lời mời, 2: Đã gửi

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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.commonErrorPrefix}: ${e.toString().replaceAll("Exception: ", "")}',
              ),
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
      if (croppedBytes == null) return;
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.commonErrorPrefix}: ${e.toString().replaceAll("Exception: ", "")}',
              ),
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

  String _formatGender(BuildContext context, String? rawGender) {
    if (rawGender == null || rawGender.trim().isEmpty) return '—';
    final l10n = AppLocalizations.of(context);
    final g = rawGender.trim().toUpperCase();
    if (g == 'MALE' || g == 'NAM' || g == 'MEN' || g == 'M') {
      return l10n?.genderMale ?? 'Nam';
    }
    if (g == 'FEMALE' || g == 'NU' || g == 'NỮ' || g == 'WOMEN' || g == 'F') {
      return l10n?.genderFemale ?? 'Nữ';
    }
    if (g == 'OTHER' || g == 'KHAC' || g == 'KHÁC') {
      return l10n?.genderOther ?? 'Khác';
    }
    return 'Nam';
  }

  // ─── BUILD ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: profileAsync.when(
        data: (profile) => _buildNestedBody(context, profile),
        loading: () => const ProfileShimmerLoading(),
        error: (err, _) => _buildError(
          context,
          ErrorParser.parse(err, 'Không thể tải thông tin hồ sơ.'),
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

  Widget _buildNestedBody(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final rankings =
        ref.watch(userRankingsProvider).asData?.value ??
        const <PlayerRanking>[];

    // Compute stats from rankings
    final totalPlayed = rankings.fold<int>(0, (s, r) => s + r.matchesPlayed);
    final totalWon = rankings.fold<int>(0, (s, r) => s + r.matchesWon);
    final totalLost = totalPlayed - totalWon;
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

    // Compute distinct sport ranks (one best rank per sport category)
    final seenCategories = <String>{};
    final distinctSportRanks = <PlayerRanking>[];
    for (final r in eligibleRankings) {
      final cat = (r.categoryName ?? '').trim().toLowerCase();
      if (cat.isNotEmpty && !seenCategories.contains(cat)) {
        seenCategories.add(cat);
        distinctSportRanks.add(r);
      }
    }
    if (distinctSportRanks.isEmpty && rankings.isNotEmpty) {
      for (final r in rankings) {
        final cat = (r.categoryName ?? '').trim().toLowerCase();
        if (cat.isNotEmpty && !seenCategories.contains(cat)) {
          seenCategories.add(cat);
          distinctSportRanks.add(r);
        }
      }
    }

    const expandedCoverHeight = 220.0;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // ── PINNED SLIVER APP BAR (Cover image + Persistent Controls + TabBar) ──
        SliverAppBar(
          expandedHeight: expandedCoverHeight,
          pinned: true,
          elevation: 0,
          backgroundColor: colors.bgDark,
          leading: Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _pickAndUploadCover();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: _uploadingCover
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/profile/settings');
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (profile.coverUrl != null &&
                    profile.coverUrl!.trim().isNotEmpty)
                  Image.network(
                    profile.coverUrl!.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => _buildArtisticCover(colors),
                  )
                else
                  _buildArtisticCover(colors),
                // Premium gradient vignette
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        colors.bgDark.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── USER PROFILE HEADER (Avatar, Name, Handle, Location, Stats) ──
        SliverToBoxAdapter(
          child: Container(
            color: colors.bgDark,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: [
                // Prominent unclipped Avatar with camera update badge
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickAndUploadAvatar();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.bgDark,
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: RankAvatar(
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
                        // Camera badge
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.bgCard,
                              border: Border.all(
                                color: colors.borderLight,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _uploading
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.textPrimary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt_rounded,
                                      size: 15,
                                      color: colors.textPrimary,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Name, verified badge, and tier badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              profile.fullName ?? 'Người dùng',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isEmailVerified == true) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 20,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ],
                      ),
                      if (distinctSportRanks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: distinctSportRanks.map((r) {
                            return RankTierBadge(
                              tierName: r.tierName,
                              elo: r.eloPoints,
                              sportName: r.categoryName,
                              showLabel: false,
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 5),

                      // Handle / Username (@username)
                      if (profile.email != null)
                        Text(
                          '@${profile.email!.split('@').first}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),

                      // Role tag + Gender
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(
                            builder: (context) {
                              final roleUpper = (profile.role ?? '')
                                  .toUpperCase();
                              final isAdmin = roleUpper == 'ADMIN';
                              final isOrganizer = roleUpper == 'ORGANIZER';
                              final roleTitle = isAdmin
                                  ? 'Quản trị viên'
                                  : (isOrganizer
                                        ? 'Ban tổ chức'
                                        : 'Vận động viên');

                              if (isAdmin) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFB45309),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFD97706,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    roleTitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  roleTitle,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),

                          if (profile.gender != null &&
                              profile.gender!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.border.withValues(alpha: 0.7),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _formatGender(context, profile.gender) ==
                                            (AppLocalizations.of(
                                                  context,
                                                )?.genderFemale ??
                                                'Nữ')
                                        ? Icons.female_rounded
                                        : Icons.male_rounded,
                                    size: 14,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatGender(context, profile.gender),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (profile.address != null &&
                              profile.address!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colors.border.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: colors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    profile.address!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Bio text if available
                      if (profile.bio != null &&
                          profile.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            profile.bio!.trim(),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── PINNED TABBAR BELOW AVATAR (4 ICONS MATCHING WEB) ──
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            tabBar: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.primary,
              unselectedLabelColor: colors.textMuted,
              tabs: const [
                Tab(icon: Icon(Icons.dynamic_feed_rounded, size: 23)),
                Tab(icon: Icon(Icons.emoji_events_rounded, size: 23)),
                Tab(icon: Icon(Icons.people_alt_rounded, size: 23)),
                Tab(icon: Icon(Icons.military_tech_rounded, size: 23)),
              ],
            ),
            backgroundColor: colors.bgDark,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(context, profile, colors),
          _buildTournamentsTab(context, profile, colors),
          _buildFriendsTab(context, colors),
          _buildAchievementsAndStatsTab(
            context,
            profile,
            colors,
            rankings: rankings,
            bestRanking: bestRanking,
            totalPlayed: totalPlayed,
            totalWon: totalWon,
            totalLost: totalLost < 0 ? 0 : totalLost,
            bestElo: bestElo,
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: HOẠT ĐỘNG (ACTIVITY FEED & MATCH SESSIONS ALIGNED WITH WEB) ──
  Widget _buildActivityTab(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors,
  ) {
    final matchesAsync = ref.watch(publicUserMatchesProvider(profile.id));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── RECENT MATCH ACTIVITY ──
          Row(
            children: [
              _sectionLabel(colors, 'Hoạt động trận đấu gần nhất'),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Switch to Achievements/Stats tab
                  _tabController.animateTo(3);
                },
                child: const Text(
                  'Xem tất cả →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          matchesAsync.when(
            loading: () => _loadingPlaceholder(colors),
            error: (err, stack) => _emptyPreviewCard(
              colors,
              Icons.sports_tennis_outlined,
              'Chưa có dữ liệu trận đấu',
            ),
            data: (matches) {
              if (matches.isEmpty) {
                return _emptyPreviewCard(
                  colors,
                  Icons.sports_tennis_outlined,
                  'Chưa có hoạt động giao lưu hoặc thi đấu nào',
                  onTap: () => context.push('/social/match-sessions/create'),
                  actionLabel: 'Tạo kèo giao lưu ngay',
                );
              }
              return Column(
                children: matches
                    .take(4)
                    .map((m) => _buildMatchHistoryCard(m, colors, context))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── UPCOMING TOURNAMENT PREVIEW ──
          Row(
            children: [
              _sectionLabel(colors, 'Giải đấu sắp tới'),
              const Spacer(),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: const Text(
                  'Chi tiết →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildUpcomingTournamentPreview(context, colors),
        ],
      ),
    );
  }

  // ─── TAB 4: THÀNH TÍCH & THỐNG KÊ (ALIGNED WITH WEB) ───────────────────
  Widget _buildAchievementsAndStatsTab(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors, {
    required List<PlayerRanking> rankings,
    required PlayerRanking? bestRanking,
    required int totalPlayed,
    required int totalWon,
    required int totalLost,
    required int bestElo,
  }) {
    final eligibleRanks = rankings
        .where((r) => r.isLeaderboardEligible && r.eloPoints > 0)
        .toList();
    final matchesAsync = ref.watch(publicUserMatchesProvider(profile.id));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── STATS ROW (Matches played, won, lost, ELO) ──
          _buildStatsRow(
            context,
            colors,
            totalPlayed,
            totalWon,
            totalLost < 0 ? 0 : totalLost,
            bestElo,
          ),
          const SizedBox(height: 22),

          // ── SPORT RANKINGS (Từng môn thể thao) ──
          Row(
            children: [
              _sectionLabel(colors, 'Xếp hạng & Trình độ môn thi đấu'),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/profile/elo'),
                child: const Text(
                  'Chi tiết ELO →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (eligibleRanks.isEmpty)
            _emptyPreviewCard(
              colors,
              Icons.sports_tennis_outlined,
              'Chưa có dữ liệu xếp hạng môn thi đấu',
              onTap: () => context.go('/dashboard'),
              actionLabel: 'Tham gia giải đấu',
            )
          else
            ...eligibleRanks.take(3).map((r) => _buildRankCard(r, colors)),

          const SizedBox(height: 22),

          // ── ACHIEVEMENTS (Danh hiệu, huy chương) ──
          const AchievementsTab(),

          const SizedBox(height: 22),

          // ── MATCH HISTORY (Lịch sử trận đấu) ──
          _sectionLabel(colors, 'Lịch sử đối đầu & kết quả'),
          const SizedBox(height: 10),
          matchesAsync.when(
            loading: () => _loadingPlaceholder(colors),
            error: (err, stack) => _emptyPreviewCard(
              colors,
              Icons.sports_tennis_outlined,
              'Chưa có dữ liệu trận đấu',
            ),
            data: (matches) {
              if (matches.isEmpty) {
                return _emptyPreviewCard(
                  colors,
                  Icons.sports_tennis_outlined,
                  'Chưa có trận đấu nào được ghi nhận',
                );
              }
              return Column(
                children: matches
                    .take(8)
                    .map((m) => _buildMatchHistoryCard(m, colors, context))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTournamentPreview(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    final followedAsync = ref.watch(followedTournamentsProvider);
    return followedAsync.when(
      loading: () => _loadingPlaceholder(colors),
      error: (e, s) => const SizedBox.shrink(),
      data: (followed) {
        final active = followed
            .where((t) => !StatusHelper.isTournamentCompleted(t.status))
            .take(2)
            .toList();
        if (active.isEmpty) {
          return _emptyPreviewCard(
            colors,
            Icons.emoji_events_outlined,
            'Không có lịch thi đấu giải nào sắp diễn ra',
            onTap: () => context.go('/dashboard'),
            actionLabel: 'Khám phá giải đấu ngay',
          );
        }
        return Column(
          children: active
              .map((t) => _buildHistoryCard(t, colors, context))
              .toList(),
        );
      },
    );
  }

  // ─── TAB 2: GIẢI ĐẤU (ALIGNED WITH WEB) ─────────────────────────────────
  Widget _buildTournamentsTab(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors,
  ) {
    final followedAsync = ref.watch(followedTournamentsProvider);
    final followed = followedAsync.asData?.value ?? [];

    final activeTournaments =
        followed
            .where((t) => !StatusHelper.isTournamentCompleted(t.status))
            .toList()
          ..sort(
            (a, b) => (b.startDate ?? b.createdAt).compareTo(
              a.startDate ?? a.createdAt,
            ),
          );

    final completedTournaments =
        followed
            .where((t) => StatusHelper.isTournamentCompleted(t.status))
            .toList()
          ..sort(
            (a, b) =>
                (b.endDate ?? b.updatedAt).compareTo(a.endDate ?? a.updatedAt),
          );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(colors, 'Giải đấu đang diễn ra & sắp tới'),
          const SizedBox(height: 10),
          followedAsync.isLoading
              ? _loadingPlaceholder(colors)
              : activeTournaments.isEmpty
              ? _emptyPreviewCard(
                  colors,
                  Icons.sports_tennis_outlined,
                  'Bạn chưa tham gia hoặc theo dõi giải đấu nào sắp diễn ra',
                  onTap: () => context.go('/dashboard'),
                  actionLabel: 'Khám phá giải đấu',
                )
              : Column(
                  children: activeTournaments
                      .map((t) => _buildHistoryCard(t, colors, context))
                      .toList(),
                ),
          const SizedBox(height: 24),
          _sectionLabel(colors, 'Giải đấu đã hoàn thành'),
          const SizedBox(height: 10),
          completedTournaments.isEmpty
              ? _emptyPreviewCard(
                  colors,
                  Icons.emoji_events_outlined,
                  'Chưa có giải đấu hoàn thành nào',
                )
              : Column(
                  children: completedTournaments
                      .take(15)
                      .map(
                        (t) =>
                            _buildCompletedTournamentCard(t, colors, context),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildArtisticCover(AppColorsExtension colors) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Elegant decorative ambient glow
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF60A5FA).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // SportO Official SVG Brandmark
          Center(
            child: Opacity(
              opacity: 0.45,
              child: SvgPicture.asset(
                'assets/images/sporto.svg',
                width: 170,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── USER INFO HEADER (CENTERED AS SHOWN IN DESIGN MOCKUP) ─────────
  Widget _buildStatsRow(
    BuildContext context,
    AppColorsExtension colors,
    int played,
    int won,
    int lost,
    int elo,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(
            context,
            colors,
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            value: played.toString(),
            label: 'Trận đã đấu',
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile/elo');
            },
          ),
          _statDivider(colors),
          _statItem(
            context,
            colors,
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
            value: won.toString(),
            label: 'Thắng',
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile/elo');
            },
          ),
          _statDivider(colors),
          _statItem(
            context,
            colors,
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFFF97316),
            iconBg: const Color(0xFFF97316).withValues(alpha: 0.12),
            value: lost.toString(),
            label: 'Thua',
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile/elo');
            },
          ),
          _statDivider(colors),
          _statItem(
            context,
            colors,
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            value: elo > 0 ? _formatNumberWithCommas(elo) : '—',
            label: 'Điểm xếp hạng',
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile/elo');
            },
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context,
    AppColorsExtension colors, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statDivider(AppColorsExtension colors) =>
      Container(width: 1, height: 34, color: colors.borderLight);

  Widget _buildRankCard(PlayerRanking rank, AppColorsExtension colors) {
    final winRate = rank.matchesPlayed > 0
        ? (rank.matchesWon / rank.matchesPlayed * 100).toStringAsFixed(0)
        : '0';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_tennis_rounded,
            size: 22,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.categoryName ?? 'Môn thể thao',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rank.matchesPlayed} trận  •  $winRate% thắng',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumberWithCommas(rank.eloPoints),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                rank.tierName.isEmpty ? 'ELO' : rank.tierName,
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTournamentCard(
    Tournament t,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    final endDate = t.endDate;
    final dateStr = endDate != null
        ? '${endDate.day}/${endDate.month}/${endDate.year}'
        : '';
    return GestureDetector(
      onTap: () => context.push('/intro/${t.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            _tournamentLogo(t.logoUrl, t.bannerUrl, colors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name.isNotEmpty ? t.name : '—',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hoàn thành',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHistoryCard(
    MatchModel match,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    final isCompleted =
        match.status.toLowerCase() == 'completed' || match.completedAt != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.schedule_rounded,
            size: 20,
            color: isCompleted ? const Color(0xFF10B981) : AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.team1Name} vs ${match.team2Name}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  match.tournamentName ??
                      (isCompleted ? 'Trận đấu hoàn thành' : 'Sắp diễn ra'),
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderLight),
            ),
            child: Text(
              '${match.score1} - ${match.score2}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    Tournament t,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    final statusLabel = StatusHelper.getTournamentStatusLabel(t.status);
    final isCompleted = StatusHelper.isTournamentCompleted(t.status);
    final statusColor = isCompleted
        ? const Color(0xFF10B981)
        : StatusHelper.isTournamentInProgress(t.status)
        ? AppTheme.primary
        : colors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/intro/${t.id}');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _tournamentLogo(t.logoUrl, t.bannerUrl, colors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name.isNotEmpty ? t.name : '—',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
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
      ),
    );
  }

  // ─── TAB 3: BẠN BÈ (ALIGNED WITH WEB ProfileFriendsTab) ─────────────
  Widget _buildFriendsTab(BuildContext context, AppColorsExtension colors) {
    final friendsAsync = ref.watch(userFriendsProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-tabs segment (Bạn bè, Lời mời, Đã gửi)
          friendsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (items) {
              final accepted = items
                  .where((i) => i.status == 'ACCEPTED')
                  .length;
              final incoming = items
                  .where(
                    (i) => i.status == 'PENDING' && i.direction == 'INCOMING',
                  )
                  .length;
              final outgoing = items
                  .where(
                    (i) => i.status == 'PENDING' && i.direction == 'OUTGOING',
                  )
                  .length;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    _subTabItem(
                      label: 'Bạn bè ($accepted)',
                      index: 0,
                      colors: colors,
                    ),
                    _subTabItem(
                      label: 'Lời mời ($incoming)',
                      index: 1,
                      colors: colors,
                    ),
                    _subTabItem(
                      label: 'Đã gửi ($outgoing)',
                      index: 2,
                      colors: colors,
                    ),
                  ],
                ),
              );
            },
          ),

          friendsAsync.when(
            loading: () => _loadingPlaceholder(colors),
            error: (err, stack) => _emptyPreviewCard(
              colors,
              Icons.people_outline_rounded,
              'Không thể tải danh sách bạn bè',
              onTap: () => ref.invalidate(userFriendsProvider),
              actionLabel: 'Thử lại',
            ),
            data: (items) {
              final acceptedFriends = items
                  .where((item) => item.status == 'ACCEPTED')
                  .toList();
              final incomingRequests = items
                  .where(
                    (item) =>
                        item.status == 'PENDING' &&
                        item.direction == 'INCOMING',
                  )
                  .toList();
              final outgoingRequests = items
                  .where(
                    (item) =>
                        item.status == 'PENDING' &&
                        item.direction == 'OUTGOING',
                  )
                  .toList();

              if (_friendsSubTabIndex == 0) {
                // Tab: Bạn bè
                if (acceptedFriends.isEmpty) {
                  return _emptyPreviewCard(
                    colors,
                    Icons.people_alt_outlined,
                    'Chưa có bạn bè nào trong danh sách',
                    onTap: () => context.push('/social'),
                    actionLabel: 'Kết nối qua Kèo giao lưu',
                  );
                }
                return Column(
                  children: acceptedFriends
                      .map(
                        (friend) => _buildFriendCard(friend, colors, context),
                      )
                      .toList(),
                );
              } else if (_friendsSubTabIndex == 1) {
                // Tab: Lời mời kết bạn
                if (incomingRequests.isEmpty) {
                  return _emptyPreviewCard(
                    colors,
                    Icons.mark_email_read_outlined,
                    'Không có lời mời kết bạn nào đang chờ duyệt',
                  );
                }
                return Column(
                  children: incomingRequests
                      .map((req) => _buildIncomingRequestCard(req, colors))
                      .toList(),
                );
              } else {
                // Tab: Lời mời đã gửi
                if (outgoingRequests.isEmpty) {
                  return _emptyPreviewCard(
                    colors,
                    Icons.outbox_rounded,
                    'Không có yêu cầu kết bạn nào đã gửi',
                  );
                }
                return Column(
                  children: outgoingRequests
                      .map((req) => _buildOutgoingRequestCard(req, colors))
                      .toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _subTabItem({
    required String label,
    required int index,
    required AppColorsExtension colors,
  }) {
    final isSelected = _friendsSubTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _friendsSubTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(
    FriendshipItem item,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          UserAvatarTap(
            userId: item.friendId,
            name: item.friendName ?? 'Vận động viên',
            imageUrl: item.friendAvatar,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendName ?? 'Vận động viên',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Bạn bè SportO',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            color: AppTheme.primary,
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/chat/${item.friendId}');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestCard(
    FriendshipItem item,
    AppColorsExtension colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          UserAvatarTap(
            userId: item.friendId,
            name: item.friendName ?? 'Người dùng',
            imageUrl: item.friendAvatar,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendName ?? 'Người dùng',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Muốn kết nối với bạn',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post(
                      '/social/friends/${item.friendshipId}/respond',
                      data: {'status': 'ACCEPTED'},
                    );
                    ref.invalidate(userFriendsProvider);
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Đồng ý',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.delete('/social/friends/${item.friendshipId}');
                    ref.invalidate(userFriendsProvider);
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Text(
                    'Từ chối',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingRequestCard(
    FriendshipItem item,
    AppColorsExtension colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          UserAvatarTap(
            userId: item.friendId,
            name: item.friendName ?? 'Người dùng',
            imageUrl: item.friendAvatar,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendName ?? 'Người dùng',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Đang chờ phản hồi...',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              try {
                final dio = ref.read(dioProvider);
                await dio.delete('/social/friends/${item.friendshipId}');
                ref.invalidate(userFriendsProvider);
              } catch (_) {}
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderLight),
              ),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS & COMMON WIDGETS ──────────────────────────────────────
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

  Widget _tournamentLogo(
    String? logoUrl,
    String? bannerUrl,
    AppColorsExtension colors,
  ) {
    final url = (logoUrl != null && logoUrl.isNotEmpty)
        ? logoUrl
        : ((bannerUrl != null && bannerUrl.isNotEmpty) ? bannerUrl : null);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
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
    padding: const EdgeInsets.all(7),
    child: Image.asset(
      'assets/images/sporto_v1_with_text.png',
      fit: BoxFit.contain,
    ),
  );

  Widget _emptyPreviewCard(
    AppColorsExtension colors,
    IconData icon,
    String message, {
    VoidCallback? onTap,
    String? actionLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: colors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (onTap != null && actionLabel != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onTap,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _loadingPlaceholder(AppColorsExtension colors) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primary,
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

  // ─── ERROR ────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, String message) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.profileLoadErrorTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => ref.invalidate(userProfileProvider),
              child: Text(AppLocalizations.of(context)!.infoRetry),
            ),
          ],
        ),
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
