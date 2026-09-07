import 'dart:async';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

String _localizedSessionStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'OPEN' => l10n.clubMatchSessionStatusOpen,
      'LIVE' => l10n.clubMatchSessionStatusLive,
      'CLOSED' => l10n.clubMatchSessionStatusClosed,
      'ENDED' => l10n.clubMatchSessionStatusEnded,
      'CANCELLED' => l10n.clubMatchSessionStatusCancelled,
      _ => l10n.clubMatchSessionStatusUnknown,
    };

String _localizedMatchStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'SCHEDULED' => l10n.clubMatchSessionMatchScheduled,
      'ONGOING' => l10n.clubMatchSessionMatchOngoing,
      'COMPLETED' => l10n.clubMatchSessionMatchCompleted,
      'CANCELLED' => l10n.clubMatchSessionMatchCancelled,
      _ => l10n.clubMatchSessionStatusUnknown,
    };

String _localizedEloStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'WAITING_RESULT' => l10n.clubMatchSessionEloWaiting,
      'PENDING' => l10n.clubMatchSessionEloPending,
      'NOT_RANKED' => l10n.clubMatchSessionEloNotRanked,
      'SKIPPED_MOCK' => l10n.clubMatchSessionEloSkippedMock,
      'SKIPPED_CANCELLED' => l10n.clubMatchSessionEloSkippedCancelled,
      'APPLIED' => l10n.clubMatchSessionEloApplied,
      'FAILED_RETRYABLE' => l10n.clubMatchSessionEloRetry,
      'FAILED_TERMINAL' => l10n.clubMatchSessionEloFailed,
      _ => l10n.clubMatchSessionStatusUnknown,
    };

class ClubMatchSessionsScreen extends ConsumerStatefulWidget {
  final String communityId;
  const ClubMatchSessionsScreen({super.key, required this.communityId});

  @override
  ConsumerState<ClubMatchSessionsScreen> createState() =>
      _ClubMatchSessionsScreenState();
}

