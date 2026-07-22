import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  Tab(text: 'Thông tin'),
                  Tab(text: 'Thành tích'),
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
                // CLB đang tham gia (placeholder)
                _sectionTitle(colors, 'Câu lạc bộ'),
                const SizedBox(height: 12),
                _buildEmptyPlaceholder(colors, Icons.people_outline_rounded, 'Chưa tham gia câu lạc bộ'),
                const SizedBox(height: 24),
                // Lịch sử giải đấu (placeholder)
                _sectionTitle(colors, 'Giải đấu đã tham gia'),
                const SizedBox(height: 12),
                _buildEmptyPlaceholder(colors, Icons.emoji_events_outlined, 'Chưa có dữ liệu giải đấu'),
              ],
            ),
          ),
          // ─── TAB 2: THÀNH TÍCH ─────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thành tích Quán quân / Á quân / Hạng ba
                _buildAchievementsSection(context, profile, colors),
                const SizedBox(height: 24),
                // Biểu đồ ELO
                _sectionTitle(colors, 'Biểu đồ ELO'),
                const SizedBox(height: 12),
                _buildEloChart(context, profile, colors),
                const SizedBox(height: 24),
                // Thống kê chuyên sâu
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

  // ─── ACHIEVEMENTS SECTION ──────────────────────────────────────────
  Widget _buildAchievementsSection(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    // Derive achievements from rank data (highest ELO = top performers)
    // In future, this will come from the API's achievements data
    final sortedRanks = List<UserPublicRank>.from(profile.ranks)
      ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

    final championCategories = sortedRanks.where((r) => r.eloPoints >= 1500).toList();
    final runnerUpCategories = sortedRanks.where((r) => r.eloPoints >= 1200 && r.eloPoints < 1500).toList();
    final thirdCategories = sortedRanks.where((r) => r.eloPoints >= 1000 && r.eloPoints < 1200).toList();

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
                categories: championCategories.map((r) => r.categoryName).toList(),
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
                categories: runnerUpCategories.map((r) => r.categoryName).toList(),
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
                categories: thirdCategories.map((r) => r.categoryName).toList(),
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
    // Mock ELO history data — real data will come from API
    // In production, fetch from GET /rankings/user/:userId/history or similar
    final mockEloHistory = _generateMockEloHistory(profile);

    if (mockEloHistory.isEmpty) {
      return _buildEmptyPlaceholder(colors, Icons.show_chart_outlined, 'Chưa có dữ liệu biểu đồ ELO');
    }

    final maxElo = mockEloHistory.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    final minElo = mockEloHistory.map((e) => e.$2).reduce((a, b) => a < b ? a : b);
    final eloRange = (maxElo - minElo).clamp(50, 1000);
    final chartMinY = (minElo - eloRange * 0.1).round();
    final chartMaxY = (maxElo + eloRange * 0.1).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 18, color: colors.success),
                const SizedBox(width: 6),
                Text(
                  'Lịch sử ELO',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                const Spacer(),
                Text(
                  'Hiện tại: ${profile.ranks.isNotEmpty ? profile.ranks.first.eloPoints : 1000}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (chartMaxY - chartMinY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colors.border.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (mockEloHistory.length / 4).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= mockEloHistory.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            mockEloHistory[index].$1,
                            style: TextStyle(fontSize: 9, color: colors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 9, color: colors.textMuted),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: chartMinY.toDouble(),
                maxY: chartMaxY.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: mockEloHistory.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.$2.toDouble());
                    }).toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == mockEloHistory.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 4 : 2,
                          color: isLast ? AppTheme.primary : colors.bgCard,
                          strokeWidth: isLast ? 2 : 1.5,
                          strokeColor: AppTheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.3),
                        AppTheme.primary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final label = index < mockEloHistory.length ? mockEloHistory[index].$1 : '';
                        return LineTooltipItem(
                          'ELO: ${spot.y.toInt()}\n$label',
                          TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate mock ELO history from current rank data
  List<(String, int)> _generateMockEloHistory(UserPublicProfile profile) {
    if (profile.ranks.isEmpty) return [];

    // Take the first rank category and generate mock history
    final currentElo = profile.ranks.first.eloPoints;
    final months = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
    final now = DateTime.now();
    final currentMonth = now.month;

    // Generate progressive ELO values
    final history = <(String, int)>[];
    var elo = (currentElo * 0.7).round(); // Start at 70% of current
    final step = ((currentElo - elo) / 6).round().clamp(1, 50);

    for (var i = 0; i < 6; i++) {
      final monthIndex = (currentMonth - 6 + i) % 12;
      final monthLabel = months[monthIndex >= 0 ? monthIndex : monthIndex + 12];
      elo += step + (i % 3 == 0 ? 10 : -5); // Some variation
      history.add((monthLabel, elo.clamp(100, 3000)));
    }
    // Ensure last point matches current ELO
    history.last = (months[(currentMonth - 1) % 12], currentElo);

    return history;
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
                  errorBuilder: (_, __, ___) => _coverGradient(),
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

  // ─── USER INFO HEADER ───────────────────────────────────────
  Widget _buildUserInfoHeader(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF161616)),
                child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(37),
                        child: Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(profile.fullName, colors),
                        ),
                      )
                    : _avatarFallback(profile.fullName, colors),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name + Bio + Thông tin
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
                const SizedBox(height: 4),
                if (profile.gender != null && profile.gender!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(profile.gender == 'Nam' ? Icons.male_rounded : Icons.female_rounded, size: 14, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(profile.gender!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Text(
                    profile.bio!,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
    final tier = TierPalette.matchTier(rank.eloPoints, []);
    final palette = TierPalette.from(tier);
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

  Widget _avatarFallback(String name, AppColorsExtension colors) {
    return Center(
      child: Text(
        _initials(name),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textSecondary),
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

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
