import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_data.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Bottom sheet with the full detail of one group match: full names, scores
/// per set, court, time and a shortcut to the live screen. Viewers who may
/// score ([canScore]: admin / organizer) get the score-entry popup instead, like
/// the management bracket cards.
Future<void> showGroupMatchSheet(
  BuildContext context, {
  required MatchModel match,
  required String tournamentId,
  required String title,
  bool canScore = false,
}) {
  if (canScore && match.hasTeams && !match.isBye) {
    return MatchScoreEntryChooser.show(
      context,
      match: match,
      tournamentId: tournamentId,
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _GroupMatchSheet(
      match: match,
      tournamentId: tournamentId,
      title: title,
      onViewMatch: () {
        Navigator.of(sheetContext).pop();
        context.push(
          NavigationHelper.getLiveMatchRoute(tournamentId, match.id),
        );
      },
    ),
  );
}

/// Status colour + label shared by the round cards and the sheet.
({Color color, String label}) groupMatchStatus(
  BuildContext context,
  MatchModel match,
) {
  final l10n = AppLocalizations.of(context)!;
  final colors = context.colors;
  if (match.isLive) {
    return (color: colors.error, label: l10n.groupStage_statusLive);
  }
  if (match.isCompleted) {
    return (color: colors.success, label: l10n.groupStage_statusDone);
  }
  return (color: colors.textMuted, label: l10n.groupStage_statusUpcoming);
}

/// "Sân 1 · 14:30 04/11", or "Chưa xếp sân" when nothing is scheduled.
String groupMatchPlace(BuildContext context, MatchModel match) {
  final l10n = AppLocalizations.of(context)!;
  final court = (match.courtName ?? '').trim();
  final time = match.scheduledTime;
  final parts = [
    if (court.isNotEmpty) court,
    if (time != null) DateFormat('HH:mm dd/MM').format(time.toLocal()),
  ];
  return parts.isEmpty ? l10n.groupStage_noCourt : parts.join(' · ');
}

/// Score of one side per set (or the goals), taken from the shared lines so
/// the matrix and the sheet can never disagree.
List<String> groupSideScores(MatchModel match, int side) => [
  for (final line in matchScoreLines(match, side)) line.split('-').first,
];

class _GroupMatchSheet extends StatelessWidget {
  const _GroupMatchSheet({
    required this.match,
    required this.tournamentId,
    required this.title,
    required this.onViewMatch,
  });

  final MatchModel match;
  final String tournamentId;
  final String title;
  final VoidCallback onViewMatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = groupMatchStatus(context, match);
    final hasWinner = match.isCompleted && match.winnerId.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: status.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final side in const [1, 2])
              _SideBlock(match: match, side: side, hasWinner: hasWinner),
            const SizedBox(height: 4),
            Text(
              groupMatchPlace(context, match),
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onViewMatch,
              child: Text(l10n.groupStage_viewMatch),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideBlock extends StatelessWidget {
  const _SideBlock({
    required this.match,
    required this.side,
    required this.hasWinner,
  });

  final MatchModel match;
  final int side;
  final bool hasWinner;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final scores = groupSideScores(match, side);
    final won =
        hasWinner &&
        match.winnerId == (side == 1 ? match.team1Id : match.team2Id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ParticipantSideLines(
                teamName: matchSideTeamName(match, side),
                players: matchSidePlayers(match, side),
                teamOnly: isFootballMatch(match),
                won: won,
                abbreviate: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (scores.isNotEmpty)
            Text(
              scores.join('   '),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: won ? AppTheme.primary : colors.textPrimary,
              ),
            ),
          if (hasWinner) ...[
            const SizedBox(width: 10),
            Text(
              won ? l10n.groupStage_won : l10n.groupStage_lost,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: won ? colors.success : colors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
