import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupStageAssignmentScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String divisionId;
  const GroupStageAssignmentScreen({
    super.key,
    required this.tournamentId,
    required this.divisionId,
  });
  @override
  ConsumerState<GroupStageAssignmentScreen> createState() =>
      _GroupStageAssignmentScreenState();
}

class _GroupStageAssignmentScreenState
    extends ConsumerState<GroupStageAssignmentScreen> {
  GroupStageConfig? _draft;
  bool _saving = false;
  final ScrollController _horizontal = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  bool _hasStartedOrResult(MatchModel match) =>
      match.startedAt != null ||
      match.isLive ||
      match.isCompleted ||
      match.score1 != 0 ||
      match.score2 != 0 ||
      match.winnerId.isNotEmpty ||
      match.sets.any((set) => set.score1 != 0 || set.score2 != 0) ||
      (match.scoreDetails?.isNotEmpty ?? false);

  void _change(GroupStageConfig config, {required bool locked}) {
    if (!locked && !_saving) setState(() => _draft = config);
  }

  Future<void> _save({
    required TournamentDivision division,
    required GroupStageConfig config,
    required GroupStageConfig savedConfig,
    required List<MatchModel> matches,
    required bool locked,
  }) async {
    if (locked || _saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateDivisionConfig(
            widget.tournamentId,
            widget.divisionId,
            buildDivisionConfigPatchPayload(
              currentRoundConfig: division.roundConfig,
              config: config,
            ),
          );
    } catch (error) {
      if (mounted) {
        setState(() {
          _draft = savedConfig;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupAssignmentSaveError(error.toString())),
          ),
        );
      }
      return;
    }

    ref.invalidate(tournamentProvider(widget.tournamentId));
    final params = (
      tournamentId: widget.tournamentId,
      divisionId: widget.divisionId,
    );
    ref.invalidate(bracketMatchesWithDivisionProvider(params));
    ref.invalidate(bracketMatchesProvider(widget.tournamentId));
    ref.invalidate(matchesProvider(widget.tournamentId));

    var generationFailed = false;
    final groupMatches = matches.where(isGroupStageMatch);
    if (groupMatches.isNotEmpty && !groupMatches.any(_hasStartedOrResult)) {
      try {
        await ref
            .read(tournamentRepositoryProvider)
            .generateBracket(
              widget.tournamentId,
              divisionId: widget.divisionId,
              seedingType: 'RANDOM',
              allowReset: true,
            );
        ref.invalidate(bracketMatchesWithDivisionProvider(params));
        ref.invalidate(bracketMatchesProvider(widget.tournamentId));
        ref.invalidate(matchesProvider(widget.tournamentId));
      } catch (error) {
        generationFailed = true;
        ref.invalidate(bracketMatchesWithDivisionProvider(params));
        ref.invalidate(bracketMatchesProvider(widget.tournamentId));
        ref.invalidate(matchesProvider(widget.tournamentId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.groupAssignmentRegenerateError(error.toString()),
              ),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _draft = config;
        _saving = false;
      });
      if (!generationFailed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.groupAssignmentSaved)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final teamsAsync = ref.watch(teamsProvider(widget.tournamentId));
    final matchesAsync = ref.watch(
      bracketMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.groupAssignmentTitle),
            Text(
              l10n.groupAssignmentManage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: tournamentAsync.when(
        data: (tournament) {
          if (tournament == null) return const SizedBox.shrink();
          final division = tournament.divisions
              .where((value) => value.id == widget.divisionId)
              .firstOrNull;
          if (division == null) return const SizedBox.shrink();
          return teamsAsync.when(
            data: (teams) => matchesAsync.when(
              data: (matches) {
                final eligible = teams
                    .where(
                      (team) =>
                          team.divisionId == widget.divisionId &&
                          _approved(team),
                    )
                    .toList(growable: false);
                final savedConfig = resolveGroupStageConfig(
                  division: division,
                  tournamentConfig: tournament.tournamentConfig,
                  teams: eligible,
                );
                final config = _draft ?? savedConfig;
                final locked = matches
                    .where(isGroupStageMatch)
                    .any(_hasStartedOrResult);
                return Column(
                  children: [
                    if (locked)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.groupAssignmentLocked,
                          key: const Key('assignment-lock-reason'),
                        ),
                      ),
                    if (config.participantIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.groupAssignmentNoParticipants),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(l10n.groupAssignmentGroupCount),
                          ),
                          for (final count in groupCountOptions(
                            participantCount: config.participantIds.length,
                            currentGroupCount: config.groups.length,
                          ))
                            TextButton(
                              key: Key('group-count-$count'),
                              onPressed: locked || _saving
                                  ? null
                                  : () => _change(
                                      config.resizeGroupCount(count),
                                      locked: locked,
                                    ),
                              child: Text('$count'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final laneWidth = (constraints.maxWidth - 32)
                              .clamp(160.0, 216.0)
                              .toDouble();
                          return SingleChildScrollView(
                            child: SingleChildScrollView(
                              controller: _horizontal,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lane(
                                    title: l10n.groupAssignmentUnassigned,
                                    titleForKey: 'unassigned',
                                    width: laneWidth,
                                    ids: config.unassignedParticipantIds,
                                    teams: eligible,
                                    onDrop: (id, {beforeId}) => _change(
                                      config.moveParticipant(id),
                                      locked: locked,
                                    ),
                                    config: config,
                                    onMove: (id, target) => _change(
                                      config.moveParticipant(
                                        id,
                                        groupIndex: target,
                                      ),
                                      locked: locked,
                                    ),
                                    disabled: locked || _saving,
                                    moveToGroupLabel:
                                        l10n.groupAssignmentMoveToGroup,
                                    moveToUnassignedLabel:
                                        l10n.groupAssignmentMoveToUnassigned,
                                    groupLabel: l10n.groupAssignmentGroupLabel,
                                  ),
                                  for (
                                    var index = 0;
                                    index < config.groups.length;
                                    index++
                                  )
                                    _lane(
                                      title: l10n.groupAssignmentGroupLabel(
                                        config.groups[index].name,
                                      ),
                                      titleForKey: config.groups[index].name,
                                      width: laneWidth,
                                      ids: config.groups[index].participantIds,
                                      teams: eligible,
                                      onDrop: (id, {beforeId}) => _change(
                                        config.moveParticipant(
                                          id,
                                          groupIndex: index,
                                          beforeParticipantId: beforeId,
                                        ),
                                        locked: locked,
                                      ),
                                      groupIndex: index,
                                      config: config,
                                      onMove: (id, target) => _change(
                                        config.moveParticipant(
                                          id,
                                          groupIndex: target,
                                        ),
                                        locked: locked,
                                      ),
                                      disabled: locked || _saving,
                                      moveToGroupLabel:
                                          l10n.groupAssignmentMoveToGroup,
                                      moveToUnassignedLabel:
                                          l10n.groupAssignmentMoveToUnassigned,
                                      groupLabel:
                                          l10n.groupAssignmentGroupLabel,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('save-assignment'),
                          onPressed: locked || _saving
                              ? null
                              : () => _save(
                                  division: division,
                                  config: config,
                                  savedConfig: savedConfig,
                                  matches: matches,
                                  locked: locked,
                                ),
                          child: Text(_saving ? '…' : l10n.groupAssignmentSave),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('$error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
      ),
    );
  }

  bool _approved(Team team) => team.isApproved;

  Widget _lane({
    required String title,
    required String titleForKey,
    required double width,
    required List<String> ids,
    required List<Team> teams,
    required void Function(String, {String? beforeId}) onDrop,
    int? groupIndex,
    GroupStageConfig? config,
    void Function(String, int)? onMove,
    required String moveToGroupLabel,
    required String moveToUnassignedLabel,
    required bool disabled,
    required String Function(String) groupLabel,
  }) {
    final lookup = {for (final team in teams) team.id: team};
    return DragTarget<String>(
      onAcceptWithDetails: disabled ? null : (details) => onDrop(details.data),
      builder: (context, candidates, rejected) => AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        key: Key('lane-$titleForKey'),
        width: width,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            for (final id in ids)
              if (lookup[id] case final team?)
                DragTarget<String>(
                  onAcceptWithDetails: disabled || groupIndex == null
                      ? null
                      : (details) => onDrop(details.data, beforeId: id),
                  builder: (context, candidates, rejected) =>
                      LongPressDraggable<String>(
                        data: id,
                        maxSimultaneousDrags: disabled ? 0 : 1,
                        onDragUpdate: (details) {
                          if (!_horizontal.hasClients) return;
                          final position = details.globalPosition.dx;
                          final width = MediaQuery.sizeOf(context).width;
                          if (position > width - 44) {
                            _horizontal.jumpTo(
                              (_horizontal.offset + 14)
                                  .clamp(
                                    0.0,
                                    _horizontal.position.maxScrollExtent,
                                  )
                                  .toDouble(),
                            );
                          } else if (position < 44) {
                            _horizontal.jumpTo(
                              (_horizontal.offset - 14)
                                  .clamp(
                                    0.0,
                                    _horizontal.position.maxScrollExtent,
                                  )
                                  .toDouble(),
                            );
                          }
                        },
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(team.name),
                          ),
                        ),
                        child: Card(
                          child: ListTile(
                            dense: true,
                            title: Text(team.name),
                            trailing: PopupMenuButton<int>(
                              key: Key('move-$id'),
                              enabled: !disabled,
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: -1,
                                  child: Text(moveToUnassignedLabel),
                                ),
                                for (
                                  var index = 0;
                                  index < (config?.groups.length ?? 0);
                                  index++
                                )
                                  PopupMenuItem(
                                    value: index,
                                    child: Text(
                                      groupLabel(config!.groups[index].name),
                                    ),
                                  ),
                              ],
                              onSelected: (target) {
                                if (target < 0) {
                                  onDrop(id);
                                } else {
                                  onMove?.call(id, target);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                ),
          ],
        ),
      ),
    );
  }
}
