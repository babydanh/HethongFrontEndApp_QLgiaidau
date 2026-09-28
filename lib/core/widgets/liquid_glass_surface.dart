import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A bounded, lightweight shader-glass surface for small interactive chrome.
///
/// The standard Liquid Glass shader adds refraction and a specular rim without
/// using BackdropFilter on a scrolling surface. High contrast uses the opaque
/// theme fallback instead.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    required this.tintColor,
    required this.fallbackColor,
    required this.borderColor,
    required this.borderRadius,
    this.blurSigma = 12,
    this.opacity = 0.76,
  }) : assert(blurSigma >= 0),
       assert(opacity >= 0 && opacity <= 1);

  final Widget child;
  final Color tintColor;
  final Color fallbackColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    if (highContrast || blurSigma == 0) {
      return ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fallbackColor,
            border: Border.all(color: borderColor),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      );
    }

    return GlassContainer(
      useOwnLayer: true,
      clipBehavior: Clip.antiAlias,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius.topLeft.x),
      settings: LiquidGlassSettings(
        glassColor: tintColor.withValues(alpha: opacity * 0.36),
        blur: blurSigma,
        thickness: 28,
        chromaticAberration: 0.004,
        lightIntensity: 0.55,
        ambientStrength: 0.12,
        ambientRim: 0.08,
        fresnelStrength: 0.75,
        refractiveIndex: 1.18,
        saturation: 1.2,
        glowIntensity: 0.3,
        standardOpacityMultiplier: 0.88,
        shadowElevation: 0.7,
        edgeAbsorption: 0.08,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor.withValues(alpha: opacity * 0.62),
            width: 0.8,
          ),
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}
