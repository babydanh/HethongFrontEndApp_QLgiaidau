import 'dart:async';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_session_create_screen.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:dio/dio.dart';
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
      ref
          .read(matchSocketServiceProvider)
          .leaveClubMatchSession(_openSessionId!);
    }
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ClubMatchSessionCreateScreen(communityId: widget.communityId),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.clubMatchSessionCreated)));
    }
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
                    Icon(
                      Icons.sports_tennis_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.outline,
                    ),
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
                        leading: const CircleAvatar(
                          child: Icon(Icons.groups_rounded),
                        ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 409) {
        ref.invalidate(clubSessionDetailProvider(session.id));
      }
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
    final sideA = <String>{};
    final sideB = <String>{};
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
                      sideA.clear();
                      sideB.clear();
                    }),
                  ),
                  ...participants
                      .where((item) => item.status == 'ACTIVE')
                      .map(
                        (item) => ListTile(
                          title: Text(item.displayName),
                          trailing: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'A', label: Text('A')),
                              ButtonSegment(value: 'B', label: Text('B')),
                            ],
                            selected: {
                              if (sideA.contains(item.userId)) 'A',
                              if (sideB.contains(item.userId)) 'B',
                            },
                            emptySelectionAllowed: true,
                            onSelectionChanged: (selection) => setState(() {
                              sideA.remove(item.userId);
                              sideB.remove(item.userId);
                              if (selection.contains('A')) {
                                sideA.add(item.userId);
                              }
                              if (selection.contains('B')) {
                                sideB.add(item.userId);
                              }
                            }),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.clubMatchSessionCreateMatch),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final needed = doubles ? 4 : 2;
    final sideSize = doubles ? 2 : 1;
    if (sideA.length != sideSize || sideB.length != sideSize) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubMatchSessionPlayerCount(needed))),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final repository = ref.read(clubMatchSessionRepositoryProvider);
    final matchType = doubles ? 'DOUBLES' : 'SINGLES';
    try {
      await repository.createMatch(
        session.id,
        sideA.toList(),
        sideB.toList(),
        matchType,
        const Uuid().v4(),
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['code']?.toString() : null;
      if (code != 'PAIRING_WARNINGS_REQUIRE_CONFIRMATION' || !context.mounted) {
        rethrow;
      }
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(l10n.clubMatchSessionPairingWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.matchConfirm),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
      await repository.createMatch(
        session.id,
        sideA.toList(),
        sideB.toList(),
        matchType,
        const Uuid().v4(),
        confirmWarnings: true,
      );
    }
    ref.invalidate(clubSessionDetailProvider(session.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubMatchSessionMatchCreated)),
      );
    }
  }

  Future<void> _forceParticipants(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final members = await ref.read(
      communityMembersProvider(session.communityId).future,
    );
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
                children: members
                    .where((member) => member.status == 'JOINED')
                    .map(
                      (member) => CheckboxListTile(
                        value: selected.contains(member.userId),
                        title: Text(
                          member.userFullName ??
                              l10n.clubMatchSessionUnnamedMember,
                        ),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            selected.add(member.userId);
                          } else {
                            selected.remove(member.userId);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(l10n.clubMatchSessionAssign),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref
          .read(clubMatchSessionRepositoryProvider)
          .forceParticipants(session.id, selected.toList(), const Uuid().v4()),
      l10n.clubMatchSessionAssigned,
    );
  }

  Future<void> _editPreferences(
    BuildContext context,
    WidgetRef ref,
    List<ClubMatchParticipantModel> participants,
    ClubMatchSessionModel currentSession,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final partners = currentSession.preferredPartnerUserIds.toSet();
    final opponents = currentSession.preferredOpponentUserIds.toSet();
    final avoided = currentSession.avoidUserIds.toSet();
    final active = participants
        .where(
          (item) =>
              item.status == 'ACTIVE' &&
              item.userId != currentSession.viewerUserId,
        )
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.clubMatchSessionPreferences),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _preferenceChips(
                l10n.clubMatchSessionPreferredPartner,
                partners,
                {...opponents, ...avoided},
                active,
                (id, selected) => setState(
                  () => selected ? partners.add(id) : partners.remove(id),
                ),
              ),
              _preferenceChips(
                l10n.clubMatchSessionPreferredOpponent,
                opponents,
                {...partners, ...avoided},
                active,
                (id, selected) => setState(
                  () => selected ? opponents.add(id) : opponents.remove(id),
                ),
              ),
              _preferenceChips(
                l10n.clubMatchSessionAvoidPlayer,
                avoided,
                {...partners, ...opponents},
                active,
                (id, selected) => setState(
                  () => selected ? avoided.add(id) : avoided.remove(id),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.clubMatchSessionSavePreferences),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref
          .read(clubMatchSessionRepositoryProvider)
          .updatePreferences(
            session.id,
            preferredPartners: partners.toList(),
            preferredOpponents: opponents.toList(),
            avoidedPlayers: avoided.toList(),
            version: currentSession.preferenceVersion,
          ),
      l10n.clubMatchSessionPreferencesSaved,
    );
  }

  Widget _preferenceChips(
    String label,
    Set<String> selected,
    Set<String> unavailable,
    List<ClubMatchParticipantModel> participants,
    void Function(String id, bool selected) onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: participants
                .map(
                  (item) => FilterChip(
                    label: Text(item.displayName),
                    selected: selected.contains(item.userId),
                    onSelected: unavailable.contains(item.userId)
                        ? null
                        : (value) => onChanged(item.userId, value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );

  Future<void> _removeParticipant(
    BuildContext context,
    WidgetRef ref,
    ClubMatchParticipantModel participant,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.clubMatchSessionRemoveParticipantConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clubMatchSessionRemoveParticipant),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref
          .read(clubMatchSessionRepositoryProvider)
          .removeParticipant(
            session.id,
            participant.userId,
            participant.version,
          ),
      l10n.clubMatchSessionParticipantRemoved,
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    String action,
    ClubMatchSessionModel currentSession,
  ) => _mutation(
    context,
    ref,
    () => ref
        .read(clubMatchSessionRepositoryProvider)
        .transition(session.id, action, currentSession.version),
    AppLocalizations.of(context)!.clubMatchSessionStatusUpdated,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(clubSessionDetailProvider(session.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(session.resolvedName),
        actions: [
          IconButton(
            tooltip: l10n.share,
            onPressed: () => AppShareModal.show(
              context: context,
              title: session.resolvedName,
              subtitle: l10n.clubMatchSessionTitle,
              webUrl:
                  '${AppConstants.appDomain}/communities/${session.communityId}/match-sessions/${session.id}',
            ),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: l10n.infoRetry,
            onPressed: () =>
                ref.invalidate(clubSessionDetailProvider(session.id)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.clubMatchSessionLoadFailed)),
        data: (value) => _buildDetailTabs(context, ref, value),
      ),
    );
  }

  Widget _buildDetailTabs(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: context.colors.bgCard,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.organizer_tabOverview),
                Tab(text: l10n.clubMatchSessionParticipants),
                Tab(text: l10n.clubMatchSessionMatches),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOverviewTab(context, ref, value),
                _buildParticipantsTab(context, ref, value),
                _buildMatchesTab(context, ref, value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader(
    BuildContext context,
    ClubMatchSessionModel currentSession,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SessionBadge(
                  label: _localizedSessionStatus(l10n, currentSession.status),
                  color: currentSession.status == 'LIVE'
                      ? colors.success
                      : colors.info,
                ),
                _SessionBadge(
                  label: currentSession.isRanked
                      ? l10n.clubMatchSessionRankedShort
                      : l10n.clubMatchSessionUnrankedShort,
                  color: currentSession.isRanked
                      ? colors.warning
                      : colors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentSession.resolvedName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              currentSession.description ?? l10n.clubMatchSessionNoDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSessionHeader(context, value.session),
          const SizedBox(height: 12),
          _SessionStats(
            participantCount: value.participants.length,
            matchCount: value.matches.length,
          ),
          const SizedBox(height: 12),
          _buildActions(context, ref, value),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (value.session.canJoin)
          FilledButton.icon(
            icon: const Icon(Icons.how_to_reg_rounded),
            onPressed: () => _mutation(
              context,
              ref,
              () => ref
                  .read(clubMatchSessionRepositoryProvider)
                  .selfJoin(session.id),
              AppLocalizations.of(context)!.clubMatchSessionJoined,
            ),
            label: Text(AppLocalizations.of(context)!.clubMatchSessionJoin),
          ),
        if (value.session.canWithdraw)
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _mutation(
              context,
              ref,
              () => ref
                  .read(clubMatchSessionRepositoryProvider)
                  .withdraw(session.id),
              AppLocalizations.of(context)!.clubMatchSessionWithdrawn,
            ),
            label: Text(AppLocalizations.of(context)!.clubMatchSessionWithdraw),
          ),
        if (value.session.canCreateMatch)
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _createMatch(context, ref, value.participants),
            label: Text(
              AppLocalizations.of(context)!.clubMatchSessionCreateMatch,
            ),
          ),
        if (value.session.canManage)
          OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _forceParticipants(context, ref),
            label: Text(
              AppLocalizations.of(context)!.clubMatchSessionAssignMembers,
            ),
          ),
        if (value.session.viewerIsActive)
          OutlinedButton.icon(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _editPreferences(
              context,
              ref,
              value.participants,
              value.session,
            ),
            label: Text(
              AppLocalizations.of(context)!.clubMatchSessionPreferences,
            ),
          ),
        if (value.session.canManage &&
            (value.session.status == 'OPEN' || value.session.status == 'LIVE'))
          OutlinedButton(
            onPressed: () => _transition(context, ref, 'CLOSE', value.session),
            child: Text(
              AppLocalizations.of(context)!.clubMatchSessionCloseRegistration,
            ),
          ),
        if (value.session.canManage &&
            value.session.status != 'ENDED' &&
            value.session.status != 'CANCELLED')
          OutlinedButton(
            onPressed: () => _transition(context, ref, 'END', value.session),
            child: Text(AppLocalizations.of(context)!.clubMatchSessionEnd),
          ),
        if (value.session.canManage &&
            value.session.status != 'ENDED' &&
            value.session.status != 'CANCELLED')
          OutlinedButton(
            onPressed: () => _transition(context, ref, 'CANCEL', value.session),
            child: Text(AppLocalizations.of(context)!.clubMatchSessionCancel),
          ),
      ],
    );
  }

  Widget _buildParticipantsTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SessionSectionTitle(
            icon: Icons.people_alt_outlined,
            title: l10n.clubMatchSessionParticipants,
            count: value.participants.length,
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Column(
              children: value.participants.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(l10n.noParticipants),
                      ),
                    ]
                  : value.participants
                        .map(
                          (item) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.info.withValues(
                                alpha: .12,
                              ),
                              child: Text(
                                item.displayName.isEmpty
                                    ? '?'
                                    : item.displayName[0].toUpperCase(),
                                style: TextStyle(color: colors.info),
                              ),
                            ),
                            title: Text(item.displayName),
                            subtitle: Text(
                              item.source == 'MANDATORY'
                                  ? l10n.clubMatchSessionMandatorySource
                                  : l10n.clubMatchSessionSelfSource,
                            ),
                            trailing:
                                value.session.canManage &&
                                    item.status == 'ACTIVE'
                                ? IconButton(
                                    tooltip:
                                        l10n.clubMatchSessionRemoveParticipant,
                                    onPressed: () =>
                                        _removeParticipant(context, ref, item),
                                    icon: const Icon(
                                      Icons.person_remove_rounded,
                                    ),
                                  )
                                : null,
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SessionSectionTitle(
            icon: Icons.sports_tennis_outlined,
            title: l10n.clubMatchSessionMatches,
            count: value.matches.length,
            action: value.session.canCreateMatch
                ? FilledButton.tonalIcon(
                    onPressed: () =>
                        _createMatch(context, ref, value.participants),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.clubMatchSessionCreateMatch),
                  )
                : null,
          ),
          if (value.matches.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text(l10n.clubMatchSessionNoMatches)),
              ),
            ),
          ...value.matches.map(
            (match) => _ClubMatchScoreCard(
              match: match,
              sessionId: session.id,
              canEdit:
                  value.session.canManage ||
                  (value.session.viewerUserId != null &&
                      [
                        ...match.sideAUserIds,
                        ...match.sideBUserIds,
                      ].contains(value.session.viewerUserId)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refreshableTab(BuildContext context, WidgetRef ref, Widget child) =>
      RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(clubSessionDetailProvider(session.id)),
        child: child,
      );
}

class _SessionBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SessionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
}

