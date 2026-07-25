import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:app_quanly_giaidau/core/widgets/province_picker.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String selectedSport;
  const LeaderboardScreen({super.key, this.selectedSport = 'all'});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedCategory = 'all';
  String _selectedMatchType = 'SINGLES';
  String? _selectedGender = 'MALE';
  String? _selectedProvince;
  final TextEditingController _searchCtrl = TextEditingController();
  final String _query = '';
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedSport;
  }

  @override
  void didUpdateWidget(covariant LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSport != widget.selectedSport) {
      setState(() {
        _selectedCategory = widget.selectedSport;
      });
    }
  }

  RankingQuery get _rankingQuery => (
    categoryId: _selectedCategory,
    matchType: _selectedMatchType,
    genderRestriction: _selectedGender,
    provinceCode: _selectedProvince,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

            // Xử lý xác định categoryId thực tế
            String effectiveCategoryId = _selectedCategory;
            if (effectiveCategoryId == 'all' || effectiveCategoryId.isEmpty) {
              effectiveCategoryId = categories.first.id;
            } else {
              final found = categories.firstWhere(
                (c) => c.id == effectiveCategoryId || c.slug.toLowerCase() == effectiveCategoryId.toLowerCase(),
                orElse: () => categories.first,
              );
              effectiveCategoryId = found.id;
            }

            final query = (
              categoryId: effectiveCategoryId,
              matchType: _selectedMatchType,
              genderRestriction: _selectedGender,
              provinceCode: _selectedProvince,
            );

            final rankingsAsync = ref.watch(rankingsProvider(query));
            final tiersAsync = ref.watch(eloTiersProvider(effectiveCategoryId));

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 160),
                  _buildRankingFilters(colors),
                  const SizedBox(height: 10),
                  _buildProvinceFilter(colors),
                  const SizedBox(height: 12),
                  tiersAsync.when(
                    data: (tiers) {
                      final myElo = rankingsAsync.asData?.value
                          .where((r) => r.userId == currentUserId)
                          .firstOrNull?.eloPoints;
                      return TierLegendView(tiers: tiers, highlightElo: myElo);
                    },
                    loading: () => const SizedBox(height: 52),
                    error: (context, error) => const SizedBox(height: 52),
                  ),
                  const SizedBox(height: 8),
                  rankingsAsync.when(
                    data: (rankings) => _buildRankingsList(
                      rankings,
                      tiersAsync.asData?.value ?? <EloTier>[],
                      colors,
                      isAuth,
                      currentUserId,
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _emptyState(
                      context,
                      icon: Icons.cloud_off_rounded,
                      title: 'Không thể tải bảng xếp hạng',
                      subtitle: '$e',
                      onRetry: () => ref.refresh(rankingsProvider(_rankingQuery)),
                    ),
                  ),
                ],
              ),
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



  String _formatLabel(String matchType, String? gender) {
    if (matchType == 'SINGLES' && gender == 'MALE') return 'Đơn nam';
    if (matchType == 'SINGLES' && gender == 'FEMALE') return 'Đơn nữ';
    if (matchType == 'DOUBLES' && gender == 'MALE') return 'Đôi nam';
    if (matchType == 'DOUBLES' && gender == 'FEMALE') return 'Đôi nữ';
    if (matchType == 'MIXED_DOUBLES') return 'Đôi nam nữ';
    return 'ELO toàn quốc';
  }

  Widget _buildRankingFilters(AppColorsExtension colors) {
    const formats = [
      ('SINGLES', 'MALE', 'Đơn nam'),
      ('SINGLES', 'FEMALE', 'Đơn nữ'),
      ('DOUBLES', 'MALE', 'Đôi nam'),
      ('DOUBLES', 'FEMALE', 'Đôi nữ'),
      ('MIXED_DOUBLES', 'MIXED', 'Đôi nam nữ'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: formats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final format = formats[index];
          final selected = _selectedMatchType == format.$1 &&
              _selectedGender == format.$2;
          return ChoiceChip(
            label: Text(format.$3),
            selected: selected,
            onSelected: (_) => setState(() {
              _selectedMatchType = format.$1;
              _selectedGender = format.$2;
            }),
            showCheckmark: false,
            selectedColor: AppTheme.primary,
            backgroundColor: colors.bgCard,
            side: BorderSide(
              color: selected ? AppTheme.primary : colors.border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  // ─── Province filter ───────────────────────────────────────────────────
  Widget _buildProvinceFilter(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 16, color: colors.textMuted),
          const SizedBox(width: 8),
          Text(
            'Tỉnh/Thành:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProvince,
                  isExpanded: true,
                  hint: Text('Tất cả', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                  icon: Icon(Icons.arrow_drop_down_rounded, size: 20, color: colors.textMuted),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                  dropdownColor: colors.bgCard,
                  onChanged: (val) => setState(() => _selectedProvince = val),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tất cả', style: TextStyle(color: colors.textSecondary)),
                    ),
                    ...ProvinceData.all.map((p) => DropdownMenuItem<String>(
                      value: p.code,
                      child: Text(p.name),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                  'Vận động viên có thể nằm ngoài Top 100 hoặc chưa tham gia giải đấu.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                  textAlign: TextAlign.center,
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
            onTap: () => context.go('/profile/user/${r.userId}'),
          );
        },
      );
    }

    final formatStr = _formatLabel(_selectedMatchType, _selectedGender);
    final top4_10 = rankings.length > 3
        ? rankings.sublist(3, rankings.length < 10 ? rankings.length : 10)
        : <PlayerRanking>[];
    final top11_100 = rankings.length > 10 ? rankings.sublist(10) : <PlayerRanking>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bục vinh danh Top 1 - 3 (luôn hiện bục vinh danh)
        PodiumView(
          rankings: rankings,
          tiers: tierList,
          formatLabel: formatStr,
        ),
        // Section 2: Top 4 - 10
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top 4 - 10 • $formatStr',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Xuất sắc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (top4_10.isNotEmpty)
          ...top4_10.map(
            (r) => RankingRow(
              ranking: r,
              tiers: tierList,
              isMe: isAuth && r.userId == currentUserId,
              formatLabel: formatStr,
              onTap: () => context.go('/profile/user/${r.userId}'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Text(
                'Chưa có vận động viên ở Top 4 - 10',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),

        // Section 3: Hạng 11 - 100
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hạng 11 - 100 • $formatStr',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Toàn quốc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (top11_100.isNotEmpty)
          ...top11_100.map(
            (r) => RankingRow(
              ranking: r,
              tiers: tierList,
              isMe: isAuth && r.userId == currentUserId,
              formatLabel: formatStr,
              onTap: () => context.go('/profile/user/${r.userId}'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Text(
                'Chưa có vận động viên ở Hạng 11 - 100',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
        if (isAuth && currentUserId != null)
          _buildStickyMeCard(rankings, tierList, colors, currentUserId),
        const SizedBox(height: 100),
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
