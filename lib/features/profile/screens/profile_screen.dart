import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/image_crop_dialog.dart';

import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _packageInfoFuture = PackageInfo.fromPlatform();
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

  // ─── NESTED SCROLL BODY ──────────────────────────────────────────────
  Widget _buildNestedBody(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
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

    final eligibleRankings = rankings
        .where((r) => r.isLeaderboardEligible && r.eloPoints > 0)
        .toList()
      ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

    final bestRanking = eligibleRankings.isNotEmpty
        ? eligibleRankings.first
        : (rankings.isNotEmpty ? rankings.first : null);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          elevation: 0,
          backgroundColor: colors.bgDark,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.bgCard.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              tooltip: 'Đổi ảnh bìa',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: _uploadingCover
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_rounded,
                        color: colors.textPrimary,
                        size: 18,
                      ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _pickAndUploadCover();
              },
            ),
            IconButton(
              tooltip: l10n.profileTabSettings,
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: colors.textPrimary,
                  size: 18,
                ),
              ),
              onPressed: () => context.go('/profile/settings'),
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildCoverSection(context, profile, colors),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: colors.bgDark,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppTheme.primary,
                unselectedLabelColor: colors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Thành tích'),
                  Tab(text: 'Lịch sử'),
                  Tab(text: 'Ảnh'),
                ],
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(
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
          _buildAchievementsTab(context, colors),
          _buildHistoryTab(context, profile, colors),
          _buildPhotosTab(context, profile, colors),
        ],
      ),
    );
  }

  // ─── COVER SECTION ───────────────────────────────────────────────────
  Widget _buildCoverSection(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors,
  ) {
    final hasCover = profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _pickAndUploadCover,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: hasCover
                  ? null
                  : const LinearGradient(
                      colors: [
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                        Color(0xFF0F3460),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: hasCover
                ? Image.network(
                    profile.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => _coverGradient(),
                  )
                : _coverGradient(),
          ),
          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colors.bgDark.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverGradient() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  // ─── USER INFO HEADER ────────────────────────────────────────────────
  Widget _buildUserInfoHeader(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors,
    List<PlayerRanking> rankings,
    PlayerRanking? bestRanking,
  ) {
    final isVerified = profile.isEmailVerified == true;
    final roleText = _formatUserRole(profile.role);
    final topBadges = _selectProfileBadges(rankings);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + Camera upload button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _pickAndUploadAvatar();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RankAvatar(
                imageUrl: profile.avatarUrl,
                name: profile.fullName ?? '',
                elo: bestRanking?.eloPoints ?? 0,
                tierName: bestRanking?.tierName,
                matchesPlayed: bestRanking?.matchesPlayed ?? 0,
                size: 78,
                ringWidth: 3,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                    border: Border.all(
                      color: colors.bgDark,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _uploading
                      ? const Padding(
                          padding: EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Right details: Name + Edit button / Role + Tier badges / Handle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line 1: Name + Verified icon + Edit button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            profile.fullName ?? 'Người dùng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút "Chỉnh sửa" gọn đẹp chuẩn phong cách capsule
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/profile/edit');
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 12,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Chỉnh sửa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Line 2: Role chip + Cấp độ (Rank tier badges) ngay cạnh role
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        roleText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (topBadges.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      ...topBadges.take(2).map(
                        (ranking) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: RankTierBadge(
                            tierName: ranking.tierName,
                            elo: ranking.eloPoints,
                            sportName: ranking.categoryName,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Line 3: Handle / Email + Location
              Row(
                children: [
                  if (profile.email != null) ...[
                    Icon(Icons.alternate_email_rounded, size: 12, color: colors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        profile.email!.split('@').first,
                        style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (profile.address != null && profile.address!.isNotEmpty) ...[
                    Icon(Icons.location_on_rounded, size: 12, color: colors.textMuted),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        profile.address!,
                        style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatUserRole(String? role) {
    if (role == null || role.trim().isEmpty) return 'Vận động viên';
    final r = role.trim().toUpperCase();
    switch (r) {
      case 'ADMIN':
      case 'SUPER_ADMIN':
        return 'Quản trị viên';
      case 'ORGANIZER':
        return 'Ban tổ chức';
      case 'REFEREE':
        return 'Trọng tài';
      case 'LEADER':
      case 'CAPTAIN':
        return 'Đội trưởng';
      case 'COACH':
        return 'Huấn luyện viên';
      case 'MEMBER':
      case 'USER':
      case 'PLAYER':
      case 'ATHLETE':
      default:
        return 'Vận động viên';
    }
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────
  Widget _buildStatsRow(
    BuildContext context,
    AppColorsExtension colors,
    int played,
    int won,
    int lost,
    int elo,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _statItem(
            context,
            colors,
            played.toString(),
            'Trận đấu',
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(2); // Tab Lịch sử
            },
          ),
          _statDivider(colors),
          _statItem(
            context,
            colors,
            won.toString(),
            'Thắng',
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(1); // Tab Thành tích
            },
          ),
          _statDivider(colors),
          _statItem(
            context,
            colors,
            lost.toString(),
            'Thua',
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(2); // Tab Lịch sử
            },
          ),
          _statDivider(colors),
          _statItem(
            context,
            colors,
            elo > 0 ? _formatNum(elo) : '—',
            'Điểm ELO',
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(1); // Tab Thành tích
            },
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context,
    AppColorsExtension colors,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statDivider(AppColorsExtension colors) => Container(
    width: 1,
    height: 28,
    color: colors.borderLight,
  );

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  // ─── TAB 1: TỔNG QUAN ────────────────────────────────────────────────
  Widget _buildOverviewTab(
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
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Tên + Role + Cấp độ + Nút Chỉnh sửa
          _buildUserInfoHeader(context, profile, colors, rankings, bestRanking),
          const SizedBox(height: 16),

          // 4-item Stats row
          _buildStatsRow(
            context,
            colors,
            totalPlayed,
            totalWon,
            totalLost,
            bestElo,
          ),
          const SizedBox(height: 20),

          // Giới thiệu
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            _sectionLabel(colors, 'Giới thiệu'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                profile.bio!,
                style: TextStyle(
                  fontSize: 13.5,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Giải đấu gần đây (preview 3 item → xem tất cả ở Dashboard)
          _buildRecentTournamentsPreview(context, colors, l10n),
          const SizedBox(height: 24),

          // CLB preview
          _buildRecentClubsPreview(context, colors, l10n),
          const SizedBox(height: 16),

          // Version
          FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (context, snapshot) {
              final info = snapshot.data;
              if (info == null) return const SizedBox.shrink();
              final build =
                  info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'Phiên bản ${info.version}$build',
                    style:
                        TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }



  // ─── PREVIEW: Giải đấu gần đây ───────────────────────────────────────
  Widget _buildRecentTournamentsPreview(
    BuildContext context,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(colors, 'Giải đấu gần đây'),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Text(
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
        workspaceAsync.when(
          data: (workspace) {
            // Collect all tournaments, deduplicate, take 3
            final all = [
              ...workspace.organizedTournaments,
              ...workspace.coOrganizerTournaments,
              ...workspace.participatingTournaments,
            ];
            final seen = <String>{};
            final deduped = all.where((t) {
              final id = t.id.toString();
              return id.isNotEmpty && seen.add(id);
            }).take(3).toList();

            if (deduped.isEmpty) {
              return _emptyPreviewCard(
                colors,
                Icons.emoji_events_outlined,
                'Chưa tham gia giải đấu nào',
                onTap: () => showPublicTournamentTypeSheet(context),
                actionLabel: 'Tạo giải đấu',
              );
            }

            return Column(
              children: deduped
                  .map((t) => _buildTournamentPreviewCard(t, colors, context))
                  .toList(),
            );
          },
          loading: () => _loadingPlaceholder(colors),
          error: (e, s) => _emptyPreviewCard(
            colors,
            Icons.cloud_off_rounded,
            'Không thể tải giải đấu',
            onTap: () => ref.invalidate(myTournamentWorkspaceProvider),
            actionLabel: 'Thử lại',
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentPreviewCard(
    dynamic t,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    final String? logoUrl = t.logoUrl?.toString();
    final String? bannerUrl = t.bannerUrl?.toString();
    final rawStatus = t.status?.toString() ?? 'draft';
    final statusLabel = StatusHelper.getTournamentStatusLabel(rawStatus);

    return GestureDetector(
      onTap: () {
        final isManager =
            t.myRole == 'OWNER' ||
            t.myRole == 'ORGANIZER' ||
            t.myRole == 'CO_ORGANIZER';
        if (isManager) {
          if (t.isClubLite == true) {
            context.push('/lite-manage/${t.id}');
          } else {
            context.push('/organizer/tournaments/${t.id}/manage');
          }
        } else {
          context.push('/intro/${t.id}');
        }
      },
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
            _tournamentLogo(logoUrl, bannerUrl, colors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name?.toString() ?? '—',
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
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
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
    );
  }

  // ─── PREVIEW: CLB ────────────────────────────────────────────────────
  Widget _buildRecentClubsPreview(
    BuildContext context,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final myCommunitiesAsync = ref.watch(myCommunitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(colors, 'Đội nhóm / CLB'),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Text(
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
        myCommunitiesAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return _emptyPreviewCard(
                colors,
                Icons.groups_outlined,
                'Chưa tham gia CLB nào',
                onTap: () => context.push('/club/create'),
                actionLabel: 'Tạo CLB',
              );
            }
            final preview = communities.take(2).toList();
            return Column(
              children: preview
                  .map((club) => _buildClubPreviewCard(club, colors, context))
                  .toList(),
            );
          },
          loading: () => _loadingPlaceholder(colors),
          error: (e, s) => _emptyPreviewCard(
            colors,
            Icons.cloud_off_rounded,
            'Không thể tải CLB',
            onTap: () => ref.invalidate(myCommunitiesProvider),
            actionLabel: 'Thử lại',
          ),
        ),
      ],
    );
  }

  Widget _buildClubPreviewCard(
    dynamic club,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => context.push('/club/${club.id}'),
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
            _tournamentLogo(
              club.logoUrl?.toString(),
              club.bannerUrl?.toString(),
              colors,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name?.toString() ?? '—',
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
                    '${club.memberCount ?? 0} thành viên',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
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
    );
  }

  // ─── TAB 2: THÀNH TÍCH ───────────────────────────────────────────────
  Widget _buildAchievementsTab(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    final rankings =
        ref.watch(userRankingsProvider).asData?.value ??
        const <PlayerRanking>[];
    final followedAsync = ref.watch(followedTournamentsProvider);
    final followed = followedAsync.asData?.value ?? [];

    // Completed tournaments (achievements)
    final completed = followed
        .where((t) => StatusHelper.isTournamentCompleted(t.status))
        .toList()
      ..sort((a, b) =>
          (b.endDate ?? b.updatedAt).compareTo(a.endDate ?? a.updatedAt));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rankings per sport
          if (rankings.isNotEmpty) ...[
            _sectionLabel(colors, 'Xếp hạng theo môn'),
            const SizedBox(height: 10),
            ...rankings
                .where((r) => r.matchesPlayed > 0 || r.adminLeaderboardEligible)
                .map((r) => _buildRankCard(r, colors)),
            const SizedBox(height: 24),
          ],

          // Completed tournaments
          _sectionLabel(colors, 'Giải đấu đã hoàn thành'),
          const SizedBox(height: 10),
          if (completed.isEmpty)
            _emptyPreviewCard(
              colors,
              Icons.emoji_events_outlined,
              'Chưa có giải đấu hoàn thành nào',
            )
          else
            ...completed.take(10).map(
              (t) => _buildCompletedTournamentCard(t, colors, context),
            ),
        ],
      ),
    );
  }

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
          const Icon(Icons.sports_tennis_rounded, size: 22, color: AppTheme.primary),
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
                _formatNum(rank.eloPoints),
                style: TextStyle(
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

  // ─── TAB 3: LỊCH SỬ ─────────────────────────────────────────────────
  Widget _buildHistoryTab(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors,
  ) {
    final matchesAsync = ref.watch(publicUserMatchesProvider(profile.id));
    final followedAsync = ref.watch(followedTournamentsProvider);
    final followed = followedAsync.asData?.value ?? [];

    final sortedTournaments = [...followed]
      ..sort((a, b) =>
          (b.endDate ?? b.updatedAt).compareTo(a.endDate ?? a.updatedAt));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Trận đấu gần đây
          _sectionLabel(colors, 'Trận đấu gần đây'),
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
                    .take(5)
                    .map((m) => _buildMatchHistoryCard(m, colors, context))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Giải đấu đã tham gia / theo dõi
          _sectionLabel(colors, 'Giải đấu theo dõi & tham gia'),
          const SizedBox(height: 10),
          followedAsync.isLoading
              ? _loadingPlaceholder(colors)
              : sortedTournaments.isEmpty
              ? _emptyPreviewCard(
                  colors,
                  Icons.emoji_events_outlined,
                  'Chưa có giải đấu nào trong lịch sử',
                )
              : Column(
                  children: sortedTournaments
                      .map(
                        (t) => _buildHistoryCard(t, colors, context),
                      )
                      .toList(),
                ),
        ],
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
                  match.tournamentName ?? (isCompleted ? 'Trận đấu hoàn thành' : 'Sắp diễn ra'),
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

  // ─── TAB 4: ẢNH ──────────────────────────────────────────────────────
  Widget _buildPhotosTab(
    BuildContext context,
    UserProfile profile,
    AppColorsExtension colors,
  ) {
    final images = <String>[];
    if (profile.coverUrl != null && profile.coverUrl!.isNotEmpty) {
      images.add(profile.coverUrl!);
    }
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      images.add(profile.avatarUrl!);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel(colors, 'Bộ sưu tập ảnh'),
              const Spacer(),
              Text(
                '${images.length} ảnh',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (images.isEmpty)
            _emptyPreviewCard(
              colors,
              Icons.photo_library_outlined,
              'Chưa có ảnh nào',
              onTap: () {
                HapticFeedback.lightImpact();
                _pickAndUploadCover();
              },
              actionLabel: 'Thêm ảnh bìa',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: images.length,
              itemBuilder: (ctx, i) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showImagePreviewDialog(context, images[i], colors);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, s) => Container(
                            color: colors.bgCard,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(
    BuildContext context,
    String imageUrl,
    AppColorsExtension colors,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, s) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Không thể mở ảnh',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
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
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
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

  // ─── HELPERS ─────────────────────────────────────────────────────────
  List<PlayerRanking> _selectProfileBadges(List<PlayerRanking> rankings) {
    final sorted = rankings
        .where(
          (ranking) => ranking.isLeaderboardEligible && ranking.eloPoints > 0,
        )
        .toList()
      ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

    final seenCategories = <String>{};
    return sorted
        .where((ranking) {
          final key = (ranking.categoryId ?? ranking.categoryName ?? ranking.id)
              .trim()
              .toLowerCase();
          return seenCategories.add(key);
        })
        .take(2)
        .toList(growable: false);
  }

  Widget _sectionLabel(AppColorsExtension colors, String text) {
    return Row(
      children: [
        Container(
          width: 3,
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
