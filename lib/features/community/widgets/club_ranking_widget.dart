import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';

class ClubRankingWidget extends ConsumerStatefulWidget {
  final String clubId;
  final bool compact;

  const ClubRankingWidget({super.key, required this.clubId, this.compact = false});

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _pollingTimer;

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
      final categories = await ref.read(categoriesProvider.future);
      final categoryId = _selectedCategoryId ??
          (categories.isNotEmpty ? categories.first.id : null);
      if (categoryId == null || categoryId.isEmpty) {
        _selectedCategoryId = null;
      }
      _selectedCategoryId = categoryId;
      final queryParams = <String, dynamic>{
        'communityId': widget.clubId,
        'scope': 'COMMUNITY',
        'matchType': _selectedMatchType,
        'genderRestriction': _selectedGender,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        'limit': widget.compact ? 3 : 20,
      };
      final response = await dio.get(
        '/rankings/leaderboard',
        queryParameters: queryParams,
      );
      final raw = response.data;
      final List<dynamic> dataList = raw is Map<String, dynamic>
          ? (raw['data'] as List<dynamic>? ?? [])
          : (raw as List<dynamic>? ?? []);
      var rankings = dataList
          .map((json) => PlayerRanking.fromJson(json as Map<String, dynamic>))
          .toList();
      if (rankings.isEmpty) {
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

    if (_error != null || _rankings == null || _rankings!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 16, color: context.colors.textSecondary),
              const SizedBox(width: 6),
              Text('Xếp hạng ELO CLB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: context.colors.border),
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
                      border: Border.all(color: context.colors.borderLight, width: 1.5),
                      color: context.colors.bgSurface,
                    ),
                    child: Center(child: Text('#${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textMuted))),
                  )),
                ),
                const SizedBox(height: 10),
                Text('Chưa có dữ liệu xếp hạng', style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
                Text('Tham gia thi đấu để có ELO', style: TextStyle(fontSize: 11, color: context.colors.textMuted.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      );
    }

    final allRankings = _rankings!;
    final query = _searchQuery.trim().toLowerCase();
    final rankings = query.isEmpty
        ? allRankings
        : allRankings
            .where((ranking) => ranking.fullName.toLowerCase().contains(query))
            .toList();
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
              'Xếp hạng ELO CLB',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            // Gender filter tabs
            if (!widget.compact) _buildGenderFilter(),
            if (!widget.compact) const SizedBox(width: 6),
            // Match type filter tabs
            if (!widget.compact) _buildMatchTypeFilter(),
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
            ),
          ),
          if (myRanking != null) ...[
            const SizedBox(height: 8),
            _buildMyRankingCard(myRanking, myRank, colors),
          ],
        ],
        if (!isSearching && rankings.isNotEmpty) _buildPodiumRow(rankings),

        // ── Ranks 4-10 List ──
        if (!widget.compact && rankings.length > (isSearching ? 0 : 3)) ...[
          const SizedBox(height: 10),
          ...List.generate(rankings.length - (isSearching ? 0 : 3), (i) {
            final index = isSearching ? i : i + 3;
            final r = rankings[index];
            final actualRank = allRankings.indexOf(r) + 1;
            return _buildListRow(r, actualRank, colors);
          }),
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
          Text('${ranking.eloPoints} ELO', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _genderTab('Nam', 'MALE'),
          _genderTab('Nữ', 'FEMALE'),
        ],
      ),
    );
  }

  Widget _genderTab(String label, String value) {
    final isActive = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        if (_selectedGender != value) {
          setState(() => _selectedGender = value);
          _fetchRankings();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }

  // ─── Match Type Filter ───

  Widget _buildMatchTypeFilter() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _matchTypeTab('Đơn', 'SINGLES'),
          _matchTypeTab('Đôi', 'DOUBLES'),
        ],
      ),
    );
  }

  Widget _matchTypeTab(String label, String value) {
    final isActive = _selectedMatchType == value;
    return GestureDetector(
      onTap: () {
        if (_selectedMatchType != value) {
          setState(() => _selectedMatchType = value);
          _fetchRankings();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }

  // ─── Podium ───

  Widget _buildPodiumRow(List<PlayerRanking> rankings) {
    final rank1 = rankings[0];
    final rank2 = rankings.length > 1 ? rankings[1] : null;
    final rank3 = rankings.length > 2 ? rankings[2] : null;

    return SizedBox(
      height: 136,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Silver (rank 2) - left
          if (rank2 != null)
            Expanded(child: _buildPodiumCard(rank2, 2, isCenter: false)),
          if (rank2 != null) const SizedBox(width: 5),

          // Gold (rank 1) - center, tallest
          Expanded(flex: 12, child: _buildPodiumCard(rank1, 1, isCenter: true)),

          // Bronze (rank 3) - right
          if (rank3 != null) const SizedBox(width: 5),
          if (rank3 != null)
            Expanded(child: _buildPodiumCard(rank3, 3, isCenter: false)),
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
    final tierInfo = _getEloTierInfo(player.eloPoints);

    return Container(
      height: isCenter ? 128 : 112,
      padding: EdgeInsets.only(
        top: 10,
        left: 6,
        right: 6,
        bottom: isCenter ? 14 : 8,
      ),
      decoration: BoxDecoration(
        color: medalColors.bg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: medalColors.border.withValues(alpha: 0.25),
          width: isCenter ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                rank == 1
                    ? Icons.emoji_events_rounded
                    : rank == 2
                    ? Icons.military_tech_rounded
                    : Icons.workspace_premium_rounded,
                size: isCenter ? 15 : 12,
                color: medalColors.icon,
              ),
              const SizedBox(width: 2),
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isCenter ? 12 : 10,
                  fontWeight: FontWeight.w700,
                  color: medalColors.icon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Avatar
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            backgroundImage:
                player.avatarUrl != null && player.avatarUrl!.isNotEmpty
                ? NetworkImage(player.avatarUrl!)
                : null,
            child: player.avatarUrl == null || player.avatarUrl!.isEmpty
                ? Text(
                    player.fullName.isNotEmpty
                        ? player.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: avatarSize * 0.38,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),

          // Name
          Text(
            player.fullName,
            style: TextStyle(
              fontSize: isCenter ? 11 : 10,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          // ELO points + Tier badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${player.eloPoints}',
                style: TextStyle(
                  fontSize: isCenter ? 14 : 12,
                  fontWeight: FontWeight.w700,
                  color: medalColors.elo,
                ),
              ),
              const SizedBox(width: 4),
              // Tier badge
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
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: tierInfo.textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
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
    final tierInfo = _getEloTierInfo(player.eloPoints);

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

          // Avatar
          CircleAvatar(
            radius: 11,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            backgroundImage:
                player.avatarUrl != null && player.avatarUrl!.isNotEmpty
                ? NetworkImage(player.avatarUrl!)
                : null,
            child: player.avatarUrl == null || player.avatarUrl!.isEmpty
                ? Text(
                    player.fullName.isNotEmpty
                        ? player.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 8,
                    ),
                  )
                : null,
          ),
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

  _EloTierInfo _getEloTierInfo(int elo) {
    final idx = EloHelpers.findTierIndex(elo);
    // Determine colors based on tier level
    switch (idx) {
      case 8: // Tier S
        return _EloTierInfo(
          label: 'S',
          bgColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFF92400E),
          borderColor: const Color(0xFFFCD34D),
        );
      case 7: // High A
        return _EloTierInfo(
          label: 'A+',
          bgColor: const Color(0xFFFEE2E2),
          textColor: const Color(0xFF991B1B),
          borderColor: const Color(0xFFFCA5A5),
        );
      case 6: // Low A
        return _EloTierInfo(
          label: 'A-',
          bgColor: const Color(0xFFFFF5F5),
          textColor: const Color(0xFFB91C1C),
          borderColor: const Color(0xFFFECACA),
        );
      case 5: // High B
        return _EloTierInfo(
          label: 'B+',
          bgColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1E40AF),
          borderColor: const Color(0xFF93C5FD),
        );
      case 4: // Low B
        return _EloTierInfo(
          label: 'B-',
          bgColor: const Color(0xFFEFF6FF),
          textColor: const Color(0xFF1D4ED8),
          borderColor: const Color(0xFFBFDBFE),
        );
      case 3: // High C
        return _EloTierInfo(
          label: 'C+',
          bgColor: const Color(0xFFD1FAE5),
          textColor: const Color(0xFF065F46),
          borderColor: const Color(0xFF6EE7B7),
        );
      case 2: // Low C
        return _EloTierInfo(
          label: 'C-',
          bgColor: const Color(0xFFECFDF5),
          textColor: const Color(0xFF047857),
          borderColor: const Color(0xFFA7F3D0),
        );
      case 1: // High D
        return _EloTierInfo(
          label: 'D+',
          bgColor: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF1E293B),
          borderColor: const Color(0xFFCBD5E1),
        );
      default: // Low D (index 0)
        return _EloTierInfo(
          label: 'D',
          bgColor: const Color(0xFFF5F5F4),
          textColor: const Color(0xFF44403C),
          borderColor: const Color(0xFFD6D3D1),
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
