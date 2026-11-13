import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/ranked_user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/participant_row_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/permission_rows.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/participant_detail_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/registration_form_editor.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

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
    this.onPresenceChanged,
  });
  final Tournament tournament;
  final bool showRegistration;

  /// Called after a check-in flip (and again on rollback) so a parent header
  /// can keep its "present x/y" count in step without reloading.
  final void Function(String participantId, bool present)? onPresenceChanged;

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
          onPresenceChanged: onPresenceChanged,
        )
      : _TournamentPermissions(tournament: tournament);
}

class _RegistrationPeople extends ConsumerStatefulWidget {
  const _RegistrationPeople({
    required this.tournament,
    this.divisionId,
    this.divisionName,
    this.embedded = false,
    this.pairFormat = false,
    this.onPresenceChanged,
  });
  final Tournament tournament;
  final String? divisionId;
  final String? divisionName;
  final bool embedded;
  final bool pairFormat;
  final void Function(String participantId, bool present)? onPresenceChanged;

  @override
  ConsumerState<_RegistrationPeople> createState() =>
      _RegistrationPeopleState();
}

class _RegistrationPeopleState extends ConsumerState<_RegistrationPeople> {
  late Future<List<OrganizerOpsParticipant>> _participantsFuture;
  String? _busyParticipantId;
  String? _mutationError;
  ParticipantStatusFilter _filter = ParticipantStatusFilter.all;
  String _query = '';

  /// Check-in flips that the server accepted (or are in flight); they win over
  /// the loaded list until the next reload.
  final Map<String, bool> _presence = {};
  final Set<String> _presenceBusy = {};

  /// Check-in only makes sense once registration is closed: hidden while the
  /// tournament is a draft, upcoming or still open for registration. The
  /// Backend does not gate `.../presence` on tournament status at all.
  bool get _showPresence => !const {
    AppConstants.statusDraft,
    AppConstants.statusUpcoming,
    AppConstants.statusRegistration,
  }.contains(StatusHelper.normalizeTournamentStatus(widget.tournament.status));

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
      _presence.clear();
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

