import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  LAYOUT CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════
const _kCardW = 240.0;
const _kCardH = 88.0;
const _kColGap = 72.0;  // horizontal gap between columns (where connectors run)
const _kRowGap = 20.0;  // minimum vertical gap between cards in same column

// ══════════════════════════════════════════════════════════════════════════════
//  SingleElimDiagram
//  Accepts a flat list of MatchModel with nextMatchId chains.
//  Renders a classic tournament tree with connecting lines.
// ══════════════════════════════════════════════════════════════════════════════
class SingleElimDiagram extends StatefulWidget {
  final List<MatchModel> matches;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;

  const SingleElimDiagram({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.isReferee = false,
    this.isReadOnly = true,
  });

  @override
  State<SingleElimDiagram> createState() => _SingleElimDiagramState();
}

class _SingleElimDiagramState extends State<SingleElimDiagram> {
  final TransformationController _tc =
      TransformationController(Matrix4.identity()..scale(0.72));

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  // ── Build structured layout ───────────────────────────────────────────────
  Map<int, List<MatchModel>> _buildRoundMap() {
    // Only valid matches — exclude full BYE-vs-BYE (both slots are BYE/unset)
    final valid = widget.matches.where((m) {
      if (m.status == 'cancelled') return false;
      // Hide matches where both sides are BYE (no real participant at all)
      if (m.isFullByeMatch) return false;
      return true;
    }).toList();

    final map = <int, List<MatchModel>>{};
    for (final m in valid) {
      map.putIfAbsent(m.round, () => []).add(m);
    }
    for (final key in map.keys) {
      map[key]!.sort((a, b) => a.bracketPosition.position.compareTo(b.bracketPosition.position));
    }
    return map;
  }

