import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:shimmer/shimmer.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const LiveMatchScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh mỗi 10 giây khi có live match
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: matchesAsync.when(
        data: (matches) => _buildContent(context, matches, tournamentAsync),
        loading: () => _buildShimmerLoading(context),
        error: (e, _) => _buildErrorState(context, e),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // MAIN CONTENT
  // ─────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    List<MatchModel> matches,
    AsyncValue tournamentAsync,
  ) {
    final validMatches = matches.where((m) {
      if (m.status == AppConstants.matchLive || m.status == AppConstants.matchCompleted) return true;
      final hasTeams = m.team1Name.trim() != 'TBD' && m.team2Name.trim() != 'TBD';
      return m.scheduledTime != null && hasTeams;
    }).toList();

    if (validMatches.isEmpty) return _buildEmptyState(context, tournamentAsync);

    final liveMatches =
        validMatches.where((m) => m.status == AppConstants.matchLive).toList();
    final completedMatches =
        validMatches.where((m) => m.status == AppConstants.matchCompleted).toList();
    final upcomingMatches =
        validMatches.where((m) => m.status == AppConstants.matchScheduled).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchesProvider(widget.tournamentId));
        await Future.delayed(const Duration(milliseconds: 100));
      },
      color: context.colors.info,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header Banner ───
          _buildHeaderBanner(context, tournamentAsync,
              liveMatches.length, validMatches.length, validMatches),

          // ─── Live Matches Section ───
          if (liveMatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                icon: Icons.sensors_rounded,
                title: 'Đang thi đấu',
                count: liveMatches.length,
                color: context.colors.error,
                badge: 'LIVE',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => LiveMatchCardV2(
                    match: liveMatches[index],
                    isLive: true,
                    onTap: () => _openMatch(liveMatches[index]),
                  ).animate().slideX(
                        begin: 0.1,
                        duration: 300.ms,
                        delay: (index * 80).ms,
                        curve: Curves.easeOut,
                      ),
                  childCount: liveMatches.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ─── Upcoming Matches Section ───
          if (upcomingMatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                icon: Icons.calendar_today_rounded,
                title: 'Sắp diễn ra',
                count: upcomingMatches.length,
                color: context.colors.info,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => LiveMatchCardV2(
                    match: upcomingMatches[index],
                    onTap: () => _openMatch(upcomingMatches[index]),
                  ).animate().fadeIn(
                        duration: 300.ms,
                        delay: (index * 60).ms,
                      ),
                  childCount: upcomingMatches.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ─── Completed Matches Section ───
          if (completedMatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                icon: Icons.check_circle_outline_rounded,
                title: 'Đã kết thúc',
                count: completedMatches.length,
                color: context.colors.success,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => LiveMatchCardV2(
                    match: completedMatches[index],
                    isCompleted: true,
                    onTap: () => _openMatch(completedMatches[index]),
                  ).animate().fadeIn(
                        duration: 300.ms,
                        delay: (index * 40).ms,
                      ),
                  childCount: completedMatches.length,
                ),
              ),
            ),
          ],

          // Bottom padding
          if (liveMatches.isEmpty &&
              upcomingMatches.isEmpty &&
              completedMatches.isEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 200)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // HEADER BANNER
  // ─────────────────────────────────────────────────────
  Widget _buildHeaderBanner(
    BuildContext context,
    AsyncValue tournamentAsync,
    int liveCount,
    int totalCount,
    List<MatchModel> matches,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tournamentAsync.when(
                        data: (t) => Text(
                          t?.name ?? 'Giải đấu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => const Text(
                          'Đang tải...',
                          style: TextStyle(color: Colors.white70),
                        ),
                        error: (_, __) => const Text(
                          'Giải đấu',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalCount trận đấu',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live count badge
                if (liveCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.error.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$liveCount LIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                          duration: 800.ms,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.sensors_rounded,
                  value: '$liveCount',
                  label: 'Đang đấu',
                  color: context.colors.error,
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  icon: Icons.schedule_rounded,
                  value: '${matches.length - liveCount}',
                  label: 'Còn lại',
                  color: context.colors.info,
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  icon: Icons.check_circle_outline_rounded,
                  value:
                      '${matches.where((m) => m.status == AppConstants.matchCompleted).length}',
                  label: 'Xong',
                  color: context.colors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, AsyncValue tournamentAsync) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchesProvider(widget.tournamentId));
        await Future.delayed(const Duration(milliseconds: 100));
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: tournamentAsync.when(
                      data: (t) => Text(
                        t?.name ?? 'Giải đấu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        'Giải đấu',
                        style: TextStyle(color: Colors.white70),
                      ),
                      error: (_, __) => const Text(
                        'Giải đấu',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.sports_score_rounded,
                      size: 44,
                      color: context.colors.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chưa có trận đấu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chờ ban tổ chức bốc thăm và xếp lịch\nCác trận đấu sẽ xuất hiện tại đây',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      ref.invalidate(matchesProvider(widget.tournamentId));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.colors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.info.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 16, color: context.colors.info),
                          const SizedBox(width: 6),
                          Text(
                            'Tải lại',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.colors.info,
                            ),
                          ),
                        ],
                      ),
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

  // ─────────────────────────────────────────────────────
  // SHIMMER LOADING
  // ─────────────────────────────────────────────────────
  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: context.colors.bgSurface,
        highlightColor: context.colors.bgCard,
        child: Column(
          children: [
            // Banner shimmer
            Container(
              margin: const EdgeInsets.all(16),
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            // Section header shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Card shimmers
            ...List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // ERROR STATE
  // ─────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: context.colors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải trận đấu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(matchesProvider(widget.tournamentId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────
  void _openMatch(MatchModel match) {
    context.push('/live/${match.id}');
  }
}
