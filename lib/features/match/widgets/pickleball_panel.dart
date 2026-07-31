import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Pickleball Side-Out scoring panel.
class PickleballPanel extends ConsumerWidget {
  final MatchControlParams params;
  final bool isReadOnly;
  const PickleballPanel({
    required this.params,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorePanelNotifierProvider(params));
    final notifier = ref.read(scorePanelNotifierProvider(params).notifier);
    final pb = state.pickleball ?? const PickleballServeState();
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    // Fetch team names
    final matchAsync = ref.watch(
      singleMatchProvider((
        tournamentId: params.tournamentId,
        matchId: params.matchId,
      )),
    );
    final team1Name = matchAsync.value?.team1Name ?? l10n.pickleballTeam1;
    final team2Name = matchAsync.value?.team2Name ?? l10n.pickleballTeam2;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = !isLandscape && constraints.maxWidth < 620;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: const Color(0xFFFFA500).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 18,
                      color: Color(0xFFFFA500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đội giao bóng: ${pb.isTeam1Serving ? team1Name : team2Name}',
                        style: const TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Lượt #${pb.serverNumber}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: compact
                    ? Column(
                        children: [
                          Expanded(
                            child: _buildTeamScore(
                              isTeam1: true,
                              pb: pb,
                              state: state,
                              notifier: notifier,
                              colors: colors,
                              teamName: team1Name,
                              compact: compact,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _buildTeamScore(
                              isTeam1: false,
                              pb: pb,
                              state: state,
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
                          _buildTeamScore(
                            isTeam1: true,
                            pb: pb,
                            state: state,
                            notifier: notifier,
                            colors: colors,
                            teamName: team1Name,
                            compact: compact,
                          ),
                          Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: colors.border,
                          ),
                          _buildTeamScore(
                            isTeam1: false,
                            pb: pb,
                            state: state,
                            notifier: notifier,
                            colors: colors,
                            teamName: team2Name,
                            compact: compact,
                          ),
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
                        label: Text(
                          l10n.pickleballSwitchServer,
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => notifier.pickleballSideOut(),
                        icon: const Icon(Icons.sync_alt_rounded, size: 16),
                        label: Text(
                          l10n.pickleballLoseServe,
                          style: const TextStyle(fontSize: 11),
                        ),
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

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: isServing ? const Color(0xFFFFA500) : color.withValues(alpha: 0.3),
                width: isServing ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tên đội (cho xuống dòng to rõ)
                SizedBox(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isServing)
                        const Icon(
                          Icons.volunteer_activism_rounded,
                          size: 16,
                          color: Color(0xFFFFA500),
                        ),
                      if (isServing) const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          teamName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLandscape) ...[
                  // MÀN HÌNH NGANG (LANDSCAPE): [-]  [ SỐ 0 ]  [+]
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!isReadOnly)
                          GestureDetector(
                            onTap: () => notifier.rallyRemovePoint(isTeam1),
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
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '$score',
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
                        if (!isReadOnly)
                          GestureDetector(
                            onTap: () => notifier.pickleballAwardPoint(isTeam1),
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
                  ),
                ] else ...[
                  // MÀN HÌNH ĐỨNG (PORTRAIT): NÚT + TRÊN | SỐ 0 GIỮA | NÚT - DƯỚI
                  Expanded(
                    child: Center(
                      child: isReadOnly
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: () => notifier.pickleballAwardPoint(isTeam1),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1.8),
                                ),
                                child: Icon(Icons.add_rounded, size: 30, color: color),
                              ),
                            ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: isReadOnly
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: () => notifier.rallyRemovePoint(isTeam1),
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
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
