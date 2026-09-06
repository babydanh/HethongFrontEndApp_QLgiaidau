import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/community/providers/user_club_rank_provider.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';

class ClubActivityTab extends ConsumerStatefulWidget {
  final String communityId;
  final Community? club;
  final String? initialSearchQuery;

  const ClubActivityTab({
    super.key,
    required this.communityId,
    this.club,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<ClubActivityTab> createState() => _ClubActivityTabState();
}

enum _ActivityFilter { all, myMatches, ongoing, completed }

class _ClubActivityTabState extends ConsumerState<ClubActivityTab> {
  List<MatchModel> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;
  _ActivityFilter _filter = _ActivityFilter.all;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _searchQuery = widget.initialSearchQuery!;
    }
    _fetchMatches();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchMatches(silent: true);
    });
  }

  @override
  void didUpdateWidget(covariant ClubActivityTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery &&
        widget.initialSearchQuery != null) {
      setState(() {
        _searchController.text = widget.initialSearchQuery!;
        _searchQuery = widget.initialSearchQuery!;
        _filter = _ActivityFilter.all;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dio = ref.read(dioClientProvider).dio;
      // 1. Lấy danh sách giải đấu thuộc CLB
      final tourRes = await dio.get(
        '/communities/${widget.communityId}/tournaments',
      );
      final rawTours = tourRes.data is Map
          ? (tourRes.data['data'] ?? tourRes.data)
          : tourRes.data;
      final tourList = (rawTours is List ? rawTours : const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (tourList.isEmpty) {
        if (mounted) {
          setState(() {
            _matches = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Lấy 5 giải mới nhất
      final recentTours = tourList.take(5).toList();
      final List<MatchModel> allMatches = [];

      for (final tour in recentTours) {
        final tourId = tour['id']?.toString();
        final tourName = tour['name']?.toString() ?? 'Giải đấu';
        if (tourId == null) continue;

        try {
          final matchRes = await dio.get(
            '/matches',
            queryParameters: {'tournament_id': tourId, 'limit': 50},
          );
          final rawMatches = matchRes.data is Map
              ? (matchRes.data['data'] ?? matchRes.data)
              : matchRes.data;
          final matchList = rawMatches is List ? rawMatches : const [];
          for (final mJson in matchList) {
            if (mJson is Map<String, dynamic>) {
              final id = mJson['id']?.toString() ?? '';
              final match = MatchModel.fromJson(mJson, id);
              if (isRenderablePublicMatch(match)) {
                allMatches.add(match.copyWith(tournamentName: tourName));
              }
            }
          }
        } catch (_) {}
      }

      // Sắp xếp: Trận đang diễn ra lên đầu, sau đó theo thời gian gần nhất
      allMatches.sort((a, b) {
        final aOngoing = a.status.toUpperCase() == 'ONGOING';
        final bOngoing = b.status.toUpperCase() == 'ONGOING';
        if (aOngoing && !bOngoing) return -1;
        if (bOngoing && !aOngoing) return 1;

        final aTime =
            a.completedAt ?? a.startedAt ?? a.scheduledTime ?? a.updatedAt;
        final bTime =
            b.completedAt ?? b.startedAt ?? b.scheduledTime ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _matches = allMatches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showMemberSheet(
    BuildContext context,
    String userId,
    String fullName,
    String? avatarUrl,
  ) {
    UserProfileBottomSheet.show(
      context,
      userId: userId,
      communityId: widget.communityId,
      initialFullName: fullName,
      initialAvatarUrl: avatarUrl,
      onFilterMatches: (query) {
        setState(() {
          _searchController.text = query;
          _searchQuery = query;
          _filter = _ActivityFilter.all;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(userProfileProvider).asData?.value;
    final membership = ref.watch(
      myCommunityMembershipProvider(widget.communityId),
    );
    final isClubMember =
        membership.asData?.value?.status.toUpperCase() == 'JOINED';
    final currentUserId = currentUser?.id ?? '';
    final currentUserName = (currentUser?.fullName ?? '').toLowerCase();

    // Lấy thông số HUD của user trong CLB
    final clubRank = isClubMember && currentUserId.isNotEmpty
        ? ref
              .watch(
                userClubRankProvider((
                  userId: currentUserId,
                  communityId: widget.communityId,
                )),
              )
              .asData
              ?.value
        : null;

    // Lọc trận đấu của tôi
    final userMatches = isClubMember
        ? _matches.where((m) {
            if (currentUserId.isEmpty && currentUserName.isEmpty) return false;
            final isT1 =
                m.team1MemberInfos.any((mem) => mem.userId == currentUserId) ||
                (currentUserName.isNotEmpty &&
                    m.team1Name.toLowerCase().contains(currentUserName));
            final isT2 =
                m.team2MemberInfos.any((mem) => mem.userId == currentUserId) ||
                (currentUserName.isNotEmpty &&
                    m.team2Name.toLowerCase().contains(currentUserName));
            return isT1 || isT2;
          }).toList()
        : <MatchModel>[];

    // Lọc danh sách theo filter và search query
    final query = _searchQuery.trim().toLowerCase();
    final filteredMatches = _matches.where((m) {
      final statusUpper = m.status.toUpperCase();
      if (_filter == _ActivityFilter.ongoing && statusUpper != 'ONGOING') {
        return false;
      }
      if (_filter == _ActivityFilter.completed && statusUpper != 'COMPLETED') {
        return false;
      }
      if (_filter == _ActivityFilter.myMatches) {
        if (!userMatches.contains(m)) return false;
      }

      if (query.isNotEmpty) {
        final t1 = m.team1Name.toLowerCase();
        final t2 = m.team2Name.toLowerCase();
        final tName = (m.tournamentName ?? '').toLowerCase();
        final memMatch =
            m.team1MemberInfos.any(
              (mem) => mem.fullName.toLowerCase().contains(query),
            ) ||
            m.team2MemberInfos.any(
              (mem) => mem.fullName.toLowerCase().contains(query),
            );
        if (!t1.contains(query) &&
            !t2.contains(query) &&
            !tName.contains(query) &&
            !memMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _fetchMatches(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ─── 1. HUD THÔNG SỐ CÁ NHÂN TRONG CLB ───────────────────
          if (isClubMember && currentUser != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      RankAvatar(
                        imageUrl: currentUser.avatarUrl,
                        name: currentUser.fullName ?? 'Tôi',
                        elo: clubRank?.eloPoints ?? 1000,
                        tierName: clubRank?.tierName ?? 'Low Tier D',
                        matchesPlayed: clubRank?.matchesPlayed ?? 0,
                        size: 46,
                        ringWidth: 2.5,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentUser.fullName ?? 'Thành viên CLB',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hồ sơ và thông số thi đấu trong câu lạc bộ',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Telemetry pills
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ĐIỂM CLB',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${clubRank?.eloPoints ?? 1000} ELO',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRẬN TRONG CLB',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${userMatches.length} trận',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (clubRank != null && clubRank.streakCount > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 7,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PHONG ĐỘ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'W${clubRank.streakCount}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── 2. THANH LỌC & TÌM KIẾM ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchDebounceTimer?.cancel();
                    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
                      if (mounted) {
                        setState(() => _searchQuery = val);
                      }
                    });
                  },
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên VĐV hoặc giải đấu...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: colors.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchDebounceTimer?.cancel();
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        );
                      },
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    fillColor: colors.bgCard,
                    filled: true,
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
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  'Tất cả (${_matches.length})',
                  _ActivityFilter.all,
                  colors,
                ),
                const SizedBox(width: 6),
                if (isClubMember && currentUser != null) ...[
                  _filterChip(
                    'Trận của tôi (${userMatches.length})',
                    _ActivityFilter.myMatches,
                    colors,
                  ),
                  const SizedBox(width: 6),
                ],
                _filterChip('Đang diễn ra', _ActivityFilter.ongoing, colors),
                const SizedBox(width: 6),
                _filterChip('Đã kết thúc', _ActivityFilter.completed, colors),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 3. DANH SÁCH TRẬN ĐẤU TIMELINE ───────────────────────
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (_errorMessage != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 36,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lỗi tải hoạt động CLB: $_errorMessage',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _fetchMatches(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (filteredMatches.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.sports_tennis_rounded,
                    size: 40,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chưa có hoạt động trận đấu nào',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _filter == _ActivityFilter.myMatches
                        ? 'Bạn chưa tham gia trận đấu nào trong các giải thuộc CLB.'
                        : 'Khi các giải đấu diễn ra, kết quả và diễn biến sẽ xuất hiện ở đây.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMatches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = filteredMatches[index];
                return _buildMatchCard(context, match, colors);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    _ActivityFilter f,
    AppColorsExtension colors,
  ) {
    final isSelected = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchModel match,
    AppColorsExtension colors,
  ) {
    final isOngoing = match.status.toUpperCase() == 'ONGOING';
    final isCompleted = match.status.toUpperCase() == 'COMPLETED';

    final t1Id = match.team1Id;
    final t2Id = match.team2Id;
    final isT1Winner = isCompleted && match.winnerId == t1Id;
    final isT2Winner = isCompleted && match.winnerId == t2Id;

    // ELO Delta calculation (+16 / -14)
    final rawEloDelta = match.scoreDetails?['eloDelta'] ?? 16;
    final t1EloDelta = isCompleted && match.winnerId.isNotEmpty
        ? (isT1Winner ? '+$rawEloDelta' : '-$rawEloDelta')
        : null;
    final t2EloDelta = isCompleted && match.winnerId.isNotEmpty
        ? (isT2Winner ? '+$rawEloDelta' : '-$rawEloDelta')
        : null;

    final roundLabel = match.round > 0
        ? 'Vòng ${match.round}'
        : 'Trận #${match.matchNumber}';

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOngoing ? const Color(0xFF3B82F6) : colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isOngoing
                ? const Color(0x1A3B82F6)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar: Tournament Name, Round & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
              border: Border(bottom: BorderSide(color: colors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          match.tournamentName ?? 'Giải đấu',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.borderLight),
                        ),
                        child: Text(
                          roundLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOngoing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record_rounded,
                          size: 8,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đang diễn ra',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isCompleted)
                  Text(
                    'Đã kết thúc',
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
              ],
            ),
          ),

          // Scores & Teams
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Team 1 Row
                _buildTeamRow(
                  context: context,
                  name: match.team1Name,
                  logoUrl: match.team1LogoUrl,
                  isWinner: isT1Winner,
                  eloDelta: t1EloDelta,
                  sets: match.sets.map((s) => s.score1).toList(),
                  memberInfos: match.team1MemberInfos,
                  colors: colors,
                ),
                const SizedBox(height: 10),
                // Team 2 Row
                _buildTeamRow(
                  context: context,
                  name: match.team2Name,
                  logoUrl: match.team2LogoUrl,
                  isWinner: isT2Winner,
                  eloDelta: t2EloDelta,
                  sets: match.sets.map((s) => s.score2).toList(),
                  memberInfos: match.team2MemberInfos,
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required BuildContext context,
    required String name,
    required String? logoUrl,
    required bool isWinner,
    required String? eloDelta,
    required List<int> sets,
    required List<MatchMemberInfo> memberInfos,
    required AppColorsExtension colors,
  }) {
    // Lấy userId của VĐV đầu tiên nếu có
    final firstMember = memberInfos.isNotEmpty ? memberInfos.first : null;
    final targetUserId = firstMember?.userId;

    return Row(
      children: [
        // Avatar click mở UserProfileBottomSheet
        GestureDetector(
          onTap: targetUserId != null && targetUserId.isNotEmpty
              ? () => _showMemberSheet(context, targetUserId, name, logoUrl)
              : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWinner ? const Color(0xFF2563EB) : colors.bgSurface,
              border: Border.all(
                color: isWinner ? const Color(0xFF2563EB) : colors.borderLight,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _avatarFallback(name, isWinner),
                    )
                  : _avatarFallback(name, isWinner),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name & ELO Delta
        Expanded(
          child: GestureDetector(
            onTap: targetUserId != null && targetUserId.isNotEmpty
                ? () => _showMemberSheet(context, targetUserId, name, logoUrl)
                : null,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
                      color: isWinner
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (eloDelta != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isWinner
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      eloDelta,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: isWinner
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Set Scores
        Row(
          mainAxisSize: MainAxisSize.min,
          children: sets.map((s) {
            return Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: isWinner ? const Color(0xFF2563EB) : colors.bgSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '$s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
                  fontFamily: 'monospace',
                  color: isWinner ? Colors.white : colors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _avatarFallback(String name, bool isWinner) {
    return Center(
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isWinner ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
