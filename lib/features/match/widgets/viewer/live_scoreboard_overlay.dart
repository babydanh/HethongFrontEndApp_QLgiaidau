import 'package:flutter/material.dart';

/// Brand blue shared with the H2H / bracket overlays and the Web scoreboard.
const _accent = Color(0xFF1E90FF);
const _panel = Color(0xFF020617);
const _rowHeight = 26.0;
const _scoreWidth = 40.0;

/// Scoreboard drawn over the video, same look as the Web
/// `LiveScoreboardOverlay`: two stacked rows, blue bar on the left, dark body
/// for the side name and a slanted blue score cell with white digits (grey once
/// the match is finished).
class LiveScoreboardOverlay extends StatelessWidget {
  const LiveScoreboardOverlay({
    super.key,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    this.finished = false,
  });

  final Widget team1;
  final Widget team2;
  final int score1;
  final int score2;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 215),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row(name: team1, score: score1, finished: finished),
                const SizedBox(height: 2),
                _Row(name: team2, score: score2, finished: finished),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.name, required this.score, required this.finished});

  final Widget name;
  final int score;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          const SizedBox(width: 5, child: ColoredBox(color: _accent)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Align(alignment: Alignment.centerLeft, child: name),
            ),
          ),
          _ScoreCell(score: score, finished: finished),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.score, required this.finished});

  final int score;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final colors = finished
        ? const [Color(0xFF475569), Color(0xFF334155)]
        : const [Color(0xFF2563EB), Color(0xFF0EA5E9)];
    return SizedBox(
      width: _scoreWidth,
      child: ClipPath(
        clipper: const _SlantClipper(),
        child: DecoratedBox(
          key: const ValueKey('live-scoreboard-score-bg'),
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
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
