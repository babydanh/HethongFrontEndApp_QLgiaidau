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
import 'package:app_quanly_giaidau/features/match/widgets/football_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/set_history_bar.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/utils/score_validation_localizer.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

SportRuleKind _resolveMatchSportKind(MatchModel match) {
  final sportRules = match.sportRules;
  if (sportRules != null && sportRules.isNotEmpty) {
    return SportRuleKind.fromString(sportRules['kind']?.toString());
  }
  return SportRuleKind.fromString(match.sportKey);
}

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
  )?
  onSubmitPenalty;
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
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _penaltyReasonController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
    final isLite =
        widget.match.tournamentConfig?['isLite'] == true ||
        widget.match.tournamentConfig?['mode']?.toString().toUpperCase() ==
            'LITE';
    final usePickleballSideOutPanel =
        !isLite &&
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
                    vertical: 4,
                  ),
                  color: colors.bgSurface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.match.team1Name} ${l10n.matchVsLabel} ${widget.match.team2Name}',
                          style: TextStyle(
                            fontSize: 14,
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
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        tooltip: l10n.matchMatchInfo,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
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
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
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
                          height: 38,
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.label,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            labelColor: AppTheme.primary,
                            unselectedLabelColor: colors.textMuted,
                            indicatorColor: AppTheme.primary,
                            tabs: [
                              Tab(text: l10n.officialScoreScoringTab),
                              Tab(text: l10n.officialScorePenaltyTab),
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
                                kind,
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
                    final selectedWinner = state.winnerTeam != 0
                        ? state.winnerTeam
                        : state.football != null
                        ? 0
                        : (state.team1SetWins >= state.team2SetWins ? 1 : 2);
                    final canSaveResult =
                        selectedWinner != 0 && n.canCompleteAs(selectedWinner);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: colors.bgSurface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!state.isLite && state.overrideEnabled) ...[
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
                                        hintText: l10n
                                            .officialScore_overrideReasonHint,
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
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              // SetHistoryBar with fallback
                              if (state.finishedSets.isNotEmpty)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SetHistoryBar(
                                    finishedSets: state.finishedSets,
                                    team1SetWins: state.team1SetWins,
                                    team2SetWins: state.team2SetWins,
                                  ),
                                ),
                              // Action Buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.end,
                                children: [
                                  // Toggle Ngoại lệ
                                  if (!state.isLite)
                                    FilterChip(
                                      selected: state.overrideEnabled,
                                      onSelected: (sel) => n.setOverride(
                                        sel,
                                        state.overrideReason,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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

                                  if (widget.onForceWin != null)
                                    FilledButton(
                                      onPressed: widget.onForceWin,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colors.error,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.matchForceWin,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (!state.isMatchComplete &&
                                      n.finishSetConfirmMessage() != null)
                                    OutlinedButton(
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () async {
                                              final message = n
                                                  .finishSetConfirmMessage();
                                              if (message == null) {
                                                return;
                                              }
                                              final confirmed = await showDialog<bool>(
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
                                                          child: Text(
                                                            l10n.officialScoreCancel,
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
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.matchFinishSet,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (state.isMatchComplete ||
                                      state.overrideEnabled ||
                                      (state.isLite &&
                                          state.finishedSets.isNotEmpty))
                                    FilledButton(
                                      onPressed:
                                          state.isSubmitting ||
                                              (state.overrideEnabled &&
                                                  state.overrideReason
                                                      .trim()
                                                      .isEmpty) ||
                                              !canSaveResult
                                          ? null
                                          : () async {
                                              final winnerTeam = selectedWinner;
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (dialogContext) => AlertDialog(
                                                  title: Text(
                                                    state.isMatchComplete
                                                        ? l10n.officialScore_completeTitle
                                                        : l10n.officialScore_saveTitle,
                                                  ),
                                                  content: Text(
                                                    state.isMatchComplete
                                                        ? l10n.officialScore_completeContent
                                                        : l10n.officialScore_saveContent,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            dialogContext,
                                                            false,
                                                          ),
                                                      child: Text(
                                                        l10n.matchCancel,
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            dialogContext,
                                                            true,
                                                          ),
                                                      child: Text(
                                                        l10n.matchConfirm,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed != true) return;
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
                                      style: FilledButton.styleFrom(
                                        backgroundColor: state.isMatchComplete
                                            ? colors.success
                                            : colors.warning,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        state.isSubmitting
                                            ? l10n.officialScore_saving
                                            : (state.isMatchComplete
                                                  ? l10n.matchSaveMatch
                                                  : l10n.matchSaveResult),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
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
            child: kind == SportRuleKind.football
                ? FootballScorePanel(
                    params: params,
                    team1Name: widget.match.team1Name,
                    team2Name: widget.match.team2Name,
                  )
                : kind == SportRuleKind.tennis
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
              if (state.errorMessage == null ||
                  state.errorMessage!.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ScoreWarningBox(
                  message: formatScoreValidationError(
                    AppLocalizations.of(context)!,
                    state.errorMessage!,
                  ),
                ),
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
    SportRuleKind kind,
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
                    l10n.officialScore_penaltyRulesDescription(
                      config.bestOf,
                      config.pointsPerSet,
                    ),
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
            l10n.officialScore_penaltyOptionsTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = MediaQuery.of(context).size;
              final isLandscape = size.width > size.height;
              final availableWidth = constraints.maxWidth;
              if (isLandscape) {
                final cardWidth = (availableWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: options.map((option) {
                    final isSelected = selectedPenalty.id == option.id;
                    return SizedBox(
                      width: cardWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? option.color
                                : option.color.withValues(alpha: 0.35),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: option.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              option.icon,
                              color: option.color,
                              size: 16,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () =>
                              setState(() => _selectedPenalty = option),
                          title: Text(
                            _penaltyLabel(option, kind, l10n),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: option.color,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: options
                    .map(
                      (option) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: option.color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: option.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              option.icon,
                              color: option.color,
                              size: 18,
                            ),
                          ),
                          selected: selectedPenalty.id == option.id,
                          onTap: () =>
                              setState(() => _selectedPenalty = option),
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
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.officialScore_penalizedTeam,
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
                l10n.officialScore_penaltySelectionRequired,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _penaltyReasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.officialScore_penaltyReasonLabel,
              hintText: l10n.officialScore_penaltyReasonHint,
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
                  title: Text(l10n.officialScore_penaltyConfirmTitle),
                  content: Text(
                    l10n.officialScore_penaltyConfirmContent(
                      _penaltyLabel(selectedPenalty, kind, l10n),
                      _selectedPenaltyTeam!,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l10n.matchCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(l10n.matchConfirm),
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
            _penaltyRulesDescription(kind, l10n),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
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
    case SportRuleKind.football:
      return 'FOOTBALL';
  }
}

String _sportLabel(SportRuleKind kind, AppLocalizations l10n) {
  switch (kind) {
    case SportRuleKind.tennis:
      return l10n.createClubTournament_sportTennis;
    case SportRuleKind.pickleball:
      return l10n.createClubTournament_sportPickleball;
    case SportRuleKind.tableTennis:
      return l10n.createClubTournament_sportTableTennis;
    case SportRuleKind.badminton:
      return l10n.createClubTournament_sportBadminton;
    case SportRuleKind.football:
      return l10n.createClubTournament_sportFootball;
  }
}

String _scoringModelLabel(SportScoringModel model, AppLocalizations l10n) {
  switch (model) {
    case SportScoringModel.tennisSet:
      return l10n.officialScore_scoringTennisSet;
    case SportScoringModel.pickleballSideOut:
      return l10n.officialScore_scoringPickleballSideOut;
    case SportScoringModel.rallyPointSet:
      return l10n.officialScore_scoringRallyPoint;
  }
}

String _penaltyLabel(
  PenaltyOption option,
  SportRuleKind kind,
  AppLocalizations l10n,
) {
  switch (option.id) {
    case 'WARNING':
      return l10n.livePenaltyWarning;
    case 'SERVICE_FAULT':
      return kind == SportRuleKind.badminton
          ? l10n.officialScore_penaltyServiceFaultBadminton
          : l10n.officialScore_penaltyServiceFault;
    case 'MISCONDUCT':
      return l10n.officialScore_penaltyMisconduct;
    case 'YELLOW_CARD':
      return l10n.livePenaltyYellowCard;
    case 'RED_CARD':
      return l10n.livePenaltyRedCard;
    case 'CODE_VIOLATION':
      return l10n.officialScore_penaltyCodeViolation;
    case 'POINT_PENALTY':
      return l10n.livePenaltyPoint;
    case 'GAME_PENALTY':
      return l10n.livePenaltyGame;
    case 'TECHNICAL_FAULT':
      return l10n.officialScore_penaltyTechnicalFault;
    case 'UNSPORTSMANLIKE':
      return l10n.officialScore_penaltyUnsportsmanlike;
    case 'FOUL':
      return l10n.officialScore_penaltyFoul;
    default:
      return option.name;
  }
}

String _penaltyRulesDescription(SportRuleKind kind, AppLocalizations l10n) {
  switch (kind) {
    case SportRuleKind.tennis:
      return l10n.officialScore_penaltyRulesTennis;
    case SportRuleKind.pickleball:
      return l10n.officialScore_penaltyRulesPickleball;
    case SportRuleKind.tableTennis:
      return l10n.officialScore_penaltyRulesTableTennis;
    case SportRuleKind.badminton:
      return l10n.officialScore_penaltyRulesBadminton;
    case SportRuleKind.football:
      return l10n.officialScore_penaltyRulesDefault;
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
            l10n.officialScore_matchInfoTitle,
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
            '${match.team1Name} ${l10n.matchVsLabel} ${match.team2Name}',
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
              _RuleChip(
                label: l10n.officialScore_sport(_sportLabel(kind, l10n)),
              ),
              _RuleChip(label: l10n.officialScore_format(config.bestOf)),
              _RuleChip(label: l10n.officialScore_setsToWin(config.setsToWin)),
              _RuleChip(
                label: l10n.officialScore_pointsPerSet(
                  config.pointsPerSet,
                  kind == SportRuleKind.tennis
                      ? l10n.officialScore_gameSetUnit
                      : l10n.officialScore_pointsSetUnit,
                ),
              ),
              if (config.mustWinByTwo) _RuleChip(label: l10n.matchWinByTwo),
              _RuleChip(label: _scoringModelLabel(config.scoringModel, l10n)),
              if (config.maxPoints > config.pointsPerSet)
                _RuleChip(
                  label: l10n.officialScore_maxPoints(config.maxPoints),
                ),
              if (match.court.isNotEmpty)
                _RuleChip(label: l10n.officialScore_court(match.court)),
              _RuleChip(label: l10n.officialScore_round(match.round)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.officialScore_close),
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
