import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_brands_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_livestream_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_sponsors_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/rich_text/rich_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum TournamentManagementSection {
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
  Widget build(BuildContext context, WidgetRef ref) => _content(context, ref);

  Widget _content(BuildContext context, WidgetRef ref) => switch (section) {
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
    TournamentManagementSection.schedule ||
    TournamentManagementSection.liveOperations => OrganizerOpsScreen(
      tournamentId: tournament.id,
      isEmbedded: true,
    ),
    TournamentManagementSection.livestream =>
      TournamentManagementLivestreamSection(
        tournamentId: tournament.id,
        communityId: tournament.communityId,
      ),
    TournamentManagementSection.teams => _ExistingOperationsDestination(
      route: '$actionRouteBase/teams',
      icon: Icons.groups_rounded,
    ),
    TournamentManagementSection.draw => _ExistingOperationsDestination(
      route: '$actionRouteBase/draw',
      icon: Icons.casino_rounded,
    ),
    TournamentManagementSection.bracket => BracketViewScreen(
      tournamentId: tournament.id,
      isEmbedded: true,
    ),
    TournamentManagementSection.tokens => _ExistingOperationsDestination(
      route: '$actionRouteBase/tokens',
      icon: Icons.qr_code_rounded,
    ),
  };
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
  // Mô tả lưu dạng HTML (Editor.js của web xuất ra HTML). Dùng state thay vì
  // TextEditingController vì RichTextField là WebView, không nhận controller.
  late String _description = widget.tournament.description;
  late String _visibility =
      widget.tournament.visibility.toUpperCase() == 'PRIVATE'
      ? 'PRIVATE'
      : 'PUBLIC';
  late bool _hideFeaturedCardText = widget.tournament.hideFeaturedCardText;
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
          showHeader: false,
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
              // Rich text dùng chung với web: cùng Editor.js nên HTML xuất ra
              // giống hệt, mô tả không bị đổi hình dạng khi lưu từ app.
              RichTextField(
                value: _description,
                label: l10n.tournamentManagementDescription,
                onChanged: (html) {
                  // Editor báo về cả lúc vừa sẵn sàng (giá trị chuẩn hoá) nên
                  // chỉ setState khi thực sự khác.
                  if (html != _description) setState(() => _description = html);
                },
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
              SwitchListTile(
                key: const ValueKey('hide-featured-card-text'),
                contentPadding: EdgeInsets.zero,
                value: _hideFeaturedCardText,
                title: Text(l10n.tournamentManagementHideFeaturedCardText),
                subtitle: Text(
                  l10n.tournamentManagementHideFeaturedCardTextDescription,
                ),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _hideFeaturedCardText = value),
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
        'description': _description.trim(),
        'visibility': _visibility,
        'tournamentConfig': {
          ...widget.tournament.tournamentConfig,
          'hideFeaturedCardText': _hideFeaturedCardText,
        },
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
  });
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final description = l10n.tournamentManagementOpsRouteDescription;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementOpenOperations,
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
