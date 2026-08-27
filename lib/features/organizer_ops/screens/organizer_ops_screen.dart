import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizerOpsScreen extends ConsumerStatefulWidget {
  const OrganizerOpsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<OrganizerOpsScreen> createState() => _OrganizerOpsScreenState();
}

class _OrganizerOpsScreenState extends ConsumerState<OrganizerOpsScreen> {
  String? _selectedDivisionId;
  String _rosterFilter = 'ALL';
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      loading: () => _OpsScaffold(
        title: l10n.opsTitle,
        onBack: () => _goBack(context),
        body: const _OpsLoadingBody(),
      ),
      error: (error, _) => _OpsScaffold(
        title: l10n.opsTitle,
        onBack: () => _goBack(context),
        body: _OpsErrorBody(
          message:
              '${l10n.opsLoadFailed}\n${ErrorParser.parse(error, l10n.opsLoadFailed, l10n)}',
          onRetry: () =>
              ref.invalidate(tournamentProvider(widget.tournamentId)),
        ),
      ),
      data: (tournament) {
        if (tournament == null) {
          return _OpsScaffold(
            title: l10n.opsTitle,
            onBack: () => _goBack(context),
            body: _OpsErrorBody(
              message: l10n.tournamentNotFound,
              onRetry: () =>
                  ref.invalidate(tournamentProvider(widget.tournamentId)),
            ),
          );
        }

        return _buildLoaded(context, l10n, tournament);
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    AppLocalizations l10n,
    Tournament tournament,
  ) {
    final colors = context.colors;
    final isReadOnly = _isReadOnlyTournament(tournament.status);
    final divisionsAsync = ref.watch(
      tournamentDivisionsProvider(widget.tournamentId),
    );

    return _OpsScaffold(
      title: tournament.name,
      subtitle: l10n.opsOrganizerOnly,
      onBack: () => _goBack(context),
      actions: [
        IconButton(
          tooltip: l10n.opsRefresh,
          onPressed: () {
            ref.invalidate(tournamentProvider(widget.tournamentId));
            ref.invalidate(tournamentDivisionsProvider(widget.tournamentId));
            if (_selectedDivisionId != null) {
              ref.invalidate(
                matchesWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: _selectedDivisionId,
                )),
              );
              ref.invalidate(
                organizerOpsReadModelProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: _selectedDivisionId!,
                )),
              );
            }
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: divisionsAsync.when(
        loading: () => const _OpsLoadingBody(),
        error: (error, _) => _OpsErrorBody(
          message:
              '${l10n.opsLoadFailed}\n${ErrorParser.parse(error, l10n.opsLoadFailed, l10n)}',
          onRetry: () =>
              ref.invalidate(tournamentDivisionsProvider(widget.tournamentId)),
        ),
        data: (rawDivisions) {
          final divisions = rawDivisions
              .map(_OpsDivision.fromJson)
              .where((division) => division.id.isNotEmpty)
              .toList(growable: false);
          if (divisions.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tournamentProvider(widget.tournamentId));
                ref.invalidate(
                  tournamentDivisionsProvider(widget.tournamentId),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _OpsReadOnlyNotice(
                    icon: Icons.category_outlined,
                    title: l10n.opsDivision,
                    message: l10n.opsEmptyDivision,
                  ),
                ],
              ),
            );
          }

