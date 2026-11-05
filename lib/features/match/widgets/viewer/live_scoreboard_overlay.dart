import 'package:flutter/material.dart';

/// Brand blue shared with the H2H / bracket overlays and the Web scoreboard.
const _accent = Color(0xFF1E90FF);
const _panel = Color(0xFF020617);
// Broadcast-size score bug: slim rows, translucent so the picture shows.
const _rowHeight = 20.0;
const _scoreWidth = 32.0;
const _panelAlpha = 0.6;
const _scoreAlpha = 0.85;

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
    this.semanticsLabel,
  });

  final Widget team1;
  final Widget team2;
  final int score1;
  final int score2;
  final bool finished;

  /// Spoken summary ("A 3, B 2"); the drawn rows are hidden from screen readers.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final board = _board();
    final label = semanticsLabel;
    if (label == null) return board;
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(child: board),
    );
  }

  Widget _board() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 170),
      child: DecoratedBox(
        key: const ValueKey('live-scoreboard-panel'),
        decoration: BoxDecoration(
          color: _panel.withValues(alpha: _panelAlpha),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
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
          const SizedBox(width: 4, child: ColoredBox(color: _accent)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
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
    final colors =
        (finished
                ? const [Color(0xFF475569), Color(0xFF334155)]
                : const [Color(0xFF2563EB), Color(0xFF0EA5E9)])
            .map((c) => c.withValues(alpha: _scoreAlpha))
            .toList();
    return SizedBox(
      width: _scoreWidth,
      child: ClipPath(
        clipper: const _SlantClipper(),
        child: DecoratedBox(
          key: const ValueKey('live-scoreboard-score-bg'),
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
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
