import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/pickleball_court_3d_animated.dart';

/// Widget hoạt họa Sân Pickleball 3D:
/// Sử dụng trực tiếp `Pickleball3DCourtAnimation` với khối sân 3D isometric chuẩn SportO,
/// bóng nảy to ra nhỏ lại theo phối cảnh 3D và sóng xung kích năng lượng.
class PickleballCourtAnimation extends StatelessWidget {
  final double size;
  final bool autoPlay;
  final VoidCallback? onTap;

  const PickleballCourtAnimation({
    super.key,
    this.size = 200,
    this.autoPlay = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pickleball3DCourtAnimation(
      size: size,
      autoPlay: autoPlay,
      onTap: onTap,
    );
  }
}
