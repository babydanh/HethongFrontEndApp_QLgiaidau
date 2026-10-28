import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/permission_rows.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/participant_detail_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/registration_form_editor.dart';
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
      : _TournamentPermissions(tournamentId: tournament.id);
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<OrganizerOpsParticipant>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: _reload,
          );
        }
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
              (item) => _matchesFilter(item, _filter),
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
                  // Compact status dropdown (36px) like the Web.
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
                        key: const ValueKey('participant-filter-menu'),
                        value: _filter,
                        isDense: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: context.colors.textSecondary,
                        ),
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
                            if (option != ParticipantStatusFilter.pendingPartner ||
                                showPendingPartner)
                              DropdownMenuItem(
                                key: ValueKey('participant-filter-${option.name}'),
                                value: option,
                                child: Text(
                                  '${_filterLabel(l10n, option)} (${counts[option]})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _filter == option
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _filter == option
                                        ? AppTheme.primary
                                        : context.colors.textPrimary,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Compact search field (36px).
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        key: const ValueKey('participant-search'),
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.athletesSearchHint,
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: context.colors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: context.colors.textSecondary,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  splashRadius: 16,
                                  onPressed: _searchController.clear,
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
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
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
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
    return LavishSurface(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ..._buildInvite(l10n),
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
  Widget _buildList(AppLocalizations l10n, List<PermissionRow> rows) {
    final visible = _filter == 'ALL'
        ? rows
        : rows.where((row) => row.role == _filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

  Widget _buildRow(AppLocalizations l10n, PermissionRow row) {
    final isReferee = row.role == 'REFEREE';
    final roleLabel = _roleLabel(l10n, row.role);
    final name = row.name.isNotEmpty ? row.name : roleLabel;
    final hasAction = row.action != RefereeAction.none || !isReferee;
    return LavishRow(
      leading: row.userId.isNotEmpty
          ? UserAvatarTap(userId: row.userId, name: name, size: 36)
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
      key: ValueKey('athlete-team-row-${participant.id}'),
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
                      key: ValueKey('participant-approve-${participant.id}'),
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
                      key: ValueKey('participant-reject-${participant.id}'),
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
                if (status == 'COMPLETE' && showPresence)
                  _PresenceCircle(
                    id: participant.id,
                    isPresent: isPresent,
                    onTap: onTogglePresence,
                  ),
                // Menu tách cặp
                if (_canUnpair)
                  PopupMenuButton<String>(
                    key: ValueKey('participant-row-menu-${participant.id}'),
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
                        key: ValueKey('participant-unpair-${participant.id}'),
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
              AppLocalizations.of(context)!.userGuestFallback,
              style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Check-in circle (main's design): 26dp circle inside a 40dp touch target.
class _PresenceCircle extends StatelessWidget {
  const _PresenceCircle({
    required this.id,
    required this.isPresent,
    required this.onTap,
  });
  final String id;
  final bool isPresent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lavish = LavishColors.of(context);
    return Semantics(
      button: true,
      checked: isPresent,
      label: l10n.participantDetailCheckIn,
      child: GestureDetector(
        key: ValueKey('participant-checkin-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
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
