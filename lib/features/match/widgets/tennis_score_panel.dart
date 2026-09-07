import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Tennis scoring panel với 15-30-40, Deuce/Advantage, Tiebreak mode.
class TennisScorePanel extends ConsumerWidget {
  final MatchControlParams params;
  final bool isReadOnly;
  const TennisScorePanel({
    required this.params,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorePanelNotifierProvider(params));
    final notifier = ref.read(scorePanelNotifierProvider(params).notifier);
    final t = state.tennis ?? const TennisGameState();
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final ts = state.config;

    // Fetch team names
    final matchAsync = ref.watch(
      singleMatchProvider((
        tournamentId: params.tournamentId,
        matchId: params.matchId,
      )),
    );
    final team1Name = matchAsync.value?.team1Name ?? l10n.pickleballTeam1;
    final team2Name = matchAsync.value?.team2Name ?? l10n.pickleballTeam2;

    final isDeuce =
        !t.isTiebreak &&
        t.team1GamePoints >= 3 &&
        t.team2GamePoints >= 3 &&
        t.team1GamePoints == t.team2GamePoints;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final team1Widget = _buildTeamControl(
      isTeam1: true,
      t: t,
      notifier: notifier,
      colors: colors,
      teamName: team1Name,
      l10n: l10n,
    );

    final team2Widget = _buildTeamControl(
      isTeam1: false,
      t: t,
      notifier: notifier,
      colors: colors,
      teamName: team2Name,
      l10n: l10n,
    );

    final tiebreakBanner = t.isTiebreak
        ? Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFF4500)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.tennisTiebreakInfo(ts.tiebreakPoints ?? 7),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    final deuceWidget = (isDeuce || t.isTiebreak)
        ? _buildCenterState(colors, isDeuce, t.isTiebreak, l10n)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          ?tiebreakBanner,
          Expanded(
            child: isLandscape
                ? Row(
                    children: [
                      Expanded(child: team1Widget),
                      if (deuceWidget != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: deuceWidget,
                        ),
                      const SizedBox(width: 8),
                      Expanded(child: team2Widget),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: team1Widget),
                      if (deuceWidget != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: deuceWidget,
                        ),
                      const SizedBox(height: 8),
                      Expanded(child: team2Widget),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamControl({
    required bool isTeam1,
    required TennisGameState t,
    required ScorePanelNotifier notifier,
    required AppColorsExtension colors,
    required String teamName,
    required AppLocalizations l10n,
  }) {
    final displayPoints = formatTennisPoint(
      isTeam1 ? t.team1GamePoints : t.team2GamePoints,
      isTeam1 ? t.team2GamePoints : t.team1GamePoints,
      t.isTiebreak,
    );
    final color = isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C);
    final rawPoints = isTeam1 ? t.team1GamePoints : t.team2GamePoints;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tên đội / VĐV
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.tennisCurrentPoint(rawPoints),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // HÀNG NGANG: [-] | [ĐIỂM SỐ TENNIS] | [+]
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nút -
                if (!isReadOnly)
                  GestureDetector(
                    onTap: () => notifier.tennisRemovePoint(isTeam1),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border, width: 1.5),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 26,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48),

                // Điểm số Tennis hiển thị to ở giữa
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        displayPoints,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // Nút +
                if (!isReadOnly)
                  GestureDetector(
                    onTap: () => notifier.tennisAwardPoint(isTeam1),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.45),
                          width: 1.8,
                        ),
                      ),
                      child: Icon(Icons.add_rounded, size: 32, color: color),
                    ),
                  )
                else
                  const SizedBox(width: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterState(
    AppColorsExtension colors,
    bool isDeuce,
    bool isTiebreak,
    AppLocalizations l10n,
  ) {
    if (!isTiebreak && !isDeuce) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isTiebreak
            ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
            : Colors.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isTiebreak
              ? const Color(0xFFFF7A00).withValues(alpha: 0.24)
              : Colors.amber.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        isTiebreak ? l10n.tennisTiebreakLabel : l10n.tennisDeuce,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isTiebreak ? const Color(0xFFFF7A00) : Colors.amber.shade700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
