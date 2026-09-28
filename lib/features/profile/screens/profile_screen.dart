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
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';

// ─── PROFILE SCREEN ──────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;
  bool _uploadingCover = false;
  String _followedFilter = 'all';

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

    final eligibleRankings =
        rankings
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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
                            name:
                                (profile.fullName != null &&
                                    profile.fullName!.isNotEmpty)
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
                                  (profile.address != null &&
                                          profile.address!.isNotEmpty)
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

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── MY TOURNAMENTS / COMMUNITIES / FOLLOWED ──
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // My Tournaments
                  _buildSectionTitle(
                    colors,
                    l10n.infoMyTournaments,
                    trailing: IconButton(
                      onPressed: () => showPublicTournamentTypeSheet(context),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                      color: AppTheme.primary,
                      tooltip: 'Tạo giải đấu',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildMyTournamentsSection(context),
                  ),
                  const SizedBox(height: 24),

                  // My Communities
                  _buildSectionTitle(colors, l10n.infoMyClubs),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildMyCommunitiesSection(context),
                  ),
                  const SizedBox(height: 24),

                  // Followed Tournaments
                  _buildSectionTitle(colors, l10n.infoFollowedTournaments),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFollowedTournamentsSection(context),
                  ),
                  const SizedBox(height: 110), // Bottom navigation clearance
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtisticCover(AppColorsExtension colors) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
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

  // ─── SECTION TITLE ────────────────────────────────────────────────
  Widget _buildSectionTitle(
    AppColorsExtension colors,
    String title, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  // ─── MY TOURNAMENTS SECTION ──────────────────────────────────────────
  Widget _buildMyTournamentsSection(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);

    return workspaceAsync.when(
      data: (workspace) {
        // Referee assignments ship as flat invites; resolve them against the
        // tournament lists so the row keeps real name/logo/status/route.
        final refereeTournaments = <Tournament>[];
        for (final invite in workspace.refereeTournaments) {
          final match = workspace.organizedTournaments
              .where((t) => t.id == invite.tournamentId)
              .firstOrNull;
          final resolved =
              match ??
              workspace.participatingTournaments
                  .where((t) => t.id == invite.tournamentId)
                  .firstOrNull;
          if (resolved != null) refereeTournaments.add(resolved);
        }

        final roleGroups =
            <
              ({
                String label,
                IconData icon,
                Color color,
                List<Tournament> items,
              })
            >[
              (
                label: l10n.profileOwnerTournamentRole,
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFF059669),
                items: workspace.organizedTournaments,
              ),
              (
                label: l10n.profileOrganizerTournamentRole,
                icon: Icons.groups_rounded,
                color: AppTheme.primary,
                items: workspace.coOrganizerTournaments,
              ),
              (
                label: l10n.profileRefereeTournamentRole,
                icon: Icons.gavel_rounded,
                color: AppTheme.refereeColor,
                items: refereeTournaments,
              ),
              (
                label: l10n.profilePlayerTournamentRole,
                icon: Icons.sports_tennis_rounded,
                color: context.colors.info,
                items: workspace.participatingTournaments,
              ),
            ];
        final seenIds = <String>{};
        final deduplicatedItems =
            <
              ({
                Tournament tournament,
                ({String label, IconData icon, Color color}) role,
              })
            >[];

        for (final group in roleGroups) {
          for (final item in group.items) {
            final id = item.id.trim();
            if (id.isNotEmpty && !seenIds.contains(id)) {
              seenIds.add(id);
              deduplicatedItems.add((
                tournament: item,
                role: (
                  label: group.label,
                  icon: group.icon,
                  color: group.color,
                ),
              ));
            }
          }
        }

        final visible = deduplicatedItems.take(4).toList();

        if (visible.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: () => showPublicTournamentTypeSheet(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 32,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.profileNoManagedTournaments,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(l10n.profileViewDashboard),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              ...visible.map(
                (entry) => _buildTournamentRow(
                  entry.tournament,
                  colors,
                  context,
                  roleLabel: entry.role.label,
                  roleColor: entry.role.color,
                  roleIcon: entry.role.icon,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    l10n.profileViewAllCount(
                      deduplicatedItems.length.toString(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      ),
      error: (e, _) => _buildSectionErrorCard(
        colors,
        message: l10n.profileTournamentLoadError,
      ),
    );
  }

  Widget _buildSectionErrorCard(
    AppColorsExtension colors, {
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MY COMMUNITIES / CLUBS SECTION ─────────────────────────────────
  Widget _buildMyCommunitiesSection(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final myCommunitiesAsync = ref.watch(myCommunitiesProvider);

    return myCommunitiesAsync.when(
      data: (communities) {
        if (communities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileNoClubs,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/club/create'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(l10n.profileCreateClub),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              ...communities.map(
                (club) => _buildCommunityRow(club, colors, context),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () => context.push('/club/create'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(l10n.profileCreateClub),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      ),
      error: (e, _) => _buildSectionErrorCard(
        colors,
        message: l10n.profileClubLoadError,
      ),
    );
  }

  Widget _buildCommunityRow(
    Community club,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(userProfileProvider).value?.id;
    final isOwner =
        club.myRole == 'OWNER' ||
        club.myRole == 'LEADER' ||
        club.myRole == 'CREATOR' ||
        club.myRole == 'HOST' ||
        (currentUserId != null && club.ownerId == currentUserId);

    final isAdmin =
        !isOwner && (club.myRole == 'ADMIN' || club.myRole == 'MODERATOR');
    final clubStatus = club.status.trim().toUpperCase();
    final isPending = clubStatus == 'PENDING';
    final isRejected = clubStatus == 'REJECTED';

    final roleLabel = isOwner
        ? l10n.profileOwnerRole
        : (isAdmin ? l10n.profileAdminRole : l10n.profileMemberRole);
    final roleColor = isOwner
        ? const Color(0xFFF59E0B)
        : (isAdmin ? AppTheme.primary : const Color(0xFF059669));
    final statusLabel = isRejected
        ? l10n.profileClubRejected
        : (isPending ? l10n.profileClubPending : roleLabel);
    final statusColor = isRejected
        ? context.colors.error
        : (isPending ? const Color(0xFFD97706) : roleColor);

    final List<Widget> sportWidgets = [];
    if (club.sports.isNotEmpty) {
      for (final rawS in club.sports) {
        final sTrim = rawS.trim();
        if (sTrim.isEmpty) continue;
        final mapped = l10n.sportDisplayName(sTrim);
        sportWidgets.add(
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              mapped.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        );
      }
    }
    if (sportWidgets.isEmpty) {
      sportWidgets.add(
        Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            l10n.profileDefaultSport,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      );
    }

    final displayMemberCount = club.memberCount > 0 ? club.memberCount : 2;
    final destination = isRejected && isOwner
        ? '/club/${club.id}/edit'
        : '/club/${club.id}';

    return InkWell(
      onTap: () => context.push(destination),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTournamentLogo(club.logoUrl, club.bannerUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    club.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...sportWidgets,
                        const SizedBox(width: 2),
                        Text(
                          '$displayMemberCount ${l10n.profileMembers}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRejected &&
                      club.rejectedReason != null &&
                      club.rejectedReason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      club.rejectedReason!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.colors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                if (isRejected && isOwner) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.profileClubResubmit,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 6),
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

  Widget _buildTournamentLogo(String? logoUrl, String? bannerUrl) {
    final colors = context.colors;
    final url = (logoUrl != null && logoUrl.isNotEmpty)
        ? logoUrl
        : ((bannerUrl != null && bannerUrl.isNotEmpty) ? bannerUrl : null);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2979FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _defaultSportoLogo(),
            )
          : _defaultSportoLogo(),
    );
  }

  Widget _defaultSportoLogo() {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: Image.asset(
        'assets/images/sporto_v1_with_text.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // ─── FOLLOWED TOURNAMENTS SECTION ───────────────────────────────────
  Widget _buildFollowedTournamentsSection(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final followedAsync = ref.watch(followedTournamentsProvider);

    return followedAsync.when(
      data: (tournaments) {
        final now = DateTime.now();

        final filteredList = tournaments.where((t) {
          if (_followedFilter == 'all') return true;
          final isCompleted = StatusHelper.isTournamentCompleted(t.status);
          final isRecentCompleted =
              isCompleted &&
              t.endDate != null &&
              now.difference(t.endDate!).inDays <= 14;

          if (_followedFilter == 'recent_completed') {
            return isRecentCompleted || isCompleted;
          }
          if (_followedFilter == 'in_progress') {
            return StatusHelper.isTournamentInProgress(t.status);
          }
          if (_followedFilter == 'registration') {
            return StatusHelper.isTournamentRegistration(t.status);
          }
          if (_followedFilter == 'upcoming') {
            return StatusHelper.isTournamentUpcoming(t.status);
          }
          return true;
        }).toList();

        final visible = [...filteredList]
          ..sort((a, b) {
            final priorityDiff = _followedTournamentPriority(
              a,
            ).compareTo(_followedTournamentPriority(b));
            if (priorityDiff != 0) return priorityDiff;
            return _followedTournamentTimestamp(
              b,
            ).compareTo(_followedTournamentTimestamp(a));
          });
        final topVisible = visible.take(5).toList();

        final filters = [
          {'id': 'all', 'label': l10n.infoAll},
          {'id': 'recent_completed', 'label': l10n.profileRecentCompleted},
          {'id': 'in_progress', 'label': l10n.profileInProgress},
          {'id': 'registration', 'label': l10n.profileRegistrationOpen},
          {'id': 'upcoming', 'label': l10n.profileUpcoming},
        ];

        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = _followedFilter == f['id'];
                      return GestureDetector(
                        key: ValueKey('profile-followed-filter-${f['id']}'),
                        onTap: () => setState(
                          () => _followedFilter = f['id'] as String,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : colors.bgSurface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXL,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : colors.border,
                            ),
                          ),
                          child: Text(
                            f['label'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              if (topVisible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    tournaments.isEmpty
                        ? l10n.profileNoFollowedTournaments
                        : l10n.profileNoMatchingTournaments,
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                )
              else
                ...topVisible.map(
                  (tournament) =>
                      _buildFollowedTournamentRow(tournament, colors, context),
                ),

              if (visible.length > 5)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      l10n.profileViewAllCount(visible.length.toString()),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      ),
      error: (e, _) => _buildSectionErrorCard(
        colors,
        message: l10n.profileFollowedLoadError,
      ),
    );
  }

  Widget _buildFollowedTournamentRow(
    Tournament tournament,
    AppColorsExtension colors,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = StatusHelper.getTournamentStatusLabel(
      tournament.status,
    );
    final isCompleted = StatusHelper.isTournamentCompleted(tournament.status);
    final isRecentCompleted =
        isCompleted &&
        tournament.endDate != null &&
        DateTime.now().difference(tournament.endDate!).inDays <= 14;
    final statusHint = isRecentCompleted
        ? l10n.profileRecentlyCompletedHint
        : isCompleted
        ? l10n.profileCompletedHint
        : StatusHelper.isTournamentInProgress(tournament.status)
        ? l10n.profileInProgressHint
        : StatusHelper.isTournamentRegistration(tournament.status)
        ? l10n.profileRegistrationHint
        : StatusHelper.isTournamentUpcoming(tournament.status)
        ? l10n.profileUpcomingHint
        : l10n.profileFollowingHint;
    return InkWell(
      onTap: () => context.push('/intro/${tournament.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildTournamentLogo(tournament.logoUrl, tournament.bannerUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name.isNotEmpty
                        ? tournament.name
                        : l10n.profileNoName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    statusHint,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  int _followedTournamentPriority(Tournament tournament) {
    if (StatusHelper.isTournamentCompleted(tournament.status)) return 0;
    if (StatusHelper.isTournamentInProgress(tournament.status)) return 1;
    if (StatusHelper.isTournamentRegistration(tournament.status) ||
        StatusHelper.isTournamentUpcoming(tournament.status)) {
      return 2;
    }
    if (StatusHelper.isTournamentCancelled(tournament.status)) return 3;
    return 4;
  }

  DateTime _followedTournamentTimestamp(Tournament tournament) {
    return tournament.endDate ?? tournament.updatedAt;
  }

  Widget _buildTournamentRow(
    Tournament t,
    AppColorsExtension colors,
    BuildContext context, {
    required String roleLabel,
    required Color roleColor,
    required IconData roleIcon,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = StatusHelper.getTournamentStatusLabel(t.status);

    return GestureDetector(
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.bgCard,
            title: Text(l10n.profileDeleteTournamentTitle),
            content: Text(
              l10n.profileDeleteTournamentContent(t.name),
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.profileCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.delete, style: TextStyle(color: colors.error)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          final success = await ref
              .read(tournamentActionProvider.notifier)
              .deleteTournament(t.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? l10n.profileTournamentDeleted
                      : l10n.profileTournamentDeleteFailed,
                ),
                backgroundColor: success ? colors.success : colors.error,
              ),
            );
            if (success) ref.invalidate(myTournamentWorkspaceProvider);
          }
        }
      },
      child: InkWell(
        onTap: () {
          final isManager =
              roleLabel == l10n.profileOwnerTournamentRole ||
              roleLabel == l10n.profileOrganizerTournamentRole;
          if (isManager) {
            if (t.isClubLite) {
              context.push('/lite-manage/${t.id}');
            } else {
              context.push('/organizer/tournaments/${t.id}/manage');
            }
          } else {
            context.push('/intro/${t.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Logo giải đấu thật hoặc SportO logo
              _buildTournamentLogo(t.logoUrl, t.bannerUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (t.communityName != null &&
                        t.communityName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 11,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              t.communityName!,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      t.isClubLite
                          ? (t.communityName != null &&
                                    t.communityName!.isNotEmpty
                                ? 'Giải Siêu Lite • ${t.communityName}'
                                : l10n.profileLiteTournamentHint)
                          : l10n.profileAdvancedTournamentHint,
                      style: TextStyle(
                        fontSize: 9,
                        color: t.isClubLite
                            ? const Color(0xFF059669)
                            : AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(roleIcon, size: 11, color: roleColor),
                        const SizedBox(width: 3),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: roleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
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
          Divider(
            height: 1,
            thickness: 0.8,
            color: colors.borderLight,
            indent: 56,
            endIndent: 16,
          ),
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
          Divider(
            height: 1,
            thickness: 0.8,
            color: colors.borderLight,
            indent: 56,
            endIndent: 16,
          ),
          _menuRowItem(
            colors: colors,
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFFF97316),
            iconBg: const Color(0xFFF97316).withValues(alpha: 0.12),
            title: 'Đội nhóm',
            subtitle: 'Các đội bạn đã tham gia',
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/home?tab=3');
            },
          ),
          Divider(
            height: 1,
            thickness: 0.8,
            color: colors.borderLight,
            indent: 56,
            endIndent: 16,
          ),
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
                      style: TextStyle(fontSize: 11.5, color: colors.textMuted),
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
