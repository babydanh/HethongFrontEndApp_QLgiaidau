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
  Future<void> Function(String teamName, PenaltyOption option, String reason)?
      onSubmitPenalty,
  VoidCallback? onForceWin,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => OfficialScorePage(
        tournamentId: tournamentId,
        matchId: matchId,
        match: match,
        onRecordPenalty: onRecordPenalty,
        onSubmitPenalty: onSubmitPenalty,
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
  final Future<void> Function(
    String teamName,
    PenaltyOption option,
    String reason,
  )? onSubmitPenalty;
  final VoidCallback? onForceWin;

  const OfficialScorePage({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.match,
    this.onRecordPenalty,
    this.onSubmitPenalty,
    this.onForceWin,
  });

  @override
  State<OfficialScorePage> createState() => _OfficialScorePageState();
}

class _OfficialScorePageState extends State<OfficialScorePage> {
  String? _selectedPenaltyTeam;
  PenaltyOption? _selectedPenalty;
  bool _penaltySelectionError = false;
  final _penaltyReasonController = TextEditingController();

  @override
  void dispose() {
    _penaltyReasonController.dispose();
    super.dispose();
  }
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
            Widget content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP HEADER BAR: Match Title & Info Popup Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
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
                      // NÚT ICON (i) ĐỂ HIỂN THỊ POPUP THÔNG TIN CÀI ĐẶT GIẢI
                      IconButton(
                        icon: Icon(
                          Icons.info_outline_rounded,
                          size: 22,
                          color: AppTheme.primary,
                        ),
                        tooltip: 'Cài đặt & Luật giải',
                        onPressed: () {
                          _showMatchInfoDialog(
                            context,
                            widget.match,
                            config,
                            kind,
                            colors,
                            l10n,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // 2. CENTER SCORE ARENA (BẢNG TÍNH ĐIỂM CHÍNH - GIÃN FULL CHIỀU CAO NGHỆ THUẬT)
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 52,
                          child: TabBar(
                          indicatorSize: TabBarIndicatorSize.label,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          labelColor: AppTheme.primary,
                          unselectedLabelColor: colors.textMuted,
                          indicatorColor: AppTheme.primary,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.scoreboard_rounded, size: 16),
                              text: 'Tính điểm',
                            ),
                            Tab(
                              icon: Icon(Icons.gavel_rounded, size: 16),
                              text: 'Phạm lỗi',
                            ),
                          ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildScoreTab(
                                context,
                                params,
                                kind,
                                usePickleballSideOutPanel,
                              ),
                              _buildFoulTab(
                                context,
                                strategy,
                                config,
                                colors,
                                l10n,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // 4. BOTTOM REFEREE CONTROL BAR (HÌNH PHẠT, NGOẠI LỆ VÀ NÚT XỬ LÝ TRỌNG TÀI)
                Consumer(
                  builder: (context, ref, _) {
                    final l10n = AppLocalizations.of(context)!;
                    final state = ref.watch(scorePanelNotifierProvider(params));
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
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

                              // Action buttons
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
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              if (!state.isMatchComplete &&
                                  n.finishSetConfirmMessage() != null)
                                OutlinedButton.icon(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () async {
                                          final message = n
                                              .finishSetConfirmMessage();
                                          if (message == null) {
                                            return;
                                          }
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
                                          if (confirmed == true) {
                                            await n.finishSet();
                                          }
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
                              if (state.isMatchComplete ||
                                  state.overrideEnabled)
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
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: Text(
                                                state.isMatchComplete
                                                    ? 'Chốt kết quả trận đấu'
                                                    : 'Xác nhận lưu kết quả',
                                              ),
                                              content: Text(
                                                state.isMatchComplete
                                                    ? 'Kết quả đã đủ điều kiện. Chốt trận để công khai điểm và cập nhật giải đấu?'
                                                    : 'Lưu kết quả hiện tại theo ngoại lệ của trọng tài? Hành động này sẽ được ghi vào lịch sử trận.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.pop(dialogContext, true),
                                                  child: const Text('Xác nhận'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed != true) return;
                                          await n.completeMatch(winnerTeam);
                                          final latest = ref.read(
                                            scorePanelNotifierProvider(params),
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
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
            return content;
          },
        ),
      ),
    );
  }

  Widget _buildScoreTab(
    BuildContext context,
    ({String tournamentId, String matchId}) params,
    SportRuleKind kind,
    bool usePickleballSideOutPanel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: kind == SportRuleKind.tennis
                ? TennisScorePanel(params: params, isReadOnly: false)
                : usePickleballSideOutPanel
                ? PickleballPanel(params: params, isReadOnly: false)
                : kind == SportRuleKind.badminton
                ? BadmintonScorePanel(params: params, isReadOnly: false)
                : kind == SportRuleKind.tableTennis
                ? TableTennisScorePanel(params: params, isReadOnly: false)
                : RallyScorePanel(params: params, isReadOnly: false),
          ),
          const SizedBox(height: 6),
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(scorePanelNotifierProvider(params));
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
    );
  }

  Widget _buildFoulTab(
    BuildContext context,
    IPenaltyStrategy strategy,
    SportConfig config,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final options = strategy.getOptions();
    final selectedPenalty = _selectedPenalty ?? options.first;
    final teams = [widget.match.team1Name, widget.match.team2Name];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rule_rounded, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lỗi được áp dụng theo luật môn và cấu hình giải. BO${config.bestOf} · ${config.pointsPerSet} điểm/set',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mức phạt được phép chọn',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          ...options.map(
            (option) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: option.color.withValues(alpha: 0.35)),
              ),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: option.color.withValues(alpha: 0.12),
                  child: Icon(option.icon, color: option.color, size: 18),
                ),
                selected: selectedPenalty.id == option.id,
                onTap: () => setState(() => _selectedPenalty = option),
                title: Text(
                  option.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                trailing: Icon(
                  selectedPenalty.id == option.id
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: option.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đội bị phạt',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: teams.map((team) {
              final selected = _selectedPenaltyTeam == team;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: team == teams.last ? 0 : 8),
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _selectedPenaltyTeam = team;
                      _penaltySelectionError = false;
                    }),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : colors.bgSurface,
                      side: BorderSide(
                        color: selected ? AppTheme.primary : colors.border,
                        width: selected ? 1.5 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      team,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_penaltySelectionError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Vui lòng chọn đội bị phạt trước khi ghi nhận.',
                style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _penaltyReasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Lý do / ghi chú',
              hintText: 'Nhập lý do nếu cần',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
                    if (_selectedPenaltyTeam == null) {
                      setState(() => _penaltySelectionError = true);
                      return;
                    }
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Xác nhận ghi phạt'),
                        content: Text(
                          '${selectedPenalty.name} cho ${_selectedPenaltyTeam!}. Tiếp tục ghi nhận?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final option = selectedPenalty;
                    final reason = _penaltyReasonController.text.trim();
                    if (widget.onSubmitPenalty != null) {
                      await widget.onSubmitPenalty!.call(
                        _selectedPenaltyTeam!,
                        option,
                        reason,
                      );
                    } else {
                      widget.onRecordPenalty?.call();
                    }
                    if (context.mounted) {
                      setState(() {
                        _selectedPenaltyTeam = null;
                        _penaltySelectionError = false;
                        _penaltyReasonController.clear();
                      });
                    }
                  },
            icon: const Icon(Icons.gavel_rounded),
            label: Text(l10n.matchRecordPenalty),
          ),
          const SizedBox(height: 6),
          Text(
            strategy.getRulesDescription(),
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
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

void _showMatchInfoDialog(
  BuildContext context,
  MatchModel match,
  SportConfig config,
  SportRuleKind kind,
  AppColorsExtension colors,
  AppLocalizations l10n,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Thông tin & Cài đặt trận đấu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${match.team1Name} vs ${match.team2Name}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _RuleChip(label: 'Môn: ${_sportLabel(kind)}'),
              _RuleChip(label: 'Thể thức: BO${config.bestOf}'),
              _RuleChip(label: 'Số set thắng: ${config.setsToWin} set'),
              _RuleChip(
                label:
                    'Mốc set: ${config.pointsPerSet} ${kind == SportRuleKind.tennis ? 'game/set' : 'điểm/set'}',
              ),
              if (config.mustWinByTwo) _RuleChip(label: l10n.matchWinByTwo),
              _RuleChip(label: _scoringModelLabel(config.scoringModel)),
              if (config.maxPoints > config.pointsPerSet)
                _RuleChip(label: 'Trần điểm: ${config.maxPoints}'),
              if (match.court.isNotEmpty)
                _RuleChip(label: 'Sân: ${match.court}'),
              _RuleChip(label: 'Vòng: ${match.round}'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
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
