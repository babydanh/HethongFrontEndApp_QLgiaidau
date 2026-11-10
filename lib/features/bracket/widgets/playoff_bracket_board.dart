import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_layout.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_seed_labels.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// Score of [side] per set. Unlike the finished-only group lines it also
/// returns the sets of a live match, so the card can show the running score.
List<String> _sideScores(MatchModel match, int side) {
  if (!isFootballMatch(match) && match.sets.isNotEmpty) {
    return [for (final s in match.sets) '${side == 1 ? s.score1 : s.score2}'];
  }
  return groupSideScores(match, side);
}

/// Width of one score cell; narrower once a match runs past three sets so the
/// names keep their room.
double _scoreCellWidth(int cells) => cells > 3 ? 16 : 20;

/// Cap for the LIVE tag + time on the card header so the code keeps its room.
const double _headerRightMaxWidth = 96;

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
  });

  final List<List<MatchModel>> columns;
  final Map<String, List<BracketFeeder>> feeders;
  final double cardWidth;
  final double gap;
  final ValueChanged<MatchModel> onTap;

  /// Placeholders ("Nhất A") for empty round-one slots; null shows "N/A".
  final PlayoffSeedLabels? seedLabels;

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
                  seedLabels: seedLabels,
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
    this.seedLabels,
  });

  final MatchModel match;
  final List<BracketFeeder> feeders;
  final VoidCallback onTap;
  final PlayoffSeedLabels? seedLabels;

  String _code() {
    final code = (match.matchCode ?? '').trim();
    return code.isEmpty ? '#${match.matchNumber}' : code;
  }

  /// An empty side is N/A (same as the web), or "bye" when the backend marked
  /// the whole match as a BYE; the connector lines already show who feeds it.
  String _waiting(AppLocalizations l10n) =>
      match.isBye ? l10n.bracketBye : l10n.playoff_slotNA;

  Widget _side(BuildContext context, int side) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final teamName = matchSideTeamName(match, side);
    final players = matchSidePlayers(match, side);
    final won =
        match.isCompleted &&
        match.winnerId.isNotEmpty &&
        match.winnerId == (side == 1 ? match.team1Id : match.team2Id);
    final scores = _sideScores(match, side);
    final empty = teamName == null && players.isEmpty;
    final seedIndex = empty && !match.isBye
        ? seedLabels?.slotIndexFor(match.id, side)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: won ? AppTheme.primary.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: seedIndex != null
                  ? _SeedLabelSlot(
                      text: seedLabels!.textFor(seedIndex),
                      index: seedIndex,
                      onSwap: seedLabels!.onSwap,
                    )
                  : empty
                  ? Text(
                      _waiting(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                    )
                  : ParticipantSideLines(
                      teamName: teamName,
                      players: players,
                      teamOnly: isFootballMatch(match),
                      won: won,
                    ),
            ),
          ),
          for (final score in scores)
            SizedBox(
              width: _scoreCellWidth(scores.length),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  score,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: won ? FontWeight.w900 : FontWeight.w700,
                    color: won ? AppTheme.primary : colors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// "TK01 · Sân 2" on the left, a LIVE tag and "09:30 08/11" on the right.
  Widget _header(BuildContext context, ({Color color, String label}) status) {
    final colors = context.colors;
    final court = (match.courtName ?? '').trim();
    final time = match.scheduledTime;
    final timeText = time == null
        ? ''
        : DateFormat('HH:mm dd/MM').format(time.toLocal());
    final muted = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: colors.textMuted,
    );
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _code(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (court.isNotEmpty) TextSpan(text: ' · $court'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
        if (match.isLive || timeText.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _headerRightMaxWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (match.isLive) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: status.color,
                      ),
                    ),
                  ],
                  if (timeText.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(timeText, style: muted),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = groupMatchStatus(context, match);
    return InkWell(
      onTap: onTap,
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
            _header(context, status),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [_side(context, 1), _side(context, 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
