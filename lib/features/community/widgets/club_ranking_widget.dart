import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

class ClubRankingWidget extends ConsumerStatefulWidget {
  final String clubId;

  const ClubRankingWidget({super.key, required this.clubId});

  @override
  ConsumerState<ClubRankingWidget> createState() => _ClubRankingWidgetState();
}

class _ClubRankingWidgetState extends ConsumerState<ClubRankingWidget> {
  List<PlayerRanking>? _rankings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  Future<void> _fetchRankings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/rankings/leaderboard',
        queryParameters: {
          'communityId': widget.clubId,
          'scope': 'COMMUNITY',
          'matchType': 'SINGLES',
          'limit': 10,
        },
      );
      final raw = response.data;
      final List<dynamic> dataList = raw is Map<String, dynamic>
          ? (raw['data'] as List<dynamic>? ?? [])
          : (raw as List<dynamic>? ?? []);
      final rankings = dataList
          .map((json) => PlayerRanking.fromJson(json as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _rankings = rankings;
          _loading = false;
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
      return const SizedBox.shrink();
    }

    final rankings = _rankings!;

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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                'Đơn',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Podium Row (Top 3) ──
        if (rankings.isNotEmpty) _buildPodiumRow(rankings),

        // ── Ranks 4-10 List ──
        if (rankings.length > 3) ...[
          const SizedBox(height: 12),
          ...List.generate(rankings.length - 3, (i) {
            final index = i + 3;
            final r = rankings[index];
            return _buildListRow(r, index + 1, colors);
          }),
        ],
      ],
    );
  }

  // ─── Podium ───

  Widget _buildPodiumRow(List<PlayerRanking> rankings) {
    // Arrange: silver (r2) | gold (r1) | bronze (r3)
    final rank1 = rankings[0];
    final rank2 = rankings.length > 1 ? rankings[1] : null;
    final rank3 = rankings.length > 2 ? rankings[2] : null;

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Silver (rank 2) - left
          if (rank2 != null)
            Expanded(child: _buildPodiumCard(rank2, 2, isCenter: false)),
          if (rank2 != null) const SizedBox(width: 6),

          // Gold (rank 1) - center, tallest
          Expanded(flex: 12, child: _buildPodiumCard(rank1, 1, isCenter: true)),

          // Bronze (rank 3) - right
          if (rank3 != null) const SizedBox(width: 6),
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
    final avatarSize = isCenter ? 44.0 : 36.0;

    return Container(
      height: isCenter ? 140 : 124,
      padding: EdgeInsets.only(
        top: 12,
        left: 8,
        right: 8,
        bottom: isCenter ? 16 : 10,
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
          // Rank badge + medal icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                rank == 1
                    ? Icons.emoji_events_rounded
                    : rank == 2
                    ? Icons.military_tech_rounded
                    : Icons.workspace_premium_rounded,
                size: isCenter ? 16 : 13,
                color: medalColors.icon,
              ),
              const SizedBox(width: 3),
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isCenter ? 13 : 11,
                  fontWeight: FontWeight.w700,
                  color: medalColors.icon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 6),

          // Name
          Text(
            player.fullName,
            style: TextStyle(
              fontSize: isCenter ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),

          // ELO
          Text(
            '${player.eloPoints}',
            style: TextStyle(
              fontSize: isCenter ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: medalColors.elo,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 24,
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
            radius: 12,
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
                      fontSize: 9,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),

          // Name
          Expanded(
            child: Text(
              player.fullName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // ELO points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              '${player.eloPoints}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Win rate bar
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${winRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
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
