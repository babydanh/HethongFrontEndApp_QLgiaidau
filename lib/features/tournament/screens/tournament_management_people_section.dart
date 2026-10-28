import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/permission_rows.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/participant_detail_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bộ lọc trạng thái VĐV của tab VĐV (task 3.1, đối chiếu bộ lọc của Web
/// `RegistrationTab`): lọc danh sách đang có, không gọi lại API.
enum ParticipantStatusFilter {
  all,
  pending,
  pendingPartner,
  approved,
  unpaid,
  rejected,
}

class TournamentManagementPeopleSection extends StatelessWidget {
  const TournamentManagementPeopleSection({
    super.key,
    required this.tournament,
    required this.showRegistration,
    this.divisionId,
    this.divisionName,
    this.embedded = false,
    this.pairFormat = false,
  });
  final Tournament tournament;
  final bool showRegistration;

  /// Chỉ hiện người tham gia của nội dung này. Null: toàn giải (hành vi cũ).
  final String? divisionId;

  /// Tên hạng mục (subtitle của sheet hồ sơ); null khi lọc toàn giải.
  final String? divisionName;

  /// Nhúng trong một vùng đã cuộn sẵn: dùng Column thay vì ListView riêng.
  final bool embedded;

  /// Nội dung đôi: hồ sơ mở được sheet chi tiết kèm badge cặp (như web).
  final bool pairFormat;

  @override
  Widget build(BuildContext context) => showRegistration
      ? _RegistrationPeople(
          tournament: tournament,
          divisionId: divisionId,
          divisionName: divisionName,
          embedded: embedded,
          pairFormat: pairFormat,
        )
      : _TournamentPermissions(tournamentId: tournament.id);
}

class _RegistrationPeople extends ConsumerStatefulWidget {
  const _RegistrationPeople({
    required this.tournament,
    this.divisionId,
    this.divisionName,
    this.embedded = false,
    this.pairFormat = false,
  });
  final Tournament tournament;
  final String? divisionId;
  final String? divisionName;
  final bool embedded;
  final bool pairFormat;

  @override
  ConsumerState<_RegistrationPeople> createState() =>
      _RegistrationPeopleState();
}

class _RegistrationPeopleState extends ConsumerState<_RegistrationPeople> {
  late Future<List<OrganizerOpsParticipant>> _participantsFuture;
  String? _busyParticipantId;
  String? _mutationError;
  ParticipantStatusFilter _filter = ParticipantStatusFilter.all;

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

  /// Đếm theo trạng thái của danh sách hiện tại (Web `participantSummary`).
  Map<ParticipantStatusFilter, int> _counts(
    List<OrganizerOpsParticipant> participants,
  ) => {
    ParticipantStatusFilter.all: participants.length,
    ParticipantStatusFilter.pending: participants
        .where((item) => _isPending(item.teamStatus))
        .length,
    ParticipantStatusFilter.pendingPartner: participants
        .where((item) => item.teamStatus.toUpperCase() == 'PENDING_PARTNER')
        .length,
    ParticipantStatusFilter.approved: participants
        .where((item) => item.teamStatus.toUpperCase() == 'COMPLETE')
        .length,
    ParticipantStatusFilter.unpaid: participants
        .where((item) => !item.isPaid)
        .length,
    ParticipantStatusFilter.rejected: participants
        .where((item) => item.teamStatus.toUpperCase() == 'REJECTED')
        .length,
  };

  bool _matchesFilter(
    OrganizerOpsParticipant participant,
    ParticipantStatusFilter filter,
  ) => switch (filter) {
    ParticipantStatusFilter.all => true,
    ParticipantStatusFilter.pending => _isPending(participant.teamStatus),
    ParticipantStatusFilter.pendingPartner =>
      participant.teamStatus.toUpperCase() == 'PENDING_PARTNER',
    ParticipantStatusFilter.approved =>
      participant.teamStatus.toUpperCase() == 'COMPLETE',
    ParticipantStatusFilter.unpaid => !participant.isPaid,
    ParticipantStatusFilter.rejected =>
      participant.teamStatus.toUpperCase() == 'REJECTED',
  };

  /// Mở sheet hồ sơ chi tiết (thay card mở rộng cũ).
  Future<void> _openDetail(OrganizerOpsParticipant participant) async {
    await ParticipantDetailSheet.show(
      context,
      tournamentId: widget.tournament.id,
      participant: participant,
      tournamentStatus: widget.tournament.status,
      divisionName: widget.divisionName,
      pairFormat: widget.pairFormat,
      onRefresh: () async {
        if (mounted) _reload();
      },
    );
  }

  /// Tách cặp (task 3.3): confirm rồi POST pairing/:pid/unpair, làm mới danh sách.
  Future<void> _unpair(OrganizerOpsParticipant participant) async {
    if (_busyParticipantId != null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.participantUnpair,
      message: l10n.participantUnpairConfirm(
        participantLabel(
          teamName: participant.teamName,
          players: participant.players,
        ),
      ),
      confirmLabel: l10n.participantUnpair,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busyParticipantId = participant.id;
      _mutationError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .unpairParticipant(widget.tournament.id, participant.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.participantUnpaired)));
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _busyParticipantId = null);
    }
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
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: _reload,
          );
        final all = snapshot.data ?? const <OrganizerOpsParticipant>[];
        final divisionId = widget.divisionId;
        final participants = divisionId == null
            ? all
            : all
                  .where((item) => item.divisionId == divisionId)
                  .toList(growable: false);
        final pending = participants
            .where((item) => _isPending(item.teamStatus))
            .toList(growable: false);
        final counts = _counts(participants);
        // Chip "Chờ đối tác" chỉ hiện với nội dung đôi hoặc khi có người chờ
        // (Web `showPendingPartnerFilter`).
        final showPendingPartner =
            widget.pairFormat ||
            counts[ParticipantStatusFilter.pendingPartner]! > 0 ||
            _filter == ParticipantStatusFilter.pendingPartner;
        final visible = participants
            .where((item) => _matchesFilter(item, _filter))
            .toList(growable: false);
        final body = <Widget>[
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
              subtitle: l10n.tournamentManagementApplicationsEmptyDescription,
              icon: Icons.how_to_reg_outlined,
            )
          else ...[
            if (!widget.embedded) const SizedBox(height: 12),
            // Chips lọc trạng thái kèm số đếm (task 3.1).
            Padding(
              padding: EdgeInsets.only(top: widget.embedded ? 4 : 0, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in ParticipantStatusFilter.values)
                    if (option != ParticipantStatusFilter.pendingPartner ||
                        showPendingPartner)
                      _FilterChip(
                        key: ValueKey('participant-filter-${option.name}'),
                        label: _filterLabel(l10n, option),
                        count: counts[option]!,
                        selected: _filter == option,
                        onTap: () => setState(() => _filter = option),
                      ),
                ],
              ),
            ),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.participantFilterEmpty,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              )
            else
              for (final participant in visible) ...[
                _ParticipantCard(
                  participant: participant,
                  pairFormat: widget.pairFormat,
                  tournamentStatus: widget.tournament.status,
                  isBusy: _busyParticipantId == participant.id,
                  onApprove: () =>
                      _setParticipantStatus(participant, 'COMPLETE'),
                  onReject: () =>
                      _setParticipantStatus(participant, 'REJECTED'),
                  onOpenDetail: () => _openDetail(participant),
                  onUnpair: () => _unpair(participant),
                ),
                Divider(height: 1, color: context.colors.border),
              ],
          ],
        ];
        if (widget.embedded) {
          // Đã nằm trong row mở rộng: số đếm hiện ở tiêu đề row, không cần
          // thẻ bọc hay ListView cuộn riêng.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TournamentManagementSectionCard(
              title: l10n.tournamentManagementRegistration,
              subtitle: l10n.tournamentManagementRegistrationDescription,
              showHeader: false,
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
                  ...body,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _filterLabel(AppLocalizations l10n, ParticipantStatusFilter filter) =>
      switch (filter) {
        ParticipantStatusFilter.all => l10n.participantFilterAll,
        ParticipantStatusFilter.pending => l10n.participantFilterPending,
        ParticipantStatusFilter.pendingPartner =>
          l10n.participantFilterPendingPartner,
        ParticipantStatusFilter.approved => l10n.participantFilterApproved,
        ParticipantStatusFilter.unpaid => l10n.participantFilterUnpaid,
        ParticipantStatusFilter.rejected => l10n.participantFilterRejected,
      };

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
          participantLabel(
            teamName: participant.teamName,
            players: participant.players,
          ),
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
  static const _roles = ['CO_ORGANIZER', 'REFEREE', 'SPECTATOR'];

  late Future<List<PermissionRow>> _rowsFuture;
  final TextEditingController _emailController = TextEditingController();
  String _role = 'CO_ORGANIZER';
  String _filter = 'ALL';
  bool _isBusy = false;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(tournamentManagementRepositoryProvider);
    _rowsFuture = Future.wait([
      repo.getStaff(widget.tournamentId),
      repo.getReferees(widget.tournamentId),
    ]).then((lists) => buildPermissionRows(lists[0], lists[1]));
  }

  void _reload() => setState(() {
    _mutationError = null;
    _load();
  });

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInviteCard(l10n),
        const SizedBox(height: 16),
        FutureBuilder<List<PermissionRow>>(
          future: _rowsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return TournamentManagementError(
                error: snapshot.error,
                onRetry: _reload,
              );
            }
            return _buildListCard(
              l10n,
              snapshot.data ?? const <PermissionRow>[],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInviteCard(AppLocalizations l10n) {
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementInviteByEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final role in _roles)
                ChoiceChip(
                  key: Key('permissions-role-$role'),
                  label: Text(_roleLabel(l10n, role)),
                  selected: _role == role,
                  onSelected: _isBusy
                      ? null
                      : (_) => setState(() => _role = role),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('permissions-invite-email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.tournamentManagementInviteEmail,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('permissions-invite-send'),
              onPressed: _isBusy ? null : _invite,
              icon: _isBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(l10n.tournamentManagementSendInvite),
            ),
          ),
          if (_mutationError != null) ...[
            const SizedBox(height: 10),
            Text(
              _mutationError == 'validation'
                  ? l10n.tournamentManagementInviteEmailInvalid
                  : l10n.tournamentManagementActionError,
              style: TextStyle(color: context.colors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListCard(AppLocalizations l10n, List<PermissionRow> rows) {
    final visible = _filter == 'ALL'
        ? rows
        : rows.where((row) => row.role == _filter).toList();
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementInvitedCount(rows.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in ['ALL', ..._roles])
                ChoiceChip(
                  key: Key('permissions-filter-$value'),
                  label: Text(
                    value == 'ALL' ? l10n.filterAll : _roleLabel(l10n, value),
                  ),
                  selected: _filter == value,
                  onSelected: (_) => setState(() => _filter = value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            TournamentManagementEmpty(
              title: l10n.tournamentManagementStaffEmpty,
              icon: Icons.groups_outlined,
            )
          else
            for (final row in visible) _buildRow(l10n, row),
        ],
      ),
    );
  }

  Widget _buildRow(AppLocalizations l10n, PermissionRow row) {
    final isReferee = row.role == 'REFEREE';
    final roleLabel = _roleLabel(l10n, row.role);
    return _PersonRow(
      name: row.name.isNotEmpty ? row.name : roleLabel,
      status: isReferee
          ? '$roleLabel · ${_refereeStatus(l10n, row.status ?? '')}'
          : roleLabel,
      userId: row.userId,
      trailing: switch (row.action) {
        RefereeAction.revoke => TextButton(
          onPressed: _isBusy ? null : () => _revoke(row),
          child: Text(
            l10n.tournamentManagementRevoke,
            style: TextStyle(color: context.colors.error),
          ),
        ),
        RefereeAction.resend => TextButton(
          onPressed: _isBusy ? null : () => _resend(row),
          child: Text(l10n.tournamentManagementResend),
        ),
        RefereeAction.none when !isReferee => IconButton(
          onPressed: _isBusy ? null : () => _removeStaff(row),
          tooltip: l10n.tournamentManagementRemove,
          icon: Icon(
            Icons.person_remove_alt_1_outlined,
            color: context.colors.error,
          ),
        ),
        RefereeAction.none => null,
      },
    );
  }

  String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
    'CO_ORGANIZER' => l10n.tournamentManagementRoleCoOrganizer,
    'REFEREE' => l10n.tournamentManagementReferee,
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

  Future<void> _invite() async {
    if (_isBusy) return;
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _mutationError = 'validation');
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(tournamentManagementRepositoryProvider);
    final asReferee = _role == 'REFEREE';
    final ok = await _runMutation(
      () => asReferee
          ? repo.addReferee(widget.tournamentId, email)
          : repo.addStaff(widget.tournamentId, email, _role),
      asReferee
          ? l10n.tournamentManagementRefereeInviteSent
          : l10n.tournamentManagementStaffAdded,
    );
    if (ok) _emailController.clear();
  }

  Future<void> _resend(PermissionRow row) async {
    final l10n = AppLocalizations.of(context)!;
    if (row.email.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementResend,
      message: l10n.tournamentManagementResendConfirm(row.name),
      confirmLabel: l10n.tournamentManagementResend,
    );
    if (!confirmed || !mounted || _isBusy) return;
    await _runMutation(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .addReferee(widget.tournamentId, row.email),
      l10n.tournamentManagementRefereeInviteResent,
    );
  }

  Future<void> _revoke(PermissionRow row) async {
    final l10n = AppLocalizations.of(context)!;
    final refereeId = row.refereeId;
    if (refereeId == null || refereeId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRevoke,
      message: l10n.tournamentManagementRevokeConfirm(row.name),
      confirmLabel: l10n.tournamentManagementRevoke,
      destructive: true,
    );
    if (!confirmed || !mounted || _isBusy) return;
    await _runMutation(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .removeReferee(widget.tournamentId, refereeId),
      l10n.tournamentManagementRefereeInviteRevoked,
    );
  }

  Future<void> _removeStaff(PermissionRow row) async {
    final l10n = AppLocalizations.of(context)!;
    if (row.userId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemoveStaff,
      message: l10n.tournamentManagementRemoveStaffConfirm(row.name),
      confirmLabel: l10n.tournamentManagementRemove,
      destructive: true,
    );
    if (!confirmed || !mounted || _isBusy) return;
    await _runMutation(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .removeStaff(widget.tournamentId, row.userId),
      l10n.tournamentManagementStaffRemoved,
    );
  }

  /// Runs one mutation under the shared busy flag. Returns whether it
  /// succeeded; a failure keeps the list as is and shows a generic error.
  Future<bool> _runMutation(
    Future<void> Function() operation,
    String success,
  ) async {
    if (_isBusy) return false;
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await operation();
      if (!mounted) return false;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
      return true;
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
      return false;
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The pill keeps its look; only the tap target grows to 44 px.
    return Semantics(
      button: true,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Align(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : null,
                border: Border.all(
                  color: selected ? AppTheme.primary : colors.border,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppTheme.primary : colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? AppTheme.primary : colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.tournamentStatus,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onOpenDetail,
    required this.onUnpair,
    this.pairFormat = false,
  });
  final OrganizerOpsParticipant participant;

  /// Trạng thái giải: COMPLETED/CANCELLED thì ẩn menu tách cặp (luật Web).
  final String tournamentStatus;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenDetail;
  final VoidCallback onUnpair;

  /// Nội dung đôi / đôi nam nữ: hồ sơ luôn mở được sheet kể cả khi mới có 1 người.
  final bool pairFormat;

  bool get _canUnpair =>
      participant.canUnpair &&
      !const {
        'COMPLETED',
        'CANCELLED',
      }.contains(tournamentStatus.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = participant.teamStatus.toUpperCase();
    final pending = const {'PENDING', 'PENDING_APPROVAL'}.contains(status);
    final (statusLabel, statusColor) = switch (status) {
      'PENDING' || 'PENDING_APPROVAL' => (
        l10n.tournamentManagementParticipantPending,
        colors.warning,
      ),
      'PENDING_PARTNER' => (
        l10n.tournamentManagementParticipantPendingPartner,
        colors.warning,
      ),
      'COMPLETE' => (
        l10n.tournamentManagementParticipantApproved,
        colors.success,
      ),
      'REJECTED' => (
        l10n.tournamentManagementParticipantRejected,
        colors.error,
      ),
      'KICKED' => (
        l10n.tournamentManagementParticipantRemoved,
        colors.textMuted,
      ),
      _ => (l10n.tournamentManagementStatusOther, colors.textSecondary),
    };
    final lead = participant.members.isEmpty ? null : participant.members.first;
    final nameDisplay = resolveParticipantDisplay(
      teamName: participant.teamName,
      players: participant.players,
    );
    final rowLabel = participantLabel(
      teamName: participant.teamName,
      players: participant.players,
    );
    final nameStyle = TextStyle(
      color: colors.textPrimary,
      fontWeight: FontWeight.w700,
    );
    final header = Row(
      children: [
        if (lead != null)
          UserAvatarTap(
            userId: lead.userId,
            name: lead.fullName,
            imageUrl: lead.avatarUrl,
            size: 34,
          )
        else
          const SizedBox(width: 34, height: 44),
        const SizedBox(width: 8),
        Expanded(
          child: nameDisplay.isTeam
              ? ParticipantLabel(
                  teamName: participant.teamName,
                  players: participant.players,
                  style: nameStyle,
                )
              : Text(
                  participant.players.isEmpty
                      ? l10n.matchNotDetermined
                      : participantLabel(
                          teamName: null,
                          players: participant.players,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          statusLabel,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Menu dòng: Tách cặp (task 3.3) — chỉ khi server cho phép.
        if (_canUnpair)
          PopupMenuButton<String>(
            key: ValueKey('participant-row-menu-${participant.id}'),
            tooltip: l10n.participantRowActions(rowLabel),
            enabled: !isBusy,
            icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
            onSelected: (value) {
              if (value == 'unpair') onUnpair();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                key: ValueKey('participant-unpair-${participant.id}'),
                value: 'unpair',
                child: Text(l10n.participantUnpair),
              ),
            ],
          ),
      ],
    );
    return Column(
      key: ValueKey('athlete-team-row-${participant.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: participantLabel(
            teamName: participant.teamName,
            players: participant.players,
          ),
          child: InkWell(
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: header,
            ),
          ),
        ),
        if (pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
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
          ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.status,
    required this.userId,
    this.trailing,
  });
  final String name;
  final String status;
  final String userId;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (userId.isNotEmpty)
            UserAvatarTap(userId: userId, name: name, size: 34)
          else
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
