import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';

/// Pickleball Side-Out scoring panel.
class PickleballPanel extends ConsumerWidget {
  final MatchControlParams params;
  final bool isReadOnly;
  const PickleballPanel({required this.params, this.isReadOnly = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(scorePanelNotifierProvider(params));
    final state = notifier.state;
    final pb = state.pickleball ?? const PickleballServeState();
    final colors = context.colors;
    final ts = state.config;

    // Fetch team names
    final matchAsync = ref.watch(singleMatchProvider((tournamentId: params.tournamentId, matchId: params.matchId)));
    final team1Name = matchAsync.value?.team1Name ?? 'Đội 1';
    final team2Name = matchAsync.value?.team2Name ?? 'Đội 2';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFA500).withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volunteer_activism_rounded, size: 18, color: Color(0xFFFFA500)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đội giao bóng: ${pb.isTeam1Serving ? team1Name : team2Name}',
                            style: const TextStyle(color: Color(0xFFFFA500), fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Lượt #${pb.serverNumber}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Side-out · chạm ${ts.pointsPerSet} · ${ts.mustWinByTwo ? 'thắng cách 2' : 'không cần cách 2'} · chỉ bên giao bóng mới ghi điểm',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: compact
                    ? Column(
                        children: [
                          Expanded(
                            child: _buildTeamScore(isTeam1: true, pb: pb, state: state, notifier: notifier, colors: colors, teamName: team1Name, compact: compact),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _buildTeamScore(isTeam1: false, pb: pb, state: state, notifier: notifier, colors: colors, teamName: team2Name, compact: compact),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildTeamScore(isTeam1: true, pb: pb, state: state, notifier: notifier, colors: colors, teamName: team1Name, compact: compact),
                          Container(width: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: colors.border),
                          _buildTeamScore(isTeam1: false, pb: pb, state: state, notifier: notifier, colors: colors, teamName: team2Name, compact: compact),
                        ],
                      ),
              ),
              if (!isReadOnly) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => notifier.pickleballSwitchServer(),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Đổi lượt giao', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => notifier.pickleballSideOut(),
                        icon: const Icon(Icons.sync_alt_rounded, size: 16),
                        label: const Text('Mất quyền giao', style: TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamScore({
    required bool isTeam1,
    required PickleballServeState pb,
    required ScorePanelState state,
    required ScorePanelNotifier notifier,
    required AppColorsExtension colors,
    required String teamName,
    required bool compact,
  }) {
    final r = state.rally ?? const RallySetState();
    final score = isTeam1 ? r.currentP1 : r.currentP2;
    final isServing = pb.isTeam1Serving == isTeam1;
    final color = isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C);

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 0 : 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isServing ? 0.16 : 0.08),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isServing ? const Color(0xFFFFA500).withValues(alpha: 0.7) : color.withValues(alpha: 0.16),
            width: isServing ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isServing) const Icon(Icons.volunteer_activism_rounded, size: 14, color: Color(0xFFFFA500)),
                if (isServing) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    teamName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$score', style: TextStyle(fontSize: compact ? 58 : 64, fontWeight: FontWeight.w900, color: color, height: 0.95)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isServing ? const Color(0xFFFFA500).withValues(alpha: 0.16) : colors.bgCard,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isServing ? 'Đang giao · có quyền ghi điểm' : 'Đang đỡ · chưa được ghi điểm',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isServing ? const Color(0xFFFFA500) : colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            if (!isReadOnly)
              GestureDetector(
                onTap: () => notifier.pickleballAwardPoint(isTeam1),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: isServing ? color.withValues(alpha: 0.18) : colors.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: isServing ? color.withValues(alpha: 0.32) : colors.border),
                  ),
                  child: Icon(Icons.add_rounded, size: 30, color: isServing ? color : colors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
