import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

class MatchCardCompact extends StatelessWidget {
  final MatchModel match;
  final bool isCompleted;

  const MatchCardCompact({
    super.key, 
    required this.match,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          // Round badge
          Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('V${match.round}',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: context.colors.textMuted)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              match.team1Name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCompleted && match.winnerId == match.team1Id
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isCompleted && match.winnerId == match.team1Id
                    ? context.colors.success
                    : context.colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${match.score1} - ${match.score2}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              match.team2Name,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCompleted && match.winnerId == match.team2Id
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isCompleted && match.winnerId == match.team2Id
                    ? context.colors.success
                    : context.colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
