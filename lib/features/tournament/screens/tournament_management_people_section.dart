import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _participantsFuture = ref
        .read(tournamentRepositoryProvider)
        .getOrganizerParticipants(widget.tournament.id);
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  ) {
    final statusMatch = switch (filter) {
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
    if (!statusMatch) return false;
    if (_searchQuery.isEmpty) return true;

    if (participant.teamName.toLowerCase().contains(_searchQuery)) return true;
    for (final p in participant.players) {
      if (p.fullName.toLowerCase().contains(_searchQuery)) return true;
    }
    for (final m in participant.members) {
      if (m.fullName.toLowerCase().contains(_searchQuery)) return true;
      if (m.email?.toLowerCase().contains(_searchQuery) == true) return true;
      if (m.phoneNumber?.contains(_searchQuery) == true) return true;
    }
    return false;
  }

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
            // Thanh tìm kiếm gọn gàng & dropdown filter (giống Web)
            Padding(
              padding: EdgeInsets.only(top: widget.embedded ? 4 : 4, bottom: 8),
              child: Row(
                children: [
                  // Dropdown bộ lọc trạng thái (height 36px gọn gàng)
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ParticipantStatusFilter>(
                        value: _filter,
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.colors.textSecondary),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => _filter = val);
                        },
                        items: [
                          for (final option in ParticipantStatusFilter.values)
                            if (option != ParticipantStatusFilter.pendingPartner || showPendingPartner)
                              DropdownMenuItem(
                                value: option,
                                child: Text('${_filterLabel(l10n, option)} (${counts[option]})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _filter == option ? FontWeight.w800 : FontWeight.w600,
                                    color: _filter == option ? AppTheme.primary : context.colors.textPrimary,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ô tìm kiếm gọn gàng (height 36px)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'TÃ¬m kiáº¿m...',
                          hintStyle: TextStyle(fontSize: 12, color: context.colors.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.colors.textSecondary),
                          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  splashRadius: 16,
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          filled: true,
                          fillColor: context.colors.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
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
                    return TournamentManagementError(
                      error: snapshot.error,
                      onRetry: _reload,
                    );
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
                          userId: _personUserId(member, const [
                            'userId',
                            'user_id',
                            'id',
                          ]),
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
                    return TournamentManagementError(
                      error: snapshot.error,
                      onRetry: _reload,
                    );
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
                          userId: _personUserId(referee, const [
                            'userId',
                            'user_id',
                          ]),
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

  /// Reads the first non-empty id among [keys], falling back to a nested `user`
  /// object. Returns '' when the row is not backed by a real account — a
  /// referee invite is keyed by its record id, not by a user, so it stays out.
  String _personUserId(Map<String, dynamic> person, List<String> keys) {
    for (final key in keys) {
      final value = person[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final nestedUser = person['user'];
    if (nestedUser is Map) {
      return _personUserId(Map<String, dynamic>.from(nestedUser), keys);
    }
    return '';
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

    final rowLabel = participantLabel(
      teamName: participant.teamName,
      players: participant.players,
    );
    final display = resolveParticipantDisplay(
      teamName: participant.teamName,
      players: participant.players,
    );
    final players = participant.players;

    return InkWell(
      key: ValueKey('athlete-team-row-'),
      onTap: onOpenDetail,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dòng trên cùng: Tên đội (nếu là đội có tên) + Tag trạng thái + Cụm nút hành động compact
            Row(
              children: [
                if (display.isTeam && participant.teamName.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      participant.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Spacer(),
                ],
                // Badge trạng thái mỏng gọn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Nút duyệt nhanh / từ chối nhanh / Menu tách cặp (compact buttons)
                if (pending) ...[
                  const SizedBox(width: 6),
                  if (isBusy)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    // Nút duyệt gọn (Pill xanh)
                    InkWell(
                      onTap: onApprove,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              l10n.tournamentManagementApprove,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Nút từ chối gọn (Icon X)
                    InkWell(
                      onTap: onReject,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.close_rounded, size: 16, color: colors.error),
                      ),
                    ),
                  ],
                ],
                // Menu tách cặp
                if (_canUnpair)
                  PopupMenuButton<String>(
                    key: ValueKey('participant-row-menu-'),
                    tooltip: l10n.participantRowActions(rowLabel),
                    enabled: !isBusy,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.textMuted),
                    onSelected: (value) {
                      if (value == 'unpair') onUnpair();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        key: ValueKey('participant-unpair-'),
                        value: 'unpair',
                        child: Text(l10n.participantUnpair),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Phần danh sách VĐV: Tách thành từng hàng VĐV (2 hàng đối với cặp đôi)
            if (players.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.matchNotDetermined,
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
            ] else ...[
              for (int idx = 0; idx < players.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 6),
                _ParticipantPlayerRow(
                  player: players[idx],
                  member: participant.members.isNotEmpty && idx < participant.members.length
                      ? participant.members[idx]
                      : null,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Hàng thông tin từng VĐV: Avatar tròn + Tên VĐV + Thông tin vai trò/khách
class _ParticipantPlayerRow extends StatelessWidget {
  const _ParticipantPlayerRow({
    required this.player,
    this.member,
  });

  final ParticipantPlayer player;
  final OrganizerOpsMember? member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = player.fullName.isNotEmpty ? player.fullName : (member?.fullName ?? '—');
    final avatarUrl = player.avatarUrl ?? member?.avatarUrl;
    final userId = player.userId ?? member?.userId;
    final isGuest = player.isGuest || (userId == null || userId.isEmpty);

    return Row(
      children: [
        // Avatar logo đàng hoàng
        if (!isGuest && userId.isNotEmpty)
          UserAvatarTap(
            userId: userId,
            name: name,
            imageUrl: avatarUrl,
            size: 26,
          )
        else
          CircleAvatar(
            radius: 13,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Text(
              name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
        const SizedBox(width: 8),
        // Tên VĐV
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        // Nhãn phụ: Khách / Dự bị nếu có
        if (isGuest)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'Khách',
              style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600),
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
    required this.onRemove,
  });
  final String name;
  final String status;
  final String userId;
  final VoidCallback? onRemove;

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