  /// Client-side search over the team name and every player/member name.
  bool _matchesSearch(OrganizerOpsParticipant participant) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final haystack = [
      participant.teamName,
      for (final player in participant.players) player.fullName,
      for (final member in participant.members) member.fullName,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  /// One tap flips the check-in. The circle changes at once; a failure puts it
  /// back and says so. A second tap while the request is in flight is ignored.
  Future<void> _togglePresence(OrganizerOpsParticipant participant) async {
    if (_presenceBusy.contains(participant.id)) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final previous = _presence[participant.id] ?? participant.isPresent;
    final next = !previous;
    setState(() {
      _presenceBusy.add(participant.id);
      _presence[participant.id] = next;
    });
    widget.onPresenceChanged?.call(participant.id, next);
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .setParticipantPresent(widget.tournament.id, participant.id, next);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              next ? l10n.athletePresenceMarked : l10n.athletePresenceCleared,
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _presence[participant.id] = previous);
      widget.onPresenceChanged?.call(participant.id, previous);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.athletePresenceFailed)));
    } finally {
      if (mounted) setState(() => _presenceBusy.remove(participant.id));
    }
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
      onPresenceChanged: (present) =>
          widget.onPresenceChanged?.call(participant.id, present),
    );
  }

  /// Mở màn soạn form đăng ký; câu hỏi đã có VĐV trả lời lấy từ danh sách đang tải.
  Future<void> _openRegistrationForm(
    List<OrganizerOpsParticipant> participants,
  ) async {
    final answered = <String>{
      for (final participant in participants)
        for (final entry in participant.customResponses.entries)
          if (entry.value != null && entry.value.toString().trim().isNotEmpty)
            entry.key,
    };
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegistrationFormEditorScreen(
          tournament: widget.tournament,
          answeredFieldIds: answered,
        ),
      ),
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

  /// Loại khỏi giải: confirm rồi POST participants/:pid/kick với lý do mặc
  /// định của Web (`kickDefaultReason`), làm mới danh sách.
  Future<void> _kick(OrganizerOpsParticipant participant) async {
    if (_busyParticipantId != null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.orgMgmtParticipantKick,
      message: l10n.orgMgmtParticipantKickConfirm(
        participantLabel(
          teamName: participant.teamName,
          players: participant.players,
        ),
      ),
      confirmLabel: l10n.orgMgmtParticipantKick,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busyParticipantId = participant.id;
      _mutationError = null;
    });
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .kickParticipant(
            tournamentId: widget.tournament.id,
            participantId: participant.id,
            reason: kickDefaultReason,
          );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.orgMgmtParticipantKicked)));
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
          return const BoneListLoading();
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
            .where(
              (item) => _matchesFilter(item, _filter) && _matchesSearch(item),
            )
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
            // Design 2: one filter chip (opens the list with counts) + search.
            Padding(
              padding: EdgeInsets.only(
                top: widget.embedded ? 4 : 0,
                bottom: 8,
              ),
              child: Row(
                children: [
                  _filterMenu(l10n, counts, showPendingPartner),
                  const SizedBox(width: 8),
                  Expanded(child: _searchField(l10n)),
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
                  showPresence: _showPresence,
                  isPresent: _presence[participant.id] ?? participant.isPresent,
                  onTogglePresence: () => _togglePresence(participant),
                  tournamentStatus: widget.tournament.status,
                  isBusy: _busyParticipantId == participant.id,
                  onApprove: () =>
                      _setParticipantStatus(participant, 'COMPLETE'),
                  onReject: () =>
                      _setParticipantStatus(participant, 'REJECTED'),
                  onOpenDetail: () => _openDetail(participant),
                  onUnpair: () => _unpair(participant),
                  onKick: () => _kick(participant),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const ValueKey('open-registration-form'),
                      onPressed: () => _openRegistrationForm(all),
                      icon: const Icon(Icons.dynamic_form_outlined),
                      label: Text(l10n.registrationFormTitle),
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Widget _filterMenu(
    AppLocalizations l10n,
    Map<ParticipantStatusFilter, int> counts,
    bool showPendingPartner,
  ) {
    return PopupMenuButton<ParticipantStatusFilter>(
      key: const ValueKey('participant-filter-menu'),
      tooltip: l10n.athletesFilterTooltip,
      padding: EdgeInsets.zero,
      initialValue: _filter,
      onSelected: (option) => setState(() => _filter = option),
      itemBuilder: (_) => [
        for (final option in ParticipantStatusFilter.values)
          if (option != ParticipantStatusFilter.pendingPartner ||
              showPendingPartner)
            PopupMenuItem(
              key: ValueKey('participant-filter-${option.name}'),
              value: option,
              child: Text('${_filterLabel(l10n, option)} (${counts[option]})'),
            ),
      ],
      // The menu owns the tap; the chip is only its face.
      child: IgnorePointer(
        child: LavishChipButton(
          label: '${_filterLabel(l10n, _filter)} (${counts[_filter]})',
          chevron: true,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _searchField(AppLocalizations l10n) {
    final colors = LavishColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.chipLine, width: 1.5),
    );
    return TextField(
      key: const ValueKey('participant-search'),
      onChanged: (value) => setState(() => _query = value),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: l10n.athletesSearchHint,
        hintStyle: TextStyle(fontSize: 13, color: colors.muted),
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: LavishColors.accent,
            width: 1.5,
          ),
        ),
      ),
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
  const _TournamentPermissions({required this.tournament});
  final Tournament tournament;

  String get tournamentId => tournament.id;

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
    return LavishSurface(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ..._buildInvite(l10n),
          FutureBuilder<List<PermissionRow>>(
            future: _rowsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const BoneListLoading(itemCount: 3);
              }
              if (snapshot.hasError) {
                return TournamentManagementError(
                  error: snapshot.error,
                  onRetry: _reload,
                );
              }
              return _buildList(l10n, snapshot.data ?? const <PermissionRow>[]);
            },
          ),
        ],
      ),
    );
  }

  /// Design 13: "MỜI NGƯỜI MỚI" group, email field, role chips, one button.
  List<Widget> _buildInvite(AppLocalizations l10n) {
    final colors = LavishColors.of(context);
    return [
      LavishGroupHeader(l10n.tournamentManagementInviteByEmail),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        child: TextField(
          key: const Key('permissions-invite-email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          style: TextStyle(fontSize: 13, color: colors.text),
          decoration: InputDecoration(
            labelText: l10n.tournamentManagementInviteEmail,
            labelStyle: TextStyle(fontSize: 13, color: colors.muted),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.chipLine, width: 1.5),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final role in _roles)
              LavishChipButton(
                key: Key('permissions-role-$role'),
                label: _roleLabel(l10n, role),
                selected: _role == role,
                onPressed: _isBusy ? null : () => setState(() => _role = role),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: LavishButton(
          buttonKey: const Key('permissions-invite-send'),
          label: l10n.tournamentManagementSendInvite,
          busy: _isBusy,
          onPressed: _isBusy ? null : _invite,
        ),
      ),
      if (_mutationError != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Text(
            _mutationError == 'validation'
                ? l10n.tournamentManagementInviteEmailInvalid
                : l10n.tournamentManagementActionError,
            style: const TextStyle(fontSize: 13, color: LavishColors.bad),
          ),
        ),
    ];
  }

  /// "ĐÃ MỜI · N" group; the role filter chips stay (logic unchanged).
  Widget _buildList(AppLocalizations l10n, List<PermissionRow> allRows) {
    // The creator has their own row, so a matching co-organizer row is a repeat.
    final creatorId = widget.tournament.creatorId;
    final rows = allRows
        .where(
          (row) =>
              creatorId.isEmpty ||
              row.userId != creatorId ||
              row.role == 'REFEREE',
        )
        .toList();
    final visible = _filter == 'ALL'
        ? rows
        : rows.where((row) => row.role == _filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (creatorId.isNotEmpty) ...[
          LavishGroupHeader(l10n.organizer_permissionsCreator),
          _buildCreatorRow(l10n),
        ],
        LavishGroupHeader(l10n.tournamentManagementInvitedCount(rows.length)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in ['ALL', ..._roles])
                LavishChipButton(
                  key: Key('permissions-filter-$value'),
                  label: value == 'ALL'
                      ? l10n.filterAll
                      : _roleLabel(l10n, value),
                  selected: _filter == value,
                  onPressed: () => setState(() => _filter = value),
                ),
            ],
          ),
        ),
        if (visible.isEmpty)
          TournamentManagementEmpty(
            title: l10n.tournamentManagementStaffEmpty,
            icon: Icons.groups_outlined,
          )
        else
          for (final row in visible) _buildRow(l10n, row),
      ],
    );
  }

  /// The person who created the tournament; they have no staff record, so the
  /// list would otherwise never say who owns the tournament.
  Widget _buildCreatorRow(AppLocalizations l10n) {
    final tournament = widget.tournament;
    final fullName = tournament.creatorFullName?.trim() ?? '';
    final name = fullName.isNotEmpty
        ? fullName
        : l10n.organizer_permissionsUnknown;
    return LavishRow(
      key: const Key('permissions-creator-row'),
      leading: RankedUserAvatarTap(
        userId: tournament.creatorId,
        name: name,
        imageUrl: tournament.creatorAvatarUrl,
        size: 36,
      ),
      title: name,
      subtitle: l10n.tournamentManagementRoleCreator,
    );
  }

  Widget _buildRow(AppLocalizations l10n, PermissionRow row) {
    final isReferee = row.role == 'REFEREE';
    final roleLabel = _roleLabel(l10n, row.role);
    final name = row.name.isNotEmpty ? row.name : roleLabel;
    final hasAction = row.action != RefereeAction.none || !isReferee;
    return LavishRow(
      leading: row.userId.isNotEmpty
          ? RankedUserAvatarTap(
              userId: row.userId,
              name: name,
              imageUrl: row.avatarUrl.isEmpty ? null : row.avatarUrl,
              size: 36,
            )
          : _LetterAvatar(name),
      title: name,
      subtitle: roleLabel,
      trailing: [
        if (isReferee) _refereePill(l10n, row.status ?? ''),
        if (hasAction)
          IconButton(
            key: Key('permissions-row-menu-${row.userId}-${row.email}'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            tooltip: l10n.club_moreOptions,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: LavishColors.of(context).faint,
            ),
            onPressed: _isBusy ? null : () => _openRowSheet(l10n, row, name),
          ),
      ],
    );
  }

  Widget _refereePill(AppLocalizations l10n, String status) {
    final label = _refereeStatus(l10n, status);
    return switch (status.toUpperCase()) {
      'INVITED' => LavishPill(label, tone: LavishTone.warn),
      'ACCEPTED' => LavishPill(label, tone: LavishTone.ok),
      'DECLINED' => LavishPill(label, tone: LavishTone.bad),
      _ => LavishPill(label, tone: LavishTone.neutral),
    };
  }

  /// Design 13b: bottom sheet with the person and the one action that applies
  /// (revoke / resend / remove); the existing confirm dialog still follows.
  Future<void> _openRowSheet(
    AppLocalizations l10n,
    PermissionRow row,
    String name,
  ) async {
    final isReferee = row.role == 'REFEREE';
    final sub = isReferee
        ? '${_roleLabel(l10n, row.role)} · ${_refereeStatus(l10n, row.status ?? '')}'
        : _roleLabel(l10n, row.role);
    final (label, tone, icon, run) = switch (row.action) {
      RefereeAction.revoke => (
        l10n.tournamentManagementRevoke,
        LavishTone.bad,
        Icons.close_rounded,
        () => _revoke(row),
      ),
      RefereeAction.resend => (
        l10n.tournamentManagementResend,
        LavishTone.accent,
        Icons.refresh_rounded,
        () => _resend(row),
      ),
      RefereeAction.remove => (
        l10n.tournamentManagementRemove,
        LavishTone.bad,
        Icons.person_remove_alt_1_outlined,
        () => _removeReferee(row),
      ),
      RefereeAction.none => (
        l10n.tournamentManagementRemove,
        LavishTone.bad,
        Icons.person_remove_alt_1_outlined,
        () => _removeStaff(row),
      ),
    };
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = LavishColors.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(fontSize: 13, color: colors.muted),
                    ),
                  ],
                ),
              ),
              LavishRow(
                key: const Key('permissions-row-sheet-action'),
                leading: LavishIconBox(tone: tone, child: Icon(icon)),
                title: label,
                titleColor: tone == LavishTone.bad ? LavishColors.bad : null,
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
            ],
          ),
        );
      },
    );
    if (chosen == true && mounted) await run();
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

  Future<void> _removeReferee(PermissionRow row) async {
    final l10n = AppLocalizations.of(context)!;
    final refereeId = row.refereeId;
    if (refereeId == null || refereeId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemove,
      message: l10n.tournamentManagementRemoveRefereeConfirm(row.name),
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

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.tournamentStatus,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onOpenDetail,
    required this.onUnpair,
    required this.onKick,
    required this.showPresence,
    required this.isPresent,
    required this.onTogglePresence,
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
  final VoidCallback onKick;

  /// Whether the check-in circle shows (not while registration is open).
  final bool showPresence;
  final bool isPresent;
  final VoidCallback onTogglePresence;

  /// Nội dung đôi / đôi nam nữ: hồ sơ luôn mở được sheet kể cả khi mới có 1 người.
  final bool pairFormat;

  bool get _canUnpair =>
      participant.canUnpair &&
      !const {
        'COMPLETED',
        'CANCELLED',
      }.contains(tournamentStatus.toUpperCase());

  bool get _canKick =>
      canKickParticipant(participant.teamStatus, tournamentStatus);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = participant.teamStatus.toUpperCase();
    final pending = const {'PENDING', 'PENDING_APPROVAL'}.contains(status);
    final statusLabel = switch (status) {
      'PENDING' || 'PENDING_APPROVAL' => l10n.tournamentManagementParticipantPending,
      'PENDING_PARTNER' => l10n.tournamentManagementParticipantPendingPartner,
      'COMPLETE' => l10n.tournamentManagementParticipantApproved,
      'REJECTED' => l10n.tournamentManagementParticipantRejected,
      'KICKED' => l10n.tournamentManagementParticipantRemoved,
      _ => l10n.tournamentManagementStatusOther,
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
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final header = Row(
      children: [
        if (lead != null)
          RankedUserAvatarTap(
            userId: lead.userId,
            name: lead.fullName,
            imageUrl: lead.avatarUrl,
            size: 36,
          )
        else
          const SizedBox(width: 36, height: 44),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameDisplay.isTeam
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
              _subtitle(context, l10n, status, statusLabel),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ..._trailing(context, l10n, status, pending),
        // Menu dòng như Web: Tách cặp (server cho phép) và Loại khỏi giải.
        if (_canUnpair || _canKick)
          PopupMenuButton<String>(
            key: ValueKey('participant-row-menu-${participant.id}'),
            tooltip: l10n.participantRowActions(rowLabel),
            enabled: !isBusy,
            icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
            onSelected: (value) {
              if (value == 'unpair') onUnpair();
              if (value == 'kick') onKick();
            },
            itemBuilder: (context) => [
              if (_canUnpair)
                PopupMenuItem<String>(
                  key: ValueKey('participant-unpair-${participant.id}'),
                  value: 'unpair',
                  child: Text(l10n.participantUnpair),
                ),
              if (_canKick)
                PopupMenuItem<String>(
                  key: ValueKey('participant-kick-${participant.id}'),
                  value: 'kick',
                  child: Text(
                    l10n.orgMgmtParticipantKick,
                    style: TextStyle(color: colors.error),
                  ),
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
          label: rowLabel,
          child: InkWell(
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: header,
            ),
          ),
        ),
      ],
    );
  }

  /// "Đã duyệt · Đã đóng phí": the fee part is bold green / red; a free entry
  /// shows plain text.
  Widget _subtitle(
    BuildContext context,
    AppLocalizations l10n,
    String status,
    String statusLabel,
  ) {
    final colors = context.colors;
    final lavish = LavishColors.of(context);
    final muted = TextStyle(
      color: status == 'REJECTED' ? colors.error : colors.textSecondary,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
    );
    final hasFee = (participant.entryFee ?? 0) > 0;
    final fee = hasFee
        ? Text(
            participant.isPaid
                ? l10n.participantDetailFeePaid
                : l10n.athleteFeeUnpaid,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: lavish.pillText(
                participant.isPaid ? LavishTone.ok : LavishTone.bad,
              ),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          )
        : (status == 'COMPLETE'
              ? Text(l10n.participantDetailFreeEntry, style: muted)
              : null);
    return Row(
      children: [
        Text(statusLabel, style: muted),
        if (fee != null) ...[
          Text(' · ', style: muted),
          Flexible(child: fee),
        ],
      ],
    );
  }

  /// Right side of the row: ✓/✕ while waiting for approval, the check-in
  /// circle once approved. A row waiting for a partner gets nothing here: the
  /// subtitle already says so and shows the fee status.
  List<Widget> _trailing(
    BuildContext context,
    AppLocalizations l10n,
    String status,
    bool pending,
  ) {
    if (pending) {
      return [
        LavishIconBox(
          key: ValueKey('participant-approve-${participant.id}'),
          size: 30,
          tone: LavishTone.ok,
          tooltip: l10n.tournamentManagementApprove,
          onTap: isBusy ? null : onApprove,
          child: const Icon(Icons.check_rounded),
        ),
        const SizedBox(width: 8),
        LavishIconBox(
          key: ValueKey('participant-reject-${participant.id}'),
          size: 30,
          tone: LavishTone.bad,
          tooltip: l10n.tournamentManagementReject,
          onTap: isBusy ? null : onReject,
          child: const Icon(Icons.close_rounded),
        ),
      ];
    }
    if (status == 'COMPLETE' && showPresence) {
      final lavish = LavishColors.of(context);
      return [
        Semantics(
          button: true,
          checked: isPresent,
          label: l10n.participantDetailCheckIn,
          child: GestureDetector(
            key: ValueKey('participant-checkin-${participant.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: onTogglePresence,
            // 40dp touch target around the design's 26dp circle.
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPresent ? LavishColors.ok : null,
                    border: Border.all(
                      color: isPresent ? LavishColors.ok : lavish.chipLine,
                      width: 2,
                    ),
                  ),
                  child: isPresent
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ];
    }
    return const [];
  }
}

/// Initial on the design's blue-soft circle (`.av`), used when the row has no
/// user id to load an avatar for.
class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFD1E9FF),
      shape: BoxShape.circle,
    ),
    child: Text(
      name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1570EF),
      ),
    ),
  );
}
