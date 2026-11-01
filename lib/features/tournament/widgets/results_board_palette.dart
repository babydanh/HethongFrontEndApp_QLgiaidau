import 'package:flutter/material.dart';

/// Colours of the match board, copied from the approved Lavish mockup
/// (`app-tab-dangdienra-ketqua.html`, option A). Light values are the mockup's
/// own; dark mode maps the same roles onto slate shades.
class ResultsBoardPalette {
  const ResultsBoardPalette._({
    required this.surface,
    required this.text,
    required this.muted,
    required this.faint,
    required this.fadedScore,
    required this.line,
    required this.rowLine,
    required this.chipBg,
    required this.chipLine,
    required this.chipText,
    required this.headBg,
    required this.headLiveBg,
    required this.pillBg,
    required this.pillLine,
    required this.pillText,
    required this.pillLiveBg,
    required this.pillLiveLine,
    required this.pillLiveText,
    required this.countBg,
    required this.badgeBg,
    required this.badgeText,
  });

  static const _light = ResultsBoardPalette._(
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF0F172A),
    muted: Color(0xFF475569),
    faint: Color(0xFF94A3B8),
    fadedScore: Color(0xFFCBD5E1),
    line: Color(0xFFE2E8F0),
    rowLine: Color(0xFFEEF2F7),
    chipBg: Color(0xFFF1F5F9),
    chipLine: Color(0xFFCBD5E1),
    chipText: Color(0xFF475569),
    headBg: Color(0xFFEFF6FF),
    headLiveBg: Color(0xFFFFF1F2),
    pillBg: Color(0xFFDBEAFE),
    pillLine: Color(0xFFBFDBFE),
    pillText: Color(0xFF1D4ED8),
    pillLiveBg: Color(0xFFFFE4E6),
    pillLiveLine: Color(0xFFFECDD3),
    pillLiveText: Color(0xFFBE123C),
    countBg: Color(0xFFF8FAFC),
    badgeBg: Color(0xFFF1F5F9),
    badgeText: Color(0xFF334155),
  );

  static const _dark = ResultsBoardPalette._(
    surface: Color(0xFF0F172A),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    faint: Color(0xFF64748B),
    fadedScore: Color(0xFF475569),
    line: Color(0xFF334155),
    rowLine: Color(0xFF1E293B),
    chipBg: Color(0xFF1E293B),
    chipLine: Color(0xFF475569),
    chipText: Color(0xFFCBD5E1),
    headBg: Color(0xFF172554),
    headLiveBg: Color(0xFF4C0519),
    pillBg: Color(0xFF1E3A8A),
    pillLine: Color(0xFF1D4ED8),
    pillText: Color(0xFFBFDBFE),
    pillLiveBg: Color(0xFF881337),
    pillLiveLine: Color(0xFFBE123C),
    pillLiveText: Color(0xFFFECDD3),
    countBg: Color(0xFF0F172A),
    badgeBg: Color(0xFF1E293B),
    badgeText: Color(0xFFE2E8F0),
  );

  static ResultsBoardPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Selected chip fill and border (`.ch.on`).
  static const chipOn = Color(0xFF1D4ED8);

  /// Live dot (`.dot`), live points and its 3px ring.
  static const live = Color(0xFFE11D48);
  static const liveRing = Color(0xFFFFE4E6);

  final Color surface;
  final Color text;
  final Color muted;
  final Color faint;

  /// Points of the losing side and the "–" of a match not played yet.
  final Color fadedScore;
  final Color line;
  final Color rowLine;
  final Color chipBg;
  final Color chipLine;
  final Color chipText;
  final Color headBg;
  final Color headLiveBg;
  final Color pillBg;
  final Color pillLine;
  final Color pillText;
  final Color pillLiveBg;
  final Color pillLiveLine;
  final Color pillLiveText;
  final Color countBg;
  final Color badgeBg;
  final Color badgeText;
}