          final selectedDivisionId = _resolveDivisionId(divisions);
          final matchesAsync = ref.watch(
            matchesWithDivisionProvider((
              tournamentId: widget.tournamentId,
              divisionId: selectedDivisionId,
            )),
          );
          final opsReadAsync = ref.watch(
            organizerOpsReadModelProvider((
              tournamentId: widget.tournamentId,
              divisionId: selectedDivisionId!,
            )),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tournamentProvider(widget.tournamentId));
              ref.invalidate(tournamentDivisionsProvider(widget.tournamentId));
              ref.invalidate(
                matchesWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: selectedDivisionId,
                )),
              );
              ref.invalidate(
                organizerOpsReadModelProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: selectedDivisionId,
                )),
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _OpsContextHeader(
                    tournament: tournament,
                    division: divisions.firstWhere(
                      (item) => item.id == selectedDivisionId,
                      orElse: () => divisions.first,
                    ),
                    colors: colors,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _OpsDivisionSelector(
                    divisions: divisions,
                    selectedDivisionId: selectedDivisionId,
                    onChanged: (value) => setState(() {
                      _selectedDivisionId = value;
                      _rosterFilter = 'ALL';
                      _selectedTab = 0;
                    }),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _OpsTabBar(
                    selectedIndex: _selectedTab,
                    onChanged: (value) => setState(() => _selectedTab = value),
                  ),
                ),
                if (_selectedTab == 0)
                  SliverToBoxAdapter(
                    child: _OpsOverview(
                      tournament: tournament,
                      divisions: divisions,
                      matchesAsync: matchesAsync,
                      readOnly: isReadOnly,
                    ),
                  )
                else if (_selectedTab == 1)
                  _buildMatchesSliver(
                    context,
                    matchesAsync,
                    readOnly: isReadOnly,
                    onRetry: () => ref.invalidate(
                      matchesWithDivisionProvider((
                        tournamentId: widget.tournamentId,
                        divisionId: selectedDivisionId,
                      )),
                    ),
                  )
                else if (_selectedTab == 2)
                  SliverToBoxAdapter(
                    child: _OpsBracketPreview(
                      tournamentId: widget.tournamentId,
                      divisionId: selectedDivisionId,
                      readOnly: isReadOnly,
                    ),
                  )
                else if (_selectedTab == 3)
                  _buildRosterSliver(
                    context,
                    opsReadAsync,
                    readOnly: isReadOnly,
                  )
                else if (_selectedTab == 4)
                  _buildActivitySliver(context, opsReadAsync)
                else
                  SliverToBoxAdapter(
                    child: _OpsReadOnlyNotice(
                      icon: Icons.videocam_outlined,
                      title: l10n.opsCamera,
                      message: l10n.opsCameraNotReady,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitySliver(
    BuildContext context,
    AsyncValue<OrganizerOpsReadModel> opsAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return opsAsync.when(
      loading: () => const SliverToBoxAdapter(child: _OpsInlineLoading()),
      error: (error, _) => SliverToBoxAdapter(
        child: _OpsErrorBody(
          message: ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
          onRetry: () => ref.invalidate(
            organizerOpsReadModelProvider((
              tournamentId: widget.tournamentId,
              divisionId: _selectedDivisionId!,
            )),
          ),
        ),
      ),
      data: (readModel) {
        if (readModel.auditEntries.isEmpty) {
          return SliverToBoxAdapter(
            child: _OpsReadOnlyNotice(
              icon: Icons.history_rounded,
              title: l10n.opsAudit,
              message: l10n.opsNoActivity,
            ),
          );
        }
        return SliverList.builder(
          itemCount: readModel.auditEntries.length,
          itemBuilder: (context, index) =>
              _OpsActivityCard(entry: readModel.auditEntries[index]),
        );
      },
    );
  }

  Widget _buildRosterSliver(
    BuildContext context,
    AsyncValue<OrganizerOpsReadModel> opsAsync, {
    required bool readOnly,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return opsAsync.when(
      loading: () => const SliverToBoxAdapter(child: _OpsInlineLoading()),
      error: (error, _) => SliverToBoxAdapter(
        child: _OpsErrorBody(
          message: ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
          onRetry: () => ref.invalidate(
            organizerOpsReadModelProvider((
              tournamentId: widget.tournamentId,
              divisionId: _selectedDivisionId!,
            )),
          ),
        ),
      ),
      data: (readModel) {
        final participants = switch (_rosterFilter) {
          'PAID' =>
            readModel.participants
                .where((participant) => participant.isPaid)
                .toList(growable: false),
          'UNPAID' =>
            readModel.participants
                .where((participant) => !participant.isPaid)
                .toList(growable: false),
          'KICKED' =>
            readModel.participants
                .where((participant) => participant.isKicked)
                .toList(growable: false),
          _ => readModel.participants,
        };
        if (readModel.participants.isEmpty) {
          return SliverToBoxAdapter(
            child: _OpsReadOnlyNotice(
              icon: Icons.people_alt_outlined,
              title: l10n.opsRoster,
              message: l10n.opsNoParticipants,
            ),
          );
        }
        return SliverList.builder(
          itemCount: participants.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _OpsReadOnlyNotice(
                  icon: Icons.info_outline_rounded,
                  title: l10n.opsRoster,
                  message: l10n.opsContextHint,
                ),
              );
            }
            if (index == 1) {
              return _OpsRosterFilterBar(
                selectedFilter: _rosterFilter,
                onChanged: (filter) => setState(() => _rosterFilter = filter),
              );
            }
            final participant = participants[index - 2];
            return _OpsParticipantCard(
              participant: participant,
              onKick: readOnly || participant.isKicked
                  ? null
                  : () => _showKickParticipantSheet(context, participant),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchesSliver(
    BuildContext context,
    AsyncValue<List<MatchModel>> matchesAsync, {
    required bool readOnly,
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return matchesAsync.when(
      loading: () => const SliverToBoxAdapter(child: _OpsInlineLoading()),
      error: (error, _) => SliverToBoxAdapter(
        child: _OpsErrorBody(
          message: ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
          onRetry: onRetry,
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return SliverToBoxAdapter(
            child: _OpsReadOnlyNotice(
              icon: Icons.sports_score_rounded,
              title: AppLocalizations.of(context)!.opsMatches,
              message: AppLocalizations.of(context)!.opsNoMatches,
            ),
          );
        }

        return SliverList.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) => _OpsMatchCard(
            match: matches[index],
            onTap: readOnly
                ? null
                : () => _showMatchActions(context, matches[index]),
          ),
        );
      },
    );
  }

  Future<void> _showKickParticipantSheet(
    BuildContext context,
    OrganizerOpsParticipant participant,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.opsKick,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                participant.teamName,
                style: TextStyle(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.opsKickReason,
                  prefixIcon: const Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    (value ?? '').trim().length < 5 ? l10n.opsKickReason : null,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ref
                        .read(tournamentRepositoryProvider)
                        .kickParticipant(
                          tournamentId: widget.tournamentId,
                          participantId: participant.id,
                          reason: reasonController.text.trim(),
                        );
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    ref.invalidate(
                      organizerOpsReadModelProvider((
                        tournamentId: widget.tournamentId,
                        divisionId: _selectedDivisionId!,
                      )),
                    );
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.opsSaved)));
                  } catch (error) {
                    if (!sheetContext.mounted) return;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_remove_outlined),
                label: Text(l10n.opsKickConfirm),
              ),
            ],
          ),
        ),
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showMatchActions(BuildContext context, MatchModel match) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.status.toUpperCase() == 'SCHEDULED')
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: Text(l10n.matchStartMatch),
                onTap: () => Navigator.pop(sheetContext, 'start'),
              ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(l10n.opsOpenBracket),
              onTap: () => Navigator.pop(sheetContext, 'bracket'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: Text(l10n.matchScheduledTime),
              onTap: () => Navigator.pop(sheetContext, 'schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.scoreboard_outlined),
              title: Text(l10n.opsOpenScoreboard),
              onTap: () => Navigator.pop(sheetContext, 'score'),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: Text(l10n.opsSpecialOperation),
              onTap: () => Navigator.pop(sheetContext, 'special'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    if (action == 'bracket') {
      final query = _selectedDivisionId == null
          ? ''
          : '?divisionId=${Uri.encodeComponent(_selectedDivisionId!)}';
      if (!context.mounted) return;
      context.push('/tournament/${widget.tournamentId}/bracket$query');
      return;
    }

    if (action == 'start') {
      await _confirmStartMatch(context, match);
      return;
    }

    if (action == 'score') {
      if (!context.mounted) return;
      context.push(
        '/organizer/tournaments/${widget.tournamentId}/ops/match/${match.id}',
      );
      return;
    }
    if (action == 'schedule') {
      await _showScheduleSheet(context, match);
      return;
    }
    await _showSpecialOperationSheet(context, match);
  }

  Future<void> _confirmStartMatch(
    BuildContext context,
    MatchModel match,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var submitting = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.matchStartMatch),
          content: Text(l10n.matchStartHint),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: Text(l10n.matchesCancel),
            ),
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      try {
                        await ref.read(matchRepositoryProvider).updateLiveState(
                              widget.tournamentId,
                              match.id,
                              status: 'ONGOING',
                            );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext, true);
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setState(() => submitting = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              ErrorParser.parse(
                                error,
                                l10n.opsLoadFailed,
                                l10n,
                              ),
                            ),
                          ),
                        );
                      }
                    },
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.matchStartMatch),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.invalidate(
        matchesWithDivisionProvider((
          tournamentId: widget.tournamentId,
          divisionId: _selectedDivisionId,
        )),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.opsSaved)));
    }
  }

  Future<void> _showSpecialOperationSheet(
    BuildContext context,
    MatchModel match,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedAction = 'WALKOVER';
    var selectedWinnerId = '';
    final operations = <String, String>{
      'WALKOVER': l10n.opsWalkover,
      'NO_SHOW': l10n.opsNoShow,
      'RETIREMENT': l10n.opsRetirement,
      'DISQUALIFICATION': l10n.opsDisqualification,
      'OVERRIDE_RESULT': l10n.opsOverrideResult,
      'POSTPONE': l10n.opsPostpone,
      'ABANDON': l10n.opsAbandon,
    };
    final winnerItems = <String, String>{
      '': l10n.opsSelectWinner,
      if (match.team1Id.isNotEmpty) match.team1Id: match.team1Name,
      if (match.team2Id.isNotEmpty) match.team2Id: match.team2Name,
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.opsSpecialOperation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAction,
                    decoration: InputDecoration(
                      labelText: l10n.opsSpecialOperation,
                      prefixIcon: const Icon(Icons.tune_rounded),
                    ),
                    items: operations.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedAction = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWinnerId,
                    decoration: InputDecoration(
                      labelText: l10n.opsWinner,
                      prefixIcon: const Icon(Icons.emoji_events_outlined),
                    ),
                    items: winnerItems.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        selectedAction == 'OVERRIDE_RESULT' &&
                            (value == null || value.isEmpty)
                        ? l10n.opsSelectWinner
                        : null,
                    onChanged: (value) =>
                        setSheetState(() => selectedWinnerId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.opsOperationReason,
                      hintText: l10n.opsOperationReasonHint,
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().length < 5) {
                        return l10n.opsOperationReason;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ref
                            .read(matchRepositoryProvider)
                            .matchOperation(
                              match.id,
                              action: selectedAction,
                              reason: reasonController.text.trim(),
                              winnerId: selectedWinnerId.isEmpty
                                  ? null
                                  : selectedWinnerId,
                            );
                        if (!context.mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.opsSaved)));
                        ref.invalidate(
                          matchesWithDivisionProvider((
                            tournamentId: widget.tournamentId,
                            divisionId: _selectedDivisionId,
                          )),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ErrorParser.parse(
                                error,
                                l10n.opsLoadFailed,
                                l10n,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.gavel_rounded),
                    label: Text(l10n.opsOperationConfirm),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showScheduleSheet(
    BuildContext context,
    MatchModel match,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final courtController = TextEditingController(text: match.court);
    DateTime? scheduledAt = match.scheduledTime;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.matchScheduledTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: courtController,
                  decoration: InputDecoration(
                    labelText: l10n.matchCourtLabel,
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: scheduledAt ?? DateTime.now(),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: scheduledAt == null
                          ? TimeOfDay.now()
                          : TimeOfDay.fromDateTime(scheduledAt!),
                    );
                    if (time == null) return;
                    setSheetState(() {
                      scheduledAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text(
                    scheduledAt == null
                        ? l10n.matchNotScheduled
                        : scheduledAt!.toLocal().toString(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(matchRepositoryProvider)
                          .updateSchedule(
                            widget.tournamentId,
                            match.id,
                            courtName: courtController.text.trim().isEmpty
                                ? null
                                : courtController.text.trim(),
                            courtAddress: match.courtAddress.isEmpty
                                ? null
                                : match.courtAddress,
                            refereeId: match.refereeId,
                            scheduledAt: scheduledAt,
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ref.invalidate(
                        matchesWithDivisionProvider((
                          tournamentId: widget.tournamentId,
                          divisionId: _selectedDivisionId,
                        )),
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.opsSaved)));
                      ref.invalidate(
                        organizerOpsReadModelProvider((
                          tournamentId: widget.tournamentId,
                          divisionId: _selectedDivisionId!,
                        )),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(l10n.matchSaveChanges),
                ),
              ],
            ),
          );
        },
      ),
    );
    courtController.dispose();
  }

  String? _resolveDivisionId(List<_OpsDivision> divisions) {
    if (divisions.isEmpty) return null;
    if (_selectedDivisionId != null &&
        divisions.any((division) => division.id == _selectedDivisionId)) {
      return _selectedDivisionId;
    }
    return divisions.first.id;
  }

  bool _isReadOnlyTournament(String status) {
    return {
      'COMPLETED',
      'CANCELLED',
      'CANCELED',
      'ARCHIVED',
      'PENDING_DELETE',
    }.contains(status.trim().toUpperCase());
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

class _OpsScaffold extends StatelessWidget {
  const _OpsScaffold({
    required this.title,
    required this.onBack,
    required this.body,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
          ],
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}

class _OpsContextHeader extends StatelessWidget {
  const _OpsContextHeader({
    required this.tournament,
    required this.division,
    required this.colors,
  });

  final Tournament tournament;
  final _OpsDivision division;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = tournament.status.toUpperCase();
    final statusColor = status == 'IN_PROGRESS' || status == 'ONGOING'
        ? colors.info
        : status == 'COMPLETED'
        ? colors.success
        : colors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: context.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.sport.isEmpty ? 'Sport' : tournament.sport,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _OpsStatusPill(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              division.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.opsDivision}: ${division.matchType}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.opsContextHint,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpsDivisionSelector extends StatelessWidget {
  const _OpsDivisionSelector({
    required this.divisions,
    required this.selectedDivisionId,
    required this.onChanged,
  });

  final List<_OpsDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    if (divisions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _OpsReadOnlyNotice(
          icon: Icons.category_outlined,
          title: l10n.opsDivision,
          message: l10n.opsEmptyDivision,
        ),
      );
    }

    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: divisions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final division = divisions[index];
          final selected = division.id == selectedDivisionId;
          return Semantics(
            button: true,
            selected: selected,
            label: division.name,
            child: InkWell(
              onTap: () => onChanged(division.id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                constraints: const BoxConstraints(minWidth: 112),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : colors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      division.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      division.matchType,
                      style: TextStyle(
                        color: selected ? Colors.white70 : colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OpsTabBar extends StatelessWidget {
  const _OpsTabBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (l10n.opsOverview, Icons.dashboard_outlined),
      (l10n.opsMatches, Icons.sports_score_outlined),
      (l10n.opsBracket, Icons.account_tree_outlined),
      (l10n.opsRoster, Icons.people_alt_outlined),
      (l10n.opsActivity, Icons.history_rounded),
      (l10n.opsCamera, Icons.videocam_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              ChoiceChip(
                selected: selectedIndex == index,
                onSelected: (_) => onChanged(index),
                avatar: Icon(items[index].$2, size: 16),
                label: Text(items[index].$1),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpsOverview extends StatelessWidget {
  const _OpsOverview({
    required this.tournament,
    required this.divisions,
    required this.matchesAsync,
    required this.readOnly,
  });

  final Tournament tournament;
  final List<_OpsDivision> divisions;
  final AsyncValue<List<MatchModel>> matchesAsync;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final matches = matchesAsync.asData?.value ?? const <MatchModel>[];
    final scheduled = matches
        .where((match) => match.scheduledTime != null)
        .length;
    final ongoing = matches.where((match) {
      final status = match.status.toUpperCase();
      return status == 'ONGOING' || status == 'IN_PROGRESS' || status == 'LIVE';
    }).length;
    final completed = matches.where((match) {
      final status = match.status.toUpperCase();
      return status == 'COMPLETED' || status == 'FINISHED';
    }).length;
    final needsAttention = matches.where((match) {
      final missingSchedule = match.scheduledTime == null;
      final missingSide = match.team1Name == 'TBD' || match.team2Name == 'TBD';
      return missingSchedule || missingSide;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.opsOverview,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            readOnly ? l10n.opsReadOnlyHint : l10n.opsContextHint,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OpsMetric(
                icon: Icons.category_outlined,
                label: l10n.opsDivision,
                value: '${divisions.length}',
                color: AppTheme.primary,
              ),
              _OpsMetric(
                icon: Icons.schedule_rounded,
                label: l10n.opsScheduled,
                value: '$scheduled',
                color: colors.info,
              ),
              _OpsMetric(
                icon: Icons.play_circle_outline_rounded,
                label: l10n.opsOngoing,
                value: '$ongoing',
                color: colors.warning,
              ),
              _OpsMetric(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.opsCompleted,
                value: '$completed',
                color: colors.success,
              ),
              _OpsMetric(
                icon: Icons.priority_high_rounded,
                label: l10n.opsAttention,
                value: '$needsAttention',
                color: needsAttention > 0 ? colors.error : colors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _OpsReadOnlyNotice(
            icon: readOnly
                ? Icons.lock_outline_rounded
                : Icons.info_outline_rounded,
            title: l10n.opsOrganizerOnly,
            message: readOnly ? l10n.opsReadOnlyHint : l10n.opsContextHint,
          ),
        ],
      ),
    );
  }
}

class _OpsMetric extends StatelessWidget {
  const _OpsMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsMatchCard extends StatelessWidget {
  const _OpsMatchCard({required this.match, this.onTap});

  final MatchModel match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = match.status.toUpperCase();
    final isCompleted = status == 'COMPLETED' || status == 'FINISHED';
    final statusColor = isCompleted
        ? colors.success
        : status == 'ONGOING' || status == 'LIVE'
        ? colors.info
        : colors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'R${match.round} • #${match.matchNumber}',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _OpsStatusPill(label: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.team1Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${match.score1} : ${match.score2}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.team2Name,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _OpsMeta(
                    icon: Icons.schedule_rounded,
                    text: match.scheduledTime == null
                        ? AppLocalizations.of(context)!.opsUnscheduled
                        : match.scheduledTime!.toLocal().toString(),
                  ),
                  if (match.court.isNotEmpty)
                    _OpsMeta(icon: Icons.place_outlined, text: match.court),
                  if (match.refereeName != null &&
                      match.refereeName!.isNotEmpty)
                    _OpsMeta(
                      icon: Icons.sports_rounded,
                      text: match.refereeName!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpsRosterFilterBar extends StatelessWidget {
  const _OpsRosterFilterBar({
    required this.selectedFilter,
    required this.onChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = <(String, String)>[
      ('ALL', l10n.opsFilterAll),
      ('PAID', l10n.opsFilterPaid),
      ('UNPAID', l10n.opsFilterUnpaid),
      ('KICKED', l10n.opsFilterKicked),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < filters.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              ChoiceChip(
                selected: selectedFilter == filters[index].$1,
                onSelected: (_) => onChanged(filters[index].$1),
                label: Text(filters[index].$2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpsActivityCard extends StatelessWidget {
  const _OpsActivityCard({required this.entry});

  final OrganizerOpsAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history_rounded, color: colors.info, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.action,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.tableName.isEmpty
                        ? entry.recordId
                        : '${entry.tableName} • ${entry.recordId}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.actorName ?? 'System'} • ${entry.createdAt.toLocal()}',
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpsParticipantCard extends StatelessWidget {
  const _OpsParticipantCard({required this.participant, this.onKick});

  final OrganizerOpsParticipant participant;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = participant.isKicked
        ? colors.error
        : participant.isDisciplined
        ? colors.warning
        : colors.success;
    final memberNames = participant.members
        .map((member) => member.fullName)
        .where((name) => name.trim().isNotEmpty)
        .join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    participant.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _OpsStatusPill(
                  label: participant.teamStatus,
                  color: statusColor,
                ),
              ],
            ),
            if (memberNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                memberNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _OpsMeta(
                  icon: participant.isPaid
                      ? Icons.verified_rounded
                      : Icons.pending_outlined,
                  text: participant.isPaid
                      ? l10n.payments_statusSuccess
                      : l10n.payments_statusPending,
                ),
                if (participant.seed != null)
                  _OpsMeta(
                    icon: Icons.numbers_rounded,
                    text: 'Seed ${participant.seed}',
                  ),
              ],
            ),
            if (onKick != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onKick,
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  label: Text(l10n.opsKick),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpsBracketPreview extends StatelessWidget {
  const _OpsBracketPreview({
    required this.tournamentId,
    this.divisionId,
    required this.readOnly,
  });

  final String tournamentId;
  final String? divisionId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OpsReadOnlyNotice(
            icon: Icons.account_tree_outlined,
            title: l10n.opsBracket,
            message: l10n.opsContextHint,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: readOnly
                ? null
                : () {
                    final query = divisionId == null
                        ? ''
                        : '?divisionId=${Uri.encodeComponent(divisionId!)}';
                    context.push(
                      '/organizer/tournaments/$tournamentId/ops/bracket$query',
                    );
                  },
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.opsOpenBracket),
          ),
        ],
      ),
    );
  }
}

class _OpsStatusPill extends StatelessWidget {
  const _OpsStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OpsMeta extends StatelessWidget {
  const _OpsMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: context.colors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _OpsReadOnlyNotice extends StatelessWidget {
  const _OpsReadOnlyNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsLoadingBody extends StatelessWidget {
  const _OpsLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}

class _OpsInlineLoading extends StatelessWidget {
  const _OpsInlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _OpsErrorBody extends StatelessWidget {
  const _OpsErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: context.colors.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.opsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpsDivision {
  const _OpsDivision({
    required this.id,
    required this.name,
    required this.matchType,
  });

  final String id;
  final String name;
  final String matchType;

  factory _OpsDivision.fromJson(Map<String, dynamic> json) {
    return _OpsDivision(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Division',
      matchType: json['matchType']?.toString() ?? 'SINGLES',
    );
  }
}
