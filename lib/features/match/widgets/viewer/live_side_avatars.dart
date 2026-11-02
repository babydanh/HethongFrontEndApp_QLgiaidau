import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:flutter/material.dart';

/// One avatar of a side: a photo when [url] is set, otherwise the initials of
/// [name] on a stable colour (same rule as the Web).
class LiveAvatarData {
  const LiveAvatarData({required this.name, this.url});

  final String name;
  final String? url;
}

/// One avatar for a single athlete or a team, two overlapped avatars for a
/// doubles pair. More than two are cut to the first two.
class LiveSideAvatars extends StatelessWidget {
  const LiveSideAvatars({
    super.key,
    required this.avatars,
    required this.diameter,
    this.borderColor = Colors.white24,
    this.borderWidth = 1.5,
  });

  static const maxShown = 2;

  /// Part of the diameter by which the second avatar covers the first.
  static const _step = 0.6;

  final List<LiveAvatarData> avatars;
  final double diameter;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final shown = avatars.take(maxShown).toList(growable: false);
    final step = diameter * _step;
    return ExcludeSemantics(
      child: SizedBox(
        width: diameter + step * (shown.length - 1).clamp(0, maxShown),
        height: diameter,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: step * i,
                child: _Dot(
                  data: shown[i],
                  diameter: diameter,
                  borderColor: borderColor,
                  borderWidth: borderWidth,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.data,
    required this.diameter,
    required this.borderColor,
    required this.borderWidth,
  });

  final LiveAvatarData data;
  final double diameter;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final url = data.url;
    final initials = Center(
      child: Text(
        avatarInitials(data.name),
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: diameter * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarFallbackColor(data.name),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? initials
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}
