import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_chart.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Trang xem hồ sơ công khai của người dùng khác.
///
/// Gọi API GET /users/:id/public — hiển thị:
/// - Cover photo + Avatar + Tên + Bio + Giới tính + Xác thực
/// - ELO + Thống kê theo từng môn
/// - Tab Thành tích (Quán quân, Á quân, Hạng ba)
/// - Biểu đồ ELO history
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userPublicProfileProvider(widget.userId));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: profileAsync.when(
        data: (profile) => _buildBody(context, profile, colors),
        loading: () => const _ProfileShimmer(),
        error: (err, _) => _buildError(context, colors, err.toString()),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          elevation: 0,
          backgroundColor: colors.bgDark,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgCard.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share_rounded, color: colors.textPrimary, size: 20),
              ),
              onPressed: () {
                AppShareModal.show(
                  context: context,
                  title: profile.fullName,
                  subtitle: profile.bio ?? 'Hồ sơ Vận động viên',
                  webUrl: 'https://sporto.asia/profile/user/${widget.userId}',
                  imageUrl: profile.avatarUrl,
                  badgeText: 'Thẻ VĐV & ELO',
                );
              },
            ),
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
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppTheme.primary,
                unselectedLabelColor: colors.textMuted,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Trận đấu'),
                  Tab(text: 'Danh hiệu'),
                  Tab(text: 'ELO'),
                ],
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: THÔNG TIN ─────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Thông tin cơ bản
                _buildUserInfoHeader(context, profile, colors),
                const SizedBox(height: 20),
                // Thống kê tổng quan
                _buildStatsOverview(context, profile, colors),
                const SizedBox(height: 24),
                // Xếp hạng theo môn
                _sectionTitle(colors, 'Xếp hạng theo bộ môn'),
                const SizedBox(height: 12),
                if (profile.ranks.isEmpty)
                  _buildNoRank(colors)
                else
                  ...profile.ranks.map((rank) => _buildRankCard(context, rank, colors)),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildMatchesTab(context, profile, colors),
          // ─── TAB 3: DANH HIỆU ─────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thành tích Quán quân / Á quân / Hạng ba
                _buildAchievementsSection(context, profile, colors),
              ],
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(colors, 'Biểu đồ ELO'),
                const SizedBox(height: 12),
                _buildEloChart(context, profile, colors),
                const SizedBox(height: 24),
                _sectionTitle(colors, 'Thống kê chi tiết'),
                const SizedBox(height: 12),
                _buildDetailedStats(context, profile, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final matchesAsync = ref.watch(publicUserMatchesProvider(profile.id));
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: matchesAsync.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
        error: (err, stack) => _buildEmptyPlaceholder(colors, Icons.sports_tennis_outlined, 'Chưa tải được lịch sử trận đấu'),
        data: (matches) => matches.isEmpty
            ? _buildEmptyPlaceholder(colors, Icons.sports_tennis_outlined, 'Chưa có trận đấu công khai')
            : Column(children: matches.map((match) => _buildPublicMatchCard(match, colors)).toList()),
      ),
    );
  }

  Widget _buildPublicMatchCard(MatchModel match, AppColorsExtension colors) {
    final completed = match.status.toLowerCase() == 'completed' || match.completedAt != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Row(children: [
        Icon(completed ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, color: completed ? Colors.green : AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${match.team1Name}  vs  ${match.team2Name}', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${match.tournamentName ?? 'Giải đấu'}  •  ${completed ? 'Đã kết thúc' : 'Chưa diễn ra'}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
        ])),
        Text('${match.score1} - ${match.score2}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colors.textPrimary)),
      ]),
    );
  }

  // ─── ACHIEVEMENTS SECTION ──────────────────────────────────────────
  Widget _buildAchievementsSection(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final achievements = List<UserPublicAchievement>.from(profile.achievements)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final championCategories = achievements.where((a) => a.rank == 1).toList();
    final runnerUpCategories = achievements.where((a) => a.rank == 2).toList();
    final thirdCategories = achievements.where((a) => a.rank == 3).toList();

    // If no real achievements, find categories with most wins
    final hasAchievements = championCategories.isNotEmpty ||
        runnerUpCategories.isNotEmpty ||
        thirdCategories.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Thành tích nổi bật',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasAchievements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 40, color: colors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có thành tích nào',
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Quán quân
            if (championCategories.isNotEmpty) ...[
              _buildMedalItem(
                colors: colors,
                medal: '🥇',
                title: 'Quán quân',
                count: championCategories.length,
                categories: championCategories.map((a) => a.tournamentName).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Á quân
            if (runnerUpCategories.isNotEmpty) ...[
              _buildMedalItem(
                colors: colors,
                medal: '🥈',
                title: 'Á quân',
                count: runnerUpCategories.length,
                categories: runnerUpCategories.map((a) => a.tournamentName).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Hạng ba
            if (thirdCategories.isNotEmpty) ...[
              _buildMedalItem(
                colors: colors,
                medal: '🥉',
                title: 'Hạng ba',
                count: thirdCategories.length,
                categories: thirdCategories.map((a) => a.tournamentName).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMedalItem({
    required AppColorsExtension colors,
    required String medal,
    required String title,
    required int count,
    required List<String> categories,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count bộ môn · ${categories.take(2).join(', ')}${categories.length > 2 ? '...' : ''}',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ELO CHART ─────────────────────────────────────────────────────
  Widget _buildEloChart(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final userId = profile.id;

    if (userId.isEmpty) {
      return _buildEmptyPlaceholder(colors, Icons.show_chart_outlined, 'Không có dữ liệu người dùng');
    }

    final query = (
      userId: userId,
      categoryId: null as String?,
      scope: null as String?,
      communityId: null as String?,
      limit: 50,
      cursor: null,
    );
    final historyAsync = ref.watch(eloHistoryProvider(query));
    final history = historyAsync.asData?.value ?? [];
    final currentElo = profile.ranks.isNotEmpty ? profile.ranks.first.eloPoints : 1000;
    final tierName = profile.ranks.isNotEmpty ? profile.ranks.first.tierName : null;
    final userName = profile.fullName.isNotEmpty ? profile.fullName : 'Người dùng';

    // Build chart data points from history
    List<(String, int)> chartData;
    if (history.isNotEmpty) {
      final sorted = List<EloHistoryLog>.from(history)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      chartData = sorted.map((h) {
        final date = DateTime.tryParse(h.createdAt) ?? DateTime.now();
        return (DateFormat('dd/MM').format(date), h.newElo);
      }).toList();
    } else {
      chartData = [];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EloProgressChart(
            data: chartData,
            currentElo: currentElo,
            tierName: tierName,
            height: 180,
            onHistoryEmpty: const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EloHistoryScreen(
                      userId: userId,
                      userName: userName,
                      avatarUrl: profile.avatarUrl,
                      currentElo: currentElo,
                      tierName: tierName,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.history_rounded, size: 16, color: AppTheme.primary),
              label: Text(
                'Xem lịch sử chi tiết',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DETAILED STATS ───────────────────────────────────────────────
  Widget _buildDetailedStats(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final totalMatches = profile.ranks.fold<int>(0, (sum, r) => sum + r.matchesPlayed);
    final totalWins = profile.ranks.fold<int>(0, (sum, r) => sum + r.matchesWon);
    final totalLosses = totalMatches - totalWins;
    final winRate = totalMatches > 0 ? (totalWins / totalMatches * 100).round() : 0;
    final totalElo = profile.ranks.fold<int>(0, (sum, r) => sum + r.eloPoints);
    final avgElo = profile.ranks.isNotEmpty ? (totalElo / profile.ranks.length).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _detailStatItem(colors, Icons.sports_rounded, 'Bộ môn', '${profile.ranks.length}'),
              _detailStatItem(colors, Icons.emoji_events_rounded, 'Tổng ELO', '$totalElo'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _detailStatItem(colors, Icons.show_chart_rounded, 'ELO TB', '$avgElo'),
              _detailStatItem(colors, Icons.check_circle_outline, 'Tỉ lệ thắng', '$winRate%'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _detailStatItem(colors, Icons.sports_score_rounded, 'Tổng trận', '$totalMatches'),
              _detailStatItem(colors, Icons.thumb_up_alt_outlined, 'Thắng', '$totalWins'),
              _detailStatItem(colors, Icons.thumb_down_alt_outlined, 'Thua', '$totalLosses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailStatItem(AppColorsExtension colors, IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: colors.textMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── COVER ──────────────────────────────────────────────────
  Widget _buildCoverSection(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final hasCover = profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: hasCover
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: hasCover
              ? Image.network(profile.coverUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _coverGradient(),
                )
              : _coverGradient(),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, colors.bgDark.withValues(alpha: 0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _coverGradient() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
        return 'Trưởng nhóm';
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

  // ─── USER INFO HEADER ───────────────────────────────────────
  Widget _buildUserInfoHeader(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final roleText = _formatUserRole(null); // default fallback
    final featuredRank = profile.ranks.where((rank) => rank.matchesPlayed > 0).fold<UserPublicRank?>(
      null,
      (best, rank) => best == null || rank.eloPoints > best.eloPoints ? rank : best,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          RankAvatar(
            imageUrl: profile.avatarUrl,
            name: profile.fullName,
            elo: featuredRank?.eloPoints ?? 0,
            tierName: featuredRank?.tierName,
            matchesPlayed: featuredRank?.matchesPlayed ?? 0,
            size: 80,
            ringWidth: 3,
          ),
          const SizedBox(width: 16),
          // Name + Role + Bio + Gender
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.fullName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF22C55E)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        roleText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (profile.gender != null && profile.gender!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(profile.gender == 'Nam' ? Icons.male_rounded : Icons.female_rounded, size: 14, color: colors.textMuted),
                      const SizedBox(width: 3),
                      Text(profile.gender!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ],
                  ],
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.bio!,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS OVERVIEW ─────────────────────────────────────────
  Widget _buildStatsOverview(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final totalMatches = profile.ranks.fold<int>(0, (sum, r) => sum + r.matchesPlayed);
    final totalWins = profile.ranks.fold<int>(0, (sum, r) => sum + r.matchesWon);
    final totalLosses = totalMatches - totalWins;
    final winRate = totalMatches > 0 ? (totalWins / totalMatches * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _statItem(colors, '${profile.ranks.length}', 'Bộ môn'),
          _statDivider(colors),
          _statItem(colors, '$totalMatches', 'Tổng trận'),
          _statDivider(colors),
          _statItem(colors, '$totalWins', 'Thắng'),
          _statDivider(colors),
          _statItem(colors, '$totalLosses', 'Thua'),
          _statDivider(colors),
          _statItem(colors, '$winRate%', 'Tỉ lệ'),
        ],
      ),
    );
  }

  Widget _statItem(AppColorsExtension colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statDivider(AppColorsExtension colors) {
    return Container(width: 1, height: 32, color: colors.border.withValues(alpha: 0.5));
  }

  // ─── RANK CARD ──────────────────────────────────────────────
  Widget _buildRankCard(BuildContext context, UserPublicRank rank, AppColorsExtension colors) {
    final palette = TierPalette.fromElo(rank.eloPoints, rank.tierName);
    final wr = rank.matchesPlayed > 0 ? (rank.matchesWon / rank.matchesPlayed * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.bgCard, colors.bgSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sports_tennis_rounded, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(rank.categoryName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: palette.soft, borderRadius: BorderRadius.circular(8), border: Border.all(color: palette.color.withValues(alpha: 0.3))),
                child: Text(rank.tierName ?? 'Chưa xếp hạng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: palette.color)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ELO', style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${rank.eloPoints}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: palette.color)),
                  ],
                ),
              ),
              _statBox('Trận', '${rank.matchesPlayed}', colors),
              _statBox('Thắng', '${rank.matchesWon}', colors),
              _statBox('Tỉ lệ', '$wr%', colors),
            ],
          ),
          if (rank.matchesPlayed > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (wr / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(wr >= 60 ? colors.success : palette.color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 9, color: colors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── EMPTY / PLACEHOLDER ────────────────────────────────────
  Widget _buildNoRank(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text('Chưa có dữ liệu xếp hạng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(AppColorsExtension colors, IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusLarge), border: Border.all(color: colors.border)),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: colors.textMuted)),
        ],
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────
  Widget _sectionTitle(AppColorsExtension colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildError(BuildContext context, AppColorsExtension colors, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text('Không thể tải thông tin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => context.go('/home'), child: const Text('Về trang chủ')),
          ],
        ),
      ),
    );
  }

}

// ─── SHIMMER ───────────────────────────────────────────────────
class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.border,
      highlightColor: colors.bgSurface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: Container(color: colors.border),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 160, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                          const SizedBox(height: 8),
                          Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 24),
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 24),
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