class _ClubMatchSessionsScreenState
    extends ConsumerState<ClubMatchSessionsScreen> {
  StreamSubscription<Map<String, dynamic>>? _matchSubscription;
  String? _openSessionId;

  @override
  void dispose() {
    _matchSubscription?.cancel();
    if (_openSessionId != null) {
      ref.read(matchSocketServiceProvider).leaveClubMatchSession(_openSessionId!);
    }
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var registrationMode = 'MIXED';
    var ranked = true;
    DateTime? startAt;
    DateTime? endAt;
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.clubMatchSessionCreateTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.clubMatchSessionName,
                    hintText: l10n.clubMatchSessionNameHint,
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.clubMatchSessionDescription,
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: registrationMode,
                  decoration: InputDecoration(
                    labelText: l10n.clubMatchSessionRegistrationMode,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'MIXED',
                      child: Text(l10n.clubMatchSessionRegistrationMixed),
                    ),
                    DropdownMenuItem(
                      value: 'SELF',
                      child: Text(l10n.clubMatchSessionRegistrationSelf),
                    ),
                    DropdownMenuItem(
                      value: 'MANAGER_ASSIGN',
                      child: Text(l10n.clubMatchSessionRegistrationManager),
                    ),
                  ],
                  onChanged: (value) => setDialogState(
                    () => registrationMode = value ?? 'MIXED',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.clubMatchSessionRanked),
                  value: ranked,
                  onChanged: (value) =>
                      setDialogState(() => ranked = value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.clubMatchSessionStartAt),
                  subtitle: Text(startAt == null
                      ? l10n.clubMatchSessionOptionalDate
                      : MaterialLocalizations.of(context).formatFullDate(startAt!)),
                  trailing: const Icon(Icons.event_rounded),
                  onTap: () async {
                    final value = await _pickDateTime(context, startAt);
                    if (value != null) setDialogState(() => startAt = value);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.clubMatchSessionEndAt),
                  subtitle: Text(endAt == null
                      ? l10n.clubMatchSessionOptionalDate
                      : MaterialLocalizations.of(context).formatFullDate(endAt!)),
                  trailing: const Icon(Icons.event_available_rounded),
                  onTap: () async {
                    final value = await _pickDateTime(context, endAt);
                    if (value != null) setDialogState(() => endAt = value);
                  },
                ),
                Text(
                  l10n.clubMatchSessionNoBracketHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.clubMatchSessionCreate),
            ),
          ],
        ),
      ),
    );
    if (shouldCreate != true || !mounted) return;
    try {
      await ref
          .read(clubMatchSessionsProvider(widget.communityId).notifier)
          .create(
            name: nameController.text,
            description: descriptionController.text,
            registrationMode: registrationMode,
            isRanked: ranked,
            startAt: startAt,
            endAt: endAt,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubMatchSessionCreated)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(error, '', l10n))),
        );
      }
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _openSession(ClubMatchSessionModel session) async {
    final socket = ref.read(matchSocketServiceProvider);
    _openSessionId = session.id;
    await socket.connect(null, joinMatch: false);
    socket.joinClubMatchSession(session.id);
    await _matchSubscription?.cancel();
    _matchSubscription = socket.onTournamentMatchUpdate.listen((event) {
      if (event['clubMatchSessionId'] == session.id) {
        ref.invalidate(clubSessionDetailProvider(session.id));
      }
    });
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ClubMatchSessionDetailPage(session: session),
      ),
    );
    socket.leaveClubMatchSession(session.id);
    _openSessionId = null;
    await _matchSubscription?.cancel();
    _matchSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = ref.watch(clubMatchSessionsProvider(widget.communityId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clubMatchSessionTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.clubMatchSessionCreate),
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton.tonal(
            onPressed: () => ref
                .read(clubMatchSessionsProvider(widget.communityId).notifier)
                .refresh(),
            child: Text(l10n.infoRetry),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref
              .read(clubMatchSessionsProvider(widget.communityId).notifier)
              .refresh(),
          child: items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 160),
                    Icon(Icons.sports_tennis_rounded, size: 52, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Center(child: Text(l10n.clubMatchSessionEmpty)),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final session = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _openSession(session),
                        leading: const CircleAvatar(child: Icon(Icons.groups_rounded)),
                        title: Text(session.resolvedName),
                        subtitle: Text(
                          session.isRanked
                              ? l10n.clubMatchSessionRankedShort
                              : l10n.clubMatchSessionUnrankedShort,
                        ),
                        trailing: Chip(
                          label: Text(
                            _localizedSessionStatus(l10n, session.status),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ClubMatchSessionDetailPage extends ConsumerWidget {
  final ClubMatchSessionModel session;
  const _ClubMatchSessionDetailPage({required this.session});

  Future<void> _mutation(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      ref.invalidate(clubSessionDetailProvider(session.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(error, '', l10n))),
        );
      }
    }
  }

  Future<void> _createMatch(
    BuildContext context,
    WidgetRef ref,
    List<ClubMatchParticipantModel> participants,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = <String>{};
    var doubles = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.clubMatchSessionCreateMatch),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.clubMatchSessionDoubles),
                    value: doubles,
                    onChanged: (value) => setState(() {
                      doubles = value;
                      selected.clear();
                    }),
                  ),
                  ...participants.where((item) => item.status == 'ACTIVE').map(
                    (item) => CheckboxListTile(
                      value: selected.contains(item.userId),
                      title: Text(item.displayName),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          selected.add(item.userId);
                        } else {
                          selected.remove(item.userId);
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.clubMatchSessionCreateMatch)),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final needed = doubles ? 4 : 2;
    if (selected.length != needed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubMatchSessionPlayerCount(needed))),
        );
      }
      return;
    }
    final ids = selected.toList();
    final sideSize = doubles ? 2 : 1;
    if (!context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref.read(clubMatchSessionRepositoryProvider).createMatch(
            session.id,
            ids.take(sideSize).toList(),
            ids.skip(sideSize).toList(),
            doubles ? 'DOUBLES' : 'SINGLES',
            const Uuid().v4(),
          ),
      l10n.clubMatchSessionMatchCreated,
    );
  }

  Future<void> _forceParticipants(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final members = await ref.read(communityMembersProvider(session.communityId).future);
    if (!context.mounted) return;
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.clubMatchSessionAssignMembers),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: members.where((member) => member.status == 'JOINED').map(
                  (member) => CheckboxListTile(
                    value: selected.contains(member.userId),
                    title: Text(member.userFullName ?? l10n.clubMatchSessionUnnamedMember),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        selected.add(member.userId);
                      } else {
                        selected.remove(member.userId);
                      }
                    }),
                  ),
                ).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, true), child: Text(l10n.clubMatchSessionAssign)),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref.read(clubMatchSessionRepositoryProvider).forceParticipants(session.id, selected.toList(), const Uuid().v4()),
      l10n.clubMatchSessionAssigned,
    );
  }

  Future<void> _editPreferences(
    BuildContext context,
    WidgetRef ref,
    List<ClubMatchParticipantModel> participants,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    String? partner;
    String? opponent;
    String? avoided;
    final active = participants.where((item) => item.status == 'ACTIVE').toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.clubMatchSessionPreferences),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _preferenceDropdown(l10n.clubMatchSessionPreferredPartner, partner, active, (value) => setState(() => partner = value)),
            _preferenceDropdown(l10n.clubMatchSessionPreferredOpponent, opponent, active, (value) => setState(() => opponent = value)),
            _preferenceDropdown(l10n.clubMatchSessionAvoidPlayer, avoided, active, (value) => setState(() => avoided = value)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.clubMatchSessionSavePreferences)),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref.read(clubMatchSessionRepositoryProvider).updatePreferences(
        session.id,
        preferredPartners: partner == null ? [] : [partner!],
        preferredOpponents: opponent == null ? [] : [opponent!],
        avoidedPlayers: avoided == null ? [] : [avoided!],
      ),
      l10n.clubMatchSessionPreferencesSaved,
    );
  }

  Widget _preferenceDropdown(
    String label,
    String? value,
    List<ClubMatchParticipantModel> participants,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: participants.map((item) => DropdownMenuItem(value: item.userId, child: Text(item.displayName))).toList(),
    onChanged: onChanged,
  );

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) => _mutation(
    context,
    ref,
    () => ref.read(clubMatchSessionRepositoryProvider).transition(
      session.id,
      action,
      session.version,
    ),
    AppLocalizations.of(context)!.clubMatchSessionStatusUpdated,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(clubSessionDetailProvider(session.id));
    return Scaffold(
      appBar: AppBar(title: Text(session.resolvedName)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.clubMatchSessionLoadFailed)),
        data: (value) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(clubSessionDetailProvider(session.id)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(session.description ?? l10n.clubMatchSessionNoDescription),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                FilledButton(
                  onPressed: () => _mutation(context, ref, () => ref.read(clubMatchSessionRepositoryProvider).selfJoin(session.id), l10n.clubMatchSessionJoined),
                  child: Text(l10n.clubMatchSessionJoin),
                ),
                OutlinedButton(
                  onPressed: () => _mutation(context, ref, () => ref.read(clubMatchSessionRepositoryProvider).withdraw(session.id), l10n.clubMatchSessionWithdrawn),
                  child: Text(l10n.clubMatchSessionWithdraw),
                ),
                FilledButton.tonal(
                  onPressed: () => _createMatch(context, ref, value.participants),
                  child: Text(l10n.clubMatchSessionCreateMatch),
                ),
                if (session.canManage) OutlinedButton(
                  onPressed: () => _forceParticipants(context, ref),
                  child: Text(l10n.clubMatchSessionAssignMembers),
                ),
                OutlinedButton(
                  onPressed: () => _editPreferences(context, ref, value.participants),
                  child: Text(l10n.clubMatchSessionPreferences),
                ),
                if (session.canManage && (session.status == 'OPEN' || session.status == 'LIVE'))
                  OutlinedButton(
                    onPressed: () => _transition(context, ref, 'CLOSE'),
                    child: Text(l10n.clubMatchSessionCloseRegistration),
                  ),
                if (session.canManage && session.status != 'ENDED' && session.status != 'CANCELLED')
                  OutlinedButton(
                    onPressed: () => _transition(context, ref, 'END'),
                    child: Text(l10n.clubMatchSessionEnd),
                  ),
              ]),
              const SizedBox(height: 24),
              Text(l10n.clubMatchSessionParticipants, style: Theme.of(context).textTheme.titleMedium),
              ...value.participants.map((item) => ListTile(
                title: Text(item.displayName),
                subtitle: Text(item.source == 'MANDATORY'
                    ? l10n.clubMatchSessionMandatorySource
                    : l10n.clubMatchSessionSelfSource),
              )),
              const SizedBox(height: 18),
              Text(l10n.clubMatchSessionMatches, style: Theme.of(context).textTheme.titleMedium),
              if (value.matches.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text(l10n.clubMatchSessionNoMatches)),
              ...value.matches.map((match) => _ClubMatchScoreCard(match: match, sessionId: session.id)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubMatchScoreCard extends ConsumerStatefulWidget {
  final ClubSessionMatchModel match;
  final String sessionId;
  const _ClubMatchScoreCard({required this.match, required this.sessionId});

  @override
  ConsumerState<_ClubMatchScoreCard> createState() => _ClubMatchScoreCardState();
}

class _ClubMatchScoreCardState extends ConsumerState<_ClubMatchScoreCard> {
  late int sideA = widget.match.sideAScore;
  late int sideB = widget.match.sideBScore;

  Future<void> _save(bool complete) async {
    await ref.read(clubMatchSessionRepositoryProvider).updateScore(widget.match, sideA, sideB, complete: complete);
    ref.invalidate(clubSessionDetailProvider(widget.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(_localizedMatchStatus(l10n, widget.match.status)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => setState(() => sideA = (sideA - 1).clamp(0, 99).toInt()), icon: const Icon(Icons.remove)),
            Text('$sideA', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(onPressed: () => setState(() => sideA++), icon: const Icon(Icons.add)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(':')),
            IconButton(onPressed: () => setState(() => sideB = (sideB - 1).clamp(0, 99).toInt()), icon: const Icon(Icons.remove)),
            Text('$sideB', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(onPressed: () => setState(() => sideB++), icon: const Icon(Icons.add)),
          ]),
          if (widget.match.status != 'COMPLETED') Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: () => _save(false), child: Text(l10n.clubMatchSessionSaveScore)),
            FilledButton(onPressed: sideA == sideB ? null : () => _save(true), child: Text(l10n.clubMatchSessionComplete)),
          ]),
          Text(_localizedEloStatus(l10n, widget.match.eloStatus), style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
