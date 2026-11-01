import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_board_palette.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mockup `.row` grid: a 44px code column, the two sides, a 56px points column.
const double _codeWidth = 44;
const double _pointsWidth = 56;
const double _gap = 6;

/// One match of the board, laid out like the Lavish mockup: code (red dot when
/// live), the two sides with a "vs" line between them and their points on the
/// same line, then a meta line. [onTap] is only set for live rows; [onScore] /
/// [onSchedule] are the organiser buttons (null hides them).
class ResultsMatchRow extends StatelessWidget {
  const ResultsMatchRow({
    super.key,
    required this.match,
    required this.label,
    this.roundLabel,
    this.waitingFor = const (null, null),
    this.onTap,
    this.onScore,
    this.onSchedule,
  });

  final MatchModel match;

  /// `#V1602` for organisers, the running number for viewers.
  final String label;

  /// Round name shown as a badge on live rows (the live box mixes rounds).
  final String? roundLabel;

  /// Codes of the matches feeding side 1 and side 2 when those are still empty.
  final (String?, String?) waitingFor;
  final VoidCallback? onTap;
  final VoidCallback? onScore;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = ResultsBoardPalette.of(context);
    final live = isLiveMatch(match);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Code(match: match, label: label, live: live),
                const SizedBox(width: _gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SideLine(match: match, side: 1, waiting: waitingFor.$1),
                      _VsLine(label: l10n.resultsBoard_vs, palette: palette),
                      _SideLine(match: match, side: 2, waiting: waitingFor.$2),
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: _codeWidth + _gap),
              child: _MetaLine(
                match: match,
                live: live,
                roundLabel: roundLabel,
                palette: palette,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.code`: 11.5px / 800, with the red `.dot` in front on live matches.
class _Code extends StatelessWidget {
  const _Code({required this.match, required this.label, required this.live});

  final MatchModel match;
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final palette = ResultsBoardPalette.of(context);
    return SizedBox(
      width: _codeWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              Container(
                key: ValueKey('results-live-dot-${match.id}'),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ResultsBoardPalette.live,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ResultsBoardPalette.liveRing,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.vs`: tiny "vs" followed by a hairline, ending before the points column.
class _VsLine extends StatelessWidget {
  const _VsLine({required this.label, required this.palette});

  final String label;
  final ResultsBoardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, color: palette.faint)),
          const SizedBox(width: 6),
          Expanded(child: Container(height: 1, color: palette.chipBg)),
          const SizedBox(width: _pointsWidth),
        ],
      ),
    );
  }
}

/// One side of the match with its points in the right column.
class _SideLine extends StatelessWidget {
  const _SideLine({
    required this.match,
    required this.side,
    required this.waiting,
  });

  final MatchModel match;
  final int side;
  final String? waiting;

  bool get _closed => isMatchClosed(match);

  bool get _won {
    if (!_closed || match.winnerId.isEmpty) return false;
    return match.winnerId == (side == 1 ? match.team1Id : match.team2Id);
  }

  bool get _lost => _closed && match.winnerId.isNotEmpty && !_won;

  bool get _showPoints => match.hasTeams && (isLiveMatch(match) || _closed);

  String get _points {
    if (!_showPoints) return '–';
    final sets = match.scoreHistory.isNotEmpty
        ? match.scoreHistory
        : [SetScore(score1: match.score1, score2: match.score2)];
    return sets.map((s) => side == 1 ? s.score1 : s.score2).join('  ');
  }

  Color _pointsColor(ResultsBoardPalette palette) {
    if (!_showPoints || _lost) return palette.fadedScore;
    return isLiveMatch(match) ? ResultsBoardPalette.live : palette.text;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ResultsBoardPalette.of(context);
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
              waitingFor: waiting,
            ),
          ),
        ),
        SizedBox(
          width: _pointsWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _points,
              key: ValueKey('results-points-${match.id}-$side'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _pointsColor(palette),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.meta`: 11.5px line. Live rows read "Sân 2 [Bán kết]"; the others read
/// "08:30 [Sân 1]" (the grey `b` badge is the second item).
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.match,
    required this.live,
    required this.roundLabel,
    required this.palette,
  });

  final MatchModel match;
  final bool live;
  final String? roundLabel;
  final ResultsBoardPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final id = match.id;
    final time = match.completedAt ?? match.scheduledTime;
    final court = TournamentLocationFormatter.matchShortCourt(
      match.court.isNotEmpty ? match.court : match.courtName,
    );
    final clock = time == null
        ? ''
        : DateFormat('HH:mm').format(time.toLocal());
    final plain = live ? court : clock;
    final badge = live ? (roundLabel ?? '') : court;
    if (plain.isEmpty && badge.isEmpty) {
      return Text(
        l10n.resultsBoard_unscheduled,
        key: ValueKey('results-meta-none-$id'),
        style: _style(palette),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (plain.isNotEmpty)
          Text(
            plain,
            key: ValueKey(
              live ? 'results-meta-court-$id' : 'results-meta-time-$id',
            ),
            style: _style(palette),
          ),
        if (badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: palette.badgeBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              badge,
              key: ValueKey('results-meta-badge-$id'),
              style: _style(palette).copyWith(color: palette.badgeText),
            ),
          ),
      ],
    );
  }

  TextStyle _style(ResultsBoardPalette palette) =>
      TextStyle(fontSize: 11.5, color: palette.muted);
}
