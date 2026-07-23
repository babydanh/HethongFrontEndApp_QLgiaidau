import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart' as tp;
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/features/profile/screens/achievements_tab.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';

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

  Future<void> _pickImage(bool isCover) async {
    final colors = context.colors;
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
                isCover ? 'Thay đổi ảnh bìa' : 'Thay đổi ảnh đại diện',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: Text('Chụp ảnh mới', style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: Text('Chọn từ thư viện', style: TextStyle(color: colors.textPrimary)),
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
    final pickedFile = await picker.pickImage(source: source);
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
            const SnackBar(content: Text('Ảnh bìa đã được cập nhật'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
            const SnackBar(content: Text('Ảnh đại diện đã được cập nhật'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Hồ sơ',
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
            label: const Text('Sửa', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildBody(context, profile, isDark),
        loading: () => const ProfileShimmerLoading(),
        error: (err, _) => _buildError(context, err.toString()),
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
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Hồ sơ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Text('Xin chào!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'Đăng nhập để xem hồ sơ, theo dõi giải đấu và kết nối với cộng đồng thể thao.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Chưa có tài khoản? Đăng ký ngay',
                    style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    child: _buildTabButton(0, "Thông tin", Icons.person_outline_rounded),
                  ),
                  Expanded(
                    child: _buildTabButton(1, "Cài đặt", Icons.settings_outlined),
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
            _buildSectionTitle(colors, 'Giải đấu của tôi'),
            const SizedBox(height: 10),
            _buildMyTournamentsSection(context),
            const SizedBox(height: 24),

            // Followed Tournaments Section
            _buildSectionTitle(colors, 'Giải đấu đang theo dõi'),
            const SizedBox(height: 10),
            _buildFollowedTournamentsSection(context),
            const SizedBox(height: 24),

            // Personal Info Section
            _buildSectionTitle(colors, 'Thông tin cá nhân'),
            const SizedBox(height: 10),
            _buildInfoCard(context, profile),
            const SizedBox(height: 32),
          ] else ...[
            // Tab 1: Cài đặt (Menu buttons)
            _buildSectionTitle(colors, 'Tài khoản & Thiết lập'),
            const SizedBox(height: 10),
            _buildAccountMenu(context),
            const SizedBox(height: 24),

            _buildSectionTitle(colors, 'Tùy chọn hệ thống'),
            const SizedBox(height: 10),
            _buildOtherMenu(context, isDark),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSportFilterChips(AppColorsExtension colors) {
    final sports = const [
      {'id': 'all', 'label': 'Tất cả', 'icon': Icons.grid_view_rounded},
      {'id': 'pickleball', 'label': 'Pickleball', 'icon': Icons.sports_tennis_rounded},
      {'id': 'badminton', 'label': 'Cầu lông', 'icon': Icons.sports_tennis_outlined},
      {'id': 'football', 'label': 'Bóng đá', 'icon': Icons.sports_soccer_rounded},
      {'id': 'tennis', 'label': 'Tennis', 'icon': Icons.sports_baseball_rounded},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : colors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
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
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: profile.coverUrl != null && profile.coverUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(profile.coverUrl!, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _coverGradient()),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, colors.bgDark.withValues(alpha: 0.5)],
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
              child: _uploadingCover
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.camera_alt_rounded, size: 17, color: Colors.white),
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: -46,
          left: 24,
          child: GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bgSurface),
                      child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(43),
                              child: Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _avatarFallback(context, profile),
                              ),
                            )
                          : _avatarFallback(context, profile),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                      border: Border.all(color: colors.bgDark, width: 2.5),
                    ),
                    child: _uploading
                        ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
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

  Widget _avatarFallback(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    return Center(
      child: Text(
        _initials(profile.fullName ?? ''),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textSecondary),
      ),
    );
  }

  // ─── USER INFO ──────────────────────────────────────────────────────
  Widget _buildUserInfo(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final isEmailVerified = profile.isEmailVerified == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                profile.fullName ?? 'Người dùng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              if (profile.role != null && profile.role!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    profile.role!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 13, color: colors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        profile.email ?? '',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEmailVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── PROFILE RANK SNAPSHOT ─────────────────────────────────────────
  // ─── PROFILE RANK SNAPSHOT ─────────────────────────────────────────
  Color _getTierColor(String tierName) {
    final name = tierName.toUpperCase();
    if (name.contains('GRANDMASTER') || name.contains('MASTER')) {
      return const Color(0xFFA855F7);
    } else if (name.contains('DIAMOND')) {
      return const Color(0xFF3B82F6);
    } else if (name.contains('PLATINUM')) {
      return const Color(0xFF06B6D4);
    } else if (name.contains('GOLD')) {
      return const Color(0xFFEAB308);
    } else if (name.contains('SILVER')) {
      return const Color(0xFF94A3B8);
    } else if (name.contains('BRONZE')) {
      return const Color(0xFFD97706);
    } else if (name.contains('RANK A') || name == 'A') {
      return const Color(0xFFF97316);
    } else if (name.contains('RANK B') || name == 'B') {
      return const Color(0xFF3B82F6);
    } else if (name.contains('RANK C') || name == 'C') {
      return const Color(0xFF10B981);
    } else if (name.contains('RANK D') || name == 'D') {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF94A3B8);
  }

  Widget _buildRankingsSection(BuildContext context) {
    final colors = context.colors;
    final rankingsAsync = ref.watch(userRankingsProvider);

    return rankingsAsync.when(
      data: (rankings) {
        final playedRankings = rankings.where((r) => r.matchesPlayed > 0).toList()
          ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

        if (playedRankings.isEmpty) {
          const unranked = PlayerRanking(
            id: '',
            userId: '',
            fullName: '',
            eloPoints: 0,
            tierName: 'Chưa xếp hạng',
            matchesPlayed: 0,
            matchesWon: 0,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildRankDonutSummary(
              context,
              ranking: unranked,
              losses: 0,
              winRate: 0,
              eloProgress: 0.0,
              nextLabel: '',
            ),
          );
        }

        final ranking = playedRankings.first;
        final losses = (ranking.matchesPlayed - ranking.matchesWon).clamp(0, 9999);
        final winRate = ranking.matchesPlayed == 0
            ? 0.0
            : ranking.matchesWon / ranking.matchesPlayed;
        final progress = EloHelpers.getEloProgressInfo(ranking.eloPoints);
        final nextThreshold = progress.nextIndex == null
            ? null
            : EloHelpers.thresholds[progress.nextIndex!];
        final nextLabel = nextThreshold?.name ?? ranking.tierName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildRankDonutSummary(
            context,
            ranking: ranking,
            losses: losses,
            winRate: winRate,
            eloProgress: progress.percent / 100.0,
            nextLabel: nextLabel,
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
        ),
      ),
      error: (_, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildRankDonutSummary(
          context,
          ranking: const PlayerRanking(
            id: '',
            userId: '',
            fullName: '',
            eloPoints: 0,
            tierName: 'Chưa xếp hạng',
            matchesPlayed: 0,
            matchesWon: 0,
          ),
          losses: 0,
          winRate: 0,
          eloProgress: 0.0,
          nextLabel: '',
        ),
      ),
    );
  }

  Widget _buildRankDonutSummary(
    BuildContext context, {
    required PlayerRanking ranking,
    required int losses,
    required double winRate,
    required double eloProgress,
    required String nextLabel,
  }) {
    final colors = context.colors;
    final isUnranked = ranking.matchesPlayed == 0 ||
        ranking.tierName == 'Chưa xếp hạng' ||
        ranking.tierName.toUpperCase().contains('UNRANKED');

    final tierColor = isUnranked ? const Color(0xFF94A3B8) : _getTierColor(ranking.tierName);
    final fmt = NumberFormat('#,###');
    const winColor = Color(0xFF22C55E);
    const lossColor = Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWinLossStat(
                context,
                label: 'Thắng',
                value: ranking.matchesWon,
                color: winColor,
              ),
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(140),
                      painter: _EloRingPainter(
                        progress: isUnranked ? 0.0 : eloProgress,
                        activeColor: tierColor,
                        trackColor: tierColor.withValues(alpha: 0.15),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUnranked ? 'TRẠNG THÁI' : 'RANK',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUnranked ? '-' : _rankLetter(ranking.tierName),
                          style: TextStyle(
                            color: tierColor,
                            fontSize: isUnranked ? 28 : 34,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUnranked ? 'Chưa có rank' : '${fmt.format(ranking.eloPoints)} ELO',
                          style: TextStyle(
                            color: isUnranked ? colors.textMuted : tierColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildWinLossStat(
                context,
                label: 'Thua',
                value: losses,
                color: lossColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tỷ lệ thắng ',
                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(winRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: winColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (!isUnranked && nextLabel.isNotEmpty) ...[
                Text(
                  ' • ',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
                Text(
                  'Tiến tới $nextLabel (${(eloProgress * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: tierColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinLossStat(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 26,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'trận',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }



  String _rankLetter(String tierName) {
    final upper = tierName.trim().toUpperCase();
    if (upper.isEmpty) return '-';
    if (upper.contains('S')) return 'S';
    if (upper.contains('A')) return 'A';
    if (upper.contains('B')) return 'B';
    if (upper.contains('C')) return 'C';
    if (upper.contains('D')) return 'D';
    return upper.characters.first;
  }

  // ─── INFO CARD ──────────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final provincesAsync = ref.watch(provincesProvider);
    final provinces = provincesAsync.value ?? [];
    final province = provinces.firstWhere(
      (p) => p.code == profile.provinceCode,
      orElse: () => Province(code: '', name: ''),
    );
    final provinceDisplay = province.name.isNotEmpty 
        ? province.name 
        : (profile.provinceCode != null && profile.provinceCode!.isNotEmpty ? profile.provinceCode! : '—');

    final emailVerified = profile.isEmailVerified == true;
    final items = <_InfoItem>[
      _InfoItem(Icons.phone_rounded, 'Số điện thoại', profile.phoneNumber ?? '—'),
      _InfoItem(Icons.cake_rounded, 'Ngày sinh', profile.dateOfBirth ?? '—'),
      _InfoItem(Icons.wc_rounded, 'Giới tính', profile.gender ?? '—'),
      _InfoItem(Icons.location_on_rounded, 'Địa chỉ', profile.address ?? '—'),
      _InfoItem(Icons.map_rounded, 'Tỉnh/Thành phố', provinceDisplay),
      _InfoItem(Icons.verified_outlined, 'Email xác thực', emailVerified ? 'Đã xác thực' : 'Chưa xác thực'),
      _InfoItem(Icons.phone_android_rounded, 'SĐT xác thực', profile.isPhoneVerified == true ? 'Đã xác thực' : 'Chưa xác thực'),
    ];
    if (profile.bankName != null && profile.bankName!.isNotEmpty) {
      items.add(_InfoItem(Icons.account_balance_rounded, 'Ngân hàng', profile.bankName!));
    }
    if (profile.bankAccountNumber != null && profile.bankAccountNumber!.isNotEmpty) {
      items.add(_InfoItem(Icons.numbers_rounded, 'STK', profile.bankAccountNumber!));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
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
                    color: (emailVerified ? const Color(0xFF22C55E) : colors.warning).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    emailVerified ? Icons.verified_rounded : Icons.mark_email_unread_rounded,
                    color: emailVerified ? const Color(0xFF16A34A) : colors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái email',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emailVerified
                            ? 'Email đã được xác thực và sẵn sàng cho các chức năng bảo mật.'
                            : 'Email chưa xác thực, nên xác minh để hoàn tất bảo mật tài khoản.',
                        style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderLight, indent: 16, endIndent: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Icon(item.icon, size: 16, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(item.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
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
    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);

    return workspaceAsync.when(
      data: (workspace) {
        final tournaments = [
          ...workspace.organizedTournaments,
          ...workspace.coOrganizerTournaments,
          ...workspace.participatingTournaments,
        ];
        final visible = tournaments.take(4).toList();

        if (visible.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 40, color: colors.textMuted),
                  const SizedBox(height: 8),
                  Text('Bạn chưa tạo hoặc tham gia giải nào.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Xem Dashboard'),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              ...visible.map((t) => _buildTournamentRow(t, colors, context)),
              if (tournaments.length > 4)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text('Xem tất cả (${tournaments.length})'),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded, size: 32, color: colors.textMuted),
              const SizedBox(height: 8),
              Text('Không thể tải dữ liệu', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowedTournamentsSection(BuildContext context) {
    final colors = context.colors;
    final followedAsync = ref.watch(followedTournamentsProvider);

    return followedAsync.when(
      data: (tournaments) {
        final visible = [...tournaments]
          ..sort((a, b) {
            final priorityDiff = _followedTournamentPriority(a).compareTo(_followedTournamentPriority(b));
            if (priorityDiff != 0) return priorityDiff;
            return _followedTournamentTimestamp(b).compareTo(_followedTournamentTimestamp(a));
          });
        final topVisible = visible.take(5).toList();

        if (topVisible.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 40, color: colors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn chưa theo dõi giải nào.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.explore_rounded, size: 16),
                    label: const Text('Khám phá giải đấu'),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _StatusPill(label: 'Vừa kết thúc', backgroundColor: Color(0xFF0F172A), foregroundColor: Colors.white),
                    _StatusPill(label: 'Đang diễn ra', backgroundColor: Color(0xFFFEF2F2), foregroundColor: Color(0xFFB91C1C), borderColor: Color(0xFFFECACA)),
                    _StatusPill(label: 'Mở đăng ký', backgroundColor: Color(0xFFF0FDF4), foregroundColor: Color(0xFF047857), borderColor: Color(0xFFBBF7D0)),
                    _StatusPill(label: 'Sắp diễn ra', backgroundColor: Color(0xFFEFF6FF), foregroundColor: Color(0xFF1D4ED8), borderColor: Color(0xFFBFDBFE)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...topVisible.map((tournament) => _buildFollowedTournamentRow(tournament, colors, context)),
              if (visible.length > 5)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text('Xem tất cả (${visible.length})'),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded, size: 32, color: colors.textMuted),
              const SizedBox(height: 8),
              Text(
                'Không thể tải danh sách theo dõi',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowedTournamentRow(Tournament tournament, AppColorsExtension colors, BuildContext context) {
    final statusLabel = StatusHelper.getTournamentStatusLabel(tournament.status);
    final isCompleted = StatusHelper.isTournamentCompleted(tournament.status);
    final isRecentCompleted = isCompleted &&
        tournament.endDate != null &&
        DateTime.now().difference(tournament.endDate!).inDays <= 14;
    final statusHint = isRecentCompleted
        ? 'Vừa kết thúc trong 14 ngày gần đây'
        : isCompleted
            ? 'Đã kết thúc'
            : StatusHelper.isTournamentInProgress(tournament.status)
                ? 'Đang diễn ra'
                : StatusHelper.isTournamentRegistration(tournament.status)
                    ? 'Mở đăng ký'
                    : StatusHelper.isTournamentUpcoming(tournament.status)
                        ? 'Sắp diễn ra'
                        : 'Đang theo dõi';
    return InkWell(
      onTap: () => context.push('/intro/${tournament.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bookmark_rounded, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name.isNotEmpty ? tournament.name : '(Chưa có tên)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusHint,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (isRecentCompleted)
                        _StatusPill(
                          label: 'Vừa kết thúc',
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                      if (isCompleted && !isRecentCompleted)
                        _StatusPill(
                          label: 'Đã kết thúc',
                          backgroundColor: colors.bgSurface,
                          foregroundColor: colors.textSecondary,
                          borderColor: colors.border,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  int _followedTournamentPriority(Tournament tournament) {
    if (StatusHelper.isTournamentCompleted(tournament.status)) return 0;
    if (StatusHelper.isTournamentInProgress(tournament.status)) return 1;
    if (StatusHelper.isTournamentRegistration(tournament.status) || StatusHelper.isTournamentUpcoming(tournament.status)) return 2;
    if (StatusHelper.isTournamentCancelled(tournament.status)) return 3;
    return 4;
  }

  DateTime _followedTournamentTimestamp(Tournament tournament) {
    return tournament.endDate ?? tournament.updatedAt;
  }

  Widget _buildTournamentRow(dynamic t, AppColorsExtension colors, BuildContext context) {
    final statusLabel = t.status?.toString().replaceAll('_', ' ') ?? 'draft';
    return GestureDetector(
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.bgCard,
            title: const Text('Xóa giải đấu?'),
            content: Text('Bạn có chắc muốn xóa "${t.name}"?',
                style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Xóa', style: TextStyle(color: colors.error)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          final success = await ref.read(tournamentActionProvider.notifier).deleteTournament(t.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Đã xóa giải đấu' : 'Không thể xóa giải đấu'),
                backgroundColor: success ? colors.success : colors.error,
              ),
            );
            if (success) ref.invalidate(myTournamentWorkspaceProvider);
          }
        }
      },
      child: InkWell(
      onTap: () => context.push('/intro/${t.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.emoji_events_rounded, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name ?? '',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    ),
    );
  }

  // ─── ACCOUNT MENU ──────────────────────────────────────────────────
  Widget _buildAccountMenu(BuildContext context) {
    final colors = context.colors;
    final items = [
      _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      _MenuItem(Icons.person_outline_rounded, 'Chỉnh sửa hồ sơ', '/profile/edit'),

      _MenuItem(Icons.account_balance_wallet_rounded, 'Lịch sử thanh toán', '/payments'),
      _MenuItem(Icons.emoji_events_rounded, 'Chuỗi giải đấu', '/series'),
	      _MenuItem(Icons.mail_outline_rounded, 'Lời mời CLB', '/club-invites'),
      _MenuItem(Icons.settings_rounded, 'Cài đặt', '/profile/settings'),
      _MenuItem(Icons.lock_outline_rounded, 'Đổi mật khẩu', '/profile/change-password'),
      _MenuItem(Icons.leaderboard_rounded, 'Lịch sử ELO', '/profile/elo'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: colors.borderLight, indent: 56),
        itemBuilder: (_, i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return InkWell(
            onTap: item.route != null ? () => context.push(item.route!) : null,
            borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(item.icon, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
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
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications_outlined, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Thông báo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
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
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.dark_mode_rounded, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text('Chế độ tối', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                Switch(
                  value: isDark,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) => ref.read(tp.themeProvider.notifier).toggleTheme(),
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
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: AppTheme.adminColor),
                  const SizedBox(width: 14),
                  const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.adminColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION TITLE ────────────────────────────────────────────────
  Widget _buildSectionTitle(AppColorsExtension colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.3)),
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
            Text('Không thể tải thông tin',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => ref.invalidate(userProfileProvider), child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────
  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
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
                  Container(width: 160, height: 22, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 14, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 16),
                  Container(height: 100, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 20),
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 200, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 20),
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 160, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(20))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _EloRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color trackColor;

  const _EloRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 14) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 10.0;
    const startAngle = -1.57079632679; // Top 12 o'clock

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final safeProgress = progress.clamp(0.0, 1.0);
    if (safeProgress > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 6.28318530718 * safeProgress;
      canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EloRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
