import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

typedef _Column = ({
  String label,
  double width,
  String Function(Standing) value,
});

/// Flat Swiss standings table. [standings] must already be in Backend `rank`
/// order (the standings provider guarantees it); the Rank column shows the
/// Backend value. Scrolls horizontally on narrow screens, never nests cards.
class SwissStandingsView extends StatelessWidget {
  const SwissStandingsView({
    super.key,
    required this.standings,
    required this.tiebreakOrder,
  });

  final List<Standing> standings;
  final List<SwissTiebreak> tiebreakOrder;

  static const double _rankWidth = 48;
  static const double _teamWidth = 160;
  static const double _statWidth = 56;
  static const double _tiebreakWidth = 104;

  String _decimal(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  List<_Column> _columns(AppLocalizations l10n) {
    final tiebreaks = <_Column?>[
      for (final t in tiebreakOrder)
        switch (t) {
          SwissTiebreak.buchholz => (
            label: l10n.swissStandingsBuchholz,
            width: _tiebreakWidth,
            value: (s) => _decimal(s.buchholz),
          ),
          SwissTiebreak.buchholzCut1 => (
            label: l10n.swissStandingsBuchholzCut1,
            width: _tiebreakWidth,
            value: (s) => _decimal(s.buchholzCut1),
          ),
          SwissTiebreak.sonnebornBerger => (
            label: l10n.swissStandingsSonnebornBerger,
            width: _tiebreakWidth,
            value: (s) => _decimal(s.sonnebornBerger),
          ),
          SwissTiebreak.pointDiff => (
            label: l10n.swissStandingsPointDiff,
            width: _tiebreakWidth,
            value: (s) => '${s.pointDifference}',
          ),
          SwissTiebreak.wins => (
            label: l10n.swissStandingsWins,
            width: _tiebreakWidth,
            value: (s) => '${s.won}',
          ),
          // Applied on the server only; no column.
          SwissTiebreak.headToHead || SwissTiebreak.seed => null,
        },
    ].nonNulls.toList();

    return [
      (
        label: l10n.swissStandingsPlayed,
        width: _statWidth,
        value: (s) => '${s.played}',
      ),
      (
        label: l10n.swissStandingsWon,
        width: _statWidth,
        value: (s) => '${s.won}',
      ),
      (
        label: l10n.swissStandingsDrawn,
        width: _statWidth,
        value: (s) => '${s.drawn}',
      ),
      (
        label: l10n.swissStandingsLost,
        width: _statWidth,
        value: (s) => '${s.lost}',
      ),
      (
        label: l10n.swissStandingsPoints,
        width: _statWidth,
        value: (s) => '${s.totalPoints}',
      ),
      ...tiebreaks,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    if (standings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Text(
            l10n.swissStandingsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    final columns = _columns(l10n);
    final headerStyle = TextStyle(
      color: colors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final cellStyle = TextStyle(color: colors.textPrimary, fontSize: 14);
    final tableWidth =
        _rankWidth + _teamWidth + columns.fold(0.0, (sum, c) => sum + c.width);

    Widget cell(
      double width,
      String text,
      TextStyle style, {
      bool left = false,
    }) => SizedBox(
      width: width,
      child: Text(
        text,
        style: style,
        maxLines: left ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        textAlign: left ? TextAlign.start : TextAlign.center,
      ),
    );

    Widget row(
      String rank,
      String team,
      String Function(_Column) text,
      TextStyle style,
    ) => Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        children: [
          cell(_rankWidth - AppSpacing.sm, rank, style),
          cell(_teamWidth - AppSpacing.sm, team, style, left: true),
          for (final c in columns) cell(c.width, text(c), style),
        ],
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth + AppSpacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(
              l10n.swissStandingsRank,
              l10n.swissStandingsTeam,
              (c) => c.label,
              headerStyle,
            ),
            const Divider(height: 1),
            for (var i = 0; i < standings.length; i++) ...[
              row(
                '${standings[i].rank ?? i + 1}',
                standings[i].teamName,
                (c) => c.value(standings[i]),
                cellStyle,
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
