import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Clean, compact schedule match card matching design spec.
/// Features:
/// - Left: Double overlapping avatars, Team 1 & Team 2 names, Scores, VS badge with set scores
/// - Right: LIVE badge, Scheduled Time, Court location, Group / Round info
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

    // Calculate set score pill text based on match settings / sets
    String setPillText = '';
    if (match.sets.isNotEmpty) {
      final p1Sets = match.sets.where((s) => s.score1 > s.score2).length;
      final p2Sets = match.sets.where((s) => s.score2 > s.score1).length;
      setPillText = '$p1Sets - $p2Sets';
    } else {
      setPillText = '${match.score1} - ${match.score2}';
    }

    // Set details breakdown string if multiple sets exist (e.g. "11-7, 9-11, 11-8")
    String setDetailsStr = '';
    if (match.sets.length > 1) {
      setDetailsStr = match.sets.map((s) => '${s.score1}-${s.score2}').join(', ');
    }

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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFFFCA5A5) : const Color(0xFFF1F5F9),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            child: Row(
              children: [
                // ── Left Main Content (Teams & Scores) ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team 1 Row
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
                                fontWeight: match.winnerId == match.team1Id
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${match.score1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),

                      // Center VS & Sets Pill Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 52),
                            const Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                              ),
                              child: Text(
                                setPillText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            if (setDetailsStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '($setDetailsStr)',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Team 2 Row
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
                                fontWeight: match.winnerId == match.team2Id
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${match.score2}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Vertical Divider Line ──
                Container(
                  height: 70,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFFF1F5F9),
                ),

                // ── Right Side Info Column (Status, Time, Court, Round) ──
                SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  fontSize: 10,
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

                      const SizedBox(height: 6),

                      // Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Court
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.grid_view_rounded, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Group / Round
                      Text(
                        roundLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
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
