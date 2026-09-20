import 'package:flutter/material.dart';

/// Widget loading thể thao chuẩn SportO (đã loại bỏ hoàn toàn sân 3D blender cũ)
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
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF1D8EF8),
        strokeWidth: 2.5,
      ),
    );
  }
}
