import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_brands_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_sponsors_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

enum TournamentManagementSection {
  overview,
  general,
  branding,
  venues,
  registration,
  divisions,
  schedule,
  teams,
  draw,
  bracket,
  liveOperations,
  sponsors,
  finance,
  livestream,
  permissions,
  tokens,
}

class TournamentManagementSectionScreen extends ConsumerWidget {
  const TournamentManagementSectionScreen({
    super.key,
    required this.tournament,
    required this.section,
    required this.opsWorkspaceRoute,
    required this.actionRouteBase,
  });

  final Tournament tournament;
  final TournamentManagementSection section;
  final String opsWorkspaceRoute;
  final String actionRouteBase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sectionTitle(l10n),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _sectionDescription(l10n),
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.border),
        Expanded(child: _content(context, ref)),
      ],
    );
  }

  String _sectionTitle(AppLocalizations l10n) => switch (section) {
    TournamentManagementSection.overview => l10n.tournamentManagementOverview,
    TournamentManagementSection.general => l10n.tournamentManagementGeneral,
    TournamentManagementSection.branding => l10n.tournamentManagementBranding,
    TournamentManagementSection.venues => l10n.tournamentManagementVenues,
    TournamentManagementSection.registration =>
      l10n.tournamentManagementRegistration,
    TournamentManagementSection.divisions => l10n.tournamentManagementDivisions,
    TournamentManagementSection.schedule => l10n.tournamentManagementSchedule,
    TournamentManagementSection.teams => l10n.manageTeams,
    TournamentManagementSection.draw => l10n.manageDraw,
    TournamentManagementSection.bracket => l10n.viewBracket,
    TournamentManagementSection.liveOperations =>
      l10n.tournamentManagementLiveOperations,
    TournamentManagementSection.sponsors => l10n.tournamentManagementSponsors,
    TournamentManagementSection.finance => l10n.tournamentManagementFinance,
    TournamentManagementSection.livestream =>
      l10n.tournamentManagementLivestream,
    TournamentManagementSection.permissions =>
      l10n.tournamentManagementPermissions,
    TournamentManagementSection.tokens => l10n.manageTokens,
  };

  String _sectionDescription(AppLocalizations l10n) => switch (section) {
    TournamentManagementSection.overview =>
      l10n.tournamentManagementOverviewDescription,
    TournamentManagementSection.general =>
      l10n.tournamentManagementGeneralDescription,
    TournamentManagementSection.branding =>
      l10n.tournamentManagementBrandingDescription,
    TournamentManagementSection.venues =>
      l10n.tournamentManagementVenuesDescription,
    TournamentManagementSection.registration =>
      l10n.tournamentManagementRegistrationDescription,
    TournamentManagementSection.divisions =>
      l10n.tournamentManagementDivisionsDescription,
    TournamentManagementSection.schedule =>
      l10n.tournamentManagementScheduleDescription,
    TournamentManagementSection.teams =>
      l10n.tournamentManagementTeamsDescription,
    TournamentManagementSection.draw =>
      l10n.tournamentManagementDrawDescription,
    TournamentManagementSection.bracket =>
      l10n.tournamentManagementBracketDescription,
    TournamentManagementSection.liveOperations =>
      l10n.tournamentManagementLiveOperationsDescription,
    TournamentManagementSection.sponsors =>
      l10n.tournamentManagementSponsorsDescription,
    TournamentManagementSection.finance =>
      l10n.tournamentManagementFinanceDescription,
    TournamentManagementSection.livestream =>
      l10n.tournamentManagementLivestreamDescription,
    TournamentManagementSection.permissions =>
      l10n.tournamentManagementPermissionsDescription,
    TournamentManagementSection.tokens =>
      l10n.tournamentManagementTokensDescription,
  };

  Widget _content(BuildContext context, WidgetRef ref) => switch (section) {
    TournamentManagementSection.overview => _TournamentManagementOverview(
      tournament: tournament,
    ),
    TournamentManagementSection.general => _TournamentGeneralSettings(
      tournament: tournament,
    ),
    TournamentManagementSection.branding => TournamentManagementBrandsSection(
      tournament: tournament,
    ),
    TournamentManagementSection.venues => TournamentManagementVenuesSection(
      tournamentId: tournament.id,
    ),
    TournamentManagementSection.registration =>
      TournamentManagementPeopleSection(
        tournament: tournament,
        showRegistration: true,
      ),
    TournamentManagementSection.permissions =>
      TournamentManagementPeopleSection(
        tournament: tournament,
        showRegistration: false,
      ),
    TournamentManagementSection.divisions =>
      TournamentManagementDivisionsSection(tournament: tournament),
    TournamentManagementSection.sponsors => TournamentManagementSponsorsSection(
      tournamentId: tournament.id,
    ),
    TournamentManagementSection.finance => TournamentManagementFinanceSection(
      tournament: tournament,
    ),
    TournamentManagementSection.schedule => _ExistingOperationsDestination(
      route: opsWorkspaceRoute,
      icon: Icons.calendar_month_rounded,
    ),
    TournamentManagementSection.liveOperations =>
      _ExistingOperationsDestination(
        route: opsWorkspaceRoute,
        icon: Icons.sports_score_rounded,
      ),
    TournamentManagementSection.livestream => _ExistingOperationsDestination(
      route: opsWorkspaceRoute,
      icon: Icons.videocam_rounded,
      isLivestream: true,
    ),
    TournamentManagementSection.teams => _ExistingOperationsDestination(
      route: '$actionRouteBase/teams',
      icon: Icons.groups_rounded,
    ),
    TournamentManagementSection.draw => _ExistingOperationsDestination(
      route: '$actionRouteBase/draw',
      icon: Icons.casino_rounded,
    ),
    TournamentManagementSection.bracket => _ExistingOperationsDestination(
      route: '$actionRouteBase/bracket',
      icon: Icons.account_tree_rounded,
    ),
    TournamentManagementSection.tokens => _ExistingOperationsDestination(
      route: '$actionRouteBase/tokens',
      icon: Icons.qr_code_rounded,
    ),
  };
}

