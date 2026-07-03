import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Thanh lịch sử set — hiển thị các set đã chốt dạng badge ngang.
/// Dùng chung cho tất cả môn (Tennis, Pickleball, Badminton, ...).
class SetHistoryBar extends StatelessWidget {
  final List<SetScoreData> finishedSets;
  final int team1SetWins;
  final int team2SetWins;

  const SetHistoryBar({
    super.key,
    required this.finishedSets,
    required this.team1SetWins,
    required this.team2SetWins,
  });

  @override
  Widget build(BuildContext context) {
    if (finishedSets.isEmpty) return const SizedBox(height: 8);

    final colors = Theme.of(context).extension<AppColorsExtension>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tỉ số set
          Row(
            children: [
              Text(
                'Set: $team1SetWins - $team2SetWins',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors?.textPrimary),
              ),
              const SizedBox(width: 8),
              if (finishedSets.length >= 2)
                Text(
                  '(${finishedSets.length} sets)',
                  style: TextStyle(fontSize: 10, color: colors?.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: finishedSets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final s = finishedSets[i];
                final winnerIs1 = s.score1 > s.score2;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors?.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: s.isFinished
                          ? (winnerIs1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C)).withValues(alpha: 0.4)
                          : (colors?.border ?? Colors.grey),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('S${i + 1}: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors?.textMuted)),
                      Text(
                        '${s.score1}-${s.score2}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.isFinished
                              ? (winnerIs1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C))
                              : colors?.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
