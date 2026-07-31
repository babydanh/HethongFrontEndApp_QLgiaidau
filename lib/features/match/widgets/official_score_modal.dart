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
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => OfficialScorePage(
        tournamentId: tournamentId,
        matchId: matchId,
        match: match,
        onRecordPenalty: onRecordPenalty,
        onForceWin: onForceWin,
      ),
    ),
  );
}

class OfficialScorePage extends StatefulWidget {
  final String tournamentId;
  final String matchId;
  final MatchModel match;
  final VoidCallback? onRecordPenalty;
  final VoidCallback? onForceWin;

  const OfficialScorePage({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.match,
    this.onRecordPenalty,
    this.onForceWin,
  });

  @override
  State<OfficialScorePage> createState() => _OfficialScorePageState();
}

class _OfficialScorePageState extends State<OfficialScorePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final kind = _resolveMatchSportKind(widget.match);
    final params = (tournamentId: widget.tournamentId, matchId: widget.matchId);
    final config = resolveSportConfig(widget.match.sportRules, kind);
    final strategy = PenaltyStrategyFactory.getStrategy(_sportKeyForKind(kind));
    final usePickleballSideOutPanel =
        kind == SportRuleKind.pickleball &&
        config.scoringModel == SportScoringModel.pickleballSideOut;

    return Scaffold(
      backgroundColor: colors.bgCard,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            Widget content = SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            '${widget.match.team1Name} vs ${widget.match.team2Name}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _sportLabel(kind).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () {
                            Navigator.of(context).pop();
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
                            _RuleChip(label: l10n.matchWinByTwo),
                          ],
                          const SizedBox(width: 6),
                          _RuleChip(
                            label: _scoringModelLabel(config.scoringModel),
                          ),
                          if (config.maxPoints > config.pointsPerSet) ...[
                            const SizedBox(width: 6),
                            _RuleChip(label: 'Trần điểm ${config.maxPoints}'),
                          ],
                          if (widget.match.court.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _RuleChip(label: 'Sân: ${widget.match.court}'),
                          ],
                          const SizedBox(width: 6),
                          _RuleChip(label: 'Vòng ${widget.match.round}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // 3. CENTER SCORE ARENA (BẢNG TÍNH ĐIỂM CHÍNH)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        kind == SportRuleKind.tennis
                            ? TennisScorePanel(
                                params: params,
                                isReadOnly: false,
                              )
                            : usePickleballSideOutPanel
                            ? PickleballPanel(params: params, isReadOnly: false)
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
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, _) {
                            final state = ref.watch(
                              scorePanelNotifierProvider(params),
                            );
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.errorMessage != null &&
                                    state.errorMessage!.trim().isNotEmpty) ...[
                                  ScoreWarningBox(message: state.errorMessage!),
                                  const SizedBox(height: 4),
                                ],
                                SetHistoryBar(
                                  finishedSets: state.finishedSets,
                                  team1SetWins: state.team1SetWins,
                                  team2SetWins: state.team2SetWins,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // 4. BOTTOM REFEREE CONTROL BAR (HÌNH PHẠT, NGOẠI LỆ VÀ NÚT XỬ LÝ TRỌNG TÀI)
                  Consumer(
                    builder: (context, ref, _) {
                      final l10n = AppLocalizations.of(context)!;
                      final state = ref.watch(
                        scorePanelNotifierProvider(params),
                      );
                      final n = ref.read(
                        scorePanelNotifierProvider(params).notifier,
                      );
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
                                              AppTheme.radiusMedium,
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
                                        : l10n.matchOverrideLabel,
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
                                      children: strategy
                                          .getOptions()
                                          .take(4)
                                          .map((option) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: option.color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppTheme.radiusSmall,
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: option.color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Action buttons
                                if (widget.onRecordPenalty != null)
                                  OutlinedButton.icon(
                                    onPressed: widget.onRecordPenalty,
                                    icon: const Icon(
                                      Icons.gavel_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      l10n.matchRecordPenalty,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                if (widget.onRecordPenalty != null &&
                                    widget.onForceWin != null)
                                  const SizedBox(width: 6),
                                if (widget.onForceWin != null)
                                  FilledButton.icon(
                                    onPressed: widget.onForceWin,
                                    icon: const Icon(
                                      Icons.emoji_events_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      l10n.matchForceWin,
                                      style: const TextStyle(fontSize: 11),
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
                                if (!state.isMatchComplete &&
                                    n.finishSetConfirmMessage() != null) ...[
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: state.isSubmitting
                                        ? null
                                        : () async {
                                            final message = n
                                                .finishSetConfirmMessage();
                                            if (message == null) return;
                                            final confirmed =
                                                await showDialog<bool>(
                                                  context: context,
                                                  builder: (dialogContext) =>
                                                      AlertDialog(
                                                        title: Text(
                                                          l10n.matchFinishSet,
                                                        ),
                                                        content: Text(message),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Hủy',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  true,
                                                                ),
                                                            child: Text(
                                                              l10n.matchFinishSet,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                            if (confirmed == true)
                                              await n.finishSet();
                                          },
                                    icon: const Icon(
                                      Icons.flag_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      l10n.matchFinishSet,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                if (state.isMatchComplete ||
                                    state.overrideEnabled) ...[
                                  const SizedBox(width: 6),
                                  FilledButton.icon(
                                    onPressed:
                                        state.isSubmitting ||
                                            (state.overrideEnabled &&
                                                state.overrideReason
                                                    .trim()
                                                    .isEmpty)
                                        ? null
                                        : () async {
                                            final winnerTeam =
                                                state.winnerTeam != 0
                                                ? state.winnerTeam
                                                : (state.team1SetWins >=
                                                          state.team2SetWins
                                                      ? 1
                                                      : 2);
                                            await n.completeMatch(winnerTeam);
                                            final latest = ref.read(
                                              scorePanelNotifierProvider(
                                                params,
                                              ),
                                            );
                                            if (context.mounted &&
                                                !latest.isSubmitting &&
                                                latest.errorMessage == null) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      state.isSubmitting
                                          ? 'Đang lưu...'
                                          : (state.isMatchComplete
                                                ? l10n.matchSaveMatch
                                                : l10n.matchSaveResult),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: state.isMatchComplete
                                          ? colors.success
                                          : colors.warning,
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
            );
            return content;
          },
        ),
      ),
    );
  }
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
      return 'Game/Set';
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
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
