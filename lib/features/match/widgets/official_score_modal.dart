import 'package:flutter/material.dart';
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
import 'package:app_quanly_giaidau/features/match/widgets/match_bottom_bar.dart';
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
  final isLive = match.isLive;
  final config = resolveSportConfig(match.sportRules, kind);
  final strategy = PenaltyStrategyFactory.getStrategy(_sportKeyForKind(kind));
  final usePickleballSideOutPanel =
      kind == SportRuleKind.pickleball &&
      config.scoringModel == SportScoringModel.pickleballSideOut;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (scrollCtx, scrollController) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BẢNG TRỌNG TÀI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${match.team1Name} vs ${match.team2Name}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sport badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLive
                            ? colors.error.withValues(alpha: 0.1)
                            : colors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLive
                              ? colors.error.withValues(alpha: 0.2)
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.error,
                                shape: BoxShape.circle,
                              ),
                              margin: const EdgeInsets.only(right: 4),
                            ),
                          ],
                          Text(
                            isLive ? 'LIVE' : 'CHỜ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isLive ? colors.error : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // Sport label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                color: colors.bgSurface,
                width: double.infinity,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kind == SportRuleKind.tennis
                            ? 'TENNIS'
                            : kind == SportRuleKind.pickleball
                            ? 'PICKLEBALL'
                            : kind == SportRuleKind.tableTennis
                            ? 'BÓNG BÀN'
                            : 'CẦU LÔNG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Vòng ${match.round}',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),

              // Score panel
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _MatchOpsSummary(
                      match: match,
                      config: config,
                      kind: kind,
                      onRecordPenalty: onRecordPenalty,
                      onForceWin: onForceWin,
                      penaltyOptions: strategy.getOptions(),
                    ),
                    const SizedBox(height: 12),
                    kind == SportRuleKind.tennis
                        ? TennisScorePanel(params: params, isReadOnly: false)
                        : usePickleballSideOutPanel
                        ? PickleballPanel(params: params, isReadOnly: false)
                        : kind == SportRuleKind.badminton
                        ? BadmintonScorePanel(params: params, isReadOnly: false)
                        : kind == SportRuleKind.tableTennis
                        ? TableTennisScorePanel(
                            params: params,
                            isReadOnly: false,
                          )
                        : RallyScorePanel(params: params, isReadOnly: false),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, _) {
                        final n = ref.watch(scorePanelNotifierProvider(params));
                        final state = n.state;
                        return Column(
                          children: [
                            if (state.errorMessage != null &&
                                state.errorMessage!.trim().isNotEmpty) ...[
                              ScoreWarningBox(message: state.errorMessage!),
                              const SizedBox(height: 12),
                            ],
                            SetHistoryBar(
                              finishedSets: n.state.finishedSets,
                              team1SetWins: n.state.team1SetWins,
                              team2SetWins: n.state.team2SetWins,
                            ),
                            const SizedBox(height: 12),
                            MatchBottomBar(params: params),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
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

String _statusLabel(MatchModel match) {
  if (match.isCompleted) {
    return 'Đã kết thúc';
  }
  if (match.isLive) {
    return 'Đang thi đấu';
  }
  return 'Chờ bắt đầu';
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

class _MatchOpsSummary extends StatelessWidget {
  const _MatchOpsSummary({
    required this.match,
    required this.config,
    required this.kind,
    required this.onRecordPenalty,
    required this.onForceWin,
    required this.penaltyOptions,
  });

  final MatchModel match;
  final SportConfig config;
  final SportRuleKind kind;
  final VoidCallback? onRecordPenalty;
  final VoidCallback? onForceWin;
  final List<PenaltyOption> penaltyOptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheduledText = match.scheduledTime != null
        ? '${match.scheduledTime!.toLocal().hour.toString().padLeft(2, '0')}:${match.scheduledTime!.toLocal().minute.toString().padLeft(2, '0')}'
        : 'Chưa xếp giờ';
    final settingSource =
        match.sportRules != null && match.sportRules!.isNotEmpty
        ? 'Theo cấu hình giải'
        : 'Theo cấu hình mặc định';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: Icons.sports_tennis_rounded,
                label: _sportLabel(kind),
                color: AppTheme.primary,
              ),
              _MetaPill(
                icon: match.isLive
                    ? Icons.fiber_manual_record_rounded
                    : Icons.schedule_rounded,
                label: _statusLabel(match),
                color: match.isLive ? colors.error : colors.textMuted,
              ),
              _MetaPill(
                icon: Icons.location_on_rounded,
                label: match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                color: colors.info,
              ),
              _MetaPill(
                icon: Icons.access_time_rounded,
                label: scheduledText,
                color: colors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Luật áp dụng',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settingSource,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RuleChip(label: 'BO${config.bestOf}'),
              _RuleChip(label: 'Thắng ${config.setsToWin} set'),
              _RuleChip(
                label:
                    '${config.pointsPerSet} ${kind == SportRuleKind.tennis ? 'game/set' : 'điểm/set'}',
              ),
              if (config.mustWinByTwo) const _RuleChip(label: 'Thắng cách 2'),
              _RuleChip(label: _scoringModelLabel(config.scoringModel)),
              if (kind == SportRuleKind.tennis)
                _RuleChip(
                  label:
                      'Tiebreak ${config.tiebreakAt}-${config.tiebreakAt} đến ${config.tiebreakPoints ?? 7}',
                ),
              if (config.maxPoints > config.pointsPerSet)
                _RuleChip(label: 'Trần điểm ${config.maxPoints}'),
              if (match.timeLimitMinutes != null)
                _RuleChip(label: 'Giới hạn ${match.timeLimitMinutes} phút'),
            ],
          ),
          if (match.maxScore != null || !match.winByTwo) ...[
            const SizedBox(height: 10),
            Text(
              'Điều chỉnh ở cấp trận',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (match.maxScore != null)
                  _RuleChip(label: 'Max score ${match.maxScore}'),
                if (!match.winByTwo)
                  const _RuleChip(label: 'Không áp dụng cách 2'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Hình phạt theo môn',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: penaltyOptions.take(4).map((option) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(option.icon, size: 14, color: option.color),
                    const SizedBox(width: 6),
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: option.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (onRecordPenalty != null || onForceWin != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (onRecordPenalty != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRecordPenalty,
                      icon: const Icon(Icons.gavel_rounded, size: 18),
                      label: const Text('Ghi phạt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (onRecordPenalty != null && onForceWin != null)
                  const SizedBox(width: 10),
                if (onForceWin != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onForceWin,
                      icon: const Icon(Icons.emoji_events_rounded, size: 18),
                      label: const Text('Xử thắng'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
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
