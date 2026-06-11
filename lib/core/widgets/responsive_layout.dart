import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktopOrTv;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktopOrTv,
  });

  /// Ngưỡng kiểm tra kích thước màn hình
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1200;

  static bool isDesktopOrTv(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1200) {
          return tablet ?? mobile;
        } else {
          return desktopOrTv ?? tablet ?? mobile;
        }
      },
    );
  }
}

class SliverResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktopOrTv;

  const SliverResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktopOrTv,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        if (constraints.crossAxisExtent < 600) {
          return mobile;
        } else if (constraints.crossAxisExtent < 1200) {
          return tablet ?? mobile;
        } else {
          return desktopOrTv ?? tablet ?? mobile;
        }
      },
    );
  }
}
