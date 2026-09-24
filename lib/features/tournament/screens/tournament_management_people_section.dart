import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TournamentManagementPeopleSection extends StatelessWidget {
  const TournamentManagementPeopleSection({
    super.key,
    required this.tournament,
    required this.showRegistration,
  });
  final Tournament tournament;
  final bool showRegistration;

  @override
  Widget build(BuildContext context) => showRegistration
      ? _RegistrationPeople(tournament: tournament)
      : _TournamentPermissions(tournamentId: tournament.id);
}

class _RegistrationPeople extends ConsumerStatefulWidget {
  const _RegistrationPeople({required this.tournament});
  final Tournament tournament;

  @override
  ConsumerState<_RegistrationPeople> createState() =>
      _RegistrationPeopleState();
}

class _RegistrationPeopleState extends ConsumerState<_RegistrationPeople> {
  late Future<List<OrganizerOpsParticipant>> _participantsFuture;
  String? _busyParticipantId;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _participantsFuture = ref
        .read(tournamentRepositoryProvider)
        .getOrganizerParticipants(widget.tournament.id);
  }

  void _reload() {
    setState(() {
      _mutationError = null;
      _participantsFuture = ref
          .read(tournamentRepositoryProvider)
          .getOrganizerParticipants(widget.tournament.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<OrganizerOpsParticipant>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return TournamentManagementError(onRetry: _reload);
        final participants = snapshot.data ?? const <OrganizerOpsParticipant>[];
        final pending = participants
            .where((item) => _isPending(item.teamStatus))
            .toList(growable: false);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TournamentManagementSectionCard(
              title: l10n.tournamentManagementRegistration,
              subtitle: l10n.tournamentManagementRegistrationDescription,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountChip(
                        label: l10n.tournamentManagementApplications,
                        count: participants.length,
                      ),
                      _CountChip(
                        label: l10n.tournamentManagementPendingApplications,
                        count: pending.length,
                      ),
                    ],
                  ),
                  if (_mutationError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.tournamentManagementActionError,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  if (participants.isEmpty)
                    TournamentManagementEmpty(
                      title: l10n.tournamentManagementApplicationsEmpty,
                      subtitle:
                          l10n.tournamentManagementApplicationsEmptyDescription,
                      icon: Icons.how_to_reg_outlined,
                    )
                  else ...[
                    const SizedBox(height: 12),
                    for (final participant in participants) ...[
                      _ParticipantCard(
                        participant: participant,
                        isBusy: _busyParticipantId == participant.id,
                        onApprove: () =>
                            _setParticipantStatus(participant, 'COMPLETE'),
                        onReject: () =>
                            _setParticipantStatus(participant, 'REJECTED'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isPending(String status) =>
      const {'PENDING', 'PENDING_APPROVAL'}.contains(status.toUpperCase());

  Future<void> _setParticipantStatus(
    OrganizerOpsParticipant participant,
    String status,
  ) async {
    if (_busyParticipantId != null) return;
    final l10n = AppLocalizations.of(context)!;
    if (status == 'REJECTED') {
      final confirmed = await confirmTournamentManagementAction(
        context,
        title: l10n.tournamentManagementRejectRegistration,
        message: l10n.tournamentManagementRejectRegistrationConfirm(
          participant.teamName,
        ),
        confirmLabel: l10n.tournamentManagementReject,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() {
      _busyParticipantId = participant.id;
      _mutationError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateParticipantStatus(
            widget.tournament.id,
            participant.id,
            status,
          );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'COMPLETE'
                ? l10n.tournamentManagementRegistrationApproved
                : l10n.tournamentManagementRegistrationRejected,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _busyParticipantId = null);
    }
  }
}

class _TournamentPermissions extends ConsumerStatefulWidget {
  const _TournamentPermissions({required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<_TournamentPermissions> createState() =>
      _TournamentPermissionsState();
}

class _TournamentPermissionsState
    extends ConsumerState<_TournamentPermissions> {
  late Future<List<Map<String, dynamic>>> _staffFuture;
  late Future<List<Map<String, dynamic>>> _refereesFuture;
  final TextEditingController _emailController = TextEditingController();
  String _staffRole = 'CO_ORGANIZER';
  bool _isBusy = false;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(tournamentManagementRepositoryProvider);
    _staffFuture = repo.getStaff(widget.tournamentId);
    _refereesFuture = repo.getReferees(widget.tournamentId);
  }

  void _reload() => setState(() {
    _mutationError = null;
    _load();
  });

  @override
  void dispose() {
    _emailController.dispose();
    _refereeEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementStaff,
          subtitle: l10n.tournamentManagementStaffDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementStaffEmail,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _staffRole,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementStaffRole,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'CO_ORGANIZER',
                    child: Text(l10n.tournamentManagementRoleCoOrganizer),
                  ),
                  DropdownMenuItem(
                    value: 'SPECTATOR',
                    child: Text(l10n.tournamentManagementRoleSpectator),
                  ),
                ],
                onChanged: _isBusy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _staffRole = value);
                      },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _addStaff,
                  icon: _isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(l10n.tournamentManagementAddStaff),
                ),
              ),
              if (_mutationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.tournamentManagementActionError,
                  style: TextStyle(color: context.colors.error),
                ),
              ],
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _staffFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  if (snapshot.hasError)
                    return TournamentManagementError(onRetry: _reload);
                  final staff = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (staff.isEmpty)
                    return TournamentManagementEmpty(
                      title: l10n.tournamentManagementStaffEmpty,
                      icon: Icons.groups_outlined,
                    );
                  return Column(
                    children: [
                      for (final member in staff)
                        _PersonRow(
                          name: _personName(
                            member,
                            l10n.tournamentManagementStaffMember,
                          ),
                          status: _staffRoleLabel(
                            l10n,
                            (member['role'] ?? '').toString(),
                          ),
                          onRemove: _isBusy ? null : () => _removeStaff(member),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementReferees,
          subtitle: l10n.tournamentManagementRefereesDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _refereeEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementRefereeEmail,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _addReferee,
                  icon: _isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(l10n.tournamentManagementSendInvite),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _refereesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  if (snapshot.hasError)
                    return TournamentManagementError(onRetry: _reload);
                  final referees =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  if (referees.isEmpty)
                    return TournamentManagementEmpty(
                      title: l10n.tournamentManagementRefereesEmpty,
                      icon: Icons.sports_outlined,
                    );
                  return Column(
                    children: [
                      for (final referee in referees)
                        _PersonRow(
                          name: _personName(
                            referee,
                            l10n.tournamentManagementReferee,
                          ),
                          status: _refereeStatus(
                            l10n,
                            (referee['status'] ?? '').toString(),
                          ),
                          onRemove: _isBusy
                              ? null
                              : () => _removeReferee(referee),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  late final TextEditingController _refereeEmailController =
      TextEditingController();

  String _personName(Map<String, dynamic> person, String fallback) {
    final nestedUser = person['user'];
    final nestedName = nestedUser is Map
        ? nestedUser['fullName'] ?? nestedUser['name']
        : null;
    final name = (person['fullName'] ?? person['name'] ?? nestedName)
        ?.toString()
        .trim();
    return name?.isNotEmpty == true ? name! : fallback;
  }

  String _staffRoleLabel(AppLocalizations l10n, String role) =>
      switch (role.toUpperCase()) {
        'CO_ORGANIZER' => l10n.tournamentManagementRoleCoOrganizer,
        'SPECTATOR' => l10n.tournamentManagementRoleSpectator,
        _ => l10n.tournamentManagementRoleOther,
      };

  String _refereeStatus(AppLocalizations l10n, String status) =>
      switch (status.toUpperCase()) {
        'INVITED' => l10n.tournamentManagementRefereeInvited,
        'ACCEPTED' => l10n.tournamentManagementRefereeAccepted,
        'DECLINED' => l10n.tournamentManagementRefereeDeclined,
        _ => l10n.tournamentManagementStatusOther,
      };

  Future<void> _addStaff() async {
    if (_isBusy) return;
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _mutationError = 'validation');
      return;
    }
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .addStaff(widget.tournamentId, email, _staffRole);
      if (!mounted) return;
      _emailController.clear();
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tournamentManagementStaffAdded,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _addReferee() async {
    if (_isBusy) return;
    final email = _refereeEmailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _mutationError = 'validation');
      return;
    }
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .addReferee(widget.tournamentId, email);
      if (!mounted) return;
      _refereeEmailController.clear();
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tournamentManagementRefereeInviteSent,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _removeStaff(Map<String, dynamic> member) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = (member['userId'] ?? member['user_id'] ?? member['id'] ?? '')
        .toString();
    if (userId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemoveStaff,
      message: l10n.tournamentManagementRemoveStaffConfirm(
        _personName(member, l10n.tournamentManagementStaffMember),
      ),
      confirmLabel: l10n.tournamentManagementRemove,
      destructive: true,
    );
    if (!confirmed || !mounted || _isBusy) return;
    await _runMutation(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .removeStaff(widget.tournamentId, userId),
      l10n.tournamentManagementStaffRemoved,
    );
  }

  Future<void> _removeReferee(Map<String, dynamic> referee) async {
    final l10n = AppLocalizations.of(context)!;
    final refereeId = (referee['id'] ?? referee['refereeId'] ?? '').toString();
    if (refereeId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemoveReferee,
      message: l10n.tournamentManagementRemoveRefereeConfirm(
        _personName(referee, l10n.tournamentManagementReferee),
      ),
      confirmLabel: l10n.tournamentManagementRemove,
      destructive: true,
    );
    if (!confirmed || !mounted || _isBusy) return;
    await _runMutation(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .removeReferee(widget.tournamentId, refereeId),
      l10n.tournamentManagementRefereeRemoved,
    );
  }

  Future<void> _runMutation(
    Future<void> Function() operation,
    String success,
  ) async {
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await operation();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && at < value.length - 3 && value.indexOf('.', at) > at + 1;
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: const Icon(Icons.people_alt_outlined, size: 18),
    label: Text('$label: $count'),
    visualDensity: VisualDensity.compact,
  );
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });
  final OrganizerOpsParticipant participant;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = participant.teamStatus.toUpperCase();
    final pending = const {'PENDING', 'PENDING_APPROVAL'}.contains(status);
    final localizedStatus = switch (status) {
      'PENDING' ||
      'PENDING_APPROVAL' => l10n.tournamentManagementParticipantPending,
      'COMPLETE' => l10n.tournamentManagementParticipantApproved,
      'REJECTED' => l10n.tournamentManagementParticipantRejected,
      'KICKED' => l10n.tournamentManagementParticipantRemoved,
      _ => l10n.tournamentManagementStatusOther,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participant.teamName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(localizedStatus),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.tournamentManagementParticipantCount(
                participant.members.length,
              ),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
          if (pending) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    child: Text(l10n.tournamentManagementReject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onApprove,
                    child: isBusy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.tournamentManagementApprove),
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

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.status,
    required this.onRemove,
  });
  final String name;
  final String status;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: colors.bgElevated,
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: AppLocalizations.of(context)!.tournamentManagementRemove,
            icon: Icon(Icons.person_remove_alt_1_outlined, color: colors.error),
          ),
        ],
      ),
    );
  }
}
