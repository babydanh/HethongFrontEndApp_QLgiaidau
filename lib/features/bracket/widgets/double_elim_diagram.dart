import 'dart:math';
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
const _kColGap = 72.0;
const _kRowGap = 20.0;
const _kBandGap = 80.0; // gap between winners and losers bands

// ══════════════════════════════════════════════════════════════════════════════
//  DoubleElimDiagram
//  Renders a two-band (winners + losers) double elimination bracket.
//  Grand final / grand final reset appear at the right, vertically centered.
// ══════════════════════════════════════════════════════════════════════════════
class DoubleElimDiagram extends StatefulWidget {
  final List<MatchModel> matches;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;

  const DoubleElimDiagram({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.isReferee = false,
    this.isReadOnly = true,
  });

  @override
  State<DoubleElimDiagram> createState() => _DoubleElimDiagramState();
}

class _DoubleElimDiagramState extends State<DoubleElimDiagram> {
  final TransformationController _tc =
      TransformationController(Matrix4.identity()..scale(0.6));

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  // ── Separate matches into bands ───────────────────────────────────────────
  _BandData _buildBands() {
    final valid = widget.matches
        .where((m) => m.status != 'cancelled')
        .toList();

    final winners = <int, List<MatchModel>>{};
    final losers = <int, List<MatchModel>>{};
    final finals = <MatchModel>[];

    for (final m in valid) {
      final b = m.bracketPosition.bracket;
      if (b == 'winners') {
        winners.putIfAbsent(m.round, () => []).add(m);
      } else if (b == 'losers') {
        losers.putIfAbsent(m.round, () => []).add(m);
      } else {
        // 'final', 'grand_final', 'grand_final_reset', etc.
        finals.add(m);
      }
    }
    // Sort positions within each round
    for (final r in winners.values) {
      r.sort((a, b) => a.bracketPosition.position.compareTo(b.bracketPosition.position));
    }
    for (final r in losers.values) {
      r.sort((a, b) => a.bracketPosition.position.compareTo(b.bracketPosition.position));
    }
    // Sort finals by round
    finals.sort((a, b) => a.round.compareTo(b.round));

    return _BandData(winners: winners, losers: losers, finals: finals);
  }

