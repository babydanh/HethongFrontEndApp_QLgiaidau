import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One match of the board, laid out like the Web row: a code/number column,
/// the two sides stacked with their score on the same line, then "Sân · giờ".
/// [onTap] is only set for live rows; [onScore] / [onSchedule] are the
/// organiser buttons (null hides them).
class ResultsMatchRow extends StatelessWidget {
  const ResultsMatchRow({
    super.key,
    required this.match,
    required this.label,
    this.onTap,
    this.onScore,
    this.onSchedule,
  });

  final MatchModel match;

  /// `#V1602` for organisers, the running number for viewers.
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onScore;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.muted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SideLine(match: match, side: 1),
                  const SizedBox(height: 4),
                  _SideLine(match: match, side: 2),
                  const SizedBox(height: 4),
                  Text(
                    _meta(l10n),
                    style: TextStyle(fontSize: 11, color: colors.muted),
                  ),
                ],
              ),
            ),
            if (onScore != null) ...[
              const SizedBox(width: 8),
              LavishIconBox(
                key: ValueKey('results-score-${match.id}'),
                size: 36,
                tooltip: l10n.resultsBoard_enterScore,
                onTap: onScore,
                child: const Icon(Icons.edit_outlined),
              ),
            ],
            if (onSchedule != null) ...[
              const SizedBox(width: 6),
              LavishIconBox(
                key: ValueKey('results-schedule-${match.id}'),
                size: 36,
                tone: LavishTone.warn,
                tooltip: l10n.matchSchedule_title,
                onTap: onSchedule,
                child: const Icon(Icons.event_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Sân 1 · 07:00", or "Chưa xếp lịch".
  String _meta(AppLocalizations l10n) {
    final time = match.completedAt ?? match.scheduledTime;
    final court = TournamentLocationFormatter.matchShortCourt(
      match.court.isNotEmpty ? match.court : match.courtName,
    );
    final when = [
      if (court.isNotEmpty) court,
      if (time != null) DateFormat('HH:mm').format(time.toLocal()),
    ].join(' · ');
    return when.isEmpty ? l10n.resultsBoard_unscheduled : when;
  }
}

/// One side of the match with its set scores on the same line.
class _SideLine extends StatelessWidget {
  const _SideLine({required this.match, required this.side});

  final MatchModel match;
  final int side;

  bool get _showScore =>
      match.hasTeams && (isLiveMatch(match) || isMatchClosed(match));

  bool get _won {
    if (!isMatchClosed(match) || match.winnerId.isEmpty) return false;
    return match.winnerId == (side == 1 ? match.team1Id : match.team2Id);
  }

  String get _score {
    final sets = match.scoreHistory.isNotEmpty
        ? match.scoreHistory
        : [SetScore(score1: match.score1, score2: match.score2)];
    return sets.map((s) => side == 1 ? s.score1 : s.score2).join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ParticipantSideLines(
              teamName: matchSideTeamName(match, side),
              players: matchSidePlayers(match, side),
              logoUrl: side == 1 ? match.team1LogoUrl : match.team2LogoUrl,
              teamOnly: isFootballMatch(match),
              won: _won,
            ),
          ),
        ),
        if (_showScore)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Text(
              _score,
              style: TextStyle(
                fontSize: 13,
                fontWeight: _won ? FontWeight.w800 : FontWeight.w600,
                color: _won ? AppTheme.primary : colors.text,
              ),
            ),
          ),
      ],
    );
  }
}
