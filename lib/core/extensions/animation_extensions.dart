import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension AnimationExtensions on Widget {
  Widget fadeInSlide({Duration delay = Duration.zero}) {
    return animate()
      .fadeIn(duration: 400.ms, delay: delay)
      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  Widget scaleIn({Duration delay = Duration.zero}) {
    return animate()
      .scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, delay: delay, curve: Curves.easeOutBack)
      .fadeIn(duration: 300.ms, delay: delay);
  }

  Widget slideInFromBottom({Duration delay = Duration.zero}) {
    return animate()
      .slideY(begin: 0.1, end: 0, duration: 350.ms, delay: delay, curve: Curves.easeOutBack)
      .fadeIn(duration: 350.ms, delay: delay);
  }
}
