import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/team_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_match_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  LAYOUT CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════
const _kCardW = 240.0;
const _kCardH = 88.0;
const _kColGap = 80.0;  // horizontal gap between columns (where connectors run)
const _kRowGap = 36.0;  // minimum vertical gap between cards in same column

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
                    lineColor: colors.border.withValues(alpha: 0.8),
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
                  top: -42,
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
                  child: BracketMatchCard(
                    match: match,
                    tournamentId: widget.tournamentId,
                    isReferee: widget.isReferee,
                    isReadOnly: widget.isReadOnly,
                    isGrandFinal: match.nextMatchId.isEmpty,
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
    if (fromEnd == 3) return 'VÒNG 1/8';
    if (fromEnd == 4) return 'VÒNG 1/16';
    if (fromEnd == 5) return 'VÒNG 1/32';
    return 'VÒNG 1/${1 << fromEnd}';
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


