import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';

class ClubRankingWidget extends ConsumerStatefulWidget {
  final String clubId;
  final bool compact;

  /// Các môn thể thao CLB đã đăng ký (key như 'pickleball', 'tennis'...).
  /// Nếu có, bộ lọc Môn chỉ hiện các môn này (giống web dùng
  /// `community.categories`); rỗng/null → hiện toàn bộ môn toàn cục.
  final List<String>? clubSportKeys;

  const ClubRankingWidget({
    super.key,
    required this.clubId,
    this.compact = false,
    this.clubSportKeys,
  });

  @override
  ConsumerState<ClubRankingWidget> createState() => _ClubRankingWidgetState();
}

class _ClubRankingWidgetState extends ConsumerState<ClubRankingWidget> {
  List<PlayerRanking>? _rankings;
  bool _loading = true;
  String? _error;
  String _selectedMatchType = 'SINGLES';
  String _selectedGender = 'MALE';
  String? _selectedCategoryId;
  List<dynamic> _availableCategories = const [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _pollingTimer;

  /// Số bộ lọc đang lệch mặc định (để hiện chấm badge trên icon bộ lọc).
  int get _activeFilterCount =>
      (_selectedMatchType != 'SINGLES' ? 1 : 0) +
      (_selectedGender != 'MALE' ? 1 : 0) +
      (_selectedCategoryId != null &&
              _availableCategories.isNotEmpty &&
              _selectedCategoryId != _availableCategories.first.id
          ? 1
          : 0);

  @override
  void initState() {
    super.initState();
    _fetchRankings();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchRankings(showLoading: false),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRankings({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final dio = ref.read(dioProvider);
      final allCategories = await ref.read(categoriesProvider.future);
      // Lọc Môn theo setting CLB (clubSportKeys), fallback toàn bộ nếu không
      // khớp — giống web dùng community.categories.
      var categories = allCategories;
      final clubKeys = widget.clubSportKeys;
      if (clubKeys != null && clubKeys.isNotEmpty) {
        final norm = clubKeys
            .map((k) => k.toLowerCase().replaceAll(' ', ''))
            .where((k) => k.isNotEmpty)
            .toSet();
        final matched = allCategories.where((c) {
          final slug = c.slug.toLowerCase().replaceAll(' ', '');
          final name = c.name.toLowerCase().replaceAll(' ', '');
          return norm.contains(slug) || norm.contains(name);
        }).toList();
        categories = matched;
      }
      _availableCategories = categories;
      final categoryId = _selectedCategoryId ??
          (categories.isNotEmpty ? categories.first.id : null);
      if (categoryId == null || categoryId.isEmpty) {
        _selectedCategoryId = null;
      }
      _selectedCategoryId = categoryId;
      final selectedCategory = categories
          .cast<dynamic>()
          .where((c) => c.id == categoryId)
          .firstOrNull;
      final categoryLabel = selectedCategory == null
          ? ''
          : '${selectedCategory.slug} ${selectedCategory.name}'.toLowerCase();
      final isFootball = categoryLabel.contains('football') ||
          categoryLabel.contains('bóng đá') ||
          categoryLabel.contains('bong da');
      if (isFootball && categoryId != null && categoryId.isNotEmpty) {
        final response = await dio.get(
          '/rankings/football-teams',
          queryParameters: {
            'categoryId': categoryId,
            'limit': widget.compact ? 3 : 20,
          },
        );
        final raw = response.data;
        final dataList = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? const [])
            : (raw as List<dynamic>? ?? const []);
        final teams = dataList.map((item) {
          final json = item as Map<String, dynamic>;
          final name =
              (json['teamName'] ?? json['team_name'] ?? 'Đội bóng').toString();
          return PlayerRanking(
            id: (json['id'] ?? json['teamId'] ?? name).toString(),
            userId: '',
            fullName: name,
            avatarUrl:
                json['logoUrl']?.toString() ?? json['logo_url']?.toString(),
            categoryId: categoryId,
            matchType: 'SINGLES',
            genderRestriction: 'MIXED',
            eloPoints:
                ((json['eloPoints'] ?? json['elo_points'] ?? 1000) as num)
                    .toInt(),
            peakElo: ((json['peakElo'] ?? json['peak_elo']) as num?)?.toInt(),
            matchesPlayed:
                ((json['matchesPlayed'] ?? json['matches_played'] ?? 0)
                        as num)
                    .toInt(),
            matchesWon:
                ((json['matchesWon'] ?? json['matches_won'] ?? 0) as num)
                    .toInt(),
            winStreak:
                ((json['winStreak'] ?? json['win_streak'] ?? 0) as num)
                    .toInt(),
            tierName: json['tierName']?.toString() ?? '',
          );
        }).toList();
        if (mounted) {
          setState(() {
            _rankings = teams;
            _loading = false;
            _error = null;
          });
        }
        return;
      }
      final queryParams = <String, dynamic>{
        'communityId': widget.clubId,
        'scope': 'COMMUNITY',
        'matchType': _selectedMatchType,
        'genderRestriction': _selectedGender,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        'limit': widget.compact ? 3 : 20,
      };
      final response = await dio.get(
        '/rankings',
        queryParameters: queryParams,
      );
      final raw = response.data;
      final List<dynamic> dataList = raw is Map<String, dynamic>
          ? (raw['data'] as List<dynamic>? ?? [])
          : (raw as List<dynamic>? ?? []);
      var rankings = dataList
          .map((json) => PlayerRanking.fromJson(json as Map<String, dynamic>))
          .toList();
      if (rankings.isEmpty && _selectedMatchType == 'SINGLES') {
        final membersResponse = await dio.get('/communities/${widget.clubId}/members');
        final rawMembers = membersResponse.data is Map<String, dynamic>
            ? (membersResponse.data['data'] as List<dynamic>? ?? const [])
            : (membersResponse.data as List<dynamic>? ?? const []);
        rankings = rawMembers
            .map((item) => CommunityMemberModel.fromJson(item as Map<String, dynamic>))
            .where((member) => member.status == 'JOINED')
            .map(
              (member) => PlayerRanking(
                id: 'community-member-${member.id}',
                userId: member.userId,
                fullName: member.userFullName ?? member.userEmail ?? 'Thành viên',
                avatarUrl: member.userAvatarUrl,
                categoryId: categoryId,
                matchType: _selectedMatchType,
                genderRestriction: _selectedGender,
                eloPoints: 1000,
                tierName: 'Chưa xếp hạng',
              ),
            )
            .toList();
      }
      if (mounted) {
        setState(() {
          _rankings = rankings;
          _loading = false;
          _error = null;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Không early-return khi rỗng/lỗi: header + thanh tìm kiếm + icon bộ lọc
    // phải LUÔN hiện để người dùng đổi được bộ lọc (chỉ phần danh sách
    // chuyển sang khung "Chưa có dữ liệu" bên dưới).
    final allRankings = _rankings ?? const <PlayerRanking>[];
    final query = _searchQuery.trim().toLowerCase();
    final rankings = query.isEmpty
        ? allRankings
        : allRankings
            .where((ranking) => ranking.fullName.toLowerCase().contains(query))
            .toList();
    final filteredRankings = rankings;
    final isSearching = query.isNotEmpty;
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id;
    final myRanking = currentUserId == null
        ? null
        : allRankings.where((ranking) => ranking.userId == currentUserId).firstOrNull;
    final myRank = myRanking == null ? null : allRankings.indexOf(myRanking) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──
        Row(
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Xếp hạng CLB',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Podium Row (Top 3) ──
        if (!widget.compact) ...[
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm thành viên trong top 20...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              filled: true,
              fillColor: colors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.border),
              ),
              suffixIcon: IconButton(
                tooltip: 'Bộ lọc xếp hạng',
                visualDensity: VisualDensity.compact,
                onPressed: _openFilterSheet,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.tune_rounded, size: 19),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (myRanking != null) ...[
            const SizedBox(height: 8),
            _buildMyRankingCard(myRanking, myRank, colors),
          ],
        ],
        // ── Nội dung: dữ liệu / trống / lỗi (search + filter luôn hiện) ──
        if (_error != null)
          _buildEmptyRanking(colors, error: true)
        else if (allRankings.isEmpty)
          _buildEmptyRanking(colors)
        else if (filteredRankings.isEmpty)
          _buildEmptyRanking(colors, searching: true)
        else ...[
          if (!isSearching) _buildPodiumRow(filteredRankings),
          // ── Ranks 4-10 List ──
          if (!widget.compact && filteredRankings.length > (isSearching ? 0 : 3)) ...[
            const SizedBox(height: 10),
            ...List.generate(filteredRankings.length - (isSearching ? 0 : 3), (i) {
              final index = isSearching ? i : i + 3;
              final r = filteredRankings[index];
              final actualRank = allRankings.indexOf(r) + 1;
              return _buildListRow(r, actualRank, colors);
            }),
          ],
        ],
        // ── Xem tất cả (compact mode) ──
        if (!widget.compact) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tự động cập nhật mỗi 30 giây',
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
          ),
        ],

        if (widget.compact) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/community/${widget.clubId}?tab=rankings'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  'Xem tất cả xếp hạng →',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text('Bộ lọc xếp hạng', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.colors.textPrimary))), IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded))]),
                Text('Chọn môn, thể thức và giới tính', style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
                const SizedBox(height: 16),
                if (_availableCategories.length > 1) ...[
                  Text('Môn thể thao', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: _availableCategories.map((category) => ChoiceChip(label: Text(category.name), selected: _selectedCategoryId == category.id, onSelected: (_) { setState(() => _selectedCategoryId = category.id); setSheetState(() {}); _fetchRankings(); })).toList()),
                  const SizedBox(height: 16),
                ],
                Text('Thể thức', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [_filterChoice('Đơn', 'SINGLES', setSheetState), _filterChoice('Đôi', 'DOUBLES', setSheetState), _filterChoice('Đôi nam nữ', 'MIXED_DOUBLES', setSheetState)]),
                if (_selectedMatchType != 'MIXED_DOUBLES') ...[
                  const SizedBox(height: 16),
                  Text('Giới tính', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [_genderChoice('Nam', 'MALE', setSheetState), _genderChoice('Nữ', 'FEMALE', setSheetState)]),
                ],
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Áp dụng'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChoice(String label, String value, StateSetter setSheetState) => ChoiceChip(label: Text(label), selected: _selectedMatchType == value, onSelected: (_) { setState(() { _selectedMatchType = value; if (value == 'MIXED_DOUBLES') _selectedGender = 'MALE'; }); setSheetState(() {}); _fetchRankings(); });

  Widget _genderChoice(String label, String value, StateSetter setSheetState) => ChoiceChip(label: Text(label), selected: _selectedGender == value, onSelected: (_) { setState(() => _selectedGender = value); setSheetState(() {}); _fetchRankings(); });

  // ─── Gender Filter ───

  Widget _buildMyRankingCard(
    PlayerRanking ranking,
    int? rank,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Text(
              rank == null ? '—' : '#$rank',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xếp hạng của bạn', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                Text(ranking.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${ranking.eloPoints} ELO', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
              if (ranking.winStreak > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text('${ranking.winStreak}', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              if (ranking.peakElo != null)
                Text('Peak: ${ranking.peakElo}', style: TextStyle(color: colors.textMuted, fontSize: 9, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty / Error card (hiện dưới thanh tìm kiếm khi không có dữ liệu) ───

  Widget _buildEmptyRanking(
    AppColorsExtension colors, {
    bool error = false,
    bool searching = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: i == 1 ? 52 : 44,
              height: i == 1 ? 52 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderLight, width: 1.5),
                color: colors.bgSurface,
              ),
              child: Center(
                child: Text(
                  '#${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 10),
          Text(
            error
                ? 'Không thể tải xếp hạng'
                : searching
                    ? 'Không tìm thấy thành viên'
                    : 'Chưa có dữ liệu xếp hạng',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text(
            error
                ? 'Vui lòng thử lại sau'
                : 'Chọn bộ lọc khác hoặc tham gia thi đấu để có ELO',
            style: TextStyle(
              fontSize: 11,
              color: colors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Podium ───

  Widget _buildPodiumRow(List<PlayerRanking> rankings) {
    final rank1 = rankings[0];
    final rank2 = rankings.length > 1 ? rankings[1] : null;
    final rank3 = rankings.length > 2 ? rankings[2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 164,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Silver (rank 2) - left
          if (rank2 != null)
            Expanded(flex: 3, child: _buildPodiumCard(rank2, 2, isCenter: false))
          else
            const Expanded(flex: 3, child: SizedBox()),

          const SizedBox(width: 6),

          // Gold (rank 1) - center, tallest
          Expanded(flex: 4, child: _buildPodiumCard(rank1, 1, isCenter: true)),

          const SizedBox(width: 6),

          // Bronze (rank 3) - right
          if (rank3 != null)
            Expanded(flex: 3, child: _buildPodiumCard(rank3, 3, isCenter: false))
          else
            const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
    PlayerRanking player,
    int rank, {
    required bool isCenter,
  }) {
    final colors = context.colors;
    final medalColors = _medalColors(rank);
    final avatarSize = isCenter ? 42.0 : 34.0;
    final tierInfo = _getEloTierInfo(player);

    return Container(
      height: isCenter ? 160 : 138,
      padding: EdgeInsets.symmetric(
        horizontal: 6,
        vertical: isCenter ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: medalColors.bg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: medalColors.border.withValues(alpha: 0.4),
          width: isCenter ? 1.5 : 1,
        ),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: medalColors.border.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: medalColors.border.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rank == 1
                      ? Icons.emoji_events_rounded
                      : rank == 2
                          ? Icons.military_tech_rounded
                          : Icons.workspace_premium_rounded,
                  size: isCenter ? 13 : 11,
                  color: medalColors.icon,
                ),
                const SizedBox(width: 2),
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: isCenter ? 11 : 9.5,
                    fontWeight: FontWeight.w900,
                    color: medalColors.icon,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          _buildPodiumAvatars(player, avatarSize),
          const SizedBox(height: 5),

          // Name
          Text(
            player.fullName,
            style: TextStyle(
              fontSize: isCenter ? 11.5 : 10,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),

          // ELO points + Tier badge
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${player.eloPoints}',
                  style: TextStyle(
                    fontSize: isCenter ? 13 : 11,
                    fontWeight: FontWeight.w900,
                    color: medalColors.elo,
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tierInfo.bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tierInfo.borderColor, width: 0.5),
                  ),
                  child: Text(
                    tierInfo.label,
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      color: tierInfo.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Rows 4-10 ───

  Widget _buildListRow(
    PlayerRanking player,
    int rank,
    AppColorsExtension colors,
  ) {
    final winRate = player.matchesPlayed > 0
        ? (player.matchesWon / player.matchesPlayed) * 100
        : 0.0;
    final tierInfo = _getEloTierInfo(player);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 22,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),

          // Đôi hiển thị đủ avatar của cả hai người trong cùng một hạng.
          if (player.partnerName != null) ...[
            _buildMiniAvatar(player.fullName.split(' / ').first, player.avatarUrl, player),
            const SizedBox(width: 2),
            _buildMiniAvatar(player.partnerName!, player.partnerAvatarUrl, player),
          ] else
            _buildMiniAvatar(player.fullName, player.avatarUrl, player),
          const SizedBox(width: 7),

          // Name
          Expanded(
            child: Text(
              player.fullName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),

          // Win rate
          Text(
            '${winRate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(width: 6),

          Text(
            '${player.matchesWon}-${player.matchesPlayed - player.matchesWon}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),

          // ELO points + tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${player.eloPoints}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: tierInfo.bgColor,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: tierInfo.borderColor, width: 0.5),
                  ),
                  child: Text(
                    tierInfo.label,
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w700,
                      color: tierInfo.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Win rate bar
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: winRate / 100,
                    minHeight: 3,
                    backgroundColor: colors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      winRate >= 60
                          ? colors.success
                          : winRate >= 40
                          ? colors.warning
                          : colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(String name, String? avatarUrl, PlayerRanking player) {
    return RankAvatar(
      imageUrl: avatarUrl,
      name: name,
      elo: player.eloPoints,
      tierName: player.tierName,
      matchesPlayed: player.matchesPlayed,
      size: 24,
      ringWidth: 1.5,
    );
  }

  Widget _buildPodiumAvatars(PlayerRanking player, double avatarSize) {
    final firstName = player.fullName.split(' / ').first;
    final avatars = <Widget>[
      _buildMiniAvatar(firstName, player.avatarUrl, player),
    ];
    if (player.partnerName != null) {
      avatars.add(_buildMiniAvatar(player.partnerName!, player.partnerAvatarUrl, player));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: avatars
          .map((avatar) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: FittedBox(child: avatar),
                ),
              ))
          .toList(),
    );
  }

  // ─── Helpers ───

  _MedalColors _medalColors(int rank) {
    switch (rank) {
      case 1:
        return const _MedalColors(
          bg: Color(0xFFFFB300),
          border: Color(0xFFFFB300),
          icon: Color(0xFFFFB300),
          elo: Color(0xFFFFB300),
        );
      case 2:
        return const _MedalColors(
          bg: Color(0xFF9E9E9E),
          border: Color(0xFF9E9E9E),
          icon: Color(0xFF9E9E9E),
          elo: Color(0xFF9E9E9E),
        );
      case 3:
        return const _MedalColors(
          bg: Color(0xFFCD7F32),
          border: Color(0xFFCD7F32),
          icon: Color(0xFFCD7F32),
          elo: Color(0xFFCD7F32),
        );
      default:
        return const _MedalColors(
          bg: Colors.transparent,
          border: Colors.transparent,
          icon: Colors.grey,
          elo: Colors.grey,
        );
    }
  }

  _EloTierInfo _getEloTierInfo(PlayerRanking player) {
    final colors = context.colors;
    final tier = resolveEloTier(elo: player.eloPoints, tierName: player.tierName);
    switch (tier.role) {
      case EloTierRole.s: // Tier S — amber (AppTheme.warning)
        return _EloTierInfo(
          label: tier.label,
          bgColor: colors.warning.withValues(alpha: 0.15),
          textColor: colors.warning,
          borderColor: colors.warning.withValues(alpha: 0.45),
        );
      case EloTierRole.a: // Tier A — emerald (AppTheme.success)
        return _EloTierInfo(
          label: tier.label,
          bgColor: colors.success.withValues(alpha: 0.15),
          textColor: colors.success,
          borderColor: colors.success.withValues(alpha: 0.45),
        );
      case EloTierRole.b: // Tier B — primary (neon)
        return _EloTierInfo(
          label: tier.label,
          bgColor: AppTheme.primary.withValues(alpha: 0.15),
          textColor: AppTheme.primary,
          borderColor: AppTheme.primary.withValues(alpha: 0.45),
        );
      case EloTierRole.c: // Tier C — slate sáng (textSecondary/bgElevated)
        return _EloTierInfo(
          label: tier.label,
          bgColor: colors.bgElevated,
          textColor: colors.textSecondary,
          borderColor: colors.border,
        );
      case EloTierRole.d: // Tier D — slate tối (textMuted/bgSurface)
        return _EloTierInfo(
          label: tier.label,
          bgColor: colors.bgSurface,
          textColor: colors.textMuted,
          borderColor: colors.border,
        );
    }
  }
}

class _MedalColors {
  final Color bg;
  final Color border;
  final Color icon;
  final Color elo;

  const _MedalColors({
    required this.bg,
    required this.border,
    required this.icon,
    required this.elo,
  });
}

class _EloTierInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _EloTierInfo({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}
