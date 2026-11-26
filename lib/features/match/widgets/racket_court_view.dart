import 'package:app_quanly_giaidau/domain/services/racket_court_layout.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_drag_widgets.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_scoreboard.dart';
import 'package:flutter/material.dart';

const _surface = Color(0xFFF7F7F9);
const _ink = Color(0xFF1B1B1F);
const _chipColor = Color(0xFFFF7A00);
const _bannerColor = Color(0xFFFFF7D1);
const _motion = Duration(milliseconds: 240);

/// Badminton / tennis court. It is drawn by the pickleball [CourtScoreboard]
/// (same halves, buttons and sizes); this view only maps the racket state
/// onto it: tennis points as text, the server and receiver cells, the chips
/// and the banner above. Drags and taps reuse the pickleball court rules.
class RacketCourtView extends StatelessWidget {
  const RacketCourtView({
    super.key,
    required this.cells,
    required this.team1Players,
    required this.team2Players,
    required this.team1Name,
    required this.team2Name,
    required this.endsFlipped,
    required this.axis,
    required this.scoreText1,
    required this.scoreText2,
    required this.servingTeam,
    required this.call,
    required this.setText,
    required this.resolve,
    required this.onDrop,
    this.chips = const [],
    this.banner,
    this.canUndo = false,
    this.onScore,
    this.onUndo,
    this.onSwitchEnds,
    this.onMenu,
    this.onPickServer,
    this.onFinishSet,
    this.finishSetEnabled = true,
    this.onPickWinner,
    this.pickWinnerEnabled = true,
    this.onForceWin,
    this.onToggleOverride,
    this.overrideEnabled = false,
    this.sportIcon = 'tennis',
  });

  final List<RacketCourtCell> cells;

  /// Full names; empty when the match has no player list (the team name shows).
  final List<String> team1Players;
  final List<String> team2Players;
  final String team1Name;
  final String team2Name;

  /// Team 2 on the first half (left, or top when upright).
  final bool endsFlipped;
  final Axis axis;
  final String scoreText1;
  final String scoreText2;

  /// Team whose score box is highlighted; null when nobody is known to serve.
  final int? servingTeam;
  final String call;
  final String setText;
  final List<String> chips;
  final String? banner;
  final bool canUndo;

  /// Null for a viewer: no score buttons, no drag, no taps.
  final void Function(int team, bool increment)? onScore;
  final VoidCallback? onUndo;
  final VoidCallback? onSwitchEnds;

  /// The "Choose server" entry of the ⋯ menu.
  final VoidCallback? onMenu;

  /// Non-null while a tap on a player is handled by the panel: choosing the
  /// first server, or (tennis doubles) the serve/receive menu.
  final void Function(int team, int playerIndex)? onPickServer;
  final ResolveCourtDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  /// Set / match controls drawn on the net; a null callback hides its icon.
  final VoidCallback? onFinishSet;
  final bool finishSetEnabled;
  final VoidCallback? onPickWinner;
  final bool pickWinnerEnabled;

  /// ⋯ menu items: quick win and the override switch (Strict only).
  final VoidCallback? onForceWin;
  final VoidCallback? onToggleOverride;
  final bool overrideEnabled;

  /// Mark in the corner of the court: 'tennis' or 'badminton'.
  final String sportIcon;

  bool get _interactive => onScore != null;

  RacketCourtCell? _cellWith(CourtCellRole role) {
    for (final cell in cells) {
      if (cell.role == role) return cell;
    }
    return null;
  }

  CourtTeamSlots _slotsOf(int team) {
    int? playerAt({required bool right}) {
      for (final cell in cells) {
        if (cell.team == team && cell.rightCourt == right) {
          return cell.playerIndex;
        }
      }
      return null;
    }

    return CourtTeamSlots(
      rightPlayerIndex: playerAt(right: true),
      leftPlayerIndex: playerAt(right: false),
    );
  }

  CourtCell _courtCell(RacketCourtCell cell) =>
      cell.rightCourt ? CourtCell.right : CourtCell.left;

  CourtLayout _layout() {
    final server = _cellWith(CourtCellRole.server);
    final receiver = _cellWith(CourtCellRole.receiver);
    return CourtLayout(
      team1First: !endsFlipped,
      team1: _slotsOf(1),
      team2: _slotsOf(2),
      servingTeam: servingTeam,
      serverPlayerIndex: server?.playerIndex,
      serverCell: server == null ? null : _courtCell(server),
      callServerNumber: null,
      servingScore: null,
      receivingScore: null,
      receiverCell: receiver == null ? null : _courtCell(receiver),
      receiverPlayerIndex: receiver?.playerIndex,
    );
  }

  /// With no player list the team name stands in for the single player.
  List<String> _namesOf(List<String> players, String teamName) =>
      players.isEmpty ? [teamName] : players;

  @override
  Widget build(BuildContext context) {
    final interactive = _interactive;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _motion;
    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          if (chips.isNotEmpty || banner != null)
            _InfoRow(chips: chips, banner: banner),
          Expanded(
            child: CourtScoreboard(
              axis: axis,
              layout: _layout(),
              team1Players: _namesOf(team1Players, team1Name),
              team2Players: _namesOf(team2Players, team2Name),
              // The points are text; the number only feeds the plain display.
              scoreOf: (_) => 0,
              scoreTextOf: (team) => team == 1 ? scoreText1 : scoreText2,
              // A minus is a correction the notifier judges, not the board.
              canRemovePoint: (_) => true,
              lockReceiverPlus: false,
              onScoreChange: onScore,
              onLoseServe: null,
              loseServeChangesHand: false,
              callText: call,
              setText: setText,
              net: CourtNetActions(
                menu: CourtMenuActions(
                  onUndo: interactive && canUndo ? onUndo : null,
                  onPickServer: interactive ? onMenu : null,
                  onForceWin: onForceWin,
                  onToggleOverride: onToggleOverride,
                  overrideEnabled: overrideEnabled,
                ),
                onFinishSet: onFinishSet,
                finishSetEnabled: finishSetEnabled,
                onPickWinner: onPickWinner,
                pickWinnerEnabled: pickWinnerEnabled,
              ),
              onSwitchEnds: interactive ? onSwitchEnds : null,
              overrideEnabled: overrideEnabled,
              startedAt: null,
              setNumber: null,
              motion: motion,
              dragEnabled: interactive,
              resolve: resolve,
              onDrop: onDrop,
              onPlayerTap: onPickServer,
              sportIcon: sportIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.chips, required this.banner});

  final List<String> chips;
  final String? banner;

  @override
  Widget build(BuildContext context) {
    final banner = this.banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final text in chips)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _chipColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (banner != null)
          ColoredBox(
            color: _bannerColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                banner,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
