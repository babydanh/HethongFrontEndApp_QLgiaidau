import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Clean, specs-driven schedule match card.
/// Features:
/// - Top: Team 1 & Team 2 with set score columns (S1, S2, S3...) matching tournament settings & Total sets won (TỔNG)
/// - Bottom Footer: Status Badge, Scheduled Time, Court location, Group / Round info
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

  String _getSingleInitials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }

  List<String> _getInitials(String name) {
    final parts = name.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return [_getSingleInitials(parts[0]), _getSingleInitials(parts[1])];
    }
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return [words[0][0].toUpperCase(), words[1][0].toUpperCase()];
    }
    return [name.isNotEmpty ? name[0].toUpperCase() : '?', '?'];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLive = match.isLive;
    final isCompleted = match.isCompleted;

    final t1Initials = _getInitials(match.team1Name);
    final t2Initials = _getInitials(match.team2Name);

    // Round / Group / Match location label
    final branch = match.bracketPosition.bracket;
    final String roundLabel;
    if (branch == 'grand_final' || branch == 'grand_final_reset') {
      roundLabel = 'Chung kết tổng';
    } else if (branch == 'losers') {
      roundLabel = 'Nhánh thua Vòng ${match.round}';
    } else if (match.groupName != null && match.groupName!.isNotEmpty) {
      roundLabel = '${match.groupName} - Trận ${match.matchNumber}';
    } else {
      roundLabel = '${_getRoundName(match.round, totalRounds)} - Trận ${match.matchNumber}';
    }

    // Time string
    final String timeStr = match.scheduledTime != null
        ? DateFormat('HH:mm').format(match.scheduledTime!.toLocal())
        : '--:--';

    // Calculate set score and sets won
    final sets = match.sets;

    int setsWon1 = 0;
    int setsWon2 = 0;
    if (sets.isNotEmpty) {
      for (final s in sets) {
        if (s.score1 > s.score2) setsWon1++;
        if (s.score2 > s.score1) setsWon2++;
      }
    } else {
      setsWon1 = match.score1;
      setsWon2 = match.score2;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFFFCA5A5) : colors.border.withValues(alpha: 0.6),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : colors.border.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/live/${match.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TOP SECTION: TEAMS & SCORES (ALIGNED VERTICALLY WITH TEAM NAMES) ──
                Row(
                  children: [
                    // Team Names Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Team 1
                          Row(
                            children: [
                              _DoubleAvatarWidget(
                                initial1: t1Initials[0],
                                initial2: t1Initials[1],
                                color: const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  match.team1Name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: match.winnerId == match.team1Id || setsWon1 > setsWon2
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Điểm các set S1, S2, S3... của Team 1
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: sets.isNotEmpty
                                    ? sets.map((s) {
                                        final isSetWon = s.score1 > s.score2;
                                        return Container(
                                          constraints: const BoxConstraints(minWidth: 26),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          margin: const EdgeInsets.only(left: 4),
                                          decoration: BoxDecoration(
                                            color: isSetWon
                                                ? AppTheme.primary.withValues(alpha: 0.12)
                                                : colors.bgSurface,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSetWon
                                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                                  : colors.border.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${s.score1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSetWon ? FontWeight.w900 : FontWeight.w600,
                                              color: isSetWon
                                                  ? AppTheme.primary
                                                  : colors.textSecondary,
                                            ),
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 26),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: setsWon1 > setsWon2
                                                ? AppTheme.primary.withValues(alpha: 0.12)
                                                : colors.bgSurface,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: setsWon1 > setsWon2
                                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                                  : colors.border,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$setsWon1',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: setsWon1 > setsWon2 ? FontWeight.w900 : FontWeight.w600,
                                              color: setsWon1 > setsWon2
                                                  ? AppTheme.primary
                                                  : colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Team 2
                          Row(
                            children: [
                              _DoubleAvatarWidget(
                                initial1: t2Initials[0],
                                initial2: t2Initials[1],
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  match.team2Name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: match.winnerId == match.team2Id || setsWon2 > setsWon1
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Điểm các set S1, S2, S3... của Team 2
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: sets.isNotEmpty
                                    ? sets.map((s) {
                                        final isSetWon = s.score2 > s.score1;
                                        return Container(
                                          constraints: const BoxConstraints(minWidth: 26),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          margin: const EdgeInsets.only(left: 4),
                                          decoration: BoxDecoration(
                                            color: isSetWon
                                                ? AppTheme.primary.withValues(alpha: 0.12)
                                                : colors.bgSurface,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSetWon
                                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                                  : colors.border.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${s.score2}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSetWon ? FontWeight.w900 : FontWeight.w600,
                                              color: isSetWon
                                                  ? AppTheme.primary
                                                  : colors.textSecondary,
                                            ),
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 26),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: setsWon2 > setsWon1
                                                ? AppTheme.primary.withValues(alpha: 0.12)
                                                : colors.bgSurface,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: setsWon2 > setsWon1
                                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                                  : colors.border,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$setsWon2',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: setsWon2 > setsWon1 ? FontWeight.w900 : FontWeight.w600,
                                              color: setsWon2 > setsWon1
                                                  ? AppTheme.primary
                                                  : colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
                const SizedBox(height: 8),

                // ── BOTTOM FOOTER: STATUS, TIME, COURT & ROUND ──
                Row(
                  children: [
                    // Status Badge
                    if (match.isBye || match.team1Name.toUpperCase() == 'BYE' || match.team2Name.toUpperCase() == 'BYE')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'VÀO THẲNG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      )
                    else if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.sensors, size: 9, color: Color(0xFFEF4444)),
                          ],
                        ),
                      )
                    else if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'ĐÃ KẾT THÚC',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          'SẮP ĐẤU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),

                    // Time
                    Icon(Icons.access_time_rounded, size: 10, color: colors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Court
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view_rounded, size: 10, color: colors.textMuted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Round / Match Number
                    Text(
                      roundLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
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

class _DoubleAvatarWidget extends StatelessWidget {
  final String initial1;
  final String initial2;
  final Color color;

  const _DoubleAvatarWidget({
    required this.initial1,
    required this.initial2,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 44,
      height: 26,
      child: Stack(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial1,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial2,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
