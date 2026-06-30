import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/podium_view.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/ranking_row.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/user_stats_card.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedCategory = 'all';

  static const _categories = [
    (key: 'all', label: 'Tất cả', icon: Icons.grid_view_rounded),
    (key: 'badminton', label: 'Cầu lông', icon: Icons.sports_kabaddi),
    (key: 'tennis', label: 'Tennis', icon: Icons.sports_tennis),
    (key: 'pickleball', label: 'Pickleball', icon: Icons.sports_handball),
    (key: 'table_tennis', label: 'Bóng bàn', icon: Icons.circle_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider(_selectedCategory == 'all' ? null : _selectedCategory));
    final authState = ref.watch(authProvider);
    final isAuth = authState.isAuthenticated;
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.asData?.value?.id;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bảng xếp hạng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: -0.3)),
                      Text('ELO Rating toàn quốc', style: TextStyle(fontSize: 12, color: colors.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Sport Filter Chips ──
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final selected = _selectedCategory == c.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : colors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppTheme.primary : colors.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.icon, size: 13, color: selected ? Colors.white : colors.textMuted),
                          const SizedBox(width: 5),
                          Text(c.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : colors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // ── Rankings List ──
            Expanded(
              child: rankingsAsync.when(
                data: (rankings) => ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: rankings.length + 1 + (isAuth ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      if (rankings.length >= 3) return PodiumView(rankings: rankings.take(3).toList());
                      return const SizedBox.shrink();
                    }
                    if (isAuth && currentUserId != null && index == rankings.length + 1) {
                      final myRank = rankings.where((r) => r.userId == currentUserId).firstOrNull;
                      if (myRank != null) return UserStatsCard(ranking: myRank);
                      return const SizedBox.shrink();
                    }
                    final ranking = rankings[index - 1];
                    return RankingRow(ranking: ranking, onTap: () {});
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
                        const SizedBox(height: 16),
                        Text('Không thể tải bảng xếp hạng', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('$e', style: TextStyle(fontSize: 12, color: colors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 20),
                        FilledButton(onPressed: () => ref.refresh(rankingsProvider(_selectedCategory == 'all' ? null : _selectedCategory)), child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
