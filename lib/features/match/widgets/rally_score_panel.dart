import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/services/rally_serve_rules.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Rally Point scoring panel — cho Badminton, Table Tennis, Pickleball Rally.
class RallyScorePanel extends ConsumerWidget {
  final MatchControlParams params;
  final bool isReadOnly;
  const RallyScorePanel({
    required this.params,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorePanelNotifierProvider(params));
    final notifier = ref.read(scorePanelNotifierProvider(params).notifier);
    final r = state.rally ?? const RallySetState();
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    // Select only what this panel shows: a socket echo or poll with the same
    // names and team sizes must not rebuild the whole panel.
    final info = ref.watch(
      singleMatchProvider((
        tournamentId: params.tournamentId,
        matchId: params.matchId,
      )).select(
        (m) => (
          m.value?.team1Name,
          m.value?.team2Name,
          m.value?.team1Members?.length ?? 0,
          m.value?.team2Members?.length ?? 0,
        ),
      ),
    );
    final team1Name = info.$1 ?? l10n.pickleballTeam1;
    final team2Name = info.$2 ?? l10n.pickleballTeam2;

    // Serve line and reminders: badminton and table tennis on a strict match
    // only. Pickleball rally and Lite scorecards keep the plain panel.
    final kind = state.config.kind;
    final showServe =
        !state.isOpenScoring &&
        (kind == SportRuleKind.badminton || kind == SportRuleKind.tableTennis);
    final doubles = info.$3 >= 2 || info.$4 >= 2;
    final gameIndex = state.finishedSets.length;
    final lastSet = state.finishedSets.isEmpty ? null : state.finishedSets.last;
    final serve = showServe
        ? rallyServe(
            kind: kind,
            p1: r.currentP1,
            p2: r.currentP2,
            gameIndex: gameIndex,
            doubles: doubles,
            lastWinner: r.lastWinner,
            prevGameWinner: lastSet == null
                ? null
                : (lastSet.score1 > lastSet.score2 ? 1 : 2),
            swaps1: r.swaps1,
            swaps2: r.swaps2,
          )
        : null;
    final breakNote = showServe
        ? _breakText(
            l10n,
            rallyServeBanner(
              kind: kind,
              p1: r.currentP1,
              p2: r.currentP2,
              gameIndex: gameIndex,
              bestOf: state.config.bestOf,
              lastWinner: r.lastWinner,
            ),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          final team1Widget = _buildTeamCardHorizontalScore(
            isTeam1: true,
            score: r.currentP1,
            colors: colors,
            teamName: team1Name,
            serveLabel: _serveLabel(l10n, serve, 1),
            showServeLine: showServe,
            onIncrement: () => notifier.rallyAddPoint(true),
            onDecrement: () => notifier.rallyRemovePoint(true),
          );

          final team2Widget = _buildTeamCardHorizontalScore(
            isTeam1: false,
            score: r.currentP2,
            colors: colors,
            teamName: team2Name,
            serveLabel: _serveLabel(l10n, serve, 2),
            showServeLine: showServe,
            onIncrement: () => notifier.rallyAddPoint(false),
            onDecrement: () => notifier.rallyRemovePoint(false),
          );

          final cards = isLandscape
              ? Row(
                  children: [
                    Expanded(child: team1Widget),
                    const SizedBox(width: 10),
                    Expanded(child: team2Widget),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: team1Widget),
                    const SizedBox(height: 10),
                    Expanded(child: team2Widget),
                  ],
                );
          if (breakNote == null) return cards;
          return Column(
            children: [
              _buildBreakBanner(breakNote),
              Expanded(child: cards),
            ],
          );
        },
      ),
    );
  }

  /// "● GIAO · ô phải · VĐV 1" for the serving team, empty for the other.
  String? _serveLabel(AppLocalizations l10n, RallyServe? serve, int team) {
    if (serve == null || serve.serverTeam != team) return null;
    return [
      l10n.cbdRallyServe,
      if (serve.rightCourt != null)
        serve.rightCourt! ? l10n.cbdRallyServeRight : l10n.cbdRallyServeLeft,
      if (serve.serverPlayer != null)
        l10n.cbdRallyServePlayer(serve.serverPlayer!),
    ].join(' · ');
  }

  String? _breakText(AppLocalizations l10n, RallyBreak b) => switch (b) {
    RallyBreak.none => null,
    RallyBreak.interval60 => l10n.cbdRallyBreak60,
    RallyBreak.interval60ChangeEnds => l10n.cbdRallyBreak60ChangeEnds,
    RallyBreak.betweenGames => l10n.cbdRallyBreakBetweenGames,
    RallyBreak.changeEnds => l10n.cbdRallyChangeEnds,
  };

  Widget _buildBreakBanner(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFF4500)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTeamCardHorizontalScore({
    required bool isTeam1,
    required int score,
    required AppColorsExtension colors,
    required String teamName,
    required String? serveLabel,
    required bool showServeLine,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final color = isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tên đội rút gọn (Đội A / Đội B) để dồn không gian cho số điểm
          Text(
            isTeam1 ? 'Đội A' : 'Đội B',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (showServeLine)
            SizedBox(
              height: 16,
              child: Center(
                child: Text(
                  serveLabel ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 4),

          // HÀNG NGANG: [- SÁT VIỀN TRÁI] | [SỐ ĐIỂM Ở GIỮA] | [+ SÁT VIỀN PHẢI]
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // NÚT - (SÁT VIỀN TRÁI, KÍCH THƯỚC 52x52)
                if (!isReadOnly)
                  GestureDetector(
                    onTap: onDecrement,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.borderLight,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 28,
                        color: colors.textMuted,
                      ),
                    ),
                  ),

                // SỐ ĐIỂM Ở CHÍNH GIỮA
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 84,
                            fontWeight: FontWeight.w900,
                            color: color,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                // NÚT + (SÁT VIỀN PHẢI, KÍCH THƯỚC 56x56, GIỮ STYLE MÀU ĐỘI)
                if (!isReadOnly)
                  GestureDetector(
                    onTap: onIncrement,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
