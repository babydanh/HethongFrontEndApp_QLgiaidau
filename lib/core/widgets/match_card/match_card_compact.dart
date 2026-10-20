import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                l10n.matchRound(match.round),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700,
                    color: context.colors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ParticipantLabel(
              teamName: matchSideTeamName(match, 1),
              players: matchSidePlayers(match, 1),
              teamOnly: isFootballMatch(match),
              compact: true,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCompleted && match.winnerId == match.team1Id
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isCompleted && match.winnerId == match.team1Id
                    ? context.colors.success
                    : context.colors.textSecondary,
              ),
            ),
          ),
          Text(
            '${match.score1} - ${match.score2}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          Expanded(
            child: ParticipantLabel(
              teamName: matchSideTeamName(match, 2),
              players: matchSidePlayers(match, 2),
              teamOnly: isFootballMatch(match),
              compact: true,
              textAlign: TextAlign.right,
              crossAxisAlignment: CrossAxisAlignment.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCompleted && match.winnerId == match.team2Id
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isCompleted && match.winnerId == match.team2Id
                    ? context.colors.success
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
