import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:flutter/material.dart';

/// Same navy + blue family as the Web `LiveHeadToHeadOverlay` and the bracket
/// overlay.
const _accent = Color(0xFF1E90FF);
const _ink = Color(0xFF0B1B3A);

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
/// navy panel with a blue edge, a thin header (title + round pill) and two
/// light slanted cards with a coloured avatar ring, "VS" in between.
class LiveH2hOverlay extends StatelessWidget {
  const LiveH2hOverlay({
    super.key,
    required this.title,
    required this.roundLabel,
    required this.left,
    required this.right,
    this.semanticsLabel,
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

  @override
  Widget build(BuildContext context) {
    final card = _card();
    final label = semanticsLabel;
    if (label == null) return card;
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: card),
    );
  }

  Widget _card() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(11, 107, 184, 0.85),
          width: 1.5,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2091F40), Color(0xF5061832)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(title: title, roundLabel: roundLabel),
            Padding(
              // Right side keeps room for the screen's 44dp close button.
              padding: const EdgeInsets.fromLTRB(6, 8, 48, 8),
              child: Row(
                children: [
                  Expanded(child: _PlayerCard(data: left, mirrored: false)),
                  const SizedBox(
                    width: 26,
                    child: Text(
                      'VS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(child: _PlayerCard(data: right, mirrored: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.roundLabel});

  final String title;
  final String roundLabel;

  @override
  Widget build(BuildContext context) {
    final words = title.trim().split(' ');
    final lead = words.length > 1
        ? '${words.sublist(0, words.length - 1).join(' ')} '
        : '';
    final tail = words.last;
    return Container(
      height: 28,
      // Room for the 44dp close button the screen puts on the right.
      padding: const EdgeInsets.only(left: 8, right: 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C2C5E), Color(0xFF0A2148), Color(0xFF0B2A58)],
          stops: [0, 0.55, 1],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xA61E90FF), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 7),
          Container(width: 1, height: 10, color: Colors.white54),
          const SizedBox(width: 7),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
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
                  style: const TextStyle(
                    color: Color(0xFFD8E4F7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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
  const _PlayerCard({required this.data, required this.mirrored});

  final LiveH2hSideData data;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final ring = LiveSideAvatars(
      avatars: data.avatars.isEmpty
          ? [LiveAvatarData(name: data.name)]
          : data.avatars,
      diameter: 28,
      borderColor: data.ringColor,
      borderWidth: 2.5,
    );
    final name = Expanded(
      child: Text(
        data.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: mirrored ? TextAlign.end : TextAlign.start,
        style: const TextStyle(
          color: _ink,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return ClipPath(
      clipper: _SlantClipper(mirrored: mirrored),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: mirrored
                ? const [Color(0xFFDDE7F2), Color(0xFFEEF3FA), Color(0xFFE8DFEA)]
                : const [Color(0xFFD3E2F5), Color(0xFFEEF4FB), Color(0xFFDCE7F3)],
          ),
        ),
        child: Row(
          children: mirrored
              ? [name, const SizedBox(width: 6), ring]
              : [ring, const SizedBox(width: 6), name],
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
