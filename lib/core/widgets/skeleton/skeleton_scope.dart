import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Một vùng skeleton dùng đúng một nhịp shimmer cho mọi khối con. Lồng trong
/// một scope khác thì dùng lại scope ngoài. Bật "giảm chuyển động" thì các khối
/// là màu tĩnh, không animation.
class SkeletonScope extends StatelessWidget {
  final Widget child;

  const SkeletonScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (_SkeletonFill.maybeOf(context) != null) return child;

    final colors = context.colors;
    if (MediaQuery.disableAnimationsOf(context)) {
      return _SkeletonFill(color: colors.bgSurface, child: child);
    }
    // Shimmer chỉ dùng độ trong suốt của khối con; màu thật do gradient quyết.
    return _SkeletonFill(
      color: Colors.white,
      child: RepaintBoundary(
        child: Shimmer.fromColors(
          baseColor: colors.bgSurface,
          highlightColor: colors.bgCard,
          child: child,
        ),
      ),
    );
  }
}

class _SkeletonFill extends InheritedWidget {
  final Color color;

  const _SkeletonFill({required this.color, required super.child});

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonFill>()?.color;

  @override
  bool updateShouldNotify(_SkeletonFill oldWidget) => color != oldWidget.color;
}

Color _fill(BuildContext context) =>
    _SkeletonFill.maybeOf(context) ?? context.colors.bgSurface;

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: _fill(context),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Một dòng chữ giả; `width` null thì kéo hết chiều ngang có sẵn.
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonLine({super.key, this.width, this.height = 12});

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, radius: height / 2);
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: _fill(context), shape: BoxShape.circle),
  );
}
