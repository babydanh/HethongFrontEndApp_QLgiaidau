import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/image_crop_dialog.dart';

import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';

// ─── PROFILE SCREEN ──────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    {
  bool _uploading = false;
  bool _uploadingCover = false;



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

    final eligibleRankings = rankings
        .where((r) => r.isLeaderboardEligible && r.eloPoints > 0)
        .toList()
      ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

    final bestRanking = eligibleRankings.isNotEmpty
        ? eligibleRankings.first
        : (rankings.isNotEmpty ? rankings.first : null);

    return _buildSinglePageProfile(
      context,
      profile,
      colors,
      rankings: rankings,
      bestRanking: bestRanking,
      totalPlayed: totalPlayed,
      totalWon: totalWon,
      totalLost: totalLost < 0 ? 0 : totalLost,
      bestElo: bestElo,
    );
  }

  // ─── SINGLE PAGE PROFILE (IMAGE 1 EXACT DESIGN) ──────────────────────
  Widget _buildSinglePageProfile(
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
    const expandedCoverHeight = 220.0;
    const avatarRadius = 46.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // ── PINNED SLIVER APP BAR (Cover image + Persistent Back/Camera/Settings) ──
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
                  context.go("/home");
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
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go("/profile/settings");
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
                  size: 18,
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
                if (profile.coverUrl != null && profile.coverUrl!.trim().isNotEmpty)
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
                        colors.bgDark.withValues(alpha: 0.85),
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

        // ── PROFILE BODY CONTENT WITH OVERLAPPING AVATAR ──
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Avatar protruding over the cover seam
              Transform.translate(
                offset: const Offset(0, -avatarRadius),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickAndUploadAvatar();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.bgDark,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: RankAvatar(
                            imageUrl: profile.avatarUrl,
                            name: (profile.fullName != null && profile.fullName!.isNotEmpty)
                                ? profile.fullName!
                                : "SportO",
                            elo: bestRanking?.eloPoints ?? 0,
                            tierName: bestRanking?.tierName,
                            matchesPlayed: bestRanking?.matchesPlayed ?? 0,
                            size: avatarRadius * 2,
                            ringWidth: 3,
                          ),
                        ),
                        // Small camera badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.bgCard,
                              border: Border.all(
                                color: colors.borderLight,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
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
                                      size: 14,
                                      color: colors.textPrimary,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Offset compensation after protruding avatar
              Transform.translate(
                offset: const Offset(0, -avatarRadius + 8),
                child: Column(
                  children: [
                    // ── USER NAME, USERNAME, LOCATION ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Full name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  profile.fullName ?? "Người dùng",
                                  style: TextStyle(
                                    fontSize: 21,
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
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Handle / Username (@minhanh)
                          if (profile.email != null)
                            Text(
                              "@${profile.email!.split("@").first}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 5),

                          // Location Pin (📍 Đắk Lắk, Việt Nam)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  (profile.address != null && profile.address!.isNotEmpty)
                                      ? profile.address!
                                      : "Đắk Lắk, Việt Nam",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 4-METRIC STATS ROW (IMAGE 1) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatsRow(
                        context,
                        colors,
                        totalPlayed,
                        totalWon,
                        totalLost < 0 ? 0 : totalLost,
                        bestElo,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 4-ITEM NAVIGATION MENU CARD (IMAGE 1) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildNavMenuCard(context, colors),
                    ),

                    const SizedBox(height: 110), // Bottom navigation clearance
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtisticCover(AppColorsExtension colors) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tennis/Badminton/Pickleball line graphics
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(
                Icons.sports_tennis_rounded,
                size: 170,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 40,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 90,
                color: Colors.white,
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

  Widget _statDivider(AppColorsExtension colors) => Container(
    width: 1,
    height: 34,
    color: colors.borderLight,
  );

  // ─── NAV MENU CARD (MATCHING 4-ITEM DESIGN MOCKUP) ────────────────
  Widget _buildNavMenuCard(BuildContext context, AppColorsExtension colors) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _menuRowItem(
            colors: colors,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            title: 'Thông tin cá nhân',
            subtitle: 'Tên, giới tính, ngày sinh...',
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/profile/edit');
            },
          ),
          Divider(height: 1, thickness: 0.8, color: colors.borderLight, indent: 56, endIndent: 16),
          _menuRowItem(
            colors: colors,
            icon: Icons.leaderboard_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
            title: 'Thống kê thi đấu',
            subtitle: 'Lịch sử, thành tích, điểm xếp hạng',
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/profile/elo');
            },
          ),
          Divider(height: 1, thickness: 0.8, color: colors.borderLight, indent: 56, endIndent: 16),
          _menuRowItem(
            colors: colors,
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFFF97316),
            iconBg: const Color(0xFFF97316).withValues(alpha: 0.12),
            title: 'Đội nhóm',
            subtitle: 'Các đội bạn đã tham gia',
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/home?tab=1');
            },
          ),
          Divider(height: 1, thickness: 0.8, color: colors.borderLight, indent: 56, endIndent: 16),
          _menuRowItem(
            colors: colors,
            icon: Icons.bookmark_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            title: 'Giải đấu đã đăng ký',
            subtitle: 'Danh sách giải đấu',
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/dashboard');
            },
          ),
        ],
      ),
    );
  }

  Widget _menuRowItem({
    required AppColorsExtension colors,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted.withValues(alpha: 0.7),
              ),
            ],
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
