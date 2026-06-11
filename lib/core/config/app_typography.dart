import 'package:flutter/material.dart';

class AppTypography {
  // Font sizes
  static const double xs = 10.0;
  static const double sm = 11.0;
  static const double label = 12.0;
  static const double body = 13.0;
  static const double bodyM = 14.0;
  static const double button = 14.0;
  static const double bodyL = 15.0;
  static const double heading = 20.0;
  static const double heading2 = 24.0;
  static const double heading3 = 28.0;
  static const double heading1 = 32.0;
  static const double display = 48.0;

  // Pre-made styles
  static TextStyle get headingStyle => const TextStyle(
        fontSize: heading,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontSize: body,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelStyle => const TextStyle(
        fontSize: label,
        fontWeight: FontWeight.w500,
      );
}
