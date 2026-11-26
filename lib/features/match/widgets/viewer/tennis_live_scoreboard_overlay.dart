import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../live_overlay_controls.dart';
import 'scoreboard_set_columns.dart';

// Same look as `LiveScoreboardOverlay` (pickleball and the other sports).
const _accent = Color(0xFF1E90FF);
const _panel = Color(0xFF020617);
const _rowHeight = 20.0;
const _pointWidth = 32.0;
const _gameCellWidth = 22.0;
const _headerHeight = 12.0;
const _panelAlpha = 0.55;
const _pointAlpha = 0.85;
const _minFontSize = 8.0;

double _font(double size, double scale) => math.max(_minFontSize, size * scale);

/// Tennis scoreboard over the video, by the rules of tennis: one games cell
/// per set that has started ("S1 S2 S3", the set in play bright) and a slanted
/// cell with the point of the game (0/15/30/40/AD). A finished match drops the
/// point cell.
class TennisLiveScoreboardOverlay extends StatelessWidget {
  const TennisLiveScoreboardOverlay({
    super.key,
    required this.team1,
    required this.team2,
    required this.sets,
    this.point1,
    this.point2,
    this.semanticsLabel,
  });

  final Widget team1;
  final Widget team2;

  /// From `tennisScoreboardSetColumns`.
  final List<SetColumn> sets;

  /// Point of the game per side; null hides the point cell.
  final String? point1;
  final String? point2;

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final board = LayoutBuilder(
      builder: (context, constraints) =>
          _board(liveOverlayScale(constraints.maxWidth, share: 0.7)),
    );
    final label = semanticsLabel;
    if (label == null) return board;
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(child: board),
    );
  }

  Widget _board(double scale) {
    final showPoint = point1 != null && point2 != null;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 120 * scale,
        maxWidth: (170 + sets.length * _gameCellWidth) * scale,
      ),
      child: DecoratedBox(
        key: const ValueKey('tennis-scoreboard-panel'),
        decoration: BoxDecoration(
          color: _panel.withValues(alpha: _panelAlpha),
          borderRadius: BorderRadius.circular(6 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5 * scale),
          child: liveGlassBackdrop(
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(scale, showPoint),
                  _row(team1, 1, point1, scale),
                  SizedBox(height: 2 * scale),
                  _row(team2, 2, point2, scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(double scale, bool showPoint) {
    Widget label(String text, double width) => SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: _font(8, scale),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
    return SizedBox(
      height: _headerHeight * scale,
      child: Row(
        children: [
          SizedBox(width: 4 * scale),
          const Expanded(child: SizedBox.shrink()),
          for (final set in sets)
            label('S${set.setNumber}', _gameCellWidth * scale),
          if (showPoint) SizedBox(width: _pointWidth * scale),
        ],
      ),
    );
  }

  Widget _row(Widget name, int side, String? point, double scale) {
    return SizedBox(
      height: _rowHeight * scale,
      child: Builder(
        builder: (context) => Row(
          children: [
            SizedBox(
              width: 4 * scale,
              child: const ColoredBox(color: _accent),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5 * scale),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      math.max(scale, _minFontSize / 10),
                    ),
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: name),
                ),
              ),
            ),
            for (final set in sets) _gameCell(set, side, scale),
            if (point != null)
              _PointCell(point: point, scale: scale),
          ],
        ),
      ),
    );
  }

  Widget _gameCell(SetColumn set, int side, double scale) {
    final current = set.state == SetColumnState.current;
    final strong = current || set.winner == side;
    return SizedBox(
      width: _gameCellWidth * scale,
      child: Center(
        child: Text(
          '${side == 1 ? set.team1 : set.team2}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: strong ? 1 : 0.55),
            fontSize: _font(12, scale),
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _PointCell extends StatelessWidget {
  const _PointCell({required this.point, required this.scale});

  final String point;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = const [Color(0xFF2563EB), Color(0xFF0EA5E9)]
        .map((c) => c.withValues(alpha: _pointAlpha))
        .toList();
    return SizedBox(
      width: _pointWidth * scale,
      child: ClipPath(
        clipper: const _SlantClipper(),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 5 * scale),
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: Text(
                  point,
                  key: ValueKey(point),
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(point.length > 2 ? 11 : 13, scale),
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parallelogram of the Web score cell: left edge slanted from 22% at the top.
class _SlantClipper extends CustomClipper<Path> {
  const _SlantClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.22, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
