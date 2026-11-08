import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_overlay_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Same navy + blue family as the Web `LiveHeadToHeadOverlay` and the bracket
/// overlay.
const _accent = Color(0xFF1E90FF);
const _ink = Color(0xFF0B1B3A);

/// Panel width as a share of the video width, kept in a readable range.
const _widthShare = 0.7;
const _minPanelWidth = 220.0;
const _maxPanelWidth = 420.0;

/// Smallest text drawn on the video.
const _minFontSize = 8.0;

double _font(double size, double scale) => math.max(_minFontSize, size * scale);

/// One side of the head-to-head strip.
class LiveH2hSideData {
  const LiveH2hSideData({
    required this.name,
    required this.ringColor,
    this.avatars = const [],
  });

  final String name;
  final Color ringColor;

  /// One avatar for a single athlete / team, two for a pair. Empty = initials
  /// of [name].
  final List<LiveAvatarData> avatars;
}

/// Head-to-head overlay drawn at the bottom of the video, same look as the Web:
/// frosted navy panel with a blue edge, a thin header (logo, title, round pill)
/// and two light slanted cards with a coloured avatar ring, "VS" in between.
///
/// It sizes itself from the width it is given (the video width): centred,
/// about 70% wide, every dimension scaled by [liveOverlayScale].
class LiveH2hOverlay extends StatelessWidget {
  const LiveH2hOverlay({
    super.key,
    required this.title,
    required this.roundLabel,
    required this.left,
    required this.right,
    this.semanticsLabel,
    this.onClose,
  });

  /// Ring colours of the two sides (blue / red, like the Web).
  static const leftRing = Color(0xFF0CA0F3);
  static const rightRing = Color(0xFFDE3F55);

  final String title;
  final String roundLabel;
  final LiveH2hSideData left;
  final LiveH2hSideData right;

  /// Spoken summary ("A vs B"); the drawn text is hidden from screen readers.
  final String? semanticsLabel;

  /// When set, a close button hangs off the panel's top-right corner.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final card = LayoutBuilder(
      builder: (context, constraints) {
        final video = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 400.0;
        final gutter = onClose == null ? 0.0 : liveOverlayCloseGutter;
        final width = math.min(
          (video * _widthShare).clamp(_minPanelWidth, _maxPanelWidth),
          video - 2 * gutter,
        );
        return Align(
          heightFactor: 1,
          child: LiveOverlayCloseFrame(
            onClose: onClose,
            child: SizedBox(
              key: const ValueKey('live-h2h-panel'),
              width: width,
              child: _card(liveOverlayScale(video)),
            ),
          ),
        );
      },
    );
    final label = semanticsLabel;
    if (label == null) return card;
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: card),
    );
  }

  Widget _card(double scale) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: const Color.fromRGBO(11, 107, 184, 0.85),
          width: math.max(1, 1.5 * scale),
        ),
        // Translucent navy (alpha 0.52 -> 0.60); the blur below does the rest.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x85091F40), Color(0x99061832)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5 * scale),
        child: liveGlassBackdrop(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                title: title,
                roundLabel: roundLabel,
                scale: scale,
                closeReserve: onClose == null ? 0 : liveOverlayCloseReserve,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  6 * scale,
                  8 * scale,
                  6 * scale,
                  8 * scale,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PlayerCard(
                        data: left,
                        mirrored: false,
                        scale: scale,
                      ),
                    ),
                    SizedBox(
                      width: 26 * scale,
                      child: Text(
                        'VS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _font(12, scale),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PlayerCard(
                        data: right,
                        mirrored: true,
                        scale: scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.roundLabel,
    required this.scale,
    required this.closeReserve,
  });

  final String title;
  final String roundLabel;
  final double scale;

  /// Right-hand room for the close button hanging over the corner (0 = none).
  final double closeReserve;

  @override
  Widget build(BuildContext context) {
    final words = title.trim().split(' ');
    final lead = words.length > 1
        ? '${words.sublist(0, words.length - 1).join(' ')} '
        : '';
    final tail = words.last;
    final height = 28 * scale;
    return Container(
      height: height,
      padding: EdgeInsets.only(
        left: 8 * scale,
        right: 8 * scale + closeReserve,
      ),
      decoration: BoxDecoration(
        // The band is denser than the panel so the title stays crisp.
        gradient: const LinearGradient(
          colors: [Color(0xB30C2C5E), Color(0xB30A2148), Color(0xB30B2A58)],
          stops: [0, 0.55, 1],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xA61E90FF),
            width: math.max(1, 1.5 * scale),
          ),
        ),
      ),
      child: Row(
        children: [
          // The logo asset is a 2049:552 wordmark, 70% of the header tall.
          SizedBox(
            height: height * 0.7,
            child: AspectRatio(
              aspectRatio: 2049 / 552,
              child: SvgPicture.asset(
                AppConstants.logoIconSvg,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
          SizedBox(width: 7 * scale),
          Container(width: 1, height: 10 * scale, color: Colors.white54),
          SizedBox(width: 7 * scale),
          Text.rich(
            TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: _font(10, scale),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6 * scale,
              ),
              children: [
                TextSpan(text: lead),
                TextSpan(
                  text: tail,
                  style: const TextStyle(color: _accent),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (roundLabel.trim().isNotEmpty)
            Flexible(
              child: Container(
                key: const ValueKey('live-h2h-round'),
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color.fromRGBO(214, 226, 246, 0.38),
                  ),
                ),
                child: Text(
                  roundLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFD8E4F7),
                    fontSize: _font(9, scale),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4 * scale,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.data,
    required this.mirrored,
    required this.scale,
  });

  final LiveH2hSideData data;
  final bool mirrored;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final ring = LiveSideAvatars(
      avatars: data.avatars.isEmpty
          ? [LiveAvatarData(name: data.name)]
          : data.avatars,
      diameter: 28 * scale,
      borderColor: data.ringColor,
      borderWidth: math.max(1.5, 2.5 * scale),
    );
    final name = Expanded(
      child: Text(
        data.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: mirrored ? TextAlign.end : TextAlign.start,
        style: TextStyle(
          color: _ink,
          fontSize: _font(10.5, scale),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return ClipPath(
      clipper: _SlantClipper(mirrored: mirrored),
      child: Container(
        height: 38 * scale,
        padding: EdgeInsets.symmetric(horizontal: 8 * scale),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: mirrored
                ? const [
                    Color(0xFFDDE7F2),
                    Color(0xFFEEF3FA),
                    Color(0xFFE8DFEA),
                  ]
                : const [
                    Color(0xFFD3E2F5),
                    Color(0xFFEEF4FB),
                    Color(0xFFDCE7F3),
                  ],
          ),
        ),
        child: Row(
          children: mirrored
              ? [name, SizedBox(width: 6 * scale), ring]
              : [ring, SizedBox(width: 6 * scale), name],
        ),
      ),
    );
  }
}

/// Parallelogram of the Web player card: the inner edge is slanted 8%.
class _SlantClipper extends CustomClipper<Path> {
  const _SlantClipper({required this.mirrored});

  final bool mirrored;

  @override
  Path getClip(Size size) {
    final cut = size.width * 0.08;
    return mirrored
        ? (Path()
            ..moveTo(cut, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close())
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width - cut, size.height)
            ..lineTo(0, size.height)
            ..close());
  }

  @override
  bool shouldReclip(covariant _SlantClipper oldClipper) =>
      oldClipper.mirrored != mirrored;
}
