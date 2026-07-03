import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';

/// Tennis scoring panel với 15-30-40, Deuce/Advantage, Tiebreak mode.
class TennisScorePanel extends ConsumerWidget {
  final MatchControlParams params;
  final bool isReadOnly;
  const TennisScorePanel({required this.params, this.isReadOnly = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(scorePanelNotifierProvider(params));
    final state = notifier.state;
    final t = state.tennis ?? const TennisGameState();
    final colors = context.colors;
    final ts = state.config;

    // Fetch team names
    final matchAsync = ref.watch(singleMatchProvider((tournamentId: params.tournamentId, matchId: params.matchId)));
    final team1Name = matchAsync.value?.team1Name ?? 'Đội 1';
    final team2Name = matchAsync.value?.team2Name ?? 'Đội 2';

    final isDeuce = !t.isTiebreak &&
        t.team1GamePoints >= 3 &&
        t.team2GamePoints >= 3 &&
        t.team1GamePoints == t.team2GamePoints;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Column(
          children: [
            if (t.isTiebreak)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF4500)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TIEBREAK · Mỗi pha bóng được 1 điểm, chạm ${ts.tiebreakPoints ?? 7} và cách 2 để thắng set',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _infoPill('Điểm game', t.isTiebreak ? 'Tiebreak' : '15 • 30 • 40'),
                  _infoPill('Set', '${ts.pointsPerSet} game/set'),
                  _infoPill('Format', 'Thắng ${ts.setsToWin} set'),
                  if (isDeuce) _infoPill('Trạng thái', 'Deuce'),
                ],
              ),
            ),
            Expanded(
              child: compact
                  ? Column(
                      children: [
                        Expanded(
                          child: _buildTeamControl(
                            isTeam1: true,
                            t: t,
                            notifier: notifier,
                            colors: colors,
                            teamName: team1Name,
                            compact: compact,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildCenterState(colors, isDeuce, t.isTiebreak),
                        ),
                        Expanded(
                          child: _buildTeamControl(
                            isTeam1: false,
                            t: t,
                            notifier: notifier,
                            colors: colors,
                            teamName: team2Name,
                            compact: compact,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildTeamControl(
                            isTeam1: true,
                            t: t,
                            notifier: notifier,
                            colors: colors,
                            teamName: team1Name,
                            compact: compact,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildCenterState(colors, isDeuce, t.isTiebreak),
                        ),
                        Expanded(
                          child: _buildTeamControl(
                            isTeam1: false,
                            t: t,
                            notifier: notifier,
                            colors: colors,
                            teamName: team2Name,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                t.isTiebreak
                    ? 'Set đang vào tiebreak, điểm hiển thị theo số thực.'
                    : 'Chấm theo game tennis của giải, hệ thống tự xử lý deuce và advantage.',
                style: TextStyle(fontSize: 11, color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamControl({
    required bool isTeam1,
    required TennisGameState t,
    required ScorePanelNotifier notifier,
    required AppColorsExtension colors,
    required String teamName,
    required bool compact,
  }) {
    final displayPoints = formatTennisPoint(
      isTeam1 ? t.team1GamePoints : t.team2GamePoints,
      isTeam1 ? t.team2GamePoints : t.team1GamePoints,
      t.isTiebreak,
    );
    final color = isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C);
    final rawPoints = isTeam1 ? t.team1GamePoints : t.team2GamePoints;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 0 : 4, vertical: compact ? 4 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.06),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
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
              'Pha hiện tại: $rawPoints',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayPoints,
            style: TextStyle(fontSize: compact ? 54 : 62, fontWeight: FontWeight.w900, color: color, height: 0.95),
          ),
          const SizedBox(height: 14),
          if (!isReadOnly)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundBtn(Icons.remove_rounded, () => notifier.tennisRemovePoint(isTeam1), colors),
                const SizedBox(width: 16),
                _roundBtn(Icons.add_rounded, () => notifier.tennisAwardPoint(isTeam1), colors, primary: true, color: color),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCenterState(AppColorsExtension colors, bool isDeuce, bool isTiebreak) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isTiebreak
                ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
                : isDeuce
                    ? Colors.amber.withValues(alpha: 0.16)
                    : colors.bgSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isTiebreak
                  ? const Color(0xFFFF7A00).withValues(alpha: 0.24)
                  : isDeuce
                      ? Colors.amber.withValues(alpha: 0.24)
                      : colors.border,
            ),
          ),
          child: Text(
            isTiebreak ? 'TIEBREAK' : isDeuce ? 'DEUCE' : 'GAME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isTiebreak
                  ? const Color(0xFFFF7A00)
                  : isDeuce
                      ? Colors.amber.shade700
                      : colors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoPill(String label, String value) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11, color: colors.textMuted),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap, AppColorsExtension colors, {bool primary = false, Color color = AppTheme.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: primary ? color.withValues(alpha: 0.15) : colors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: primary ? color.withValues(alpha: 0.3) : colors.border),
        ),
        child: Icon(icon, size: 24, color: primary ? color : colors.textSecondary),
      ),
    );
  }
}
