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
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          final team1Widget = _buildTeamCardHorizontalScore(
            isTeam1: true,
            score: r.currentP1,
            colors: colors,
            teamName: team1Name,
            onIncrement: () => notifier.rallyAddPoint(true),
            onDecrement: () => notifier.rallyRemovePoint(true),
          );

          final team2Widget = _buildTeamCardHorizontalScore(
            isTeam1: false,
            score: r.currentP2,
            colors: colors,
            teamName: team2Name,
            onIncrement: () => notifier.rallyAddPoint(false),
            onDecrement: () => notifier.rallyRemovePoint(false),
          );

          if (isLandscape) {
            return Row(
              children: [
                Expanded(child: team1Widget),
                const SizedBox(width: 10),
                Expanded(child: team2Widget),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: team1Widget),
              const SizedBox(height: 10),
              Expanded(child: team2Widget),
            ],
          );
        },
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
          const SizedBox(height: 4),

          // SỐ ĐIỂM TO RÕ Ở GIỮA
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 80,
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
          const SizedBox(height: 6),

          // NÚT ĐIỀU KHIỂN: [- (34x34) nhạt] VÀ [+ (52x52) nổi bật màu đội]
          if (!isReadOnly)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút - nhỏ hơn, màu nhạt
                GestureDetector(
                  onTap: onDecrement,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.borderLight,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Nút + to nổi bật màu đội
                GestureDetector(
                  onTap: onIncrement,
                  child: Container(
                    width: 52,
                    height: 52,
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
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