  // ── Compute canvas positions for each match ───────────────────────────────
  Map<String, Offset> _computePositions(
    Map<int, List<MatchModel>> roundMap,
    List<int> sortedRounds,
  ) {
    final positions = <String, Offset>{};
    // The last round (e.g. Final) has only 1 card. We compute from it outward.
    // Phase 1: compute column X
    for (int ci = 0; ci < sortedRounds.length; ci++) {
      final colX = ci * (_kCardW + _kColGap);
      final matches = roundMap[sortedRounds[ci]]!;
      for (int mi = 0; mi < matches.length; mi++) {
        final y = mi * (_kCardH + _kRowGap);
        positions[matches[mi].id] = Offset(colX, y);
      }
    }

    // Phase 2: vertically align parent nodes to the midpoint of their children
    // Process rounds from latest (final) backwards
    for (int ci = sortedRounds.length - 1; ci >= 1; ci--) {
      final round = sortedRounds[ci];
      final prevRound = sortedRounds[ci - 1];
      final prevMatches = roundMap[prevRound]!;

      // Group prev-round matches by their nextMatchId (parent)
      final childrenOf = <String, List<String>>{};
      for (final m in prevMatches) {
        if (m.nextMatchId.isNotEmpty) {
          childrenOf.putIfAbsent(m.nextMatchId, () => []).add(m.id);
        }
      }

      // For each match in current round, adjust Y to midpoint of children
      for (final m in roundMap[round]!) {
        final children = childrenOf[m.id];
        if (children != null && children.isNotEmpty) {
          double totalY = 0;
          int count = 0;
          for (final c in children) {
            final pos = positions[c];
            if (pos != null) {
              totalY += pos.dy + _kCardH / 2;
              count++;
            }
          }
          if (count > 0) {
            final centerY = totalY / count - _kCardH / 2;
            positions[m.id] = Offset(positions[m.id]!.dx, centerY);
          }
        }
      }
    }

    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roundMap = _buildRoundMap();
    if (roundMap.isEmpty) {
      return Center(
        child: Text('Chưa có sơ đồ', style: TextStyle(color: colors.textSecondary)),
      );
    }

    final sortedRounds = roundMap.keys.toList()..sort();
    final totalRounds = sortedRounds.length;
    final positions = _computePositions(roundMap, sortedRounds);

    // Compute canvas size
    double maxX = 0, maxY = 0;
    for (final pos in positions.values) {
      if (pos.dx + _kCardW > maxX) maxX = pos.dx + _kCardW;
      if (pos.dy + _kCardH > maxY) maxY = pos.dy + _kCardH;
    }
    final canvasW = maxX + 80;
    final canvasH = maxY + 80;

    return InteractiveViewer(
      transformationController: _tc,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(800),
      minScale: 0.25,
      maxScale: 2.5,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Connector lines (drawn behind cards) ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _BracketConnectorPainter(
                    matches: widget.matches,
                    positions: positions,
                    lineColor: AppTheme.primary.withValues(alpha: 0.35),
                    cardW: _kCardW,
                    cardH: _kCardH,
                    colGap: _kColGap,
                  ),
                ),
              ),
              // ── Round header labels ──
              ...sortedRounds.asMap().entries.map((entry) {
                final ci = entry.key;
                final round = entry.value;
                final colX = ci * (_kCardW + _kColGap);
                final roundName = _getRoundLabel(round, totalRounds);
                return Positioned(
                  left: colX,
                  top: -36,
                  width: _kCardW,
                  child: _RoundHeader(label: roundName),
                );
              }),
              // ── Match cards ──
              ...widget.matches.map((match) {
                final pos = positions[match.id];
                if (pos == null) return const SizedBox.shrink();
                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  width: _kCardW,
                  height: _kCardH,
                  child: _BracketMatchCard(
                    match: match,
                    tournamentId: widget.tournamentId,
                    isReferee: widget.isReferee,
                    isReadOnly: widget.isReadOnly,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoundLabel(int round, int total) {
    final fromEnd = total - round;
    if (fromEnd == 0) return 'CHUNG KẾT';
    if (fromEnd == 1) return 'BÁN KẾT';
    if (fromEnd == 2) return 'TỨ KẾT';
    return 'VÒNG $round';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Connector CustomPainter
// ══════════════════════════════════════════════════════════════════════════════
class _BracketConnectorPainter extends CustomPainter {
  final List<MatchModel> matches;
  final Map<String, Offset> positions;
  final Color lineColor;
  final double cardW;
  final double cardH;
  final double colGap;

  const _BracketConnectorPainter({
    required this.matches,
    required this.positions,
    required this.lineColor,
    required this.cardW,
    required this.cardH,
    required this.colGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final match in matches) {
      if (match.nextMatchId.isEmpty) continue;
      final from = positions[match.id];
      final to = positions[match.nextMatchId];
      if (from == null || to == null) continue;

      // Start point: right-center of current card
      final start = Offset(from.dx + cardW, from.dy + cardH / 2);
      // End point: left-center of parent card
      final end = Offset(to.dx, to.dy + cardH / 2);

      // Mid-X (where horizontal lines meet vertically)
      final midX = start.dx + colGap / 2;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(midX, start.dy)
        ..lineTo(midX, end.dy)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, paint);

      // Small dot at junction
      canvas.drawCircle(
        Offset(midX, start.dy),
        3,
        Paint()..color = lineColor.withAlpha(180),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  Round Header Label
// ══════════════════════════════════════════════════════════════════════════════
class _RoundHeader extends StatelessWidget {
  final String label;
  const _RoundHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppTheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Match card for bracket diagram — compact, tappable, status-aware
// ══════════════════════════════════════════════════════════════════════════════
class _BracketMatchCard extends StatelessWidget {
  final MatchModel match;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;

  const _BracketMatchCard({
    required this.match,
    required this.tournamentId,
    required this.isReferee,
    required this.isReadOnly,
  });

  void _onTap(BuildContext context) {
    // Referees/admins can go directly to live scoring screen
    if ((isReferee || !isReadOnly) && (match.isLive || match.isScheduled)) {
      context.push('/live/${match.id}');
      return;
    }
    // Everyone else sees a detail dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 320,
          child: MatchCardDetail(
            match: match,
            isReferee: isReferee,
            isReadOnly: isReadOnly,
            tournamentId: tournamentId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBye1 = match.team1Name == 'BYE' || match.team1Id == 'BYE';
    final isBye2 = match.team2Name == 'BYE' || match.team2Id == 'BYE';

    Color statusColor = colors.textMuted;
    String statusLabel = 'SẮP ĐẤU';
    Color borderColor = colors.border;

    if (match.isLive) {
      statusColor = colors.error;
      statusLabel = 'LIVE';
      borderColor = colors.error.withValues(alpha: 0.5);
    } else if (match.isCompleted) {
      statusColor = colors.success;
      statusLabel = 'XONG';
    }

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: match.isLive
              ? colors.error.withValues(alpha: 0.06)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Team 1 ──
            Expanded(
              child: _TeamRow(
                name: isBye1 ? 'Miễn đấu' : match.team1Name,
                score: match.score1,
                sets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score1).toList()
                    : null,
                isWinner: match.isCompleted && match.winnerId == match.team1Id,
                isLive: match.isLive,
                isBye: isBye1,
                colors: colors,
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.border),
            // ── Team 2 ──
            Expanded(
              child: _TeamRow(
                name: isBye2 ? 'Miễn đấu' : match.team2Name,
                score: match.score2,
                sets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score2).toList()
                    : null,
                isWinner: match.isCompleted && match.winnerId == match.team2Id,
                isLive: match.isLive,
                isBye: isBye2,
                colors: colors,
              ),
            ),
            // ── Footer: status + action ──
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if ((isReferee || !isReadOnly) && match.isLive)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Tính điểm →',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: colors.error,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Xem →',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int score;
  final List<int>? sets;
  final bool isWinner;
  final bool isLive;
  final bool isBye;
  final AppColorsExtension colors;

  const _TeamRow({
    required this.name,
    required this.score,
    required this.isWinner,
    required this.isLive,
    required this.isBye,
    required this.colors,
    this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Winner indicator
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: isWinner
                  ? colors.success
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                color: isBye
                    ? colors.textMuted
                    : isWinner
                        ? colors.textPrimary
                        : colors.textSecondary,
                fontStyle: isBye ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Set scores
          if (sets != null)
            ...sets!.map((s) => Container(
                  margin: const EdgeInsets.only(left: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    '$s',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                )),
          const SizedBox(width: 6),
          // Total score
          Text(
            isBye ? '' : '$score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isLive
                  ? colors.error
                  : isWinner
                      ? colors.textPrimary
                      : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