class _SessionStats extends StatelessWidget {
  final int participantCount;
  final int matchCount;

  const _SessionStats({
    required this.participantCount,
    required this.matchCount,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: context.colors.bgSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      side: BorderSide(color: context.colors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SessionStat(
            icon: Icons.people_alt_outlined,
            label: AppLocalizations.of(context)!.clubMatchSessionParticipants,
            value: '$participantCount',
          ),
          _SessionStat(
            icon: Icons.sports_tennis_outlined,
            label: AppLocalizations.of(context)!.clubMatchSessionMatches,
            value: '$matchCount',
          ),
        ],
      ),
    ),
  );
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SessionStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140,
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.colors.info),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SessionSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Widget? action;
  const _SessionSectionTitle({
    required this.icon,
    required this.title,
    required this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: context.colors.info),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title ($count)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ...?(action == null ? null : <Widget>[action!]),
      ],
    ),
  );
}

class _ClubMatchScoreCard extends ConsumerStatefulWidget {
  final ClubSessionMatchModel match;
  final String sessionId;
  final bool canEdit;
  const _ClubMatchScoreCard({
    required this.match,
    required this.sessionId,
    required this.canEdit,
  });

  @override
  ConsumerState<_ClubMatchScoreCard> createState() =>
      _ClubMatchScoreCardState();
}

