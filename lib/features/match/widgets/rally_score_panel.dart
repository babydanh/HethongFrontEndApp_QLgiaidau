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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Đội 1 (Trái)
          Expanded(
            child: _buildSideVerticalLayout(
              isTeam1: true,
              score: r.currentP1,
              colors: colors,
              teamName: team1Name,
              onIncrement: () => notifier.rallyAddPoint(true),
              onDecrement: () => notifier.rallyRemovePoint(true),
            ),
          ),
          const SizedBox(width: 12),
          // Đường phân cách giữa 2 đội
          Container(
            width: 1.5,
            height: 220,
            color: colors.border.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          // Đội 2 (Phải)
          Expanded(
            child: _buildSideVerticalLayout(
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

  Widget _buildSideVerticalLayout({
    required bool isTeam1,
    required int score,
    required AppColorsExtension colors,
    required String teamName,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final color = isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tên vận động viên (cho xuống dòng to rõ dễ đọc)
          SizedBox(
            height: 42,
            child: Center(
              child: Text(
                teamName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // NẰM NGANG SONG SONG: [-]  [ SỐ 0 ]  [+]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nút - (Bên trái số 0)
              if (!isReadOnly)
                GestureDetector(
                  onTap: onDecrement,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border, width: 1.2),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 24,
                      color: colors.textSecondary,
                    ),
                  ),
                ),

              // SỐ ĐIỂM 0 (Ở GIỮA NẰM NGANG NỐI VỚI + VÀ -)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // Nút + (Bên phải số 0)
              if (!isReadOnly)
                GestureDetector(
                  onTap: onIncrement,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(Icons.add_rounded, size: 28, color: color),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
