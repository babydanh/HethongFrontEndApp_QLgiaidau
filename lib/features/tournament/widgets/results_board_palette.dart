import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
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

  /// Box head colours and icon of a bracket branch (Web `BOX_TONE`): green
  /// winners, amber losers, violet grand final, slate for plain rounds.
  static BranchTone branchTone(BuildContext context, ResultsBranch branch) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (branch) {
      ResultsBranch.winners => dark ? _winnersDark : _winnersLight,
      ResultsBranch.losers => dark ? _losersDark : _losersLight,
      ResultsBranch.grandFinal => dark ? _grandDark : _grandLight,
      ResultsBranch.main => dark ? _mainDark : _mainLight,
    };
  }

  /// Left border of a match row (Web `matchTone`).
  static Color toneBorder(MatchTone tone) => switch (tone) {
    MatchTone.ready => const Color(0xFF3B82F6),
    MatchTone.wait => const Color(0xFF94A3B8),
    MatchTone.live => const Color(0xFFF43F5E),
    MatchTone.done => const Color(0xFF10B981),
    MatchTone.cancel => const Color(0xFFD1D5DB),
  };

  static const _winnersLight = BranchTone(
    head: Color(0xFFECFDF5),
    pill: Color(0xFFD1FAE5),
    pillLine: Color(0xFFA7F3D0),
    pillText: Color(0xFF047857),
    icon: Icons.trending_up_rounded,
  );
  static const _winnersDark = BranchTone(
    head: Color(0xFF022C22),
    pill: Color(0xFF064E3B),
    pillLine: Color(0xFF047857),
    pillText: Color(0xFFA7F3D0),
    icon: Icons.trending_up_rounded,
  );
  static const _losersLight = BranchTone(
    head: Color(0xFFFFFBEB),
    pill: Color(0xFFFEF3C7),
    pillLine: Color(0xFFFDE68A),
    pillText: Color(0xFFB45309),
    icon: Icons.trending_down_rounded,
  );
  static const _losersDark = BranchTone(
    head: Color(0xFF2A1D05),
    pill: Color(0xFF78350F),
    pillLine: Color(0xFFB45309),
    pillText: Color(0xFFFDE68A),
    icon: Icons.trending_down_rounded,
  );
  static const _grandLight = BranchTone(
    head: Color(0xFFF5F3FF),
    pill: Color(0xFFEDE9FE),
    pillLine: Color(0xFFDDD6FE),
    pillText: Color(0xFF6D28D9),
    icon: Icons.emoji_events_rounded,
  );
  static const _grandDark = BranchTone(
    head: Color(0xFF1E1B4B),
    pill: Color(0xFF4C1D95),
    pillLine: Color(0xFF6D28D9),
    pillText: Color(0xFFDDD6FE),
    icon: Icons.emoji_events_rounded,
  );
  static const _mainLight = BranchTone(
    head: Color(0xFFF8FAFC),
    pill: Color(0xFFF1F5F9),
    pillLine: Color(0xFFE2E8F0),
    pillText: Color(0xFF334155),
    icon: Icons.account_tree_outlined,
  );
  static const _mainDark = BranchTone(
    head: Color(0xFF1E293B),
    pill: Color(0xFF334155),
    pillLine: Color(0xFF475569),
    pillText: Color(0xFFE2E8F0),
    icon: Icons.account_tree_outlined,
  );
}

/// Colours and icon of one box head, see [ResultsBoardPalette.branchTone].
class BranchTone {
  const BranchTone({
    required this.head,
    required this.pill,
    required this.pillLine,
    required this.pillText,
    required this.icon,
  });

  final Color head;
  final Color pill;
  final Color pillLine;
  final Color pillText;
  final IconData icon;
}