class _ClubMatchScoreCardState extends ConsumerState<_ClubMatchScoreCard> {
  late int sideA = widget.match.sideAScore;
  late int sideB = widget.match.sideBScore;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant _ClubMatchScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.revision != widget.match.revision ||
        oldWidget.match.sideAScore != widget.match.sideAScore ||
        oldWidget.match.sideBScore != widget.match.sideBScore) {
      sideA = widget.match.sideAScore;
      sideB = widget.match.sideBScore;
    }
  }

  Future<void> _save(bool complete) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(clubMatchSessionRepositoryProvider)
          .updateScore(widget.match, sideA, sideB, complete: complete);
      ref.invalidate(clubSessionDetailProvider(widget.sessionId));
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 409) {
        ref.invalidate(clubSessionDetailProvider(widget.sessionId));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(error, '', l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editable =
        widget.canEdit &&
        !_saving &&
        !['COMPLETED', 'CANCELLED'].contains(widget.match.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(_localizedMatchStatus(l10n, widget.match.status)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.clubMatchSessionDecreaseSideA,
                  onPressed: editable
                      ? () => setState(
                          () => sideA = (sideA - 1).clamp(0, 99).toInt(),
                        )
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$sideA',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  tooltip: l10n.clubMatchSessionIncreaseSideA,
                  onPressed: editable ? () => setState(() => sideA++) : null,
                  icon: const Icon(Icons.add),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(':'),
                ),
                IconButton(
                  tooltip: l10n.clubMatchSessionDecreaseSideB,
                  onPressed: editable
                      ? () => setState(
                          () => sideB = (sideB - 1).clamp(0, 99).toInt(),
                        )
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$sideB',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  tooltip: l10n.clubMatchSessionIncreaseSideB,
                  onPressed: editable ? () => setState(() => sideB++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (widget.canEdit &&
                !['COMPLETED', 'CANCELLED'].contains(widget.match.status))
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => _save(false),
                    child: Text(l10n.clubMatchSessionSaveScore),
                  ),
                  FilledButton(
                    onPressed: _saving || sideA == sideB
                        ? null
                        : () => _save(true),
                    child: Text(l10n.clubMatchSessionComplete),
                  ),
                ],
              ),
            Text(
              _localizedEloStatus(l10n, widget.match.eloStatus),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.match.eloStatus == 'APPLIED' &&
                widget.match.eloDelta.isNotEmpty)
              Text(
                l10n.clubMatchSessionEloDelta(
                  widget.match.eloDelta.values.fold<int>(
                    0,
                    (sum, value) => sum + value.abs(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
