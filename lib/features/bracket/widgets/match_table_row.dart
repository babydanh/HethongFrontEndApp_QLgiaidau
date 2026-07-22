import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Redesigned match card for knockout bracket views.
/// Features:
/// - Card: borderRadius: 12, padding: 12, bgCard background
/// - Round name, team1 vs team2, score
/// - Winner: bold text + border-left accent
/// - Live: red dot + pulsing border animation
class MatchTableRow extends StatelessWidget {
  final MatchModel match;
  final bool isReadOnly;
  final int totalRounds;
  final String tournamentId;
  final bool isReferee;

  const MatchTableRow({
    super.key,
    required this.match,
    required this.isReadOnly,
    required this.totalRounds,
    required this.tournamentId,
    this.isReferee = false,
  });

  static String _getRoundName(int round, int totalRounds) {
    final fromEnd = totalRounds - round;
    if (fromEnd == 0) return 'Chung kết';
    if (fromEnd == 1) return 'Bán kết';
    if (fromEnd == 2) return 'Tứ kết';
    if (fromEnd == 3) return 'Vòng 1/8';
    if (fromEnd == 4) return 'Vòng 1/16';
    if (fromEnd == 5) return 'Vòng 1/32';
    if (fromEnd >= 6) return 'Vòng 1/${1 << fromEnd}';
    return 'Vòng $round';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Round name
    final branch = match.bracketPosition.bracket;
    final String roundName;
    if (branch == 'grand_final' || branch == 'grand_final_reset') {
      roundName = 'Chung kết tổng';
    } else if (branch == 'losers') {
      roundName = 'Nhánh thua Vòng ${match.round}';
    } else {
      roundName = _getRoundName(match.round, totalRounds);
    }

    // Time string
    final String timeStr;
    if (match.scheduledTime != null) {
      timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(match.scheduledTime!.toLocal());
    } else {
      timeStr = 'Chưa xếp lịch';
    }

    // Status colors
    final bool isLive = match.isLive;
    final bool isCompleted = match.isCompleted;

    // Winner detection
    final bool isT1Winner = isCompleted && match.winnerId == match.team1Id;
    final bool isT2Winner = isCompleted && match.winnerId == match.team2Id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border(
            left: BorderSide(
              color: isT1Winner || isT2Winner
                  ? colors.success
                  : isLive
                      ? colors.error
                      : colors.border,
              width: isLive ? 5 : (isT1Winner || isT2Winner ? 4 : 1),
            ),
            top: BorderSide(
              color: isLive ? colors.error.withValues(alpha: 0.7) : colors.border,
              width: isLive ? 1.5 : 1,
            ),
            right: BorderSide(
              color: isLive ? colors.error.withValues(alpha: 0.7) : colors.border,
              width: isLive ? 1.5 : 1,
            ),
            bottom: BorderSide(
              color: isLive ? colors.error.withValues(alpha: 0.7) : colors.border,
              width: isLive ? 1.5 : 1,
            ),
          ),
          boxShadow: [
            if (isLive)
              BoxShadow(
                color: colors.error.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL - 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/live/${match.id}'),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Top row: Round name + Status ───
                    Row(
                      children: [
                        // Live indicator
                        if (isLive) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.error,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.error.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: colors.error,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (isCompleted) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'KẾT THÚC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: colors.success,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (!isLive && !isCompleted) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.textMuted.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SẮP ĐẤU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // Round pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            roundName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── Team 1 Row ───
                    _buildTeamRow(
                      name: match.team1Name,
                      score: match.score1,
                      match: match,
                      isWinner: isT1Winner,
                      isTeam1: true,
                      colors: colors,
                    ),
                    const SizedBox(height: 6),

                    // ─── VS Divider ───
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ─── Team 2 Row ───
                    _buildTeamRow(
                      name: match.team2Name,
                      score: match.score2,
                      match: match,
                      isWinner: isT2Winner,
                      isTeam1: false,
                      colors: colors,
                    ),

                    const SizedBox(height: 10),

                    // ─── Footer: Time + Court + Referee action ───
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 10, color: colors.textMuted),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on_rounded, size: 12, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textMuted,
                              fontStyle: match.court.isNotEmpty ? null : FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isReferee && (match.isLive || match.isScheduled)) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tính điểm',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: match.isLive ? colors.error : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: match.isLive ? colors.error : AppTheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    required int score,
    required MatchModel match,
    required bool isWinner,
    required bool isTeam1,
    required AppColorsExtension colors,
  }) {
    return Row(
      children: [
        // Trophy icon for winner
        if (isWinner)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(Icons.emoji_events_rounded, size: 14, color: AppTheme.accent),
          ),
        // Team name
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              color: isWinner ? colors.textPrimary : colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Score badge
        Container(
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner
                ? colors.success.withValues(alpha: 0.15)
                : (match.isLive ? colors.error.withValues(alpha: 0.1) : colors.bgSurface),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isWinner
                  ? colors.success.withValues(alpha: 0.3)
                  : (match.isLive ? colors.error.withValues(alpha: 0.3) : colors.border),
              width: 0.5,
            ),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isWinner
                  ? colors.success
                  : (match.isLive ? colors.error : colors.textPrimary),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
