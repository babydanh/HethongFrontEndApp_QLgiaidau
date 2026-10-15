import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_brands_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_livestream_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
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
  information,
  schedule,
  registration,
  divisions,
  teams,
  draw,
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
    TournamentManagementSection.information => _SettingsPage(
      children: [
        _TournamentSettingsForm(
          tournament: tournament,
          group: _SettingsGroup.information,
        ),
        TournamentManagementBrandsSection(tournament: tournament),
      ],
    ),
    TournamentManagementSection.schedule => _SettingsPage(
      children: [
        _TournamentSettingsForm(
          tournament: tournament,
          group: _SettingsGroup.schedule,
        ),
        TournamentManagementVenuesSection(tournamentId: tournament.id),
      ],
    ),
    TournamentManagementSection.registration => _SettingsPage(
      children: [
        _TournamentSettingsForm(
          tournament: tournament,
          group: _SettingsGroup.registration,
        ),
      ],
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
    TournamentManagementSection.tokens => _ExistingOperationsDestination(
      route: '$actionRouteBase/tokens',
      icon: Icons.qr_code_rounded,
    ),
  };
}

/// Trang cài đặt: các khối xếp dọc, cách nhau 16, cuộn chung một ListView.
class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        children[i],
      ],
    ],
  );
}

/// Ba nhóm cài đặt. Mỗi nhóm có form và nút Lưu riêng.
enum _SettingsGroup { information, schedule, registration }

/// Form của một nhóm cài đặt. Chỉ gửi các trường thuộc nhóm đó.
class _TournamentSettingsForm extends ConsumerStatefulWidget {
  const _TournamentSettingsForm({
    required this.tournament,
    required this.group,
  });

  final Tournament tournament;
  final _SettingsGroup group;

  @override
  ConsumerState<_TournamentSettingsForm> createState() =>
      _TournamentSettingsFormState();
}

class _TournamentSettingsFormState
    extends ConsumerState<_TournamentSettingsForm>
    with _TournamentActionMixin<_TournamentSettingsForm> {
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
  String? _error;

  @override
  String get _actionTournamentId => widget.tournament.id;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManagementSectionCard(
      title: _title(l10n),
      subtitle: _groupDescription(l10n),
      showHeader: false,
      child: Column(
        children: [
          ..._fields(context, l10n),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InlineError(text: _errorText(l10n)),
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
    );
  }

  String _title(AppLocalizations l10n) => switch (widget.group) {
    _SettingsGroup.information => l10n.manageSettingsInfoSection,
    _SettingsGroup.schedule => l10n.manageSettingsScheduleSection,
    _SettingsGroup.registration => l10n.tournamentManagementRegistration,
  };

  String _groupDescription(AppLocalizations l10n) => switch (widget.group) {
    _SettingsGroup.information => l10n.manageSettingsInfoSectionDescription,
    _SettingsGroup.schedule => l10n.manageSettingsScheduleSectionDescription,
    _SettingsGroup.registration =>
      l10n.manageSettingsRegistrationSectionDescription,
  };

  List<Widget> _fields(BuildContext context, AppLocalizations l10n) =>
      switch (widget.group) {
        _SettingsGroup.information => [
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
        ],
        _SettingsGroup.schedule => [
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
        ],
        _SettingsGroup.registration => [
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
          const SizedBox(height: 16),
          _inviteRow(context, l10n),
          if (_actionFailed) ...[
            const SizedBox(height: 8),
            _InlineError(text: l10n.tournamentManagementActionError),
          ],
          if (_isActing) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      };

  Widget _inviteRow(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final code = widget.tournament.inviteCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.manageSettingsInviteCode, style: textTheme.bodyMedium),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                code == null || code.isEmpty
                    ? l10n.tournamentManagementNotSet
                    : code,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isActing || _isSaving
              ? null
              : () => _runAction(
                  () => ref
                      .read(tournamentManagementRepositoryProvider)
                      .regenerateInviteCode(widget.tournament.id),
                  l10n.tournamentManagementRegenerateInviteConfirm,
                ),
          icon: const Icon(Icons.autorenew_rounded),
          label: Text(l10n.tournamentManagementRegenerateInvite),
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
        ),
      ],
    );
  }

  String _errorText(AppLocalizations l10n) => switch (_error) {
    'validation' => l10n.tournamentManagementRequiredFields,
    'dateRange' => l10n.tournamentManagementEndAfterStart,
    'registrationRange' => l10n.tournamentManagementRegistrationEndAfterStart,
    'registrationBeforeStart' => l10n.tournamentManagementStartAfterRegistration,
    _ => l10n.tournamentManagementSaveError,
  };

  /// Kiểm tra của nhóm hiện tại; `null` khi hợp lệ. Kiểm tra chéo nhóm dùng
  /// giá trị đã lưu của giải, không dùng giá trị đang nhập ở nhóm khác.
  String? _validate() => switch (widget.group) {
    _SettingsGroup.information =>
      _nameController.text.trim().isEmpty ? 'validation' : null,
    _SettingsGroup.schedule => _scheduleError(),
    _SettingsGroup.registration => _registrationError(),
  };

  /// Ngày kết thúc không trước ngày bắt đầu; ngày bắt đầu giải không trước
  /// hạn kết thúc đăng ký đã lưu.
  String? _scheduleError() {
    final start = _startDate;
    final end = _endDate;
    final savedRegistrationEnd = widget.tournament.registrationEndDate;
    if (start != null && end != null && _isBeforeDateTime(end, start)) {
      return 'dateRange';
    }
    if (start != null &&
        savedRegistrationEnd != null &&
        _isBeforeDateTime(start, savedRegistrationEnd)) {
      return 'registrationBeforeStart';
    }
    return null;
  }

  /// Hạn kết thúc đăng ký phải sau hạn mở; và không được muộn hơn ngày bắt
  /// đầu giải đã lưu.
  String? _registrationError() {
    final start = _registrationStartDate;
    final end = _registrationEndDate;
    final savedStart = widget.tournament.startDate;
    if (start != null && end != null && !_isAfterDateTime(end, start)) {
      return 'registrationRange';
    }
    if (savedStart != null &&
        end != null &&
        _isBeforeDateTime(savedStart, end)) {
      return 'registrationBeforeStart';
    }
    return null;
  }

  Map<String, dynamic> _payload() {
    final saved = widget.tournament;
    final payload = <String, dynamic>{};
    switch (widget.group) {
      case _SettingsGroup.information:
        payload['name'] = _nameController.text.trim();
        payload['description'] = _description.trim();
        payload['tournamentConfig'] = {
          ...saved.tournamentConfig,
          'hideFeaturedCardText': _hideFeaturedCardText,
        };
      case _SettingsGroup.schedule:
        _addDateUpdate(payload, 'startDate', _startDate, saved.startDate);
        _addDateUpdate(payload, 'endDate', _endDate, saved.endDate);
      case _SettingsGroup.registration:
        payload['visibility'] = _visibility;
        _addDateUpdate(
          payload,
          'registrationStartDate',
          _registrationStartDate,
          saved.registrationStartDate,
        );
        _addDateUpdate(
          payload,
          'registrationEndDate',
          _registrationEndDate,
          saved.registrationEndDate,
        );
    }
    return payload;
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

  Future<void> _save() async {
    if (_isSaving) return;
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .update(widget.tournament.id, _payload());
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
}

/// Thao tác vòng đời và mã mời: xác nhận, gọi máy chủ, rồi làm mới giải đấu.
mixin _TournamentActionMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _isActing = false;
  bool _actionFailed = false;

  String get _actionTournamentId;

  Future<void> _runAction(
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
      _actionFailed = false;
    });
    try {
      await operation();
      ref.invalidate(tournamentProvider(_actionTournamentId));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
    } catch (_) {
      if (mounted) setState(() => _actionFailed = true);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }
}

