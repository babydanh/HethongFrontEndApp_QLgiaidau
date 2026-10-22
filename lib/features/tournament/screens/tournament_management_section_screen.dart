import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  liveOperations,
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
        TournamentManagementVenuesSection(tournamentId: tournament.id),
      ],
    ),
    TournamentManagementSection.registration => _TournamentSettingsForm(
      tournament: tournament,
      group: _SettingsGroup.registration,
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
    TournamentManagementSection.liveOperations => OrganizerOpsScreen(
      tournamentId: tournament.id,
      isEmbedded: true,
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

/// Thanh dưới cố định của trang Đăng ký: đường kẻ mảnh phía trên, có SafeArea đáy.
class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({required this.error, required this.button});

  final String? error;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                _InlineError(text: error!),
                const SizedBox(height: 8),
              ],
              Align(alignment: Alignment.centerRight, child: button),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hai nhóm cài đặt. Mỗi nhóm có form và nút Lưu riêng.
enum _SettingsGroup { information, registration }

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
  late String _visibility = _savedVisibility;
  late String _registrationMode = _savedRegistrationMode;
  late String _pairingMode = _savedPairingMode;
  late bool _hideFeaturedCardText = widget.tournament.hideFeaturedCardText;
  late DateTime? _startDate = widget.tournament.startDate;
  late DateTime? _endDate = widget.tournament.endDate;
  late DateTime? _registrationStartDate =
      widget.tournament.registrationStartDate;
  late DateTime? _registrationEndDate = widget.tournament.registrationEndDate;
  bool _isSaving = false;
  String? _errorMessage;

  String get _savedVisibility =>
      widget.tournament.visibility.toUpperCase() == 'PRIVATE'
      ? 'PRIVATE'
      : 'PUBLIC';

  String get _savedRegistrationMode =>
      switch (widget.tournament.registrationMode?.toUpperCase()) {
        'APPROVAL' => 'APPROVAL',
        'INVITE_ONLY' => 'INVITE_ONLY',
        _ => 'OPEN',
      };

  String get _savedPairingMode =>
      widget.tournament.doublesPairingMode?.toUpperCase() == 'SELF'
      ? 'SELF'
      : 'ORGANIZER';

  /// Giải đã khoá đăng ký: mọi điều khiển và nút Lưu bị khoá.
  bool get _locked => widget.tournament.isRegistrationLocked;

  /// Giải đã đóng (chưa khoá): chỉ được gia hạn hạn chót đăng ký.
  bool get _closed =>
      widget.tournament.status.toUpperCase() == 'REGISTRATION_CLOSED';

  bool get _settingsEditable => !_isSaving && !_locked && !_closed;

  bool get _deadlineEditable => !_isSaving && !_locked;

  bool get _regenerateEnabled =>
      !_isSaving && !_isActing && !_locked && !_closed;

  String? get _inviteCode {
    final code = widget.tournament.inviteCode;
    return code == null || code.isEmpty ? null : code;
  }

  bool get _showsInvite =>
      (_visibility == 'PRIVATE' || _registrationMode == 'INVITE_ONLY') &&
      _inviteCode != null;

  /// Giống web: chỉ hiện cặp ghép khi giải có nội dung đôi.
  bool get _hasDoublesContent {
    const doubles = {'DOUBLES', 'MIXED_DOUBLES'};
    final tournament = widget.tournament;
    return doubles.contains(tournament.format.toUpperCase()) ||
        tournament.divisions.any(
          (division) => doubles.contains(division.matchType.toUpperCase()),
        );
  }

  /// Hạn chót mới phải sau hạn đã lưu thì mới gia hạn được.
  bool get _deadlineExtended {
    final value = _registrationEndDate;
    final saved = widget.tournament.registrationEndDate;
    return value != null && (saved == null || _isAfterDateTime(value, saved));
  }

  /// Giống web: giải Lite của cộng đồng chỉ giữ INVITE_ONLY, còn lại là OPEN.
  String _effectiveRegistrationMode() {
    final tournament = widget.tournament;
    final isLite =
        tournament.isLite || tournament.tournamentConfig['isLite'] == true;
    final hasCommunity = (tournament.communityId ?? '').isNotEmpty;
    if (hasCommunity && isLite) {
      return _registrationMode == 'INVITE_ONLY' ? 'INVITE_ONLY' : 'OPEN';
    }
    return _registrationMode;
  }

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
    final card = TournamentManagementSectionCard(
      title: _title(l10n),
      subtitle: _groupDescription(l10n),
      showHeader: false,
      child: Column(
        children: [
          ..._fields(context, l10n),
          if (!_hasStickySave) ...[
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _InlineError(text: _errorMessage!),
            ],
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: _saveButton(l10n)),
          ],
        ],
      ),
    );
    if (!_hasStickySave) return card;
    // Trang Đăng ký: nút Lưu dính đáy, nằm ngoài ListView nên không bị cuộn.
    return Column(
      children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [card]),
        ),
        _StickySaveBar(
          error: _errorMessage,
          button: _saveButton(
            l10n,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        ),
      ],
    );
  }

  bool get _hasStickySave => widget.group == _SettingsGroup.registration;

  Widget _saveButton(AppLocalizations l10n, {ButtonStyle? style}) =>
      FilledButton.icon(
        onPressed: _isSaving || _locked ? null : _save,
        style: style,
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
      );

  String _title(AppLocalizations l10n) => switch (widget.group) {
    _SettingsGroup.information => l10n.manageSettingsInfoSection,
    _SettingsGroup.registration => l10n.tournamentManagementRegistration,
  };

  String _groupDescription(AppLocalizations l10n) => switch (widget.group) {
    _SettingsGroup.information => l10n.manageSettingsInfoSectionDescription,
    _SettingsGroup.registration =>
      l10n.manageSettingsRegistrationSectionDescription,
  };

  List<Widget> _fields(
    BuildContext context,
    AppLocalizations l10n,
  ) => switch (widget.group) {
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
    _SettingsGroup.registration => [
      if (_locked)
        _hint(context, l10n.tournamentManagementRegistrationLockedHint)
      else if (_closed)
        _hint(context, l10n.tournamentManagementRegistrationClosedHint),
      _dateField(
        context,
        buttonKey: const ValueKey('registration-opens'),
        label: l10n.tournamentManagementRegistrationStarts,
        value: _registrationStartDate,
        enabled: _settingsEditable,
        onTap: () => _pickDate(
          _registrationStartDate,
          (value) => setState(() => _registrationStartDate = value),
        ),
      ),
      const SizedBox(height: 8),
      _dateField(
        context,
        buttonKey: const ValueKey('registration-deadline'),
        label: l10n.tournamentManagementRegistrationEnds,
        value: _registrationEndDate,
        enabled: _deadlineEditable,
        onTap: () => _pickDate(
          _registrationEndDate,
          (value) => setState(() => _registrationEndDate = value),
        ),
      ),
      const SizedBox(height: 8),
      _dateField(
        context,
        buttonKey: const ValueKey('tournament-opening'),
        label: l10n.tournamentManagementStartDate,
        value: _startDate,
        enabled: _settingsEditable,
        onTap: () => _pickDate(
          _startDate,
          (value) => setState(() => _startDate = value),
        ),
      ),
      const SizedBox(height: 8),
      _dateField(
        context,
        buttonKey: const ValueKey('tournament-closing'),
        label: l10n.tournamentManagementEndDate,
        value: _endDate,
        enabled: _settingsEditable,
        onTap: () =>
            _pickDate(_endDate, (value) => setState(() => _endDate = value)),
      ),
      const Divider(height: 32),
      SwitchListTile(
        key: const ValueKey('registration-public'),
        contentPadding: EdgeInsets.zero,
        value: _visibility == 'PUBLIC',
        title: Text(l10n.tournamentManagementPublic),
        onChanged: _settingsEditable
            ? (value) =>
                  setState(() => _visibility = value ? 'PUBLIC' : 'PRIVATE')
            : null,
      ),
      const SizedBox(height: 12),
      Text(
        l10n.tournamentManagementRegistrationMode,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SegmentedButton<String>(
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 44)),
            segments: [
              ButtonSegment(
                value: 'OPEN',
                label: Text(l10n.tournamentManagementRegistrationModeOpen),
              ),
              ButtonSegment(
                value: 'APPROVAL',
                label: Text(l10n.tournamentManagementRegistrationModeApproval),
              ),
              ButtonSegment(
                value: 'INVITE_ONLY',
                label: Text(
                  l10n.tournamentManagementRegistrationModeInviteOnly,
                ),
              ),
            ],
            selected: {_registrationMode},
            onSelectionChanged: _settingsEditable
                ? (selection) =>
                      setState(() => _registrationMode = selection.first)
                : null,
          ),
        ),
      ),
      if (_hasDoublesContent) ...[
        const Divider(height: 32),
        SwitchListTile(
          key: const ValueKey('registration-pairing'),
          contentPadding: EdgeInsets.zero,
          value: _pairingMode == 'ORGANIZER',
          title: Text(l10n.tournamentManagementPairing),
          subtitle: Text(
            _pairingMode == 'SELF'
                ? l10n.tournamentManagementPairingSelf
                : l10n.tournamentManagementPairingOrganizer,
          ),
          onChanged: _settingsEditable
              ? (value) =>
                    setState(() => _pairingMode = value ? 'ORGANIZER' : 'SELF')
              : null,
        ),
      ],
      if (_showsInvite) ...[
        const Divider(height: 32),
        _inviteSection(context, l10n, _inviteCode!),
      ],
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

  Widget _hint(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );

  Widget _inviteSection(
    BuildContext context,
    AppLocalizations l10n,
    String code,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.manageSettingsInviteCode,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                code,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isSaving || _isActing
                  ? null
                  : () => _copyInvite(code, l10n),
              icon: const Icon(Icons.copy_rounded),
              label: Text(l10n.tournamentManagementCopy),
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
            ),
            OutlinedButton.icon(
              onPressed: _regenerateEnabled
                  ? () => _runAction(
                      () => ref
                          .read(tournamentManagementRepositoryProvider)
                          .regenerateInviteCode(widget.tournament.id),
                      l10n.tournamentManagementRegenerateInviteConfirm,
                    )
                  : null,
              icon: const Icon(Icons.autorenew_rounded),
              label: Text(l10n.tournamentManagementRegenerateInvite),
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _copyInvite(String code, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tournamentManagementInviteCodeCopied)),
    );
  }

  /// Kiểm tra theo đúng thứ tự của web; `null` khi hợp lệ.
  String? _validate(AppLocalizations l10n) => switch (widget.group) {
    _SettingsGroup.information =>
      _nameController.text.trim().isEmpty
          ? l10n.tournamentManagementRequiredFields
          : null,
    _SettingsGroup.registration => _registrationError(l10n),
  };

  String? _registrationError(AppLocalizations l10n) {
    final registrationStart = _registrationStartDate;
    final registrationEnd = _registrationEndDate;
    final start = _startDate;
    final end = _endDate;
    if (registrationStart != null &&
        registrationEnd != null &&
        !_isAfterDateTime(registrationEnd, registrationStart)) {
      return l10n.tournamentManagementRegistrationEndAfterStart;
    }
    if (registrationEnd != null &&
        !_isAfterDateTime(registrationEnd, DateTime.now())) {
      return l10n.tournamentManagementRegistrationDeadlineInFuture;
    }
    if (start != null &&
        registrationEnd != null &&
        _isBeforeDateTime(start, registrationEnd)) {
      return l10n.tournamentManagementStartAfterRegistration;
    }
    if (start != null && end != null && _isBeforeDateTime(end, start)) {
      return l10n.tournamentManagementEndAfterStart;
    }
    if (_closed && !_locked && !_deadlineExtended) {
      return l10n.tournamentManagementClosedDeadlineExtensionOnly;
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
      case _SettingsGroup.registration:
        _addDateUpdate(
          payload,
          'registrationEndDate',
          _registrationEndDate,
          saved.registrationEndDate,
        );
        // Giải đã đóng chỉ gửi hạn chót đăng ký; máy chủ từ chối phần còn lại.
        if (_closed && !_locked) return payload;
        _addDateUpdate(
          payload,
          'registrationStartDate',
          _registrationStartDate,
          saved.registrationStartDate,
        );
        _addDateUpdate(payload, 'startDate', _startDate, saved.startDate);
        _addDateUpdate(payload, 'endDate', _endDate, saved.endDate);
        if (_visibility != _savedVisibility) {
          payload['visibility'] = _visibility;
        }
        final mode = _effectiveRegistrationMode();
        final pairingChanged =
            _hasDoublesContent && _pairingMode != _savedPairingMode;
        if (mode != _savedRegistrationMode || pairingChanged) {
          payload['tournamentConfig'] = {
            ...saved.tournamentConfig,
            'registrationMode': mode,
            if (_hasDoublesContent) 'doublesPairingMode': _pairingMode,
          };
        }
    }
    return payload;
  }

  Widget _dateField(
    BuildContext context, {
    required Key buttonKey,
    required String label,
    required DateTime? value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
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
            key: buttonKey,
            onPressed: enabled ? onTap : null,
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
    if (_isSaving || _locked) return;
    final l10n = AppLocalizations.of(context)!;
    final validationError = _validate(l10n);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .update(widget.tournament.id, _payload());
      if (!mounted) return;
      ref.invalidate(tournamentProvider(widget.tournament.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              _serverMessage(error) ?? l10n.tournamentManagementSaveError,
        );
      }
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
  String? _actionError;

  String get _actionTournamentId;

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function() operation,
    String confirmation, {
    bool destructive = false,
    ValueNotifier<bool>? option,
    String? optionLabel,
  }) async {
    if (_isActing) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: confirmation,
      confirmLabel: l10n.tournamentManagementConfirm,
      destructive: destructive,
      option: option,
      optionLabel: optionLabel,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _isActing = true;
      _actionFailed = false;
      _actionError = null;
    });
    try {
      await operation();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
    } catch (error) {
      if (mounted) {
        setState(() {
          _actionFailed = true;
          _actionError =
              _serverMessage(error) ?? l10n.tournamentManagementActionError;
        });
      }
    } finally {
      // Thao tác nhiều bước có thể đã đổi một phần (vd. đã chốt rồi khai mạc lỗi): luôn tải lại.
      if (mounted) {
        ref.invalidate(tournamentProvider(_actionTournamentId));
        setState(() => _isActing = false);
      }
    }
  }
}

