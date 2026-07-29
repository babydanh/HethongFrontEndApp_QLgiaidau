import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Compact history of completed sets, aligned with the lower action area.
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          height: 32,
          child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: finishedSets.length,
            separatorBuilder: (_, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final score = finishedSets[index];
              final winnerIsTeam1 = score.score1 > score.score2;
              final accent = score.isFinished
                  ? (winnerIsTeam1
                        ? const Color(0xFF2979FF)
                        : const Color(0xFFEA580C))
                  : (colors?.border ?? Colors.grey);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors?.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'S${index + 1}: ${score.score1}-${score.score2}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: score.isFinished ? accent : colors?.textPrimary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
