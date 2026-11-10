import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_card_parts.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_slot_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_layout.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_seed_labels.dart';
import 'package:flutter/material.dart';

const double _singlesCardHeight = 92;
const double _doublesCardHeight = 128;

/// Doubles show two player lines per side, so their cards are taller.
double bracketCardHeight(List<List<MatchModel>> columns) {
  final doubles = columns.any(
    (column) => column.any(
      (m) =>
          !isFootballMatch(m) &&
          (matchSidePlayers(m, 1).length > 1 ||
              matchSidePlayers(m, 2).length > 1),
    ),
  );
  return doubles ? _doublesCardHeight : _singlesCardHeight;
}

/// The visible rounds as columns of cards joined by connector lines.
class PlayoffBracketBoard extends StatelessWidget {
  const PlayoffBracketBoard({
    super.key,
    required this.columns,
    required this.feeders,
    required this.cardWidth,
    required this.gap,
    required this.onTap,
    this.seedLabels,
    this.editing,
    this.onDoubleTap,
  });

  final List<List<MatchModel>> columns;
  final Map<String, List<BracketFeeder>> feeders;
  final double cardWidth;
  final double gap;
  final ValueChanged<MatchModel> onTap;

  /// Placeholders ("Nhất A") for empty round-one slots; null shows "N/A".
  final PlayoffSeedLabels? seedLabels;

  /// Manager mode: slots with a participant can be dragged onto other slots.
  final BracketEditing? editing;

  /// Double tap on a card (managers open the ops page); null leaves single tap instant.
  final ValueChanged<MatchModel>? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final cardHeight = bracketCardHeight(columns);
    final tops = computeBracketTops(columns, cardHeight);
    final width = columns.isEmpty
        ? 0.0
        : columns.length * cardWidth + (columns.length - 1) * gap;
    return SizedBox(
      width: width,
      height: bracketHeight(tops, cardHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LinkPainter(
                links: computeBracketLinks(columns),
                tops: tops,
                cardWidth: cardWidth,
                cardHeight: cardHeight,
                gap: gap,
                idleColor: context.colors.border,
              ),
            ),
          ),
          for (var c = 0; c < columns.length; c++)
            for (final match in columns[c])
              Positioned(
                key: ValueKey('playoff-card-${match.id}'),
                left: c * (cardWidth + gap),
                top: tops[match.id]!,
                width: cardWidth,
                height: cardHeight,
                child: _BracketCard(
                  match: match,
                  feeders: feeders[match.id] ?? const [],
                  onTap: () => onTap(match),
                  onDoubleTap: onDoubleTap == null
                      ? null
                      : () => onDoubleTap!(match),
                  seedLabels: seedLabels,
                  editing: editing,
                ),
              ),
        ],
      ),
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({
    required this.links,
    required this.tops,
    required this.cardWidth,
    required this.cardHeight,
    required this.gap,
    required this.idleColor,
  });

  final List<BracketLink> links;
  final Map<String, double> tops;
  final double cardWidth;
  final double cardHeight;
  final double gap;
  final Color idleColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      final x1 = link.fromColumn * (cardWidth + gap) + cardWidth;
      final x2 = link.toColumn * (cardWidth + gap);
      final y1 = tops[link.fromId]! + cardHeight / 2;
      final y2 = tops[link.toId]! + cardHeight / 2;
      final midX = x1 + gap / 2;
      final path = Path()
        ..moveTo(x1, y1)
        ..lineTo(midX, y1)
        ..lineTo(midX, y2)
        ..lineTo(x2, y2);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = link.completed ? AppTheme.primary : idleColor,
      );
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) => true;
}

/// A "Nhất A" placeholder; a manager long-presses it and drops it on another
/// placeholder to swap the two seeds.
class _SeedLabelSlot extends StatelessWidget {
  const _SeedLabelSlot({
    required this.text,
    required this.index,
    required this.onSwap,
  });

  final String text;
  final int index;
  final Future<void> Function(int from, int to)? onSwap;

  Widget _label({bool highlighted = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: highlighted ? 0.2 : 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.primary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final swap = onSwap;
    if (swap == null) return _label();
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => swap(details.data, index),
      builder: (context, candidates, _) => LongPressDraggable<int>(
        key: ValueKey('seed-slot-$index'),
        data: index,
        delay: bracketDragDelay,
        feedback: Material(
          color: Colors.transparent,
          child: _label(highlighted: true),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: _label()),
        child: _label(highlighted: candidates.isNotEmpty),
      ),
    );
  }
}

class _BracketCard extends StatelessWidget {
  const _BracketCard({
    required this.match,
    required this.feeders,
    required this.onTap,
    this.onDoubleTap,
    this.seedLabels,
    this.editing,
  });

  final MatchModel match;
  final List<BracketFeeder> feeders;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final PlayoffSeedLabels? seedLabels;
  final BracketEditing? editing;

  /// [_side] wrapped for drag and drop in manager mode. A slot holding a seed
  /// label is left alone: the label itself drags (see [_SeedLabelSlot]).
  Widget _slot(int side) {
    final row = _side(side);
    final edit = editing;
    if (edit == null) return row;
    final teamName = matchSideTeamName(match, side);
    final players = matchSidePlayers(match, side);
    final empty = teamName == null && players.isEmpty;
    final hasSeedLabel =
        empty &&
        !match.isBye &&
        seedLabels?.slotIndexFor(match.id, side) != null;
    if (hasSeedLabel) return row;
    final participantId = side == 1 ? match.team1Id : match.team2Id;
    final data = BracketSlotDragData(
      matchId: match.id,
      slot: side == 1 ? 'participant1' : 'participant2',
      participantId: participantId,
      isBye:
          participantId == 'BYE' ||
          (side == 1 ? match.team1Name : match.team2Name) == 'BYE',
      // The backend treats a BYE match as unplayed even though it is COMPLETED.
      isLocked: !match.isScheduled && !match.isBye,
      label: participantLabel(
        teamName: teamName,
        players: players,
        teamOnly: isFootballMatch(match),
        abbreviated: true,
      ),
    );
    return BracketSlotRow(
      data: data,
      selected: edit.selectedSlot == data,
      onTap: edit.onSlotTap,
      onDrop: edit.onSlotDrop,
      child: row,
    );
  }

  Widget _side(int side) {
    final empty =
        matchSideTeamName(match, side) == null &&
        matchSidePlayers(match, side).isEmpty;
    final seedIndex = empty && !match.isBye
        ? seedLabels?.slotIndexFor(match.id, side)
        : null;
    return BracketSideRow(
      match: match,
      side: side,
      placeholder: seedIndex == null
          ? null
          : _SeedLabelSlot(
              text: seedLabels!.textFor(seedIndex),
              index: seedIndex,
              onSwap: seedLabels!.onSwap,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = groupMatchStatus(context, match);
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: match.isLive ? status.color : colors.border,
          ),
        ),
        child: Column(
          children: [
            BracketCardHeader(match: match),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [_slot(1), _slot(2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