class _TournamentManagementOverview extends StatelessWidget {
  const _TournamentManagementOverview({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat.currency(
      locale: locale,
      name: 'VND',
      symbol: '₫',
      decimalDigits: 0,
    );
    final localizations = MaterialLocalizations.of(context);
    String date(DateTime? value) => value == null
        ? l10n.tournamentManagementNotSet
        : localizations.formatMediumDate(value.toLocal());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: tournament.name,
          subtitle: _statusLabel(l10n, tournament.status),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tournament.description.trim().isNotEmpty)
                Text(
                  tournament.description,
                  style: TextStyle(color: colors.textSecondary),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.tournamentManagementStartDate,
                    value: date(tournament.startDate),
                  ),
                  _SummaryChip(
                    icon: Icons.event_available_rounded,
                    label: l10n.tournamentManagementEndDate,
                    value: date(tournament.endDate),
                  ),
                  _SummaryChip(
                    icon: Icons.people_alt_outlined,
                    label: l10n.tournamentManagementDivisions,
                    value: '${tournament.divisions.length}',
                  ),
                  _SummaryChip(
                    icon: Icons.place_outlined,
                    label: l10n.tournamentManagementVenue,
                    value: (tournament.venueName?.trim().isNotEmpty == true
                        ? tournament.venueName!
                        : l10n.tournamentManagementNotSet),
                  ),
                  _SummaryChip(
                    icon: Icons.payments_outlined,
                    label: l10n.tournamentManagementEntryFee,
                    value: tournament.entryFee == null
                        ? l10n.tournamentManagementNotSet
                        : money.format(tournament.entryFee),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementRegistrationWindow,
          subtitle: tournament.isRegistrationLocked
              ? l10n.tournamentManagementRegistrationLocked
              : l10n.tournamentManagementRegistrationOpen,
          child: Row(
            children: [
              Expanded(
                child: _InfoValue(
                  label: l10n.tournamentManagementRegistrationStarts,
                  value: date(tournament.registrationStartDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoValue(
                  label: l10n.tournamentManagementRegistrationEnds,
                  value: date(tournament.registrationEndDate),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tournamentManagementOverviewHint,
          style: TextStyle(color: colors.textSecondary),
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) => switch (status
      .toUpperCase()) {
    'DRAFT' => l10n.tournamentManagementStatusDraft,
    'UPCOMING' => l10n.tournamentManagementStatusUpcoming,
    'REGISTRATION_OPEN' => l10n.tournamentManagementStatusRegistrationOpen,
    'REGISTRATION_CLOSED' => l10n.tournamentManagementStatusRegistrationClosed,
    'IN_PROGRESS' => l10n.tournamentManagementStatusInProgress,
    'COMPLETED' => l10n.tournamentManagementStatusCompleted,
    'CANCELLED' => l10n.tournamentManagementStatusCancelled,
    _ => l10n.tournamentManagementStatusOther,
  };
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 135, maxWidth: 245),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppTheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoValue extends StatelessWidget {
  const _InfoValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TournamentGeneralSettings extends ConsumerStatefulWidget {
  const _TournamentGeneralSettings({required this.tournament});
  final Tournament tournament;

  @override
  ConsumerState<_TournamentGeneralSettings> createState() =>
      _TournamentGeneralSettingsState();
}

class _TournamentGeneralSettingsState
    extends ConsumerState<_TournamentGeneralSettings> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.tournament.name,
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.tournament.description);
  late String _visibility =
      widget.tournament.visibility.toUpperCase() == 'PRIVATE'
      ? 'PRIVATE'
      : 'PUBLIC';
  late DateTime? _startDate = widget.tournament.startDate;
  late DateTime? _endDate = widget.tournament.endDate;
  late DateTime? _registrationStartDate =
      widget.tournament.registrationStartDate;
  late DateTime? _registrationEndDate = widget.tournament.registrationEndDate;
  bool _isSaving = false;
  bool _isActing = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final status = widget.tournament.status.toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementGeneral,
          subtitle: l10n.tournamentManagementGeneralDescription,
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementDescription,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              _dateField(
                context,
                l10n.tournamentManagementStartDate,
                _startDate,
                () => _pickDate(
                  _startDate,
                  (value) => setState(() => _startDate = value),
                ),
              ),
              const SizedBox(height: 8),
              _dateField(
                context,
                l10n.tournamentManagementEndDate,
                _endDate,
                () => _pickDate(
                  _endDate,
                  (value) => setState(() => _endDate = value),
                ),
              ),
              const SizedBox(height: 8),
              _dateField(
                context,
                l10n.tournamentManagementRegistrationStarts,
                _registrationStartDate,
                () => _pickDate(
                  _registrationStartDate,
                  (value) => setState(() => _registrationStartDate = value),
                ),
              ),
              const SizedBox(height: 8),
              _dateField(
                context,
                l10n.tournamentManagementRegistrationEnds,
                _registrationEndDate,
                () => _pickDate(
                  _registrationEndDate,
                  (value) => setState(() => _registrationEndDate = value),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementVisibility,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'PUBLIC',
                    child: Text(l10n.tournamentManagementPublic),
                  ),
                  DropdownMenuItem(
                    value: 'PRIVATE',
                    child: Text(l10n.tournamentManagementPrivate),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _visibility = value);
                      },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _InlineError(
                  text: switch (_error) {
                    'validation' => l10n.tournamentManagementRequiredFields,
                    'dateRange' => l10n.tournamentManagementEndAfterStart,
                    'registrationRange' =>
                      l10n.tournamentManagementRegistrationEndAfterStart,
                    'registrationBeforeStart' =>
                      l10n.tournamentManagementStartAfterRegistration,
                    _ => l10n.tournamentManagementSaveError,
                  },
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? l10n.tournamentManagementSaving
                        : l10n.tournamentManagementSave,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementLifecycle,
          subtitle: l10n.tournamentManagementLifecycleDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status == 'DRAFT')
                _lifecycleButton(
                  context,
                  l10n.tournamentManagementPublish,
                  Icons.public_rounded,
                  () => _runLifecycle(
                    () => ref
                        .read(tournamentManagementRepositoryProvider)
                        .publishTournament(widget.tournament.id),
                    l10n.tournamentManagementPublishConfirm,
                  ),
                ),
              if (status == 'REGISTRATION_CLOSED' || status == 'UPCOMING')
                _lifecycleButton(
                  context,
                  l10n.tournamentManagementReopenRegistration,
                  Icons.lock_open_rounded,
                  () => _runLifecycle(
                    () => ref
                        .read(tournamentManagementRepositoryProvider)
                        .reopenRegistration(widget.tournament.id),
                    l10n.tournamentManagementReopenConfirm,
                  ),
                ),
              if (status == 'REGISTRATION_OPEN')
                _lifecycleButton(
                  context,
                  l10n.tournamentManagementLockTournament,
                  Icons.lock_outline_rounded,
                  () => _runLifecycle(
                    () => ref
                        .read(tournamentManagementRepositoryProvider)
                        .lockTournament(widget.tournament.id),
                    l10n.tournamentManagementLockConfirm,
                    destructive: true,
                  ),
                ),
              _lifecycleButton(
                context,
                l10n.tournamentManagementRegenerateInvite,
                Icons.autorenew_rounded,
                () => _runLifecycle(
                  () => ref
                      .read(tournamentManagementRepositoryProvider)
                      .regenerateInviteCode(widget.tournament.id),
                  l10n.tournamentManagementRegenerateInviteConfirm,
                ),
              ),
              if (status == 'REGISTRATION_OPEN')
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    l10n.tournamentManagementFinalizeRegistrationUnavailable,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (_isActing) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                _InlineError(text: l10n.tournamentManagementActionError),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.tournamentManagementServerAuthorizationNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateField(
    BuildContext context,
    String label,
    DateTime? value,
    VoidCallback onTap,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final localValue = value?.toLocal();
    final dateLabel = localValue == null
        ? l10n.tournamentManagementChooseDate
        : '${MaterialLocalizations.of(context).formatMediumDate(localValue)}, ${TimeOfDay.fromDateTime(localValue).format(context)}';
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : onTap,
            icon: const Icon(Icons.calendar_today_outlined, size: 17),
            label: Text(
              dateLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onSelected,
  ) async {
    final currentLocal = current?.toLocal();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentLocal ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentLocal == null
          ? const TimeOfDay(hour: 0, minute: 0)
          : TimeOfDay.fromDateTime(currentLocal),
    );
    if (pickedTime == null || !mounted) return;
    onSelected(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  Widget _lifecycleButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isActing ? null : onPressed,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
      ),
    ),
  );

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'validation');
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _isBeforeDateTime(_endDate!, _startDate!)) {
      setState(() => _error = 'dateRange');
      return;
    }
    if (_registrationStartDate != null &&
        _registrationEndDate != null &&
        !_isAfterDateTime(_registrationEndDate!, _registrationStartDate!)) {
      setState(() => _error = 'registrationRange');
      return;
    }
    if (_startDate != null &&
        _registrationEndDate != null &&
        _isBeforeDateTime(_startDate!, _registrationEndDate!)) {
      setState(() => _error = 'registrationBeforeStart');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'name': name,
        'description': _descriptionController.text.trim(),
        'visibility': _visibility,
      };
      _addDateUpdate(
        payload,
        'startDate',
        _startDate,
        widget.tournament.startDate,
      );
      _addDateUpdate(payload, 'endDate', _endDate, widget.tournament.endDate);
      _addDateUpdate(
        payload,
        'registrationStartDate',
        _registrationStartDate,
        widget.tournament.registrationStartDate,
      );
      _addDateUpdate(
        payload,
        'registrationEndDate',
        _registrationEndDate,
        widget.tournament.registrationEndDate,
      );
      await ref
          .read(tournamentRepositoryProvider)
          .update(widget.tournament.id, payload);
      if (!mounted) return;
      ref.invalidate(tournamentProvider(widget.tournament.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tournamentManagementSaved,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'save');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _runLifecycle(
    Future<Map<String, dynamic>> Function() operation,
    String confirmation, {
    bool destructive = false,
  }) async {
    if (_isActing) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: confirmation,
      confirmLabel: l10n.tournamentManagementConfirm,
      destructive: destructive,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _isActing = true;
      _error = null;
    });
    try {
      await operation();
      ref.invalidate(tournamentProvider(widget.tournament.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
    } catch (_) {
      if (mounted) setState(() => _error = 'action');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }
}

void _addDateUpdate(
  Map<String, dynamic> payload,
  String field,
  DateTime? value,
  DateTime? original,
) {
  if (value == null || _sameDateTime(value, original)) return;
  final localValue = value.toLocal();
  final selectedDateTime = DateTime(
    localValue.year,
    localValue.month,
    localValue.day,
    localValue.hour,
    localValue.minute,
  );
  payload[field] = selectedDateTime.toUtc().toIso8601String();
}

bool _sameDateTime(DateTime value, DateTime? other) {
  if (other == null) return false;
  final localValue = value.toLocal();
  final localOther = other.toLocal();
  return localValue.year == localOther.year &&
      localValue.month == localOther.month &&
      localValue.day == localOther.day &&
      localValue.hour == localOther.hour &&
      localValue.minute == localOther.minute;
}

bool _isAfterDateTime(DateTime value, DateTime other) =>
    value.toLocal().isAfter(other.toLocal());

bool _isBeforeDateTime(DateTime value, DateTime other) =>
    value.toLocal().isBefore(other.toLocal());

class _ExistingOperationsDestination extends StatelessWidget {
  const _ExistingOperationsDestination({
    required this.route,
    required this.icon,
    this.isLivestream = false,
  });
  final String route;
  final IconData icon;
  final bool isLivestream;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final description = isLivestream
        ? l10n.tournamentManagementLivestreamRouteDescription
        : l10n.tournamentManagementOpsRouteDescription;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: isLivestream
              ? l10n.tournamentManagementLivestream
              : l10n.tournamentManagementOpenOperations,
          subtitle: description,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.primary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(route),
                  icon: Icon(icon),
                  label: Text(l10n.tournamentManagementOpenDestination),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: context.colors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: context.colors.error.withValues(alpha: 0.35)),
    ),
    child: Text(text, style: TextStyle(color: context.colors.error)),
  );
}
