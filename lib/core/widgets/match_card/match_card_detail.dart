import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:go_router/go_router.dart';

class MatchCardDetail extends StatelessWidget {
  final MatchModel match;
  final bool isReferee;
  final bool isReadOnly;
  final String tournamentId;

  const MatchCardDetail({
    super.key,
    required this.match,
    this.isReferee = false,
    this.isReadOnly = false,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == AppConstants.matchLive;
    final isCompleted = match.status == AppConstants.matchCompleted;

    return GestureDetector(
      onTap: match.hasTeams
          ? () {
              context.go('/live/${match.id}');
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isLive
                ? context.colors.error
                : isCompleted
                ? context.colors.success.withValues(alpha: 0.5)
                : context.colors.border,
            width: isLive ? 2 : 1,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: context.colors.error.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live indicator
            if (isLive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: context.liveGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMedium - 1),
                    topRight: Radius.circular(AppTheme.radiusMedium - 1),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            // Team 1
            _buildTeamRow(
              context,
              match.team1Name,
              match.score1,
              isWinner: isCompleted && match.winnerId == match.team1Id,
            ),
            Divider(
              color: context.colors.border,
              height: 1,
              indent: 12,
              endIndent: 12,
            ),
            // Team 2
            _buildTeamRow(
              context,
              match.team2Name,
              match.score2,
              isWinner: isCompleted && match.winnerId == match.team2Id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    BuildContext context,
    String name,
    int score, {
    bool isWinner = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          if (isWinner) ...[
            const Icon(Icons.emoji_events, size: 14, color: AppTheme.accent),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
                color: isWinner
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: isWinner
                  ? context.colors.success.withValues(alpha: 0.15)
                  : context.colors.bgSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isWinner
                      ? context.colors.success
                      : context.colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
