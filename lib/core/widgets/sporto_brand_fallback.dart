import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Packaged brand fallback used when tournament media is missing or fails.
/// It never waits for the API/CDN, so the fallback cannot flash blank first.
class SportoBrandFallback extends StatelessWidget {
  final bool withTagline;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;

  const SportoBrandFallback({
    super.key,
    this.withTagline = false,
    this.padding = const EdgeInsets.all(20),
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: SvgPicture.asset(
          withTagline
              ? 'assets/images/sporto_v1_with_text.svg'
              : 'assets/images/sporto_v1.svg',
          fit: BoxFit.contain,
          semanticsLabel: semanticsLabel ?? 'SportO',
        ),
      ),
    );
  }
}
