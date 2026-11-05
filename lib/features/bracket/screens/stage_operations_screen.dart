import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/repositories/stage_operations_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart'
    show tournamentSheetServerMessage;
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/stage_operations_provider.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Two teams of one group level on points, point difference and points scored.
typedef StageOpsTie = (Standing, Standing);

/// Pairs of teams (same group) with identical record: the candidates for a
/// playoff. Groups of three or more tied teams are left out, as on the Web.
List<StageOpsTie> findStageOpsTies(List<Standing> standings) {
  final buckets = <String, List<Standing>>{};
  for (final row in standings) {
    if (row.played == 0 || row.id.isEmpty) continue;
    final key =
        '${row.group}|${row.totalPoints}|${row.pointsFor - row.pointsAgainst}|${row.pointsFor}';
    buckets.putIfAbsent(key, () => []).add(row);
  }
  return [
    for (final rows in buckets.values)
      if (rows.length == 2) (rows[0], rows[1]),
  ];
}

/// Organizer operations on the stages of one division: finish a stage early,
/// lock the group stage into the knockout, create a playoff match and cancel
/// a bracket that has not started. Mirrors the Web bracket tab.
class StageOperationsScreen extends ConsumerStatefulWidget {
  const StageOperationsScreen({
    super.key,
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  ConsumerState<StageOperationsScreen> createState() =>
      _StageOperationsScreenState();
}

class _StageOperationsScreenState extends ConsumerState<StageOperationsScreen> {
  /// True while a request is in flight: every action is locked (double tap).
  bool _busy = false;

  ({String tournamentId, String divisionId}) get _params =>
      (tournamentId: widget.tournamentId, divisionId: widget.divisionId);

  IStageOperationsRepository get _repo =>
      ref.read(stageOperationsRepositoryProvider);

  void _refresh() {
    ref.invalidate(divisionStageOpsProvider(_params));
    ref.invalidate(bracketMatchesProvider(widget.tournamentId));
    ref.invalidate(
      bracketMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );
    ref.invalidate(
      standingsWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );
  }

  String _errorText(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      if (error.response == null) return l10n.stageActionNetworkError;
      final server = tournamentSheetServerMessage(error);
      if (server != null) return server;
      if (error.response?.statusCode == 409) return l10n.stageActionConflict;
    }
    return l10n.stageActionGenericError;
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.stageActionDismiss),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Confirms, runs [action] with every button locked, then reloads and shows
  /// the success text it returns; errors become a snackbar.
  Future<void> _run({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<String> Function(AppLocalizations l10n) action,
    bool destructive = false,
  }) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirm(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!confirmed || !mounted || _busy) return;

    setState(() => _busy = true);
    try {
      final message = await action(l10n);
      if (!mounted) return;
      _refresh();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_errorText(error, l10n))));
      // A 409 means the bracket moved under us: show the latest state.
      if (error is DioException && error.response?.statusCode == 409) {
        _refresh();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(StageOpsStage stage) {
    final l10n = AppLocalizations.of(context)!;
    return _run(
      title: l10n.stageActionFinishConfirmTitle,
      body: l10n.stageActionFinishConfirmBody(stage.openMatches),
      confirmLabel: l10n.stageActionFinishConfirm,
      destructive: true,
      action: (l10n) async {
        await _repo.finalizeStage(widget.tournamentId, stage.id);
        return l10n.stageActionFinishDone;
      },
    );
  }

  Future<void> _advance(StageOpsStage stage) {
    final l10n = AppLocalizations.of(context)!;
    return _run(
      title: l10n.stageActionAdvanceConfirmTitle,
      body: l10n.stageActionAdvanceConfirmBody,
      confirmLabel: l10n.stageActionAdvanceConfirm,
      action: (l10n) async {
        final result = await _repo.advanceStandings(
          widget.tournamentId,
          divisionId: widget.divisionId,
          stageId: stage.id,
        );
        return l10n.stageActionAdvanceDone(result.totalMatches);
      },
    );
  }

  Future<void> _playoff(StageOpsStage stage, StageOpsTie tie) {
    final l10n = AppLocalizations.of(context)!;
    return _run(
      title: l10n.stageActionPlayoffConfirmTitle,
      body: l10n.stageActionPlayoffConfirmBody(tie.$1.teamName, tie.$2.teamName),
      confirmLabel: l10n.stageActionPlayoffCreate,
      action: (l10n) async {
        await _repo.createPlayoffMatch(
          widget.tournamentId,
          stageId: stage.id,
          participant1Id: tie.$1.id,
          participant2Id: tie.$2.id,
        );
        return l10n.stageActionPlayoffDone;
      },
    );
  }

  Future<void> _cancelBracket(List<StageOpsStage> stages) {
    final l10n = AppLocalizations.of(context)!;
    final matchCount = stages.fold<int>(0, (sum, s) => sum + s.totalMatches);
    return _run(
      title: l10n.stageActionCancelConfirmTitle,
      body: l10n.stageActionCancelConfirmBody(stages.length, matchCount),
      confirmLabel: l10n.stageActionCancelConfirm,
      destructive: true,
      action: (l10n) async {
        final result = await _repo.cancelDivisionBracket(
          widget.tournamentId,
          widget.divisionId,
        );
        return l10n.stageActionCancelDone(
          result.cancelledStages,
          result.cancelledMatches,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stagesAsync = ref.watch(divisionStageOpsProvider(_params));
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        title: Text(l10n.stageActionTitle),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: stagesAsync.when(
        // Keep the cards on screen while a reload after an action runs.
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.stageActionLoadError, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('stage-action-retry'),
                  onPressed: () =>
                      ref.invalidate(divisionStageOpsProvider(_params)),
                  child: Text(l10n.stageActionRetry),
                ),
              ],
            ),
          ),
        ),
        data: (stages) => stages.isEmpty
            ? Center(child: Text(l10n.stageActionEmpty))
            : _buildStages(stages, l10n),
      ),
    );
  }

  Widget _buildStages(List<StageOpsStage> stages, AppLocalizations l10n) {
    final hasKnockout = stages.any((s) => s.order == 2 && !s.isRoundRobin);
    final needsTies = stages.any((s) => s.isRoundRobin && s.playoffTiebreak);
    final ties = needsTies
        ? findStageOpsTies(
            ref.watch(standingsWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: widget.divisionId,
                ))).value ??
                const <Standing>[],
          )
        : const <StageOpsTie>[];
    final started = stages.any((s) => s.hasStartedMatch);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final stage in stages)
          _StageCard(
            stage: stage,
            busy: _busy,
            canAdvance: stage.isRoundRobin && hasKnockout,
            ties: stage.isRoundRobin && stage.playoffTiebreak
                ? ties
                : const <StageOpsTie>[],
            onFinish: () => _finish(stage),
            onAdvance: () => _advance(stage),
            onPlayoff: (tie) => _playoff(stage, tie),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('stage-action-cancel-bracket'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _busy || started ? null : () => _cancelBracket(stages),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.stageActionCancelBracket),
        ),
        if (started)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.stageActionCancelStarted,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.busy,
    required this.canAdvance,
    required this.ties,
    required this.onFinish,
    required this.onAdvance,
    required this.onPlayoff,
  });

  final StageOpsStage stage;
  final bool busy;
  final bool canAdvance;
  final List<StageOpsTie> ties;
  final VoidCallback onFinish;
  final VoidCallback onAdvance;
  final ValueChanged<StageOpsTie> onPlayoff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = stage.totalMatches - stage.openMatches;
    final blocked = stage.openGroupMatches;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stage.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.stageActionStageSummary(done, stage.totalMatches),
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
            ),
            if (stage.isRoundRobin && stage.openMatches > 0) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: Key('stage-action-finish-${stage.id}'),
                onPressed: busy ? null : onFinish,
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.stageActionFinish),
              ),
            ],
            if (canAdvance) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                key: Key('stage-action-advance-${stage.id}'),
                onPressed: busy || blocked > 0 ? null : onAdvance,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.stageActionAdvance),
              ),
              if (blocked > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.stageActionAdvanceBlocked(blocked),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
            ],
            if (ties.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.stageActionPlayoffHeading,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              for (final tie in ties)
                Row(
                  children: [
                    Expanded(child: Text('${tie.$1.teamName} - ${tie.$2.teamName}')),
                    TextButton(
                      key: Key('stage-action-playoff-${tie.$1.id}-${tie.$2.id}'),
                      onPressed: busy ? null : () => onPlayoff(tie),
                      child: Text(l10n.stageActionPlayoffCreate),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
