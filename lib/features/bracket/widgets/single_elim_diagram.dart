import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_match_card.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';

const _kCardW = 240.0;
const _kCardH = 88.0;
const _kColGap = 80.0;
const _kRowGap = 36.0;

class SingleElimDiagram extends StatefulWidget {
  final List<MatchModel> matches;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;
  final bool isEditable;
  final Future<void> Function(
    BracketSlotDragData source,
    BracketSlotDragData target,
  )?
  onSlotDrop;

  const SingleElimDiagram({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.isReferee = false,
    this.isReadOnly = true,
    this.isEditable = false,
    this.onSlotDrop,
  });

  @override
  State<SingleElimDiagram> createState() => _SingleElimDiagramState();
}

class _SingleElimDiagramState extends State<SingleElimDiagram> {
  final TransformationController _tc = TransformationController();
  bool _didCenterInitialView = false;
  BracketSlotDragData? _selectedSlot;
  bool _isUpdating = false;

  Future<void> _handleSlotDrop(
    BracketSlotDragData source,
    BracketSlotDragData target,
  ) async {
    if (_isUpdating || widget.onSlotDrop == null) return;
    setState(() {
      _isUpdating = true;
      _selectedSlot = null;
    });
    try {
      await widget.onSlotDrop!(source, target);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật vị trí: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _handleSlotTap(BracketSlotDragData slot) {
    if (_isUpdating || !widget.isEditable) return;
    final selected = _selectedSlot;
    if (selected == null) {
      // Empty/TBD/BYE rows are destinations only; they cannot be a source.
      if (!slot.hasParticipant) return;
      setState(() => _selectedSlot = slot);
      return;
    }
    if (selected == slot) {
      setState(() => _selectedSlot = null);
      return;
    }
    if (slot.isBye) return;
    _handleSlotDrop(selected, slot);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Map<int, List<MatchModel>> _buildRoundMap() {
    final valid = widget.matches
        .where(
          (m) =>
              m.status != 'cancelled' &&
              !m.isFullByeMatch &&
              isKnockoutMatch(m),
        )
        .toList();

    final map = <int, List<MatchModel>>{};
    for (final match in valid) {
      map.putIfAbsent(match.round, () => []).add(match);
    }
    for (final key in map.keys) {
      map[key]!.sort(
        (a, b) =>
            a.bracketPosition.position.compareTo(b.bracketPosition.position),
      );
    }
    return map;
  }

  Map<String, Offset> _computePositions(
    Map<int, List<MatchModel>> roundMap,
    List<int> sortedRounds,
  ) {
    final positions = <String, Offset>{};

    for (var ci = 0; ci < sortedRounds.length; ci++) {
      final colX = ci * (_kCardW + _kColGap);
      final matches = roundMap[sortedRounds[ci]]!;
      for (var mi = 0; mi < matches.length; mi++) {
        positions[matches[mi].id] = Offset(colX, mi * (_kCardH + _kRowGap));
      }
    }

    for (var ci = 1; ci < sortedRounds.length; ci++) {
      final round = sortedRounds[ci];
      final prevRound = sortedRounds[ci - 1];
      final prevMatches = roundMap[prevRound]!;

      final childrenOf = <String, List<String>>{};
      for (final match in prevMatches) {
        if (match.nextMatchId.isNotEmpty) {
          childrenOf.putIfAbsent(match.nextMatchId, () => []).add(match.id);
        }
      }

      for (final match in roundMap[round]!) {
        final children = childrenOf[match.id];
        if (children == null || children.isEmpty) continue;

        var totalY = 0.0;
        var count = 0;
        for (final childId in children) {
          final pos = positions[childId];
          if (pos == null) continue;
          totalY += pos.dy + _kCardH / 2;
          count++;
        }
        if (count == 0) continue;

        final centerY = totalY / count - _kCardH / 2;
        positions[match.id] = Offset(positions[match.id]!.dx, centerY);
      }
    }

    return positions;
  }

  String? _findFinalMatchId(List<MatchModel> matches) {
    final terminalMatches =
        matches
            .where(
              (match) =>
                  match.nextMatchId.isEmpty && match.loserNextMatchId.isEmpty,
            )
            .toList()
          ..sort((a, b) {
            final roundCompare = b.round.compareTo(a.round);
            if (roundCompare != 0) return roundCompare;
            return a.matchNumber.compareTo(b.matchNumber);
          });

    return terminalMatches.isEmpty ? null : terminalMatches.first.id;
  }

  void _centerInitialView(Size viewport, Size canvas) {
    if (_didCenterInitialView || viewport.width <= 0 || viewport.height <= 0) {
      return;
    }
    _didCenterInitialView = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Compute scale to fit canvas within viewport with 85% margin
      final scaleX = viewport.width / canvas.width;
      final scaleY = viewport.height / canvas.height;
      final fitScale = (scaleX < scaleY ? scaleX : scaleY) * 0.85;

      final dx = ((viewport.width - canvas.width * fitScale) / 2).clamp(
        16.0,
        double.infinity,
      );
      final dy = ((viewport.height - canvas.height * fitScale) / 2).clamp(
        16.0,
        double.infinity,
      );
      _tc.value = Matrix4.identity()
        ..setEntry(0, 0, fitScale)
        ..setEntry(1, 1, fitScale)
        ..setEntry(0, 3, dx)
        ..setEntry(1, 3, dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roundMap = _buildRoundMap();
    if (roundMap.isEmpty) {
      return Center(
        child: Text(
          'Chưa có sơ đồ',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    final sortedRounds = roundMap.keys.toList()..sort();
    final totalRounds = sortedRounds.length;
    final diagramMatches = [
      for (final round in sortedRounds) ...roundMap[round]!,
    ];
    final finalMatchId = _findFinalMatchId(diagramMatches);
    final positions = _computePositions(roundMap, sortedRounds);

    var maxX = 0.0;
    var maxY = 0.0;
    for (final pos in positions.values) {
      if (pos.dx + _kCardW > maxX) maxX = pos.dx + _kCardW;
      if (pos.dy + _kCardH > maxY) maxY = pos.dy + _kCardH;
    }
    final canvasW = maxX + 80;
    final canvasH = maxY + 80;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(canvasW + 80, canvasH + 80);
        _centerInitialView(
          Size(constraints.maxWidth, constraints.maxHeight),
          canvasSize,
        );

        return InteractiveViewer(
          transformationController: _tc,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(800),
          minScale: 0.25,
          maxScale: 2.5,
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: SizedBox(
                width: canvasW,
                height: canvasH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _BracketConnectorPainter(
                            matches: diagramMatches,
                            positions: positions,
                            lineColor: colors.border.withValues(alpha: 0.8),
                            cardW: _kCardW,
                            cardH: _kCardH,
                            colGap: _kColGap,
                          ),
                        ),
                      ),
                    ),
                    ...sortedRounds.asMap().entries.map((entry) {
                      final columnIndex = entry.key;
                      final colX = columnIndex * (_kCardW + _kColGap);
                      final roundName = _getRoundLabel(
                        columnIndex,
                        totalRounds,
                      );
                      return Positioned(
                        left: colX,
                        top: -42,
                        width: _kCardW,
                        child: _RoundHeader(label: roundName),
                      );
                    }),
                    ...diagramMatches.map((match) {
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
                          isGrandFinal: match.id == finalMatchId,
                          isSlotEditable: widget.isEditable && !_isUpdating,
                          selectedSlot: _selectedSlot,
                          onSlotTap: _handleSlotTap,
                          onSlotDrop: _handleSlotDrop,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getRoundLabel(int columnIndex, int totalColumns) {
    final fromEnd = totalColumns - 1 - columnIndex;
    if (fromEnd == 0) return 'CHUNG KẾT';
    if (fromEnd == 1) return 'BÁN KẾT';
    if (fromEnd == 2) return 'TỨ KẾT';
    if (fromEnd == 3) return 'VÒNG 1/8';
    if (fromEnd == 4) return 'VÒNG 1/16';
    if (fromEnd == 5) return 'VÒNG 1/32';
    return 'VÒNG 1/${1 << fromEnd}';
  }
}

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

    final childrenByParent = <String, List<MatchModel>>{};
    for (final match in matches) {
      if (match.nextMatchId.isEmpty) continue;
      final from = positions[match.id];
      final to = positions[match.nextMatchId];
      if (from == null || to == null) continue;

      final dx = to.dx - from.dx;
      final expectedDx = cardW + colGap;
      if (dx <= 0 || dx > expectedDx * 1.35) continue;

      childrenByParent.putIfAbsent(match.nextMatchId, () => []).add(match);
    }

    for (final entry in childrenByParent.entries) {
      final parentPos = positions[entry.key];
      if (parentPos == null) continue;

      final childCenters = entry.value
          .map((child) => positions[child.id])
          .whereType<Offset>()
          .map((pos) => Offset(pos.dx + cardW, pos.dy + cardH / 2))
          .toList();
      if (childCenters.isEmpty) continue;

      final parentCenter = Offset(parentPos.dx, parentPos.dy + cardH / 2);
      final midX = childCenters.first.dx + colGap / 2;

      for (final childCenter in childCenters) {
        final childPath = Path()
          ..moveTo(childCenter.dx, childCenter.dy)
          ..lineTo(midX, childCenter.dy);
        canvas.drawPath(childPath, paint);
      }

      final allY = [...childCenters.map((p) => p.dy), parentCenter.dy];
      final minY = allY.reduce((a, b) => a < b ? a : b);
      final maxY = allY.reduce((a, b) => a > b ? a : b);

      if (minY != maxY) {
        final spine = Path()
          ..moveTo(midX, minY)
          ..lineTo(midX, maxY);
        canvas.drawPath(spine, paint);
      }

      final parentPath = Path()
        ..moveTo(midX, parentCenter.dy)
        ..lineTo(parentCenter.dx, parentCenter.dy);
      canvas.drawPath(parentPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) {
    return oldDelegate.matches != matches ||
        oldDelegate.positions != positions ||
        oldDelegate.lineColor != lineColor;
  }
}

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
