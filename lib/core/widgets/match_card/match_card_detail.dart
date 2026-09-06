import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final isLive = match.status == AppConstants.matchLive;
    final isCompleted = match.status == AppConstants.matchCompleted;
    final scheduleText = match.scheduledTime != null
        ? DateFormatterUtils.formatDateTime(match.scheduledTime!.toLocal())
        : l10n.liveNotScheduled;
    final venueText = _venueText(match, l10n);
    final tournamentText = (match.tournamentName ?? '').trim().isNotEmpty
        ? match.tournamentName!.trim()
        : l10n.publicProfileTournamentFallback;
    final refereeText = (match.refereeName ?? '').trim().isNotEmpty
        ? match.refereeName!.trim()
        : l10n.liveUnknownValue;

    final isLiteMatch = match.tournamentConfig?['isLite'] == true ||
        match.tournamentConfig?['mode']?.toString().toUpperCase() == 'LITE';
    final canScoreMatch = isReferee || !isReadOnly || isLiteMatch;

    return GestureDetector(
      onTap: match.hasTeams
          ? () {
              if (isReferee && tournamentId.isNotEmpty) {
                context.push('/organizer/tournaments/$tournamentId/ops/match/${match.id}');
              } else {
                context.push('/live/${match.id}${tournamentId.isNotEmpty ? '?tournamentId=$tournamentId' : ''}');
              }
            }
          : null,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 8,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        l10n.matchTableLive,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournamentText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _roundLabel(match, l10n),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
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
              _buildTeamRow(
                context,
                match.team2Name,
                match.score2,
                isWinner: isCompleted && match.winnerId == match.team2Id,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    _infoRow(
                      context,
                      Icons.schedule_rounded,
                      l10n.liveScheduledTimeLabel,
                      scheduleText,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      context,
                      Icons.location_on_rounded,
                      l10n.matchesFilterLocation,
                      venueText,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      context,
                      Icons.verified_user_rounded,
                      l10n.infoReferee,
                      refereeText,
                    ),
                    if (match.sets.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.sports_score_rounded,
                        l10n.liveSetScoresTitle,
                        match.sets
                            .asMap()
                            .entries
                            .map(
                              (e) =>
                                  'S${e.key + 1}: ${e.value.score1}-${e.value.score2}',
                            )
                            .join('  |  '),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive
                              ? context.colors.error
                              : AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                          if (canScoreMatch && tournamentId.isNotEmpty) {
                            context.push('/organizer/tournaments/$tournamentId/ops/match/${match.id}');
                          } else {
                            context.push('/live/${match.id}${tournamentId.isNotEmpty ? '?tournamentId=$tournamentId' : ''}');
                          }
                        },
                        icon: Icon(
                          isLive
                              ? Icons.live_tv_rounded
                              : (canScoreMatch
                                    ? Icons.edit_note_rounded
                                    : Icons.sports_score_rounded),
                          size: 18,
                        ),
                        label: Text(
                          isLive
                              ? l10n.liveOpenScoreboardShort
                              : (canScoreMatch
                                    ? l10n.officialScoreScoringTab
                                    : l10n.liveOpenScoreboardShort),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roundLabel(MatchModel match, AppLocalizations l10n) {
    return MatchRoundLabel.formatRound(
      match: match,
      l10n: l10n,
    );
  }

  String _venueText(MatchModel match, AppLocalizations l10n) {
    final location = TournamentLocationFormatter.matchFullLocationFromConfig(
      courtName: match.court,
      courtAddress: match.courtAddress,
      tournamentConfig: match.tournamentConfig,
    );
    return location.isEmpty ? l10n.matchTableUnassignedCourt : location;
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
