import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Clean, specs-driven schedule match card.
/// Features:
/// - Top: Team 1 & Team 2 with real API Set Score Columns (S1, S2, S3...) & Total score column (no VS text clutter)
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

    // Calculate sets won & set columns
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                // ── TOP SECTION: TEAMS & REAL API SET SCORE COLUMNS ──
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
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
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
                                color: const Color(0xFF16A34A),
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
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── SET SCORE COLUMNS ──
                    Row(
                      children: [
                        if (sets.isNotEmpty)
                          ...sets.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final s = entry.value;
                            final isT1Win = s.score1 > s.score2;
                            final isT2Win = s.score2 > s.score1;

                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 32,
                              child: Column(
                                children: [
                                  Text(
                                    'S$idx',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.score1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isT1Win ? FontWeight.w900 : FontWeight.w500,
                                      color: isT1Win ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${s.score2}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isT2Win ? FontWeight.w900 : FontWeight.w500,
                                      color: isT2Win ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        // Total Sets Column (TỔNG)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TỔNG',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$setsWon1',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: match.winnerId == match.team1Id || setsWon1 > setsWon2
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$setsWon2',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: match.winnerId == match.team2Id || setsWon2 > setsWon1
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // ── BOTTOM FOOTER: STATUS, TIME, COURT & ROUND ──
                Row(
                  children: [
                    // Status Badge
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.sensors, size: 10, color: Color(0xFFDC2626)),
                          ],
                        ),
                      )
                    else if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Text(
                          'ĐÃ KẾT THÚC',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'SẮP ĐẤU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),

                    // Time
                    const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Court
                    const Icon(Icons.grid_view_rounded, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const Spacer(),

                    // Round / Match Number
                    Text(
                      roundLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
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
    return SizedBox(
      width: 44,
      height: 26,
      child: Stack(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
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
                color: Colors.white,
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
