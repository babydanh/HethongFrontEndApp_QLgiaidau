import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../live_overlay_controls.dart';
import 'scoreboard_set_columns.dart';

/// Brand blue shared with the H2H / bracket overlays and the Web scoreboard.
const _accent = Color(0xFF1E90FF);
const _panel = Color(0xFF020617);
// Broadcast-size score bug: slim rows, translucent so the picture shows.
const _rowHeight = 20.0;
const _scoreWidth = 32.0;
const _setCellWidth = 22.0;
const _headerHeight = 12.0;
const _panelAlpha = 0.55;
const _scoreAlpha = 0.85;

/// Smallest text drawn on the video.
const _minFontSize = 8.0;

double _font(double size, double scale) => math.max(_minFontSize, size * scale);

/// Scoreboard drawn over the video, same look as the Web
/// `LiveScoreboardOverlay`: two stacked rows, blue bar on the left, dark body
/// for the side name and a slanted blue score cell with white digits (grey once
/// the match is finished).
///
/// Every dimension is scaled by [liveOverlayScale] of the width it is given
/// (the video width), so the board stays a small score bug on any video.
class LiveScoreboardOverlay extends StatelessWidget {
  const LiveScoreboardOverlay({
    super.key,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    this.finished = false,
    this.setColumns = const [],
    this.semanticsLabel,
  });

  final Widget team1;
  final Widget team2;
  final int score1;
  final int score2;
  final bool finished;

  /// Sets played so far (oldest first, current last); empty draws the single
  /// score of the current set only.
  final List<SetColumn> setColumns;

  /// Spoken summary ("A 3, B 2"); the drawn rows are hidden from screen readers.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final board = LayoutBuilder(
      builder: (context, constraints) =>
          _board(liveOverlayScale(constraints.maxWidth)),
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
    final finishedSets = [
      for (final column in setColumns)
        if (column.state == SetColumnState.finished) column,
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 120 * scale,
        maxWidth: (170 + finishedSets.length * _setCellWidth) * scale,
      ),
      child: DecoratedBox(
        key: const ValueKey('live-scoreboard-panel'),
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
                  if (finishedSets.isNotEmpty)
                    _SetHeader(
                      sets: finishedSets,
                      current: setColumns.last,
                      scale: scale,
                    ),
                  _Row(
                    name: team1,
                    score: score1,
                    finished: finished,
                    sets: finishedSets,
                    side: 1,
                    scale: scale,
                  ),
                  SizedBox(height: 2 * scale),
                  _Row(
                    name: team2,
                    score: score2,
                    finished: finished,
                    sets: finishedSets,
                    side: 2,
                    scale: scale,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "S1 S2 … Sn" labels above the finished-set cells and the current score cell.
class _SetHeader extends StatelessWidget {
  const _SetHeader({
    required this.sets,
    required this.current,
    required this.scale,
  });

  final List<SetColumn> sets;
  final SetColumn current;
  final double scale;

  @override
  Widget build(BuildContext context) {
    Widget label(SetColumn set, double width) => SizedBox(
      width: width,
      child: Center(
        child: Text(
          'S${set.setNumber}',
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
          for (final set in sets) label(set, _setCellWidth * scale),
          label(current, _scoreWidth * scale),
        ],
      ),
    );
  }
}

/// Score of one finished set for one side: the set winner bold, the loser dim.
class _SetCell extends StatelessWidget {
  const _SetCell({required this.score, required this.won, required this.scale});

  final int score;
  final bool won;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _setCellWidth * scale,
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: Colors.white.withValues(alpha: won ? 1 : 0.55),
            fontSize: _font(12, scale),
            fontWeight: won ? FontWeight.w900 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.score,
    required this.finished,
    required this.sets,
    required this.side,
    required this.scale,
  });

  final Widget name;
  final int score;
  final bool finished;
  final List<SetColumn> sets;
  final int side;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight * scale,
      child: Row(
        children: [
          SizedBox(
            width: 4 * scale,
            child: const ColoredBox(color: _accent),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5 * scale),
              // Side names arrive as ready-made Text; shrink them with the
              // board, but never below the readable floor (8 / 10).
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
          for (final set in sets)
            _SetCell(
              score: side == 1 ? set.team1 : set.team2,
              won: set.winner == side,
              scale: scale,
            ),
          _ScoreCell(score: score, finished: finished, scale: scale),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.score,
    required this.finished,
    required this.scale,
  });

  final int score;
  final bool finished;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors =
        (finished
                ? const [Color(0xFF475569), Color(0xFF334155)]
                : const [Color(0xFF2563EB), Color(0xFF0EA5E9)])
            .map((c) => c.withValues(alpha: _scoreAlpha))
            .toList();
    return SizedBox(
      width: _scoreWidth * scale,
      child: ClipPath(
        clipper: const _SlantClipper(),
        child: DecoratedBox(
          key: const ValueKey('live-scoreboard-score-bg'),
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 5 * scale),
              // A new score pops in (scale + fade), the old one fades out.
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween(begin: 0.7, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  '$score',
                  key: ValueKey(score),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(13, scale),
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