/// Thao tác vòng đời giải (công bố, mở lại, khoá đăng ký) theo trạng thái
/// hiện tại. Không thao tác nào áp dụng thì không hiển thị.
class TournamentLifecycleCard extends ConsumerStatefulWidget {
  const TournamentLifecycleCard({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentLifecycleCard> createState() =>
      _TournamentLifecycleCardState();
}

class _TournamentLifecycleCardState
    extends ConsumerState<TournamentLifecycleCard>
    with _TournamentActionMixin<TournamentLifecycleCard> {
  @override
  String get _actionTournamentId => widget.tournament.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final id = widget.tournament.id;
    final status = widget.tournament.status.toUpperCase();
    final buttons = <Widget>[
      if (status == 'DRAFT')
        _lifecycleButton(
          l10n.tournamentManagementPublish,
          Icons.public_rounded,
          () => _runAction(
            () => ref
                .read(tournamentManagementRepositoryProvider)
                .publishTournament(id),
            l10n.tournamentManagementPublishConfirm,
          ),
        ),
      if (status == 'REGISTRATION_CLOSED' || status == 'UPCOMING')
        _lifecycleButton(
          l10n.tournamentManagementReopenRegistration,
          Icons.lock_open_rounded,
          () => _runAction(
            () => ref
                .read(tournamentManagementRepositoryProvider)
                .reopenRegistration(id),
            l10n.tournamentManagementReopenConfirm,
          ),
        ),
      if (status == 'REGISTRATION_OPEN')
        _lifecycleButton(
          l10n.tournamentManagementLockTournament,
          Icons.lock_outline_rounded,
          () => _runAction(
            () => ref
                .read(tournamentManagementRepositoryProvider)
                .lockTournament(id),
            l10n.tournamentManagementLockConfirm,
            destructive: true,
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementLifecycle,
      subtitle: l10n.tournamentManagementLifecycleDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...buttons,
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
          if (_actionFailed) ...[
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
    );
  }

  Widget _lifecycleButton(String label, IconData icon, VoidCallback onPressed) =>
      Padding(
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
