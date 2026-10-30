import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/format_illustration_scenes.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

typedef _Palette = ({Color surface, Color line, Color text, Color accent});

/// Looping animation of one bracket format (Web `IllustrationPlayer`): chips
/// travel through the bracket skeleton, with replay and play/pause. With
/// reduced motion it shows the final frame and offers no playback.
class FormatIllustrationStage extends StatefulWidget {
  const FormatIllustrationStage({super.key, required this.bracketType});

  final String bracketType;

  @override
  State<FormatIllustrationStage> createState() =>
      _FormatIllustrationStageState();
}

class _FormatIllustrationStageState extends State<FormatIllustrationStage>
    with SingleTickerProviderStateMixin {
  late final FormatScene _scene = sceneFor(widget.bracketType);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_scene.duration * 1000).round()),
  );
  bool? _reduced;
  bool _playing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller.value = 1;
      _playing = false;
    } else {
      _playing = true;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.value = 0;
    setState(() => _playing = true);
    _controller.repeat();
  }

  void _togglePlaying() {
    if (_playing) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final palette = (
      surface: colors.bgSurface,
      line: colors.border,
      text: colors.textPrimary,
      accent: AppTheme.primary,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Decorative: the text under the stage says the same in words.
        ExcludeSemantics(
          child: AspectRatio(
            aspectRatio: kSceneCanvas.width / kSceneCanvas.height,
            child: CustomPaint(
              key: const ValueKey('format-illustration-canvas'),
              painter: _ScenePainter(
                scene: _scene,
                progress: _controller,
                palette: palette,
              ),
            ),
          ),
        ),
        if (_reduced == false)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                key: const ValueKey('format-illustration-replay'),
                tooltip: l10n.formatIllustrationReplay,
                onPressed: _replay,
                icon: const Icon(Icons.replay_rounded),
              ),
              IconButton(
                key: const ValueKey('format-illustration-play-pause'),
                tooltip: _playing
                    ? l10n.formatIllustrationPause
                    : l10n.formatIllustrationPlay,
                onPressed: _togglePlaying,
                icon: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.scene,
    required this.progress,
    required this.palette,
  }) : super(repaint: progress);

  final FormatScene scene;
  final Animation<double> progress;
  final _Palette palette;

  static const double _chipRadius = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / kSceneCanvas.width,
      size.height / kSceneCanvas.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - kSceneCanvas.width * scale) / 2,
        (size.height - kSceneCanvas.height * scale) / 2,
      )
      ..scale(scale);
    final time = progress.value * scene.duration;
    for (final link in scene.links) {
      _paintLink(canvas, link, time);
    }
    for (final slot in scene.slots) {
      _paintSlot(canvas, slot);
    }
    for (final chip in scene.chips) {
      _paintChip(canvas, chip.label, chip.at(time));
    }
    canvas.restore();
  }

  void _paintLink(Canvas canvas, SceneLink link, double time) {
    final span = link.end - link.start;
    final drawn = span <= 0
        ? 1.0
        : ((time - link.start) / span).clamp(0.0, 1.0);
    if (drawn <= 0) return;
    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = link.accent
          ? palette.accent.withValues(alpha: 0.7)
          : palette.line;
    canvas.drawLine(link.a, Offset.lerp(link.a, link.b, drawn)!, paint);
  }

  // Empty slot: filled with the surface colour so no link shows through it.
  void _paintSlot(Canvas canvas, Offset slot) {
    canvas
      ..drawCircle(slot, _chipRadius, Paint()..color = palette.surface)
      ..drawCircle(
        slot,
        _chipRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = palette.line.withValues(alpha: 0.6),
      );
  }

  void _paintChip(Canvas canvas, String label, SceneFrame frame) {
    final radius = _chipRadius * frame.scale;
    final fill = Color.lerp(palette.surface, palette.accent, frame.win)!;
    final edge = Color.lerp(palette.line, palette.accent, frame.win)!;
    final ink = Color.lerp(palette.text, Colors.white, frame.win)!;
    canvas
      ..drawCircle(
        frame.pos,
        radius,
        Paint()..color = fill.withValues(alpha: frame.opacity),
      )
      ..drawCircle(
        frame.pos,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = edge.withValues(alpha: frame.opacity),
      );
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: label.length > 1 ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: ink.withValues(alpha: frame.opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, frame.pos - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.scene != scene || old.palette != palette;
}
