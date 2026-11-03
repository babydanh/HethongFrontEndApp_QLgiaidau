import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_layout.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
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

/// Sets won by [side] of a finished match (goals for football).
String _sideScore(MatchModel match, int side) {
  if (!match.isCompleted) return '';
  if (!isFootballMatch(match) && match.sets.isNotEmpty) {
    return '${match.sets.where((s) => side == 1 ? s.score1 > s.score2 : s.score2 > s.score1).length}';
  }
  final scores = groupSideScores(match, side);
  return scores.isEmpty ? '' : scores.first;
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
  });

  final List<List<MatchModel>> columns;
  final Map<String, List<BracketFeeder>> feeders;
  final double cardWidth;
  final double gap;
  final ValueChanged<MatchModel> onTap;

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

class _BracketCard extends StatelessWidget {
  const _BracketCard({
    required this.match,
    required this.feeders,
    required this.onTap,
  });

  final MatchModel match;
  final List<BracketFeeder> feeders;
  final VoidCallback onTap;

  String _code() {
    final code = (match.matchCode ?? '').trim();
    return code.isEmpty ? '#${match.matchNumber}' : code;
  }

  /// "Thắng W4" / "Thua W6" for an empty side. Side 1 / 2 are matched to the
  /// 1st / 2nd feeder in bracket order (the API has no explicit slot field).
  String _waiting(AppLocalizations l10n, int side) {
    if (side > feeders.length) return l10n.matchNotDetermined;
    final f = feeders[side - 1];
    return f.loser
        ? l10n.playoff_waitLoser(f.code)
        : l10n.playoff_waitWinner(f.code);
  }

  Widget _side(BuildContext context, int side) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final teamName = matchSideTeamName(match, side);
    final players = matchSidePlayers(match, side);
    final won =
        match.isCompleted &&
        match.winnerId.isNotEmpty &&
        match.winnerId == (side == 1 ? match.team1Id : match.team2Id);
    final score = _sideScore(match, side);
    final empty = teamName == null && players.isEmpty;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: empty
                ? Text(
                    _waiting(l10n, side),
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
        if (score.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: won ? AppTheme.primary : colors.textPrimary,
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
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _code(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
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
