import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

enum _StatsPeriod { sevenDays, oneMonth, threeMonths, all }

class ClubStatisticsTab extends ConsumerStatefulWidget {
  final String communityId;
  final Community? club;

  const ClubStatisticsTab({super.key, required this.communityId, this.club});

  @override
  ConsumerState<ClubStatisticsTab> createState() => _ClubStatisticsTabState();
}

class _ClubStatisticsTabState extends ConsumerState<ClubStatisticsTab> {
  _StatsPeriod _period = _StatsPeriod.oneMonth;
  bool _isLoading = true;
  String? _errorMessage;
  List<MatchModel> _allMatches = [];

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final matchRepo = ref.read(matchRepositoryProvider);
      final sessionRepo = ref.read(clubMatchSessionRepositoryProvider);

      final matchesList = <MatchModel>[];

      final tourFetchFuture = () async {
        try {
          final tourRes = await dio.get('/communities/${widget.communityId}/tournaments');
          final rawTours = tourRes.data is Map ? (tourRes.data['data'] ?? tourRes.data) : tourRes.data;
          final tours = (rawTours is List ? rawTours : const <dynamic>[])
              .whereType<Map>()
              .map((t) => Map<String, dynamic>.from(t))
              .take(6)
              .toList(growable: false);

          final tourMatches = await Future.wait(
            tours.map((tour) async {
              final tourId = tour['id']?.toString();
              final tourName = tour['name']?.toString() ?? 'Giải đấu';
              if (tourId == null || tourId.isEmpty) return <MatchModel>[];
              try {
                final page = await matchRepo.getTournamentMatchesPaged(
                  tournamentId: tourId,
                  limit: 50,
                );
                return page.matches
                    .where(isRenderablePublicMatch)
                    .map((m) => m.copyWith(tournamentName: tourName))
                    .toList(growable: false);
              } catch (_) {
                return <MatchModel>[];
              }
            }),
          );
          for (final list in tourMatches) {
            matchesList.addAll(list);
          }
        } catch (_) {}
      }();

      // 2. Tải danh sách buổi giao lưu
      final sessionFetchFuture = () async {
        try {
          final sessionPage = await sessionRepo.listPage(
            widget.communityId,
            limit: 20,
          );

          final sessionMatches = await Future.wait(
            sessionPage.data.map((session) async {
              if (session.id.isEmpty) return <MatchModel>[];
              try {
                final matchPage = await sessionRepo.matchesPage(
                  session.id,
                  limit: 50,
                );
                return matchPage.data
                    .map(
                      (m) => _mapSessionMatchToModel(
                        m,
                        tournamentName: session.resolvedName.isNotEmpty
                            ? session.resolvedName
                            : 'Giao lưu CLB',
                        sessionId: session.id,
                        fallbackTime: session.startAt,
                      ),
                    )
                    .toList(growable: false);
              } catch (_) {
                return <MatchModel>[];
              }
            }),
          );
          for (final list in sessionMatches) {
            matchesList.addAll(list);
          }
        } catch (_) {}
      }();

      // 3. Tải danh sách trận riêng (standalone)
      final standaloneFetchFuture = () async {
        try {
          final standalonePage = await sessionRepo.standaloneMatchesPage(
            widget.communityId,
            limit: 50,
          );
          for (final m in standalonePage.data) {
            matchesList.add(
              _mapSessionMatchToModel(
                m,
                tournamentName: 'Thách đấu CLB',
                fallbackTime: m.updatedAt ?? m.createdAt,
              ),
            );
          }
        } catch (_) {}
      }();

      await Future.wait([
        tourFetchFuture,
        sessionFetchFuture,
        standaloneFetchFuture,
      ]);

