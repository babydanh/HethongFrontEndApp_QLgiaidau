import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';

/// Rally Point scoring panel — cho Badminton, Table Tennis, Pickleball Rally.
///
/// Grid 2 cột đối xứng với nút +/− dạng tròn 48×48, touch target lớn.
/// Font số tabular-nums để không nhảy layout (9→10).
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
    final notifier = ref.watch(scorePanelNotifierProvider(params));
    final state = notifier.state;
    final r = state.rally ?? const RallySetState();
    final colors = context.colors;
    final ts = state.config;

    // Fetch team names
    final matchAsync = ref.watch(
      singleMatchProvider((
        tournamentId: params.tournamentId,
        matchId: params.matchId,
      )),
    );
    final team1Name = matchAsync.value?.team1Name ?? 'Đội 1';
    final team2Name = matchAsync.value?.team2Name ?? 'Đội 2';

    return SizedBox(
      height: 520,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final maxLivePoint = r.currentP1 > r.currentP2
              ? r.currentP1
              : r.currentP2;
          final nearSetPoint = maxLivePoint >= ts.tiebreakAt;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: nearSetPoint
                        ? colors.warning.withValues(alpha: 0.12)
                        : colors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: nearSetPoint
                          ? colors.warning.withValues(alpha: 0.3)
                          : colors.border,
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _topPill('${ts.pointsPerSet} điểm/set'),
                      _topPill(ts.bestOf > 1 ? 'BO${ts.bestOf}' : '1 set'),
                      if (ts.mustWinByTwo) _topPill('Thắng cách 2'),
                      if (nearSetPoint) _topPill('Đang gần điểm chốt set'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: compact
                      ? Column(
                          children: [
                            Expanded(
                              child: _buildSide(
                                isTeam1: true,
                                score: r.currentP1,
                                colors: colors,
                                onIncrement: () => notifier.rallyAddPoint(true),
                                onDecrement: () =>
                                    notifier.rallyRemovePoint(true),
                                teamName: team1Name,
                                compact: compact,
                                targetPoint: ts.pointsPerSet,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _buildSide(
                                isTeam1: false,
                                score: r.currentP2,
                                colors: colors,
                                onIncrement: () =>
                                    notifier.rallyAddPoint(false),
                                onDecrement: () =>
                                    notifier.rallyRemovePoint(false),
                                teamName: team2Name,
                                compact: compact,
                                targetPoint: ts.pointsPerSet,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildSide(
                                isTeam1: true,
                                score: r.currentP1,
                                colors: colors,
                                onIncrement: () => notifier.rallyAddPoint(true),
                                onDecrement: () =>
                                    notifier.rallyRemovePoint(true),
                                teamName: team1Name,
                                compact: compact,
                                targetPoint: ts.pointsPerSet,
                              ),
                            ),
                            Container(
                              width: 3,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: _buildSide(
                                isTeam1: false,
                                score: r.currentP2,
                                colors: colors,
                                onIncrement: () =>
                                    notifier.rallyAddPoint(false),
                                onDecrement: () =>
                                    notifier.rallyRemovePoint(false),
                                teamName: team2Name,
                                compact: compact,
                                targetPoint: ts.pointsPerSet,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSide({
    required bool isTeam1,
    required int score,
    required AppColorsExtension colors,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required String teamName,
    required bool compact,
    required int targetPoint,
  }) {
    final color = isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C);
    final distance = targetPoint - score;

    return Container(
      margin: EdgeInsets.symmetric(vertical: compact ? 0 : 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              distance > 0
                  ? 'Còn $distance điểm tới mốc set'
                  : 'Đã chạm mốc set',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: compact ? 64 : 74,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (!isReadOnly) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onDecrement,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 24,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: onIncrement,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.add_rounded, size: 28, color: color),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _topPill(String label) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