  // ── Layout positions for one band ─────────────────────────────────────────
  Map<String, Offset> _layoutBand(
    Map<int, List<MatchModel>> roundMap,
    List<int> sortedRounds,
    double offsetY,
  ) {
    final positions = <String, Offset>{};

    // Phase 1: initial grid layout
    for (int ci = 0; ci < sortedRounds.length; ci++) {
      final colX = ci * (_kCardW + _kColGap);
      final matches = roundMap[sortedRounds[ci]]!;
      for (int mi = 0; mi < matches.length; mi++) {
        final y = offsetY + mi * (_kCardH + _kRowGap);
        positions[matches[mi].id] = Offset(colX, y);
      }
    }

    // Phase 2: align parent to midpoint of children
    for (int ci = sortedRounds.length - 1; ci >= 1; ci--) {
      final round = sortedRounds[ci];
      final prevRound = sortedRounds[ci - 1];
      final prevMatches = roundMap[prevRound]!;
      final childrenOf = <String, List<String>>{};
      for (final m in prevMatches) {
        if (m.nextMatchId.isNotEmpty) {
          childrenOf.putIfAbsent(m.nextMatchId, () => []).add(m.id);
        }
      }
      for (final m in roundMap[round]!) {
        final children = childrenOf[m.id];
        if (children != null && children.length == 2) {
          final y1 = positions[children[0]]?.dy ?? 0;
          final y2 = positions[children[1]]?.dy ?? 0;
          positions[m.id] = Offset(positions[m.id]!.dx, (y1 + y2) / 2);
        }
      }
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bands = _buildBands();

    if (bands.winners.isEmpty && bands.losers.isEmpty && bands.finals.isEmpty) {
      return Center(
        child: Text('Chưa có sơ đồ', style: TextStyle(color: colors.textSecondary)),
      );
    }

    final wRounds = bands.winners.keys.toList()..sort();
    final lRounds = bands.losers.keys.toList()..sort();

    // Estimate heights
    final wMaxCount = wRounds.isEmpty ? 1 : wRounds.map((r) => bands.winners[r]!.length).reduce(max);
    final lMaxCount = lRounds.isEmpty ? 1 : lRounds.map((r) => bands.losers[r]!.length).reduce(max);

    final wBandH = wMaxCount * (_kCardH + _kRowGap);
    final lBandH = lMaxCount * (_kCardH + _kRowGap);

    // Offsets: winners at top, then gap, then losers
    const wOffsetY = 52.0; // room for band label + round header
    final lOffsetY = wOffsetY + wBandH + _kBandGap + 52.0;

    final positions = <String, Offset>{};
    positions.addAll(_layoutBand(bands.winners, wRounds, wOffsetY));
    positions.addAll(_layoutBand(bands.losers, lRounds, lOffsetY));

    // Finals placement: right-most column, centered between bands
    final maxCols = max(wRounds.length, lRounds.length);
    final finalsX = maxCols * (_kCardW + _kColGap);
    final totalBandsH = lOffsetY + lBandH - wOffsetY;
    final finalsStartY = wOffsetY + totalBandsH / 2 - (bands.finals.length * (_kCardH + _kRowGap)) / 2;
    for (int fi = 0; fi < bands.finals.length; fi++) {
      positions[bands.finals[fi].id] = Offset(finalsX, finalsStartY + fi * (_kCardH + _kRowGap));
    }

    // Canvas size
    double maxX = 0, maxY = 0;
    for (final pos in positions.values) {
      if (pos.dx + _kCardW > maxX) maxX = pos.dx + _kCardW;
      if (pos.dy + _kCardH > maxY) maxY = pos.dy + _kCardH;
    }

    return InteractiveViewer(
      transformationController: _tc,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(800),
      minScale: 0.2,
      maxScale: 2.5,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: SizedBox(
          width: maxX + 80,
          height: maxY + 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Band background labels ──
              if (wRounds.isNotEmpty)
                Positioned(
                  left: 0,
                  top: wOffsetY - 32,
                  child: _DeBandLabel(
                    label: '▲ NHÁNH THẮNG',
                    color: const Color(0xFF0284C7),
                    width: wRounds.length * (_kCardW + _kColGap) - _kColGap,
                  ),
                ),
              if (lRounds.isNotEmpty)
                Positioned(
                  left: 0,
                  top: lOffsetY - 32,
                  child: _DeBandLabel(
                    label: '▼ NHÁNH TUA',
                    color: const Color(0xFFDC2626),
                    width: lRounds.length * (_kCardW + _kColGap) - _kColGap,
                  ),
                ),
              if (bands.finals.isNotEmpty)
                Positioned(
                  left: finalsX,
                  top: finalsStartY - 30,
                  width: _kCardW,
                  child: _DeRoundHeader(label: 'CHUNG KẾT TỔNG'),
                ),

              // ── Connector lines ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _DoubleElimPainter(
                    matches: widget.matches,
                    positions: positions,
                    cardW: _kCardW,
                    cardH: _kCardH,
                    primaryColor: AppTheme.primary.withValues(alpha: 0.3),
                    loserColor: const Color(0xFFDC2626).withValues(alpha: 0.22),
                  ),
                ),
              ),

              // ── Round headers — winners band ──
              ...wRounds.asMap().entries.map((e) {
                final ci = e.key;
                final round = e.value;
                final fromEnd = wRounds.length - (ci + 1);
                String label;
                if (fromEnd == 0) label = 'CK NHÁNH THẮNG';
                else if (fromEnd == 1) label = 'BK NHÁNH THẮNG';
                else label = 'VÒNG $round';
                return Positioned(
                  left: ci * (_kCardW + _kColGap),
                  top: wOffsetY - 18,
                  width: _kCardW,
                  child: _DeRoundHeader(label: label),
                );
              }),

              // ── Round headers — losers band ──
              ...lRounds.asMap().entries.map((e) {
                final ci = e.key;
                final round = e.value;
                final fromEnd = lRounds.length - (ci + 1);
                String label;
                if (fromEnd == 0) label = 'CK NHÁNH TUA';
                else if (fromEnd == 1) label = 'BK NHÁNH TUA';
                else label = 'VÒNG $round';
                return Positioned(
                  left: ci * (_kCardW + _kColGap),
                  top: lOffsetY - 18,
                  width: _kCardW,
                  child: _DeRoundHeader(label: label),
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
                  child: _DeBracketMatchCard(
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
}

// ── Band label ────────────────────────────────────────────────────────────────
class _DeBandLabel extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  const _DeBandLabel({required this.label, required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.35), width: 2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Round header ──────────────────────────────────────────────────────────────
class _DeRoundHeader extends StatelessWidget {
  final String label;
  const _DeRoundHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppTheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────────
class _DeBracketMatchCard extends StatelessWidget {
  final MatchModel match;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;

  const _DeBracketMatchCard({
    required this.match,
    required this.tournamentId,
    required this.isReferee,
    required this.isReadOnly,
  });

  void _onTap(BuildContext context) {
    if ((isReferee || !isReadOnly) && (match.isLive || match.isScheduled)) {
      context.push('/live/${match.id}');
      return;
    }
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

    Color statusColor = AppTheme.primary;
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
              ? colors.error.withValues(alpha: 0.05)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _DeTeamRow(
              name: isBye1 ? 'Miễn đấu' : match.team1Name,
              score: match.score1,
              sets: match.sets.isNotEmpty ? match.sets.map((s) => s.score1).toList() : null,
              isWinner: match.isCompleted && match.winnerId == match.team1Id,
              isLive: match.isLive,
              isBye: isBye1,
              colors: colors,
            ),
            Divider(height: 1, thickness: 1, color: colors.border),
            _DeTeamRow(
              name: isBye2 ? 'Miễn đấu' : match.team2Name,
              score: match.score2,
              sets: match.sets.isNotEmpty ? match.sets.map((s) => s.score2).toList() : null,
              isWinner: match.isCompleted && match.winnerId == match.team2Id,
              isLive: match.isLive,
              isBye: isBye2,
              colors: colors,
            ),
            // ── Footer ──
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
                    width: 5, height: 5,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      (isReferee || !isReadOnly) && match.isLive ? 'Tính điểm →' : 'Xem →',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: (isReferee || !isReadOnly) && match.isLive ? colors.error : colors.textMuted,
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

class _DeTeamRow extends StatelessWidget {
  final String name;
  final int score;
  final List<int>? sets;
  final bool isWinner;
  final bool isLive;
  final bool isBye;
  final AppColorsExtension colors;

  const _DeTeamRow({
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 3, height: 22,
              decoration: BoxDecoration(
                color: isWinner ? colors.success : Colors.transparent,
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
                  color: isBye ? colors.textMuted : isWinner ? colors.textPrimary : colors.textSecondary,
                  fontStyle: isBye ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sets != null)
              ...sets!.map((s) => Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text('$s', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.textSecondary)),
                  )),
            const SizedBox(width: 6),
            Text(
              isBye ? '' : '$score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isLive ? colors.error : isWinner ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Connector painter ─────────────────────────────────────────────────────────
class _DoubleElimPainter extends CustomPainter {
  final List<MatchModel> matches;
  final Map<String, Offset> positions;
  final Color primaryColor;
  final Color loserColor;
  final double cardW;
  final double cardH;

  const _DoubleElimPainter({
    required this.matches,
    required this.positions,
    required this.primaryColor,
    required this.loserColor,
    required this.cardW,
    required this.cardH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final winPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final losPaint = Paint()
      ..color = loserColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final match in matches) {
      if (match.nextMatchId.isNotEmpty) {
        final from = positions[match.id];
        final to = positions[match.nextMatchId];
        if (from != null && to != null) {
          _drawConnector(canvas, from, to, winPaint);
        }
      }
      if (match.loserNextMatchId.isNotEmpty) {
        final from = positions[match.id];
        final to = positions[match.loserNextMatchId];
        if (from != null && to != null) {
          _drawConnector(canvas, from, to, losPaint);
        }
      }
    }
  }

  void _drawConnector(Canvas canvas, Offset from, Offset to, Paint paint) {
    final start = Offset(from.dx + cardW, from.dy + cardH / 2);
    final end = Offset(to.dx, to.dy + cardH / 2);
    final midX = (start.dx + end.dx) / 2;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(midX, start.dy)
      ..lineTo(midX, end.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Internal data class ───────────────────────────────────────────────────────
class _BandData {
  final Map<int, List<MatchModel>> winners;
  final Map<int, List<MatchModel>> losers;
  final List<MatchModel> finals;
  const _BandData({required this.winners, required this.losers, required this.finals});
}