      if (mounted) {
        setState(() {
          _allMatches = matchesList;
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

  MatchModel _mapSessionMatchToModel(
    ClubSessionMatchModel sessionMatch, {
    String? tournamentName,
    String? sessionId,
    DateTime? fallbackTime,
  }) {
    final sideAMembers = sessionMatch.sideAMembers
        .map(
          (m) => MatchMemberInfo(
            userId: m.userId,
            fullName: m.displayName,
            avatarUrl: m.avatarUrl,
            isMock: m.isMock,
          ),
        )
        .toList(growable: false);
    final sideBMembers = sessionMatch.sideBMembers
        .map(
          (m) => MatchMemberInfo(
            userId: m.userId,
            fullName: m.displayName,
            avatarUrl: m.avatarUrl,
            isMock: m.isMock,
          ),
        )
        .toList(growable: false);

    final isCompleted = sessionMatch.status.trim().toUpperCase() == 'COMPLETED';
    final winnerId = isCompleted
        ? (sessionMatch.sideAScore > sessionMatch.sideBScore
            ? 'SIDE_A'
            : sessionMatch.sideBScore > sessionMatch.sideAScore
                ? 'SIDE_B'
                : '')
        : '';

    return MatchModel(
      id: sessionMatch.id,
      tournamentId: '',
      tournamentName: tournamentName ?? 'CLB',
      round: 1,
      matchNumber: 1,
      status: sessionMatch.status,
      score1: sessionMatch.sideAScore,
      score2: sessionMatch.sideBScore,
      sets: [
        SetScore(
          score1: isCompleted ? sessionMatch.sideAScore : 0,
          score2: isCompleted ? sessionMatch.sideBScore : 0,
        ),
      ],
      bracketPosition: const BracketPosition(round: 1, position: 1),
      winnerId: winnerId,
      loserId: winnerId == 'SIDE_A'
          ? 'SIDE_B'
          : winnerId == 'SIDE_B'
              ? 'SIDE_A'
              : '',
      team1Members: sideAMembers.map((m) => m.fullName).toList(),
      team2Members: sideBMembers.map((m) => m.fullName).toList(),
      team1MemberInfos: sideAMembers,
      team2MemberInfos: sideBMembers,
      team1Id: 'side_a_${sessionMatch.id}',
      team2Id: 'side_b_${sessionMatch.id}',
      team1Name: sideAMembers.map((m) => m.fullName).join(' / '),
      team2Name: sideBMembers.map((m) => m.fullName).join(' / '),
      clubMatchSessionId: sessionId,
      completedAt: sessionMatch.completedAt ?? fallbackTime,
      startedAt: sessionMatch.startedAt ?? fallbackTime,
      scheduledTime: fallbackTime,
      updatedAt: sessionMatch.updatedAt ?? fallbackTime ?? DateTime.now(),
    );
  }

  DateTime? _getMatchDate(MatchModel match) {
    return match.completedAt ??
        match.startedAt ??
        match.scheduledTime ??
        match.updatedAt;
  }

  List<MatchModel> _filterMatchesByPeriod(List<MatchModel> matches) {
    final now = DateTime.now();
    DateTime? threshold;

    switch (_period) {
      case _StatsPeriod.sevenDays:
        threshold = now.subtract(const Duration(days: 7));
        break;
      case _StatsPeriod.oneMonth:
        threshold = now.subtract(const Duration(days: 30));
        break;
      case _StatsPeriod.threeMonths:
        threshold = now.subtract(const Duration(days: 90));
        break;
      case _StatsPeriod.all:
        threshold = null;
        break;
    }

    if (threshold == null) return matches;

    return matches.where((m) {
      final date = _getMatchDate(m);
      if (date == null) return true;
      return date.isAfter(threshold!);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return _buildSkeleton(colors);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadStatsData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.club_retryButton),
              ),
            ],
          ),
        ),
      );
    }

    final filteredMatches = _filterMatchesByPeriod(_allMatches);
    final completedMatches = filteredMatches.where((m) => m.isCompleted).toList();

    // Tính toán thống kê theo từng thành viên
    final memberStatsMap = <String, _MemberStat>{};

    void recordMember(MatchMemberInfo member, bool won, DateTime? matchTime) {
      // Bỏ qua thành viên mock / ảo và người chơi không có ID
      if (member.isMock) return;
      final uId = member.userId?.trim() ?? '';
      if (uId.isEmpty) return;
      final stat = memberStatsMap.putIfAbsent(
        uId,
        () => _MemberStat(
          userId: uId,
          displayName: member.fullName.isNotEmpty ? member.fullName : 'VĐV',
          avatarUrl: member.avatarUrl,
          isMock: false,
        ),
      );
      stat.addResult(won: won, matchTime: matchTime);
    }

    // Sắp xếp trận completed theo thời gian tăng dần để tính chuỗi streak chuẩn xác
    completedMatches.sort((a, b) {
      final timeA = _getMatchDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = _getMatchDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeA.compareTo(timeB);
    });

    for (final match in completedMatches) {
      final s1 = match.score1;
      final s2 = match.score2;
      if (s1 == s2) continue; // Hòa không tính thắng thua rõ ràng

      final side1Won = s1 > s2;
      final matchTime = _getMatchDate(match);

      for (final m in match.team1MemberInfos) {
        recordMember(m, side1Won, matchTime);
      }
      for (final m in match.team2MemberInfos) {
        recordMember(m, !side1Won, matchTime);
      }
    }

    final memberStatsList = memberStatsMap.values.toList();
    // Sắp xếp danh sách thành viên theo số trận thắng giảm dần, sau đó theo tỷ lệ thắng
    memberStatsList.sort((a, b) {
      final byWins = b.wins.compareTo(a.wins);
      if (byWins != 0) return byWins;
      final byRate = b.winRate.compareTo(a.winRate);
      if (byRate != 0) return byRate;
      return b.totalMatches.compareTo(a.totalMatches);
    });

    // Tính nổi bật (Spotlight)
    _MemberStat? topWins;
    _MemberStat? topStreak;
    _MemberStat? topWinRate;

    final activeMembers = memberStatsList.where((s) => s.totalMatches > 0).toList();
    if (activeMembers.isNotEmpty) {
      topWins = activeMembers.reduce((a, b) => b.wins > a.wins ? b : a);
      topStreak = activeMembers.reduce((a, b) => b.bestWinStreak > a.bestWinStreak ? b : a);
      final qualifiedForRate = activeMembers.where((s) => s.totalMatches >= 3).toList();
      if (qualifiedForRate.isNotEmpty) {
        topWinRate = qualifiedForRate.reduce((a, b) => b.winRate > a.winRate ? b : a);
      }
    }

    final totalCompleted = completedMatches.length;
    final totalAllInPeriod = filteredMatches.length;

    return RefreshIndicator(
      onRefresh: _loadStatsData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Bộ lọc thời gian tinh gọn ít chữ (Pill Chips)
          _buildPeriodFilterRow(colors, l10n),
          const SizedBox(height: 16),

          // 2. Thẻ tổng quan trận đấu
          _buildOverviewCards(
            colors: colors,
            l10n: l10n,
            totalMatches: totalAllInPeriod,
            completedMatches: totalCompleted,
            activeMembersCount: activeMembers.length,
          ),
          const SizedBox(height: 16),

          // 3. Gương mặt nổi bật (Spotlight)
          if (topWins != null && topWins.wins > 0) ...[
            _buildSectionHeader(
              title: l10n.clubStats_spotlightTitle,
              icon: Icons.auto_awesome_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),
            _buildSpotlightRow(
              colors: colors,
              l10n: l10n,
              topWins: topWins,
              topStreak: topStreak,
              topWinRate: topWinRate,
            ),
            const SizedBox(height: 20),
          ],

          // 4. Bảng thành tích thành viên
          _buildSectionHeader(
            title: '${l10n.clubStats_memberListTitle} (${memberStatsList.length})',
            icon: Icons.leaderboard_rounded,
            colors: colors,
          ),
          const SizedBox(height: 10),

          if (memberStatsList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.query_stats_rounded,
                      size: 40,
                      color: colors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.clubStats_emptyData,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < memberStatsList.length; i++) ...[
                    _buildMemberStatItem(
                      stat: memberStatsList[i],
                      rank: i + 1,
                      colors: colors,
                      l10n: l10n,
                    ),
                    if (i < memberStatsList.length - 1)
                      Divider(
                        height: 1,
                        indent: 58,
                        endIndent: 14,
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Filter Pills ───
  Widget _buildPeriodFilterRow(AppColorsExtension colors, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPillChip(
            label: l10n.clubStats_filter7D,
            period: _StatsPeriod.sevenDays,
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: l10n.clubStats_filter1M,
            period: _StatsPeriod.oneMonth,
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: l10n.clubStats_filter3M,
            period: _StatsPeriod.threeMonths,
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: l10n.clubStats_filterAll,
            period: _StatsPeriod.all,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required _StatsPeriod period,
    required AppColorsExtension colors,
  }) {
    final isSelected = _period == period;
    return InkWell(
      onTap: () {
        if (_period != period) {
          setState(() => _period = period);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : colors.border.withValues(alpha: 0.7),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : colors.textMuted,
          ),
        ),
      ),
    );
  }

  // ─── Overview Metric Cards ───
  Widget _buildOverviewCards({
    required AppColorsExtension colors,
    required AppLocalizations l10n,
    required int totalMatches,
    required int completedMatches,
    required int activeMembersCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _buildMetricColumn(
            label: l10n.clubStats_totalMatches,
            value: '$totalMatches',
            color: AppTheme.primary,
            icon: Icons.sports_tennis_rounded,
            colors: colors,
          ),
          _buildVerticalSeparator(colors),
          _buildMetricColumn(
            label: l10n.completedMatchesLabel,
            value: '$completedMatches',
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline_rounded,
            colors: colors,
          ),
          _buildVerticalSeparator(colors),
          _buildMetricColumn(
            label: l10n.club_tabMembers,
            value: '$activeMembersCount',
            color: const Color(0xFF0284C7),
            icon: Icons.group_outlined,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSeparator(AppColorsExtension colors) {
    return Container(
      height: 28,
      width: 1,
      color: colors.border.withValues(alpha: 0.6),
    );
  }

  // ─── Section Header ───
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Spotlight Cards ───
  Widget _buildSpotlightRow({
    required AppColorsExtension colors,
    required AppLocalizations l10n,
    required _MemberStat? topWins,
    required _MemberStat? topStreak,
    required _MemberStat? topWinRate,
  }) {
    return Row(
      children: [
        if (topWins != null)
          Expanded(
            child: _buildSpotlightCard(
              title: l10n.clubStats_topWins,
              stat: topWins,
              detail: '${topWins.wins} ${l10n.clubStats_wins} (${topWins.winRate.round()}%)',
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFFF59E0B),
              colors: colors,
            ),
          ),
        if (topWins != null && topStreak != null && topStreak.bestWinStreak >= 2) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildSpotlightCard(
              title: l10n.clubStats_topStreak,
              stat: topStreak,
              detail: '🔥 ${l10n.clubStats_streakWin(topStreak.bestWinStreak)}',
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFEA580C),
              colors: colors,
            ),
          ),
        ] else if (topWinRate != null && topWins != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildSpotlightCard(
              title: l10n.clubStats_highestWinRate,
              stat: topWinRate,
              detail: '${topWinRate.winRate.round()}% (${topWinRate.wins}/${topWinRate.losses})',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF16A34A),
              colors: colors,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpotlightCard({
    required String title,
    required _MemberStat stat,
    required String detail,
    required IconData icon,
    required Color iconColor,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: () {
        if (stat.userId.isNotEmpty && !stat.isMock) {
          UserProfileBottomSheet.show(
            context,
            userId: stat.userId,
            communityId: widget.communityId,
            initialFullName: stat.displayName,
            initialAvatarUrl: stat.avatarUrl,
            onFilterMatches: (query) {
              final clubName = widget.club?.name ?? '';
              context.push(
                '/club/${widget.communityId}/search?name=${Uri.encodeComponent(clubName)}&q=${Uri.encodeComponent(query)}&type=MATCHES',
              );
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  backgroundImage: stat.avatarUrl != null && stat.avatarUrl!.isNotEmpty
                      ? NetworkImage(stat.avatarUrl!)
                      : null,
                  child: stat.avatarUrl == null || stat.avatarUrl!.isEmpty
                      ? Text(
                          stat.displayName.isNotEmpty ? stat.displayName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: iconColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Member Stat Row ───
  Widget _buildMemberStatItem({
    required _MemberStat stat,
    required int rank,
    required AppColorsExtension colors,
    required AppLocalizations l10n,
  }) {
    Color rankColor = colors.textMuted;
    if (rank == 1) rankColor = const Color(0xFFF59E0B);
    if (rank == 2) rankColor = const Color(0xFF94A3B8);
    if (rank == 3) rankColor = const Color(0xFFB45309);

    final streakBadge = stat.currentStreak >= 2
        ? stat.isCurrentStreakWin
            ? '🔥 ${stat.currentStreak}'
            : '↘ ${stat.currentStreak}'
        : null;

    return InkWell(
      onTap: () {
        if (stat.userId.isNotEmpty && !stat.isMock) {
          UserProfileBottomSheet.show(
            context,
            userId: stat.userId,
            communityId: widget.communityId,
            initialFullName: stat.displayName,
            initialAvatarUrl: stat.avatarUrl,
            onFilterMatches: (query) {
              final clubName = widget.club?.name ?? '';
              context.push(
                '/club/${widget.communityId}/search?name=${Uri.encodeComponent(clubName)}&q=${Uri.encodeComponent(query)}&type=MATCHES',
              );
            },
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Avatar
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              backgroundImage: stat.avatarUrl != null && stat.avatarUrl!.isNotEmpty
                  ? NetworkImage(stat.avatarUrl!)
                  : null,
              child: stat.avatarUrl == null || stat.avatarUrl!.isEmpty
                  ? Text(
                      stat.displayName.isNotEmpty ? stat.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Name & matches summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          stat.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (streakBadge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: stat.isCurrentStreakWin
                                ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                                : colors.textMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            streakBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: stat.isCurrentStreakWin
                                  ? const Color(0xFFEA580C)
                                  : colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stat.totalMatches} ${l10n.ranking_matchesLabel} · ${stat.wins}T - ${stat.losses}B',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Win rate percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stat.winRate.round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: stat.winRate >= 50 ? const Color(0xFF16A34A) : colors.textMuted,
                  ),
                ),
                Text(
                  l10n.clubStats_winRate,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(AppColorsExtension colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Filter pills skeleton
        Row(
          children: List.generate(
            4,
            (index) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: index == 1 ? 72 : 58,
              height: 32,
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Overview metrics card skeleton
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 54,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Spotlight skeleton
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            2,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? 10 : 0),
                height: 88,
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Member list skeleton
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 110,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 70,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberStat {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isMock;

  int wins = 0;
  int losses = 0;

  int currentStreak = 0;
  bool isCurrentStreakWin = true;
  int bestWinStreak = 0;

  // Lịch sử kết quả trận theo thứ tự thời gian tăng dần
  final List<bool> _history = [];

  _MemberStat({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.isMock = false,
  });

  int get totalMatches => wins + losses;

  double get winRate => totalMatches == 0 ? 0.0 : (wins / totalMatches) * 100.0;

  void addResult({required bool won, DateTime? matchTime}) {
    if (won) {
      wins++;
    } else {
      losses++;
    }
    _history.add(won);
    _recalculateStreaks();
  }

  void _recalculateStreaks() {
    if (_history.isEmpty) {
      currentStreak = 0;
      bestWinStreak = 0;
      return;
    }

    int tempWinStreak = 0;
    int maxWinStreak = 0;

    for (final won in _history) {
      if (won) {
        tempWinStreak++;
        if (tempWinStreak > maxWinStreak) maxWinStreak = tempWinStreak;
      } else {
        tempWinStreak = 0;
      }
    }
    bestWinStreak = maxWinStreak;

    // Chuỗi hiện tại (nhìn từ trận mới nhất ngược về trước)
    final lastResult = _history.last;
    isCurrentStreakWin = lastResult;
    int cur = 0;
    for (int i = _history.length - 1; i >= 0; i--) {
      if (_history[i] == lastResult) {
        cur++;
      } else {
        break;
      }
    }
    currentStreak = cur;
  }
}

