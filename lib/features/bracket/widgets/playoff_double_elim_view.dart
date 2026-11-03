import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Rounds shown per page, like the Web `PagedDoubleElimView`.
const int kPlayoffRoundsPerPage = 3;

/// One titled round of a branch (the grand final rides at the end of winners).
class PlayoffRound {
  const PlayoffRound(this.label, this.matches);

  final String label;
  final List<MatchModel> matches;
}

/// Splits double-elimination matches into the two branches. The grand final(s)
/// are appended to the winners branch as a last round.
({List<PlayoffRound> winners, List<PlayoffRound> losers}) buildPlayoffBranches(
  List<MatchModel> matches,
  AppLocalizations l10n,
) {
  final winners = <int, List<MatchModel>>{};
  final losers = <int, List<MatchModel>>{};
  final finals = <MatchModel>[];
  for (final m in matches) {
    if (m.status == 'cancelled' || m.isFullByeMatch) continue;
    switch (m.bracketPosition.bracket) {
      case 'winners':
        winners.putIfAbsent(m.round, () => []).add(m);
      case 'losers':
        losers.putIfAbsent(m.round, () => []).add(m);
      default:
        finals.add(m);
    }
  }

  int byPosition(MatchModel a, MatchModel b) =>
      a.bracketPosition.position.compareTo(b.bracketPosition.position);

  List<PlayoffRound> toRounds(
    Map<int, List<MatchModel>> byRound,
    String Function(int fromEnd, int round) label,
  ) {
    final rounds = byRound.keys.toList()..sort();
    return [
      for (var i = 0; i < rounds.length; i++)
        PlayoffRound(
          label(rounds.length - (i + 1), rounds[i]),
          byRound[rounds[i]]!..sort(byPosition),
        ),
    ];
  }

  final winnerRounds = toRounds(winners, (fromEnd, _) {
    if (fromEnd == 0) return l10n.doubleElimUpperGrandFinal;
    if (fromEnd == 1) return l10n.doubleElimUpperSemifinal;
    return MatchRoundLabel.doubleUpperHeader(fromEnd, l10n: l10n);
  });
  final loserRounds = toRounds(losers, (fromEnd, round) {
    if (fromEnd == 0) return l10n.doubleElimLowerGrandFinal;
    if (fromEnd == 1) return l10n.doubleElimLowerSemifinal;
    return MatchRoundLabel.doubleLowerHeader(fromEnd, round, l10n: l10n);
  });
  if (finals.isNotEmpty) {
    finals.sort((a, b) => a.round.compareTo(b.round));
    winnerRounds.add(PlayoffRound(l10n.doubleElimGrandFinal, finals));
  }
  return (winners: winnerRounds, losers: loserRounds);
}

/// Public playoff of a group-stage + double-elimination division: winners and
/// losers branches as tabs, rounds listed [kPlayoffRoundsPerPage] per page.
class PlayoffDoubleElimView extends StatefulWidget {
  const PlayoffDoubleElimView({
    super.key,
    required this.matches,
    required this.tournamentId,
  });

  final List<MatchModel> matches;
  final String tournamentId;

  @override
  State<PlayoffDoubleElimView> createState() => _PlayoffDoubleElimViewState();
}

class _PlayoffDoubleElimViewState extends State<PlayoffDoubleElimView> {
  bool _losers = false;
  final Map<bool, int> _pages = {false: 0, true: 0};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final branches = buildPlayoffBranches(widget.matches, l10n);
    final rounds = _losers ? branches.losers : branches.winners;
    final pageCount = (rounds.length / kPlayoffRoundsPerPage).ceil().clamp(
      1,
      1000,
    );
    final page = (_pages[_losers] ?? 0).clamp(0, pageCount - 1);
    final visible = rounds
        .skip(page * kPlayoffRoundsPerPage)
        .take(kPlayoffRoundsPerPage);

    void go(int target) => setState(() => _pages[_losers] = target);

    Widget arrow(IconData icon, String tooltip, int? target) => IconButton(
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
      onPressed: target == null ? null : () => go(target),
      icon: Icon(
        icon,
        color: target == null
            ? colors.textMuted.withValues(alpha: 0.3)
            : AppTheme.primary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ModeChip(
                label: l10n.playoff_tabWinners,
                selected: !_losers,
                onTap: () => setState(() => _losers = false),
              ),
              ModeChip(
                label: l10n.playoff_tabLosers,
                selected: _losers,
                onTap: () => setState(() => _losers = true),
              ),
            ],
          ),
          if (pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                arrow(
                  Icons.chevron_left_rounded,
                  l10n.playoff_prevPage,
                  page > 0 ? page - 1 : null,
                ),
                Text(
                  l10n.playoff_pageIndicator(page + 1, pageCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                arrow(
                  Icons.chevron_right_rounded,
                  l10n.playoff_nextPage,
                  page < pageCount - 1 ? page + 1 : null,
                ),
              ],
            ),
          if (rounds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.doubleElimNoBracket,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
          for (final round in visible) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                round.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            for (final match in round.matches)
              RoundMatchCard(
                match: match,
                onTap: () => showGroupMatchSheet(
                  context,
                  match: match,
                  tournamentId: widget.tournamentId,
                  title: round.label,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
