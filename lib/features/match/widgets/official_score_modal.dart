import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/strategy/penalty_strategy.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/tennis_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/rally_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/badminton_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/table_tennis_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/set_history_bar.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

SportRuleKind _resolveMatchSportKind(MatchModel match) {
  final sportRules = match.sportRules;
  if (sportRules != null && sportRules.isNotEmpty) {
    return SportRuleKind.fromString(sportRules['kind']?.toString());
  }
  return SportRuleKind.fromString(match.sportKey);
}

/// Hiển thị OfficialScoreModal (modal chấm điểm trọng tài)
/// Tự động chọn panel theo môn: Tennis / Pickleball / Rally (badminton, table tennis)
void showOfficialScoreModal(
  BuildContext context, {
  required String tournamentId,
  required String matchId,
  required MatchModel match,
  VoidCallback? onRecordPenalty,
  VoidCallback? onForceWin,
}) {
  final colors = Theme.of(context).extension<AppColorsExtension>()!;
  final kind = _resolveMatchSportKind(match);
  final params = (tournamentId: tournamentId, matchId: matchId);
  final config = resolveSportConfig(match.sportRules, kind);
  final strategy = PenaltyStrategyFactory.getStrategy(_sportKeyForKind(kind));
  final usePickleballSideOutPanel =
      kind == SportRuleKind.pickleball &&
      config.scoringModel == SportScoringModel.pickleballSideOut;

  // Ép buộc xoay ngang màn hình (System Orientation Lock) khi mở modal
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  showDialog(
    context: context,
    useSafeArea: false,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      },
      child: Dialog.fullscreen(
        child: SafeArea(
          child: Container(
            color: colors.bgCard,
            child: Column(
              children: [
                // 1. TOP HEADER BAR: Match Title & Quick Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: colors.bgSurface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${match.team1Name} vs ${match.team2Name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _sportLabel(kind).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () async {
                          await SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),

                // 2. CONFIG BAR (ĐẨY HẾT NẰM NGANG TRÊN CÙNG)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: colors.bgSurface.withValues(alpha: 0.5),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _RuleChip(label: 'BO${config.bestOf}'),
                        const SizedBox(width: 6),
                        _RuleChip(label: 'Thắng ${config.setsToWin} set'),
                        const SizedBox(width: 6),
                        _RuleChip(
                          label:
                              '${config.pointsPerSet} ${kind == SportRuleKind.tennis ? 'game/set' : 'điểm/set'}',
                        ),
                        if (config.mustWinByTwo) ...[
                          const SizedBox(width: 6),
                          const _RuleChip(label: 'Thắng cách 2'),
                        ],
                        const SizedBox(width: 6),
                        _RuleChip(
                          label: _scoringModelLabel(config.scoringModel),
                        ),
                        if (config.maxPoints > config.pointsPerSet) ...[
                          const SizedBox(width: 6),
                          _RuleChip(label: 'Trần điểm ${config.maxPoints}'),
                        ],
                        if (match.court.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _RuleChip(label: 'Sân: ${match.court}'),
                        ],
                        const SizedBox(width: 6),
                        _RuleChip(label: 'Vòng ${match.round}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // 3. CENTER SCORE ARENA (BẢNG TÍNH ĐIỂM CHÍNH NẰM CHÍNH GIỮA MÀN HÌNH)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: kind == SportRuleKind.tennis
                              ? TennisScorePanel(
                                  params: params,
                                  isReadOnly: false,
                                )
                              : usePickleballSideOutPanel
                              ? PickleballPanel(
                                  params: params,
                                  isReadOnly: false,
                                )
                              : kind == SportRuleKind.badminton
                              ? BadmintonScorePanel(
                                  params: params,
                                  isReadOnly: false,
                                )
                              : kind == SportRuleKind.tableTennis
                              ? TableTennisScorePanel(
                                  params: params,
                                  isReadOnly: false,
                                )
                              : RallyScorePanel(
                                  params: params,
                                  isReadOnly: false,
                                ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final n = ref.watch(
                              scorePanelNotifierProvider(params),
                            );
                            final state = n.state;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.errorMessage != null &&
                                    state.errorMessage!.trim().isNotEmpty) ...[
                                  ScoreWarningBox(message: state.errorMessage!),
                                  const SizedBox(height: 4),
                                ],
                                SetHistoryBar(
                                  finishedSets: n.state.finishedSets,
                                  team1SetWins: n.state.team1SetWins,
                                  team2SetWins: n.state.team2SetWins,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // 4. BOTTOM REFEREE CONTROL BAR (HÌNH PHẠT, NGOẠI LỆ VÀ NÚT XỬ LÝ TRỌNG TÀI)
                Consumer(
                  builder: (context, ref, _) {
                    final n = ref.watch(scorePanelNotifierProvider(params));
                    final state = n.state;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: colors.bgSurface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.overrideEnabled) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (val) =>
                                          n.setOverride(true, val),
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Nhập lý do ngoại lệ bắt buộc...',
                                        hintStyle: TextStyle(
                                          fontSize: 11,
                                          color: colors.textMuted,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                        filled: true,
                                        fillColor: colors.warning.withValues(
                                          alpha: 0.1,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: colors.warning.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              // Toggle Ngoại lệ
                              FilterChip(
                                selected: state.overrideEnabled,
                                onSelected: (sel) =>
                                    n.setOverride(sel, state.overrideReason),
                                label: Text(
                                  state.overrideEnabled
                                      ? 'Ngoại lệ: BẬT'
                                      : 'Ngoại lệ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: state.overrideEnabled
                                        ? colors.warning
                                        : colors.textMuted,
                                  ),
                                ),
                                selectedColor: colors.warning.withValues(
                                  alpha: 0.16,
                                ),
                                backgroundColor: colors.bgCard,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              // Tag Hình phạt theo môn
                              Text(
                                'Phạt: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: strategy.getOptions().take(4).map(
                                      (option) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: option.color.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                option.icon,
                                                size: 12,
                                                color: option.color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                option.name,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: option.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Action buttons
                              if (onRecordPenalty != null)
                                OutlinedButton.icon(
                                  onPressed: onRecordPenalty,
                                  icon: const Icon(
                                    Icons.gavel_rounded,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Ghi phạt',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              if (onRecordPenalty != null && onForceWin != null)
                                const SizedBox(width: 6),
                              if (onForceWin != null)
                                FilledButton.icon(
                                  onPressed: onForceWin,
                                  icon: const Icon(
                                    Icons.emoji_events_rounded,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Xử thắng',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.error,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              if (state.overrideEnabled) ...[
                                const SizedBox(width: 6),
                                FilledButton.icon(
                                  onPressed:
                                      state.overrideReason.trim().isEmpty ||
                                          state.isSubmitting
                                      ? null
                                      : () async {
                                          final winnerTeam =
                                              state.team1SetWins >=
                                                  state.team2SetWins
                                              ? 1
                                              : 2;
                                          await n.completeMatch(winnerTeam);
                                        },
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    size: 15,
                                  ),
                                  label: Text(
                                    state.isSubmitting
                                        ? 'Đang lưu...'
                                        : 'Chốt kết quả',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.warning,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _sportKeyForKind(SportRuleKind kind) {
  switch (kind) {
    case SportRuleKind.tennis:
      return AppConstants.sportTennis;
    case SportRuleKind.pickleball:
      return AppConstants.sportPickleball;
    case SportRuleKind.tableTennis:
      return AppConstants.sportTableTennis;
    case SportRuleKind.badminton:
      return AppConstants.sportBadminton;
  }
}

String _sportLabel(SportRuleKind kind) {
  switch (kind) {
    case SportRuleKind.tennis:
      return 'Tennis';
    case SportRuleKind.pickleball:
      return 'Pickleball';
    case SportRuleKind.tableTennis:
      return 'Bóng bàn';
    case SportRuleKind.badminton:
      return 'Cầu lông';
  }
}

String _scoringModelLabel(SportScoringModel model) {
  switch (model) {
    case SportScoringModel.tennisSet:
      return 'Chấm theo game tennis';
    case SportScoringModel.pickleballSideOut:
      return 'Pickleball side-out';
    case SportScoringModel.rallyPointSet:
      return 'Rally point';
  }
}

class ScoreWarningBox extends StatelessWidget {
  final String message;

  const ScoreWarningBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
