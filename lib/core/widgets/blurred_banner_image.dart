import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

/// Shows a tournament banner whole, whatever its shape.
///
/// The banner is scaled to fit the frame (never cropped). A blurred copy of the
/// same image fills the frame behind it, so a square or very wide image leaves
/// no empty sides. A white-background logo simply blends into its own backdrop.
class BlurredBannerImage extends StatelessWidget {
  const BlurredBannerImage({
    super.key,
    required this.image,
    this.errorBuilder,
    this.frameBuilder,
  });

  final ImageProvider image;

  /// Built in place of the whole banner when the image cannot be loaded.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Wraps the banner, e.g. to show a placeholder until the first frame.
  final ImageFrameBuilder? frameBuilder;

  @override
  Widget build(BuildContext context) {
    // The blur is expensive to repaint, so keep it on its own layer.
    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Opacity(
                opacity: 0.7,
                child: Transform.scale(
                  scale: 1.15,
                  child: Image(
                    image: image,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    // A failed backdrop stays empty; the foreground shows the fallback.
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Image(
              image: image,
              fit: BoxFit.contain,
              frameBuilder: frameBuilder,
              errorBuilder: errorBuilder,
            ),
          ],
        ),
      ),
    );
  }
}
