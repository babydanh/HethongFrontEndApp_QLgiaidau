import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart' as tp;
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
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
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

import 'package:app_quanly_giaidau/features/profile/screens/achievements_tab.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;
  bool _uploadingCover = false;
  int _activeTab = 0;
  String _selectedSport = 'all';
  String _followedFilter = 'all';
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

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
              backgroundColor: Color(0xFF10B981),
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
      setState(() => _uploading = true);
      try {
        final repo = ref.read(userRepositoryProvider);
        await repo.uploadAvatar(bytes, fileName);
        ref.invalidate(userProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileAvatarUpdated),
              backgroundColor: Color(0xFF10B981),
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(tp.themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    if (!authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.colors.textPrimary,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          l10n.profileTitle,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
            label: Text(
              l10n.infoEdit,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildBody(context, profile, isDark),
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
        onProfileTap: () {},
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
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
              // Official Sporto SVG Logo
              Image.asset(
                'assets/images/sporto_v1_with_text.png',
                width: 190,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              Text(
                l10n.profileLoginGreeting,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.profileLoginDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(
                    l10n.profileLoginButton,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
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
        onProfileTap: () {},
      ),
    );
  }

  // ─── MAIN BODY ──────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, UserProfile profile, bool isDark) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Cover + Avatar section
          _buildCoverAndAvatar(context, profile),
          const SizedBox(height: 4),

          // Name + Role + Email + Bio
          _buildUserInfo(context, profile),
          const SizedBox(height: 20),

          // Tab bar selector (3 Tabs: Thông tin | Theo dõi | Thành tích)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      0,
                      l10n.profileTabInfo,
                      Icons.person_outline_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      1,
                      l10n.profileTabSettings,
                      Icons.settings_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          if (_activeTab == 0) ...[
            // Category selector chips placed at the VERY TOP of Tab 0
            _buildSportFilterChips(colors),
            const SizedBox(height: 16),

            // Dynamic rankings card list based on actual ELO and category ranks
            _buildRankingsSection(context),
            const SizedBox(height: 20),

            // Achievements & Stats (Compact & Filtered by selectedSport)
            AchievementsTab(selectedSport: _selectedSport),
            const SizedBox(height: 24),

            // My Tournaments Section
            _buildSectionTitle(colors, l10n.infoMyTournaments),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMyTournamentsSection(context),
            ),
            const SizedBox(height: 24),

            // My Communities Section
            _buildSectionTitle(colors, l10n.infoMyClubs),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMyCommunitiesSection(context),
            ),
            const SizedBox(height: 24),

            // Followed Tournaments Section
            _buildSectionTitle(colors, l10n.infoFollowedTournaments),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFollowedTournamentsSection(context),
            ),
            const SizedBox(height: 24),

            // Personal Info Section
            _buildSectionTitle(colors, l10n.infoPersonalInfo),
            const SizedBox(height: 10),
            _buildInfoCard(context, profile),
            const SizedBox(height: 32),
          ] else ...[
            // Tab 1: Cài đặt (Menu buttons)
            _buildSectionTitle(colors, l10n.settingsAccountTitle),
            const SizedBox(height: 10),
            _buildAccountMenu(context),
            const SizedBox(height: 24),

            _buildSectionTitle(colors, l10n.settingsSystemTitle),
            const SizedBox(height: 10),
            _buildOtherMenu(context, isDark),
            const SizedBox(height: 32),
          ],
          FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (context, snapshot) {
              final info = snapshot.data;
              if (info == null) return const SizedBox(height: 8);
              final build = info.buildNumber.isEmpty
                  ? ''
                  : ' (${info.buildNumber})';
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Text(
                  l10n.profileVersion(info.version, build),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilterChips(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    final sports = [
      {'id': 'all', 'label': l10n.infoAll, 'icon': Icons.grid_view_rounded},
      ...categories.map(
        (category) => <String, Object>{
          'id': category.slug,
          'label': category.name,
          'icon': _profileSportIcon(category.slug),
        },
      ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sports.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sport = sports[index];
          final isSelected = _selectedSport == sport['id'];
          final icon = sport['icon'] as IconData;
          return GestureDetector(
            onTap: () => setState(() => _selectedSport = sport['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : colors.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : colors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sport['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _profileSportIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'football':
        return Icons.sports_soccer_rounded;
      case 'badminton':
        return Icons.sports_tennis_outlined;
      case 'table_tennis':
        return Icons.sports_rounded;
      default:
        return Icons.sports_handball_rounded;
    }
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final colors = context.colors;
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── COVER + AVATAR ─────────────────────────────────────────────────
  Widget _buildCoverAndAvatar(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final rankings =
        ref.watch(userRankingsProvider).asData?.value ??
        const <PlayerRanking>[];
    final allRankings = rankings.toList()
      ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));
    final bestRanking = allRankings.isEmpty ? null : allRankings.first;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover photo
        GestureDetector(
          onTap: _pickAndUploadCover,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: profile.coverUrl != null && profile.coverUrl!.isNotEmpty
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
            child: profile.coverUrl != null && profile.coverUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        profile.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _coverGradient(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              colors.bgDark.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  )
                : _coverGradient(),
          ),
        ),
        // Cover upload overlay
        Positioned(
          top: 12,
          right: 16,
          child: GestureDetector(
            onTap: _pickAndUploadCover,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: _uploadingCover
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
        // Avatar Centered (Facebook Style)
        Positioned(
          bottom: -50,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Stack(
                children: [
                  RankAvatar(
                    imageUrl: profile.avatarUrl,
                    name: profile.fullName ?? '',
                    elo: bestRanking?.eloPoints ?? 0,
                    tierName: bestRanking?.tierName,
                    matchesPlayed: bestRanking?.matchesPlayed ?? 0,
                    size: 100,
                    ringWidth: 4,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                        border: Border.all(color: colors.bgDark, width: 2.5),
                      ),
                      child: _uploading
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
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
      ],
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

  // ─── USER INFO ──────────────────────────────────────────────────────
  Widget _buildUserInfo(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isEmailVerified = profile.isEmailVerified == true;

    // Translate role to Vietnamese
    String getRoleText(String? r) {
      if (r == null || r.isEmpty) return l10n.infoPlayer;
      final upper = r.toUpperCase();
      if (upper == 'ADMIN') return l10n.infoAdmin;
      if (upper == 'ORGANIZER') return l10n.infoOrganizer;
      if (upper == 'REFEREE') return l10n.infoReferee;
      if (upper == 'PLAYER') return l10n.infoPlayer;
      return upper;
    }

    final roleText = getRoleText(profile.role);
    final rankings =
        ref.watch(userRankingsProvider).asData?.value ??
        const <PlayerRanking>[];
    final profileBadges = _selectProfileBadges(rankings);

    // Format joined date
    String joinedDateText = '${l10n.infoJoinedAt} 7/2026';
    if (profile.createdAt != null && profile.createdAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(profile.createdAt!);
        joinedDateText = '${l10n.infoJoinedAt} ${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Centered Name
          Text(
            profile.fullName ?? l10n.profileUnknownUser,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (profileBadges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: profileBadges
                  .map(
                    (ranking) => RankTierBadge(
                      tierName: ranking.tierName,
                      elo: ranking.eloPoints,
                      sportName: ranking.categoryName,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 6),

          // 2. Role Badge (Placed cleanly below name, matching Web brand royal blue style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // bg-blue-50
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
              ), // border-blue-200
            ),
            child: Text(
              roleText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB), // text-blue-600 (Royal Blue brand)
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Email with Verified Checkmark Centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  profile.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEmailVerified) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Color(0xFF2563EB), // Web Royal Blue Verified Check
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // 4. Joined Date Line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: colors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                joinedDateText,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                profile.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PlayerRanking> _selectProfileBadges(List<PlayerRanking> rankings) {
    final sorted =
        rankings
            .where(
              (ranking) =>
                  ranking.isLeaderboardEligible && ranking.eloPoints > 0,
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

  // ─── PROFILE RANK SNAPSHOT ─────────────────────────────────────────

  Widget _buildRankingsSection(BuildContext context) {
    final colors = context.colors;
    final rankingsAsync = ref.watch(userRankingsProvider);

    return rankingsAsync.when(
      data: (rankings) {
        final playedRankings =
            rankings.where((ranking) => ranking.matchesPlayed > 0).toList()
              ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

        if (playedRankings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPrivateNoRankState(colors),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: playedRankings
                .map((ranking) => _buildPrivateRankCard(context, ranking))
                .toList(),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: colors.border),
          ),
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildPrivateNoRankState(colors),
      ),
    );
  }

  Widget _buildPrivateNoRankState(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 42, color: colors.textMuted),
          const SizedBox(height: 10),
          Text(
            l10n.publicProfileNoPlayedElo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.publicProfileNoPlayedEloHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateRankCard(BuildContext context, PlayerRanking ranking) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final tierColor = TierPalette.fromElo(
      ranking.eloPoints,
      ranking.tierName,
    ).badgeBg;
    final winRate = ranking.matchesPlayed > 0
        ? (ranking.matchesWon / ranking.matchesPlayed * 100).round()
        : 0;
    final isDoubles =
        ranking.matchType == 'DOUBLES' || ranking.matchType == 'MIXED_DOUBLES';
    final streakType = ranking.currentStreakType?.toUpperCase();
    final streakColor = streakType == 'WIN'
        ? const Color(0xFF2563EB)
        : streakType == 'LOSS'
        ? const Color(0xFFDC2626)
        : colors.textMuted;
    final streakText = streakType == 'WIN'
        ? l10n.publicProfileWinStreak(ranking.currentStreakCount)
        : streakType == 'LOSS'
        ? l10n.publicProfileLossStreak(ranking.currentStreakCount)
        : l10n.publicProfileNoStreak;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EloHistoryScreen(
              userId: ranking.userId,
              userName: ranking.fullName,
              avatarUrl: ranking.avatarUrl,
              currentElo: ranking.eloPoints,
              tierName: ranking.tierName,
              categoryId: ranking.categoryId,
              categoryName: ranking.categoryName,
              initialScope: 'PUBLIC',
              matchType: ranking.matchType,
              genderRestriction: ranking.genderRestriction ?? '__NONE__',
              partnerId: ranking.partnerId,
              lockRatingScope: true,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDoubles ? Icons.people_alt_rounded : Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ranking.categoryName?.isNotEmpty == true
                        ? ranking.categoryName!
                        : l10n.publicProfileUserFallback,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  isDoubles
                      ? ranking.matchType == 'MIXED_DOUBLES'
                            ? l10n.publicProfileScopeMixedDoubles
                            : l10n.publicProfileScopeDoubles
                      : l10n.publicProfileScopeSingles,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
              ],
            ),
            if (isDoubles && ranking.partnerName?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.publicProfilePartner}: ${ranking.partnerName}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RankTierBadge(
                        tierName: ranking.tierName,
                        elo: ranking.eloPoints,
                        sportName: ranking.categoryName,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ELO',
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ranking.eloPoints}',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCompactProfileStat(
                  l10n.publicProfileMatchesShort,
                  '${ranking.matchesPlayed}',
                  colors,
                ),
                _buildCompactProfileStat(
                  l10n.infoWin,
                  '${ranking.matchesWon}',
                  colors,
                ),
                _buildCompactProfileStat(
                  l10n.publicProfileWinRateShort,
                  '$winRate%',
                  colors,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (winRate / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  winRate >= 60 ? colors.success : tierColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  streakType == 'NONE'
                      ? Icons.remove_circle_outline_rounded
                      : Icons.local_fire_department_rounded,
                  color: streakColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.publicProfileCurrentStreak}: $streakText',
                  style: TextStyle(
                    color: streakColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProfileStat(
    String label,
    String value,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO CARD ──────────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final provincesAsync = ref.watch(provincesProvider);
    final provinces = provincesAsync.value ?? [];
    final province = provinces.firstWhere(
      (p) => p.code == profile.provinceCode,
      orElse: () => Province(code: '', name: ''),
    );
    final provinceDisplay = province.name.isNotEmpty
        ? province.name
        : (profile.provinceCode != null && profile.provinceCode!.isNotEmpty
              ? profile.provinceCode!
              : '—');

    final emailVerified = profile.isEmailVerified == true;
    final items = <_InfoItem>[
      _InfoItem(
        Icons.phone_rounded,
        l10n.profilePhoneLabel,
        profile.phoneNumber ?? '—',
      ),
      _InfoItem(
        Icons.cake_rounded,
        l10n.profileDobLabel,
        profile.dateOfBirth ?? '—',
      ),
      _InfoItem(
        Icons.wc_rounded,
        l10n.profileGenderLabel,
        profile.gender ?? '—',
      ),
      _InfoItem(
        Icons.location_on_rounded,
        l10n.profileAddressLabel,
        profile.address ?? '—',
      ),
      _InfoItem(Icons.map_rounded, l10n.profileProvinceLabel, provinceDisplay),
      _InfoItem(
        Icons.verified_outlined,
        l10n.infoEmailVerified,
        emailVerified ? l10n.infoEmailVerified : l10n.infoEmailUnverified,
      ),
      _InfoItem(
        Icons.phone_android_rounded,
        l10n.profilePhoneVerifiedLabel,
        profile.isPhoneVerified == true
            ? l10n.infoEmailVerified
            : l10n.infoEmailUnverified,
      ),
    ];
    if (profile.bankName != null && profile.bankName!.isNotEmpty) {
      items.add(
        _InfoItem(
          Icons.account_balance_rounded,
          l10n.profileBankLabel,
          profile.bankName!,
        ),
      );
    }
    if (profile.bankAccountNumber != null &&
        profile.bankAccountNumber!.isNotEmpty) {
      items.add(
        _InfoItem(
          Icons.numbers_rounded,
          l10n.profileBankAccountLabel,
          profile.bankAccountNumber!,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        (emailVerified
                                ? const Color(0xFF22C55E)
                                : colors.warning)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    emailVerified
                        ? Icons.verified_rounded
                        : Icons.mark_email_unread_rounded,
                    color: emailVerified
                        ? const Color(0xFF16A34A)
                        : colors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileEmailStatusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emailVerified
                            ? l10n.profileEmailVerifiedDescription
                            : l10n.profileEmailUnverifiedDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colors.borderLight,
            indent: 16,
            endIndent: 16,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 58),
              child: Divider(height: 1, color: colors.borderLight),
            ),
            itemBuilder: (_, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
        final roleGroups =
            <({String label, IconData icon, Color color, List<dynamic> items})>[
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
                items: workspace.refereeTournaments,
              ),
              (
                label: l10n.profilePlayerTournamentRole,
                icon: Icons.sports_tennis_rounded,
                color: context.colors.info,
                items: workspace.participatingTournaments,
              ),
            ];
        final tournaments = roleGroups.expand((group) => group.items).toList();
        final visible = tournaments.take(4).toList();

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
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 40,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: 8),
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
              ...visible.map((t) {
                final group = roleGroups.firstWhere(
                  (item) => item.items.any((candidate) => candidate.id == t.id),
                );
                return _buildTournamentRow(
                  t,
                  colors,
                  context,
                  roleLabel: group.label,
                  roleColor: group.color,
                  roleIcon: group.icon,
                );
              }),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    l10n.profileViewAllCount(tournaments.length.toString()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      ),
      error: (e, _) => Container(
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
                l10n.profileTournamentLoadError,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MY COMMUNITIES / CLUBS SECTION ─────────────────────────────────────
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
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Text(
            l10n.profileClubLoadError,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
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

    final roleLabel = isOwner
        ? l10n.profileOwnerRole
        : (isAdmin ? l10n.profileAdminRole : l10n.profileMemberRole);
    final roleColor = isOwner
        ? const Color(0xFFF59E0B)
        : (isAdmin ? AppTheme.primary : const Color(0xFF059669));

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
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      );
    }

    final displayMemberCount = club.memberCount > 0 ? club.memberCount : 2;

    return InkWell(
      onTap: () => context.push('/club/${club.id}'),
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                ),
              ),
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
                        onTap: () =>
                            setState(() => _followedFilter = f['id'] as String),
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
      error: (e, _) => Container(
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
                l10n.profileFollowedLoadError,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
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
                    style: TextStyle(
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
    dynamic t,
    AppColorsExtension colors,
    BuildContext context, {
    required String roleLabel,
    required Color roleColor,
    required IconData roleIcon,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final rawStatus = t.status?.toString() ?? 'draft';
    final statusLabel = StatusHelper.getTournamentStatusLabel(rawStatus);
    final String? logoUrl = t is Tournament
        ? t.logoUrl
        : (t.logoUrl?.toString());
    final String? bannerUrl = t is Tournament
        ? t.bannerUrl
        : (t.bannerUrl?.toString());

    return GestureDetector(
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.bgCard,
            title: Text(l10n.profileDeleteTournamentTitle),
            content: Text(
              l10n.profileDeleteTournamentContent(t.name?.toString() ?? ''),
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
          if (t.isClubLite) {
            context.push('/lite-manage/${t.id}');
          } else {
            _showAdvancedManagementUnsupported(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Logo giải đấu thật hoặc SportO logo
              _buildTournamentLogo(logoUrl, bannerUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name ?? '',
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
                      t.isClubLite
                          ? l10n.profileLiteTournamentHint
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

  void _showAdvancedManagementUnsupported(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileAdvancedManagementTitle),
        content: Text(l10n.profileAdvancedManagementContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.profileUnderstood),
          ),
        ],
      ),
    );
  }

  // ─── ACCOUNT MENU ──────────────────────────────────────────────────
  Widget _buildAccountMenu(BuildContext context) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    final items = [
      _MenuItem(Icons.dashboard_rounded, l.settingsDashboard, '/dashboard'),
      _MenuItem(Icons.leaderboard_rounded, l.navRankings, '/rankings'),
      _MenuItem(
        Icons.person_outline_rounded,
        l.settingsEditProfile,
        '/profile/edit',
      ),
      _MenuItem(
        Icons.account_balance_wallet_rounded,
        l.settingsPaymentHistory,
        '/payments',
      ),
      _MenuItem(Icons.emoji_events_rounded, l.settingsSeries, '/series'),
      _MenuItem(
        Icons.mail_outline_rounded,
        l.settingsClubInvites,
        '/club-invites',
      ),
      _MenuItem(
        Icons.lock_outline_rounded,
        l.settingsChangePassword,
        '/profile/change-password',
      ),
      _MenuItem(
        Icons.leaderboard_rounded,
        l.settingsEloHistory,
        '/profile/elo',
      ),
      _MenuItem(Icons.flag_outlined, l.myReportsTitle, '/profile/reports'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: colors.borderLight, indent: 56),
        itemBuilder: (_, i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return InkWell(
            onTap: item.route != null ? () => context.push(item.route!) : null,
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(20))
                : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
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
        },
      ),
    );
  }

  // ─── OTHER MENU ────────────────────────────────────────────────────
  Widget _buildOtherMenu(BuildContext context, bool isDark) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l.settingsNotifications,
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
          ),
          Divider(height: 1, color: colors.borderLight, indent: 56),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    size: 16,
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
                        ref,
                      ),
                      _langSegmentButton(
                        'en',
                        'EN',
                        ref.watch(localeProvider).languageCode == 'en',
                        ref,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderLight, indent: 56),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dark_mode_rounded,
                    size: 16,
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
          Divider(height: 1, color: colors.borderLight, indent: 56),
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              ref.invalidate(userProfileProvider);
              ref.invalidate(userRankingsProvider);
              if (!context.mounted) return;
              context.go('/home');
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
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
                    style: TextStyle(
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
      ),
    );
  }

  Widget _langSegmentButton(
    String code,
    String label,
    bool isSelected,
    WidgetRef ref,
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

  // ─── SECTION TITLE ────────────────────────────────────────────────
  Widget _buildSectionTitle(AppColorsExtension colors, String title) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ERROR ─────────────────────────────────────────────────────────
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

  // ─── HELPERS ────────────────────────────────────────────────────────
}

// ─── DATA CLASSES ───────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  const _MenuItem(this.icon, this.label, this.route);
}

// ─── SHIMMER ────────────────────────────────────────────────────────
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
            Container(height: 180, color: colors.border),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
                    height: 160,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