/// Vòng đời giải: mỗi lúc một nút theo việc tiếp theo (công bố, mở đăng ký,
/// chốt đăng ký, khai mạc, kết thúc). Không thao tác nào áp dụng thì ẩn.
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
    // Entity lưu mã đã chuẩn hoá ("registration", không phải "REGISTRATION_OPEN").
    final status = StatusHelper.normalizeTournamentStatus(
      widget.tournament.status,
    );
    final divisionMatches = widget.tournament.divisions.isEmpty
        ? null
        : ref.watch(matchesProvider(id)).asData?.value;
    final hasBracket = divisionMatches?.isNotEmpty ?? false;
    final hasDivisionWithoutBracket =
        divisionMatches != null &&
        widget.tournament.divisions.any(
          (division) =>
              division.status?.toUpperCase() != 'CANCELLED' &&
              !divisionMatches.any((match) => match.divisionId == division.id),
        );
    // Mỗi lúc một nút theo việc tiếp theo (như Web). Khoá/mở từng nội dung nằm ở mục Nội dung.
    final primary = switch (status) {
      AppConstants.statusDraft => _lifecycleButton(
        l10n.tournamentManagementPublish,
        Icons.public_rounded,
        () => _runAction(
          () => ref
              .read(tournamentManagementRepositoryProvider)
              .publishTournament(id),
          l10n.tournamentManagementPublishConfirm,
        ),
      ),
      AppConstants.statusUpcoming => _lifecycleButton(
        l10n.tournamentManagementOpenRegistrationNow,
        Icons.lock_open_rounded,
        () => _runAction(
          () => ref
              .read(tournamentManagementRepositoryProvider)
              .reopenRegistration(id),
          l10n.tournamentManagementOpenRegistrationConfirm,
        ),
      ),
      AppConstants.statusRegistration when !hasBracket => _lifecycleButton(
        l10n.tournamentManagementCloseRegistration,
        Icons.lock_outline_rounded,
        () => _runAction(
          () => ref
              .read(tournamentManagementRepositoryProvider)
              .closeRegistration(id),
          l10n.tournamentManagementCloseRegistrationConfirm,
        ),
      ),
      AppConstants.statusRegistration ||
      AppConstants.statusRegistrationClosed => _lifecycleButton(
        l10n.tournamentManagementStartTournament,
        Icons.play_arrow_rounded,
        () => _start(
          id,
          offerClose: status == AppConstants.statusRegistration,
          confirmation: hasDivisionWithoutBracket
              ? l10n.tournamentManagementStartTournamentMissingBracketConfirm
              : l10n.tournamentManagementStartTournamentConfirm,
        ),
      ),
      AppConstants.statusInProgress => _lifecycleButton(
        l10n.tournamentManagementCompleteTournament,
        Icons.check_circle_outline_rounded,
        () => _runAction(
          () => ref
              .read(tournamentManagementRepositoryProvider)
              .completeTournament(id),
          l10n.tournamentManagementCompleteTournamentConfirm,
        ),
      ),
      _ => null,
    };
    if (primary == null) return const SizedBox.shrink();
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementLifecycle,
      subtitle: l10n.tournamentManagementLifecycleDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          primary,
          // Đã đóng hết: vẫn cần lối mở lại cả giải; chỉ là nút chữ, không phải nút chính.
          if (status == AppConstants.statusRegistrationClosed)
            TextButton(
              onPressed: _isActing
                  ? null
                  : () => _runAction(
                      () => ref
                          .read(tournamentManagementRepositoryProvider)
                          .reopenRegistration(id),
                      l10n.tournamentManagementReopenConfirm,
                    ),
              child: Text(l10n.tournamentManagementReopenRegistration),
            ),
          if (_isActing) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (_actionError case final error?) ...[
            const SizedBox(height: 8),
            _InlineError(text: error),
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

  /// Khai mạc; giải còn mở đăng ký thì hỏi kèm "chốt luôn" (mặc định không).
  /// Tick thì đóng đăng ký trước, đóng lỗi thì không khai mạc.
  Future<void> _start(
    String id, {
    required bool offerClose,
    required String confirmation,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final closeOpen = ValueNotifier(false);
    try {
      await _runAction(
        () async {
          final repository = ref.read(tournamentManagementRepositoryProvider);
          if (offerClose && closeOpen.value) {
            await repository.closeRegistration(id);
          }
          return repository.startTournament(id);
        },
        confirmation,
        option: offerClose ? closeOpen : null,
        optionLabel: offerClose
            ? l10n.tournamentManagementCloseOpenOnStart
            : null,
      );
    } finally {
      closeOpen.dispose();
    }
  }

  Widget _lifecycleButton(
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

/// Thông báo do máy chủ trả về (trường `message`), nếu có.
String? _serverMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final message = data['message'];
  return message is String && message.trim().isNotEmpty ? message : null;
}

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
