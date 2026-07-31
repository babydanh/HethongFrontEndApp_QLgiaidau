import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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

    final matchAsync = ref.watch(
      singleMatchProvider((
        tournamentId: params.tournamentId,
        matchId: params.matchId,
      )),
    );
    final team1Name = matchAsync.value?.team1Name ?? l10n.pickleballTeam1;
    final team2Name = matchAsync.value?.team2Name ?? l10n.pickleballTeam2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          // ĐỘI 1 (BLUE - NẰM Ở Ô TRÊN)
          Expanded(
            child: _buildTeamCardHorizontalScore(
              isTeam1: true,
              score: r.currentP1,
              colors: colors,
              teamName: team1Name,
              onIncrement: () => notifier.rallyAddPoint(true),
              onDecrement: () => notifier.rallyRemovePoint(true),
            ),
          ),
          const SizedBox(height: 10),
          // ĐỘI 2 (RED - NẰM Ở Ô DƯỚI)
          Expanded(
            child: _buildTeamCardHorizontalScore(
              isTeam1: false,
              score: r.currentP2,
              colors: colors,
              teamName: team2Name,
              onIncrement: () => notifier.rallyAddPoint(false),
              onDecrement: () => notifier.rallyRemovePoint(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCardHorizontalScore({
    required bool isTeam1,
    required int score,
    required AppColorsExtension colors,
    required String teamName,
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
          // Tên vận động viên / Đội (NẰM Ở TRÊN CÙNG MỖI Ô)
          Text(
            teamName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // HÀNG NGANG: [- SÁT VIỀN TRÁI] | [SỐ 0 Ở GIỮA] | [+ SÁT VIỀN PHẢI]
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // NÚT - (SÁT VIỀN TRÁI)
                if (!isReadOnly)
                  GestureDetector(
                    onTap: onDecrement,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border, width: 1.5),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 28,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),

                // SỐ ĐIỂM 0 (NẰM NỔI BẬT NẰM NGANG SONG SONG Ở CHÍNH GIỮA)
                Expanded(
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

                // NÚT + (SÁT VIỀN PHẢI)
                if (!isReadOnly)
                  GestureDetector(
                    onTap: onIncrement,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.8),
                      ),
                      child: Icon(Icons.add_rounded, size: 34, color: color),
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
