import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_board.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_layout.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_seed_labels.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One titled round of a branch (the grand final rides at the end of winners).
class PlayoffRound {
  const PlayoffRound(this.label, this.matches);

  final String label;
  final List<MatchModel> matches;
}

int _byPosition(MatchModel a, MatchModel b) =>
    a.bracketPosition.position.compareTo(b.bracketPosition.position);

/// Single elimination has one branch; rounds are named from the final backwards.
List<PlayoffRound> _singleElimRounds(
  List<MatchModel> matches,
  AppLocalizations l10n,
) {
  final byRound = <int, List<MatchModel>>{};
  for (final m in matches) {
    if (m.status == 'cancelled' || m.isFullByeMatch) continue;
    byRound.putIfAbsent(m.round, () => []).add(m);
  }
  final rounds = byRound.keys.toList()..sort();
  return [
    for (final round in rounds)
      PlayoffRound(
        MatchRoundLabel.knockoutRoundName(round, rounds.last, l10n: l10n),
        byRound[round]!..sort(_byPosition),
      ),
  ];
}

/// Splits double-elimination matches into the two branches. The grand final(s)
/// are appended to the winners branch as a last round. Single elimination
/// yields only the winners branch.
({List<PlayoffRound> winners, List<PlayoffRound> losers}) buildPlayoffBranches(
  List<MatchModel> matches,
  AppLocalizations l10n,
) {
  if (!matches.any(isDoubleEliminationMatch)) {
    return (winners: _singleElimRounds(matches, l10n), losers: const []);
  }
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

  List<PlayoffRound> toRounds(
    Map<int, List<MatchModel>> byRound,
    String Function(int fromEnd, int round) label,
  ) {
    final rounds = byRound.keys.toList()..sort();
    return [
      for (var i = 0; i < rounds.length; i++)
        PlayoffRound(
          label(rounds.length - (i + 1), rounds[i]),
          byRound[rounds[i]]!..sort(_byPosition),
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

const double _bracketGap = 14;
const double _minCardWidth = 96;
const double _maxCardWidth = 200;

/// Minimum fling speed (px/s) on the stepper row that counts as a page turn.
const double _swipeMinVelocity = 250;

/// Public playoff of a group-stage + double-elimination division, drawn like the
/// Web `PagedDoubleElimView`: winners / losers tabs, a window of
/// [kBracketVisibleRounds] rounds with connector lines, Trước/Sau to slide it
/// (the old window fades out while the new one slides in).
class PlayoffDoubleElimView extends StatefulWidget {
  const PlayoffDoubleElimView({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.canScoreMatch = false,
    this.seedLabels,
    this.onOpenFull,
  });

  final List<MatchModel> matches;
  final String tournamentId;
  final bool canScoreMatch;

  /// Opens the full-screen diagram; null hides the expand button.
  final VoidCallback? onOpenFull;

  /// "Nhất A / Nhì B" placeholders for empty round-one slots; null hides them.
  final PlayoffSeedLabels? seedLabels;

  @override
  State<PlayoffDoubleElimView> createState() => _PlayoffDoubleElimViewState();
}

class _PlayoffDoubleElimViewState extends State<PlayoffDoubleElimView> {
  // Null until the user picks one: the default follows the live data.
  bool? _losers;
  final Map<bool, int> _active = {};

  // Which way the last page turn went, so the new window slides in from there.
  bool _forward = true;

  // Which way the last page turn went, so the new window slides in from there.
  bool _forward = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branches = buildPlayoffBranches(widget.matches, l10n);
    List<List<MatchModel>> raw(List<PlayoffRound> r) => [
      for (final round in r) round.matches,
    ];
    final hasLosers = branches.losers.isNotEmpty;
    final isDouble = widget.matches.any(isDoubleEliminationMatch);
    final losers =
        hasLosers &&
        (_losers ??
            defaultLosersBranch(raw(branches.winners), raw(branches.losers)));
    final rounds = losers ? branches.losers : branches.winners;
    final active = rounds.isEmpty
        ? 0
        : (_active[losers] ?? defaultActiveRound(raw(rounds))).clamp(
            0,
            rounds.length - 1,
          );
    final start = bracketWindowStart(active, rounds.length);
    final visible = rounds.skip(start).take(kBracketVisibleRounds).toList();
    final titles = {
      for (final round in visible)
        for (final m in round.matches) m.id: round.label,
    };

    void select(int index) => setState(() {
      _forward = index >= active;
      _active[losers] = index;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDouble)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ModeChip(
                  label:
                      '${l10n.playoff_tabWinners} (${_count(branches.winners)})',
                  selected: !losers,
                  onTap: () => setState(() => _losers = false),
                ),
                if (hasLosers)
                  ModeChip(
                    label:
                        '${l10n.playoff_tabLosers} (${_count(branches.losers)})',
                    selected: losers,
                    onTap: () => setState(() => _losers = true),
                  ),
              ],
            ),
          if (rounds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.doubleElimNoBracket,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            )
          else ...[
            // Swiping the stepper row turns the page like its arrows; the
            // diagram below keeps its own horizontal scroll and the tab swipe.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity <= -_swipeMinVelocity &&
                    active < rounds.length - 1) {
                  select(active + 1);
                } else if (velocity >= _swipeMinVelocity && active > 0) {
                  select(active - 1);
                }
              },
              child: _RoundStepper(
                label: rounds[active].label,
                position: '${active + 1}/${rounds.length}',
                onPrev: active > 0 ? () => select(active - 1) : null,
                onNext: active < rounds.length - 1
                    ? () => select(active + 1)
                    : null,
                onExpand: widget.onOpenFull,
              ),
            ),
            ClipRect(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_forward ? 0.15 : -0.15, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('playoff-window-$losers-$start'),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth =
                          ((constraints.maxWidth -
                                      (kBracketVisibleRounds - 1) *
                                          _bracketGap) /
                                  kBracketVisibleRounds)
                              .clamp(_minCardWidth, _maxCardWidth);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RoundPills(
                              rounds: visible,
                              firstIndex: start,
                              active: active,
                              cardWidth: cardWidth,
                              onSelect: select,
                            ),
                            const SizedBox(height: 10),
                            PlayoffBracketBoard(
                              columns: [for (final r in visible) r.matches],
                              feeders: buildFeeders(widget.matches),
                              cardWidth: cardWidth,
                              gap: _bracketGap,
                              seedLabels: widget.seedLabels,
                              onTap: (match) => showGroupMatchSheet(
                                context,
                                match: match,
                                tournamentId: widget.tournamentId,
                                title: titles[match.id] ?? '',
                                canScore: widget.canScoreMatch,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _count(List<PlayoffRound> rounds) =>
      rounds.fold(0, (sum, round) => sum + round.matches.length);
}

/// "‹  Tứ kết · 2/4  ›" row that slides the window one round at a time.
class _RoundStepper extends StatelessWidget {
  const _RoundStepper({
    required this.label,
    required this.position,
    required this.onPrev,
    required this.onNext,
    this.onExpand,
  });

  final String label;
  final String position;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  /// Opens the full-screen diagram; null hides the button.
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    Widget arrow(
      IconData icon,
      String tooltip,
      VoidCallback? onTap, {
      Key? key,
    }) => IconButton(
      key: key,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null
            ? colors.textMuted.withValues(alpha: 0.3)
            : AppTheme.primary,
      ),
    );
    return Row(
      children: [
        arrow(Icons.chevron_left_rounded, l10n.playoff_prevRound, onPrev),
        Expanded(
          child: Text(
            '$label · $position',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        ),
        arrow(Icons.chevron_right_rounded, l10n.playoff_nextRound, onNext),
        if (onExpand != null)
          arrow(
            Icons.open_in_full_rounded,
            l10n.imageViewerZoomIn,
            onExpand,
            key: const ValueKey('playoff-open-full'),
          ),
      ],
    );
  }
}

/// One pill above each visible column; tapping re-centres the window on it.
class _RoundPills extends StatelessWidget {
  const _RoundPills({
    required this.rounds,
    required this.firstIndex,
    required this.active,
    required this.cardWidth,
    required this.onSelect,
  });

  final List<PlayoffRound> rounds;
  final int firstIndex;
  final int active;
  final double cardWidth;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var i = 0; i < rounds.length; i++) ...[
          if (i > 0) const SizedBox(width: _bracketGap),
          SizedBox(
            width: cardWidth,
            child: InkWell(
              onTap: () => onSelect(firstIndex + i),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: firstIndex + i == active
                      ? AppTheme.primary
                      : colors.chipBackground,
                ),
                child: Text(
                  rounds[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: firstIndex + i == active
                        ? Colors.white
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
