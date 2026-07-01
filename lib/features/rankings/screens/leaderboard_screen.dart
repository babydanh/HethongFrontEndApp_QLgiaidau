import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/podium_view.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/ranking_row.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_legend_view.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/user_stats_card.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedCategory = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  IconData _getSportIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'badminton':
        return Icons.sports_kabaddi;
      case 'tennis':
        return Icons.sports_tennis;
      case 'pickleball':
        return Icons.sports_handball;
      case 'table-tennis':
      case 'table_tennis':
        return Icons.sports_baseball_outlined;
      default:
        return Icons.sports_rounded;
    }
  }

  void _scrollToRank(int rankIndex, int totalCount) {
    if (!_scrollCtrl.hasClients) return;
    // Ước lượng vị trí: mỗi row ~ 62px + podium ~ 200px + header.
    final podiumOffset = totalCount >= 3 ? 230.0 : 0.0;
    final target = podiumOffset + (rankIndex - (totalCount >= 3 ? 3 : 0)) * 62.0;
    _scrollCtrl.animateTo(
      target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final authState = ref.watch(authProvider);
    final isAuth = authState.isAuthenticated;
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.asData?.value.id;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: SafeArea(
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return _emptyState(
                context,
                icon: Icons.sports_rounded,
                title: 'Không có môn thể thao',
                subtitle: 'Chưa có môn thể thao nào được định nghĩa.',
                onRetry: () => ref.refresh(categoriesProvider),
              );
            }

            // Đặt mặc định category đầu tiên.
            if (_selectedCategory == 'all' ||
                !categories.any((c) => c.id == _selectedCategory)) {
              final defaultId = categories.first.id;
              Future.microtask(() {
                if (mounted) setState(() => _selectedCategory = defaultId);
              });
            }

            final rankingsAsync = _selectedCategory == 'all'
                ? const AsyncValue<List<PlayerRanking>>.loading()
                : ref.watch(rankingsProvider(_selectedCategory));
            final tiersAsync = ref.watch(eloTiersProvider(_selectedCategory));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                const SizedBox(height: 8),
                _buildSportChips(categories, colors),
                const SizedBox(height: 12),
                _buildSearchBar(colors),
                const SizedBox(height: 12),
                tiersAsync.when(
                  data: (tiers) {
                    final myElo = rankingsAsync.asData?.value
                        .where((r) => r.userId == currentUserId)
                        .firstOrNull?.eloPoints;
                    return TierLegendView(tiers: tiers, highlightElo: myElo);
                  },
                  loading: () => const SizedBox(height: 52),
                  error: (_, __) => const SizedBox(height: 52),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: rankingsAsync.when(
                    data: (rankings) => _buildRankingsList(
                      rankings,
                      tiersAsync.asData?.value ?? <EloTier>[],
                      colors,
                      isAuth,
                      currentUserId,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _emptyState(
                      context,
                      icon: Icons.cloud_off_rounded,
                      title: 'Không thể tải bảng xếp hạng',
                      subtitle: '$e',
                      onRetry: () => ref.refresh(rankingsProvider(_selectedCategory)),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _emptyState(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'Lỗi tải danh sách môn thể thao',
            subtitle: e.toString(),
            onRetry: () => ref.refresh(categoriesProvider),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Top 100 · ELO toàn quốc',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sport chips ───────────────────────────────────────────────────────
  Widget _buildSportChips(List categories, AppColorsExtension colors) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final selected = _selectedCategory == c.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : colors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getSportIcon(c.slug),
                    size: 13,
                    color: selected ? Colors.white : colors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : colors.textSecondary,
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

  // ─── Search bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.trim()),
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tìm vận động viên, xem hạng của họ...',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ─── Rankings list ─────────────────────────────────────────────────────
  Widget _buildRankingsList(
    List<PlayerRanking> rankings,
    List<EloTier> tiers,
    AppColorsExtension colors,
    bool isAuth,
    String? currentUserId,
  ) {
    final tierList = tiers;
    final lowerQuery = _query.toLowerCase();

    // Lọc theo từ khoá tìm kiếm.
    final filtered = _query.isEmpty
        ? rankings
        : rankings
            .where((r) => r.fullName.toLowerCase().contains(lowerQuery))
            .toList();

    // Trường hợp đang tìm kiếm: hiện danh sách kết quả + nhãn "hạng X / top 100".
    if (_query.isNotEmpty) {
      if (filtered.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_rounded, size: 48, color: colors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy "$_query"',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vận động viên có thể nằm ngoài Top 100.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final r = filtered[i];
          return RankingRow(
            ranking: r,
            tiers: tierList,
            isMe: isAuth && r.userId == currentUserId,
            highlight: true,
            onTap: () => _scrollToRank(r.rank, rankings.length),
          );
        },
      );
    }

    // Không tìm kiếm: podium + list từ hạng 4.
    final hasPodium = rankings.length >= 3;
    final rest = hasPodium ? rankings.sublist(3) : rankings;

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: 1 + rest.length + (isAuth ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              if (hasPodium) {
                return PodiumView(rankings: rankings, tiers: tierList);
              }
              return const SizedBox(height: 8);
            }
            if (isAuth && currentUserId != null && index == 1 + rest.length) {
              final myRank = rankings.where((r) => r.userId == currentUserId).firstOrNull;
              if (myRank != null) {
                return UserStatsCard(ranking: myRank, tiers: tierList);
              }
              return const SizedBox.shrink();
            }
            final restIndex = index - 1;
            if (restIndex >= rest.length) return const SizedBox.shrink();
            final r = rest[restIndex];
            return RankingRow(
              ranking: r,
              tiers: tierList,
              isMe: isAuth && r.userId == currentUserId,
              onTap: () {},
            );
          },
        ),
        // Card "Bạn" dán đáy khi không tìm kiếm.
        if (isAuth && currentUserId != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyMeCard(rankings, tierList, colors, currentUserId),
          ),
      ],
    );
  }

  Widget _buildStickyMeCard(
    List<PlayerRanking> rankings,
    List<EloTier> tiers,
    AppColorsExtension colors,
    String currentUserId,
  ) {
    final myRank = rankings.where((r) => r.userId == currentUserId).firstOrNull;
    if (myRank == null) {
      // Người dùng chưa có rank trong top 100 → hiện card mời thi đấu.
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: colors.textMuted, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bạn chưa có hạng trong Top 100. Tham gia giải đấu để được xếp hạng!',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return UserStatsCard(ranking: myRank, tiers: tiers);
  }

  // ─── Empty / error state ───────────────────────────────────────────────
  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRetry,
  }) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
