import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Standalone match row card used in the knockout match table view.
/// Extracted from BracketViewScreen._buildMatchTableRow.
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

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Xác định tên vòng theo bracket branch
    final branch = match.bracketPosition.bracket;
    String roundName;
    if (branch == 'grand_final' || branch == 'grand_final_reset') {
      roundName = 'Chung kết tổng';
    } else if (branch == 'losers') {
      roundName = 'Nhánh thua Vòng ${match.round}';
    } else {
      roundName = _getRoundName(match.round, totalRounds);
    }

    String timeStr = 'Chưa xếp lịch';
    if (match.scheduledTime != null) {
      timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(match.scheduledTime!.toLocal());
    }

    Color statusColor;
    String statusLabel;
    if (match.isLive) {
      statusColor = colors.error;
      statusLabel = 'Đang thi đấu';
    } else if (match.isCompleted) {
      statusColor = colors.success;
      statusLabel = 'Đã kết thúc';
    } else {
      statusColor = AppTheme.primary;
      statusLabel = 'Chưa thi đấu';
    }

    final isT1Winner = match.isCompleted && match.winnerId == match.team1Id;
    final isT2Winner = match.isCompleted && match.winnerId == match.team2Id;

    final isT1Loser = match.isCompleted && match.winnerId == match.team2Id;
    final isT2Loser = match.isCompleted && match.winnerId == match.team1Id;

    int maxCols = 3; // default
    int? stw = match.setsToWin;
    if (stw == null && match.sportRules != null) {
      final rules = match.sportRules!;
      final stwVal = rules['setsToWin'] ?? rules['sets_to_win'];
      if (stwVal != null) {
        stw = int.tryParse(stwVal.toString());
      }
    }
    if (stw != null) {
      if (stw == 1) maxCols = 1;
      else if (stw == 2) maxCols = 3;
      else if (stw == 3) maxCols = 5;
    }

    Widget buildSetHeaders() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Expanded(child: SizedBox.shrink()),
          ...List.generate(maxCols, (index) {
            return Container(
              width: 28,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'S${index + 1}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              'TỔNG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildTeamRow({
      required String name,
      required int score,
      required List<SetScore> sets,
      required bool isTeam1,
      required bool isWinner,
      required bool isLoser,
    }) {
      final nameColor = isLoser ? colors.textMuted : colors.textPrimary;
      final fontWeight = isWinner ? FontWeight.w800 : FontWeight.w600;
      final displayNames = name.split(RegExp(r'[-–\\n]'));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Overlapping circular avatars
            SizedBox(
              width: 38,
              height: 24,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: Text(
                        displayNames[0].trim().isNotEmpty ? displayNames[0].trim()[0].toUpperCase() : 'T',
                        style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (displayNames.length > 1 && displayNames[1].trim().isNotEmpty)
                    Positioned(
                      left: 12,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        child: Text(
                          displayNames[1].trim()[0].toUpperCase(),
                          style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Team Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: fontWeight,
                  color: nameColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Sets display
            ...List.generate(maxCols, (index) {
              String setScoreStr = '-';
              if (index < sets.length) {
                final setScore = isTeam1 ? sets[index].score1 : sets[index].score2;
                setScoreStr = '$setScore';
              }
              final hasScore = setScoreStr != '-';
              return Container(
                width: 28,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: hasScore ? colors.bgDark.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasScore ? colors.border.withValues(alpha: 0.5) : colors.border.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    setScoreStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: hasScore ? colors.textSecondary : colors.textMuted.withValues(alpha: 0.5),
                      fontWeight: hasScore ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            // Main score
            Container(
              width: 32,
              height: 28,
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
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isWinner
                        ? colors.success
                        : (match.isLive ? colors.error : colors.textPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: match.isLive ? AppTheme.primary : colors.border,
          width: match.isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (match.isLive)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.push('/live/${match.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Status and Round info)
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: match.isLive
                            ? [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colors.textPrimary.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        roundName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Set columns header
                buildSetHeaders(),
                const SizedBox(height: 4),

                // Teams list
                Column(
                  children: [
                    buildTeamRow(
                      name: match.team1Name,
                      score: match.score1,
                      sets: match.sets,
                      isTeam1: true,
                      isWinner: isT1Winner,
                      isLoser: isT1Loser,
                    ),
                    const SizedBox(height: 6),
                    buildTeamRow(
                      name: match.team2Name,
                      score: match.score2,
                      sets: match.sets,
                      isTeam1: false,
                      isWinner: isT2Winner,
                      isLoser: isT2Loser,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.border.withValues(alpha: 0.8)),
                const SizedBox(height: 8),

                // Footer (Court, Sport & Time metadata)
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.location_on_rounded, size: 12, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                        style: TextStyle(
                          fontSize: 11,
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
    );
  }
}
