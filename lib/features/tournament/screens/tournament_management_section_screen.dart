import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_date_time_picker_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_brands_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_livestream_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_sponsors_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_opening_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_stepper.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/shared/widgets/date_time_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/widgets/rich_text/rich_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  liveOperations,
}

/// The exact thing a manager tapped on the overview; the section opens
/// straight on it (focused field, open group or date picker).
enum TournamentManagementFocus {
  name,
  branding,
  contact,
  venue,
  fee,
  registrationOpens,
  registrationDeadline,
  tournamentOpening,
}

class TournamentManagementSectionScreen extends ConsumerWidget {
  const TournamentManagementSectionScreen({
    super.key,
    required this.tournament,
    required this.section,
    required this.opsWorkspaceRoute,
    required this.actionRouteBase,
    this.unsavedChanges,
    this.focus,
    this.popup = false,
  });

  final Tournament tournament;
  final TournamentManagementSection section;
  final String opsWorkspaceRoute;
  final String actionRouteBase;
  final TournamentManagementFocus? focus;

  /// Shown in a popup: only the focused item, closing itself after a save.
  final bool popup;

  /// Set to true while the information page holds edits that are not saved,
  /// so the hub can ask before leaving the page.
  final ValueNotifier<bool>? unsavedChanges;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _content(context, ref);

  Widget _content(BuildContext context, WidgetRef ref) => switch (section) {
    TournamentManagementSection.information => _TournamentSettingsForm(
      tournament: tournament,
      group: _SettingsGroup.information,
      unsavedChanges: unsavedChanges,
      focus: focus,
      popup: popup,
    ),
    TournamentManagementSection.schedule => TournamentManagementVenuesSection(
      tournamentId: tournament.id,
      editFirstVenue: focus == TournamentManagementFocus.venue,
    ),
    TournamentManagementSection.registration => _TournamentSettingsForm(
      tournament: tournament,
      group: _SettingsGroup.registration,
      focus: focus,
      popup: popup,
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
      focusEntryFee: focus == TournamentManagementFocus.fee,
      popup: popup,
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
  };
}

/// Thanh dưới cố định của trang Thông tin và Đăng ký: đường kẻ mảnh phía trên, có SafeArea đáy.
class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({required this.error, required this.button});

  final String? error;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                _InlineError(text: error!),
                const SizedBox(height: 8),
              ],
              button,
            ],
          ),
        ),
      ),
    );
  }
}

/// Hai nhóm cài đặt. Mỗi nhóm có form và nút Lưu riêng (dính đáy).
enum _SettingsGroup { information, registration }

/// Editable values of the information page, compared by value for dirty checks.
typedef _InfoValues = ({
  String name,
  String description,
  bool hideCardText,
  String prize,
  String phone,
  String email,
});

/// One collapsible group of the information page: the design's `.hd` header
/// with an accent "Thu gọn / Mở" toggle; the body stays mounted while hidden so
/// unsaved edits survive a collapse.
class _InfoGroup extends StatefulWidget {
  const _InfoGroup({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_InfoGroup> createState() => _InfoGroupState();
}

class _InfoGroupState extends State<_InfoGroup> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: ValueKey('info-group-${widget.title}'),
          onTap: () => setState(() => _open = !_open),
          child: LavishGroupHeader(
            widget.title,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (_open
                          ? l10n.manageInfoGroupCollapse
                          : l10n.manageInfoGroupExpand)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.66,
                    color: LavishColors.accent,
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: LavishColors.accent,
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _open,
          maintainState: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Date fields of the registration group that can carry an order error.
enum _RegistrationField { opens, deadline, opening, closing }

/// Form của một nhóm cài đặt. Chỉ gửi các trường thuộc nhóm đó.
class _TournamentSettingsForm extends ConsumerStatefulWidget {
  const _TournamentSettingsForm({
    required this.tournament,
    required this.group,
    this.unsavedChanges,
    this.focus,
    this.popup = false,
  });

  final Tournament tournament;
  final _SettingsGroup group;
  final ValueNotifier<bool>? unsavedChanges;
  final TournamentManagementFocus? focus;
  final bool popup;

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
  late String _prize = widget.tournament.prizeDescription ?? '';
  late final TextEditingController _phoneController = TextEditingController(
    text: _contactText('phone'),
  );
  late final TextEditingController _emailController = TextEditingController(
    text: _contactText('email'),
  );
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

  /// Values last saved (or loaded) for the information page; edits are
  /// "unsaved" while [_current] differs from it.
  late _InfoValues _baseline = _current;

  _InfoValues get _current => (
    name: _nameController.text.trim(),
    description: _description.trim(),
    hideCardText: _hideFeaturedCardText,
    prize: _prize.trim(),
    phone: _phoneController.text.trim(),
    email: _emailController.text.trim(),
  );

  bool get _isInformation => widget.group == _SettingsGroup.information;

  bool get _dirty => _isInformation && _current != _baseline;

  /// Email is not part of the contact block in MANUAL display mode (Web rule).
  bool get _contactIsManual =>
      widget.tournament.contactInfo?['displayMode']?.toString().toUpperCase() ==
      'MANUAL';

  String _contactText(String key) {
    final value = widget.tournament.contactInfo?[key];
    return value is String ? value.trim() : '';
  }

  void _syncDirty() {
    widget.unsavedChanges?.value = _dirty;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (!_isInformation) {
      _openFocusedDate();
      return;
    }
    _baseline = _current;
    _nameController.addListener(_syncDirty);
    _phoneController.addListener(_syncDirty);
    _emailController.addListener(_syncDirty);
  }

  /// Opens the picker of the roadmap row tapped on the overview, once the
  /// page is up. Locked rows stay shut, exactly as their field is.
  void _openFocusedDate() {
    final field = switch (widget.focus) {
      TournamentManagementFocus.registrationOpens => _RegistrationField.opens,
      TournamentManagementFocus.registrationDeadline =>
        _RegistrationField.deadline,
      TournamentManagementFocus.tournamentOpening => _RegistrationField.opening,
      _ => null,
    };
    if (field == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final editable = field == _RegistrationField.deadline
          ? _deadlineEditable
          : _settingsEditable;
      if (!editable) return;
      final picked = await _pickRegistrationDate(field);
      if (!picked && widget.popup && mounted) Navigator.of(context).pop();
    });
  }

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
    _phoneController.dispose();
    _emailController.dispose();
    if (_dirty) widget.unsavedChanges?.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.popup) return _popupBody(l10n);
    final body = _isInformation
        ? _informationGroups(context, l10n)
        : TournamentManagementSectionCard(
            title: _title(l10n),
            subtitle: _groupDescription(l10n),
            showHeader: false,
            child: Column(children: _fields(context, l10n)),
          );
    // Nút Lưu dính đáy, nằm ngoài ListView nên không bị cuộn.
    return Column(
      children: [
        Expanded(
          child: LavishSurface(
            child: ListView(
              padding: _isInformation
                  ? const EdgeInsets.only(bottom: 16)
                  : const EdgeInsets.all(16),
              children: [body],
            ),
          ),
        ),
        _StickySaveBar(
          error: _errorMessage,
          button: _saveButton(l10n),
        ),
      ],
    );
  }

  /// Popup: only the tapped item and its own save button.
  Widget _popupBody(AppLocalizations l10n) {
    final dateField = switch (widget.focus) {
      TournamentManagementFocus.registrationOpens => _RegistrationField.opens,
      TournamentManagementFocus.registrationDeadline =>
        _RegistrationField.deadline,
      TournamentManagementFocus.tournamentOpening => _RegistrationField.opening,
      _ => null,
    };
    if (widget.focus == TournamentManagementFocus.branding) {
      return SingleChildScrollView(
        child: TournamentManagementBrandsSection(tournament: widget.tournament),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.focus == TournamentManagementFocus.name)
                _nameField(l10n)
              else if (widget.focus == TournamentManagementFocus.contact)
                ..._contactFields(l10n)
              else if (dateField != null)
                _registrationDateRow(l10n, dateField),
            ],
          ),
        ),
        _StickySaveBar(error: _errorMessage, button: _saveButton(l10n)),
      ],
    );
  }

  /// Bốn nhóm như Web; mỗi nhóm thu gọn/mở được, chỉ nhóm Chung mở sẵn.
  Widget _informationGroups(BuildContext context, AppLocalizations l10n) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoGroup(
            title: l10n.manageInfoGroupGeneral,
            initiallyExpanded: true,
            children: _generalFields(l10n),
          ),
          _InfoGroup(
            title: l10n.manageInfoGroupIdentity,
            children: [
              TournamentManagementBrandsSection(tournament: widget.tournament),
            ],
          ),
          _InfoGroup(
            title: l10n.manageInfoGroupPrizes,
            children: [
              RichTextField(
                value: _prize,
                label: l10n.manageInfoPrizeLabel,
                onChanged: (html) {
                  if (html == _prize) return;
                  _prize = html;
                  _syncDirty();
                },
              ),
            ],
          ),
          _InfoGroup(
            title: l10n.manageInfoGroupContact,
            children: _contactFields(l10n),
          ),
        ],
      );

  List<Widget> _contactFields(AppLocalizations l10n) => [
    TextField(
      key: const ValueKey('info-contact-phone'),
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: l10n.contactPhone,
        border: _fieldBorder(context),
      ),
    ),
    if (!_contactIsManual) ...[
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('info-contact-email'),
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: l10n.contactEmail,
          border: _fieldBorder(context),
        ),
      ),
    ],
  ];

  bool _hasOrderErrors(AppLocalizations l10n) =>
      widget.group == _SettingsGroup.registration &&
      _registrationOrderErrors(l10n).isNotEmpty;

  Widget _saveButton(AppLocalizations l10n) => LavishButton(
    busy: _isSaving,
    onPressed:
        _isSaving ||
            _locked ||
            _hasOrderErrors(l10n) ||
            (_isInformation && !_dirty)
        ? null
        : _save,
    label: _isSaving
        ? l10n.tournamentManagementSaving
        : _isInformation
        ? l10n.manageInfoSaveChanges
        : l10n.tournamentManagementSave,
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

  void _setHideCardText(bool value) {
    _hideFeaturedCardText = value;
    _syncDirty();
  }

  /// Design `.field`: 12dp radius, 1.5dp neutral border.
  OutlineInputBorder _fieldBorder(BuildContext context) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: LavishColors.of(context).chipLine,
      width: 1.5,
    ),
  );

  Widget _nameField(AppLocalizations l10n) => TextField(
    controller: _nameController,
    autofocus: widget.focus == TournamentManagementFocus.name,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: l10n.tournamentManagementName,
      border: _fieldBorder(context),
    ),
  );

  List<Widget> _generalFields(AppLocalizations l10n) => [
    _nameField(l10n),
    const SizedBox(height: 12),
    // Rich text dùng chung với web: cùng Editor.js nên HTML xuất ra
    // giống hệt, mô tả không bị đổi hình dạng khi lưu từ app.
    RichTextField(
      value: _description,
      label: l10n.tournamentManagementDescription,
      onChanged: (html) {
        // Editor báo về cả lúc vừa sẵn sàng (giá trị chuẩn hoá) nên
        // chỉ setState khi thực sự khác.
        if (html == _description) return;
        _description = html;
        _syncDirty();
      },
    ),
    const SizedBox(height: 12),
    // Design 16: `.li` row with the green switch on the right.
    LavishRow(
      key: const ValueKey('hide-featured-card-text'),
      title: l10n.tournamentManagementHideFeaturedCardText,
      subtitle: l10n.tournamentManagementHideFeaturedCardTextDescription,
      onTap: _isSaving ? null : () => _setHideCardText(!_hideFeaturedCardText),
      trailing: [
        LavishSwitch(
          value: _hideFeaturedCardText,
          onChanged: _isSaving ? null : _setHideCardText,
        ),
      ],
    ),
  ];

  List<Widget> _fields(BuildContext context, AppLocalizations l10n) => [
    if (_locked)
      _hint(context, l10n.tournamentManagementRegistrationLockedHint)
    else if (_closed)
      _hint(context, l10n.tournamentManagementRegistrationClosedHint),
    _registrationDateRow(l10n, _RegistrationField.opens),
    const SizedBox(height: 12),
    _registrationDateRow(l10n, _RegistrationField.deadline),
    const SizedBox(height: 12),
    _registrationDateRow(l10n, _RegistrationField.opening),
    const SizedBox(height: 12),
    _registrationDateRow(l10n, _RegistrationField.closing),
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
  ];

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

  /// Order errors per field, in the same order as the Web rules; empty while
  /// the registration is locked (nothing is editable then).
  Map<_RegistrationField, String> _registrationOrderErrors(
    AppLocalizations l10n,
  ) {
    if (_locked) return const {};
    final registrationStart = _registrationStartDate;
    final registrationEnd = _registrationEndDate;
    final start = _startDate;
    final end = _endDate;
    final errors = <_RegistrationField, String>{};
    if (registrationStart != null &&
        registrationEnd != null &&
        !_isAfterDateTime(registrationEnd, registrationStart)) {
      errors[_RegistrationField.deadline] =
          l10n.tournamentManagementRegistrationEndAfterStart;
    } else if (registrationEnd != null &&
        !_isAfterDateTime(registrationEnd, DateTime.now())) {
      errors[_RegistrationField.deadline] =
          l10n.tournamentManagementRegistrationDeadlineInFuture;
    }
    if (start != null &&
        registrationEnd != null &&
        _isBeforeDateTime(start, registrationEnd)) {
      errors[_RegistrationField.opening] =
          l10n.tournamentManagementStartAfterRegistration;
    }
    if (start != null && end != null && _isBeforeDateTime(end, start)) {
      errors[_RegistrationField.closing] =
          l10n.tournamentManagementEndAfterStart;
    }
    return errors;
  }

  String? _registrationError(AppLocalizations l10n) {
    final orderErrors = _registrationOrderErrors(l10n);
    if (orderErrors.isNotEmpty) return orderErrors.values.first;
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
        final current = _current;
        if (current.prize != _baseline.prize) {
          payload['prizeDescription'] = current.prize;
        }
        if (current.phone != _baseline.phone ||
            current.email != _baseline.email) {
          payload['contactInfo'] = _contactPayload(current);
        }
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

  /// The server replaces the whole `contactInfo` JSON, so every other key
  /// (hidden, displayMode, custom fields) is sent back untouched.
  Map<String, dynamic> _contactPayload(_InfoValues current) {
    final info = <String, dynamic>{...?widget.tournament.contactInfo};
    void put(String key, String value) =>
        value.isEmpty ? info.remove(key) : info[key] = value;
    put('phone', current.phone);
    if (!_contactIsManual) put('email', current.email);
    return info;
  }

  Widget _dateField(
    BuildContext context, {
    required Key buttonKey,
    required String label,
    required DateTime? value,
    required bool enabled,
    required VoidCallback onTap,
    String? error,
  }) => DateTimeField(
    buttonKey: buttonKey,
    label: label,
    placeholder: AppLocalizations.of(context)!.tournamentManagementChooseDate,
    value: value,
    onTap: enabled ? onTap : null,
    errorText: error,
  );

  /// "Label · limit" for the popup subtitle; just the label without a bound.
  String _pickerSubtitle(
    String label,
    DateTime? bound,
    String Function(String date) limit,
  ) => bound == null
      ? label
      : '$label · ${limit(DateFormat('dd/MM/yyyy HH:mm').format(bound.toLocal()))}';

  DateTime _laterOf(DateTime? first, DateTime second) =>
      first != null && first.isAfter(second) ? first : second;

  Widget _registrationDateRow(AppLocalizations l10n, _RegistrationField field) {
    final (key, label, value, enabled) = switch (field) {
      _RegistrationField.opens => (
        'registration-opens',
        l10n.tournamentManagementRegistrationStarts,
        _registrationStartDate,
        _settingsEditable,
      ),
      _RegistrationField.deadline => (
        'registration-deadline',
        l10n.tournamentManagementRegistrationEnds,
        _registrationEndDate,
        _deadlineEditable,
      ),
      _RegistrationField.opening => (
        'tournament-opening',
        l10n.tournamentManagementStartDate,
        _startDate,
        _settingsEditable,
      ),
      _RegistrationField.closing => (
        'tournament-closing',
        l10n.tournamentManagementEndDate,
        _endDate,
        _settingsEditable,
      ),
    };
    return _dateField(
      context,
      buttonKey: ValueKey(key),
      label: label,
      value: value,
      enabled: enabled,
      error: _registrationOrderErrors(l10n)[field],
      onTap: () => _pickRegistrationDate(field),
    );
  }

  /// True when a date was chosen. In a popup the choice is saved at once.
  Future<bool> _pickRegistrationDate(_RegistrationField field) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await switch (field) {
      _RegistrationField.opens => _pickDate(
        _registrationStartDate,
        (value) => setState(() => _registrationStartDate = value),
        subtitle: _pickerSubtitle(
          l10n.tournamentManagementRegistrationStarts,
          _registrationEndDate,
          l10n.tournamentManagementDateLimitRegistrationStartMax,
        ),
        maxDate: _registrationEndDate,
      ),
      _RegistrationField.deadline => _pickDate(
        _registrationEndDate,
        (value) => setState(() => _registrationEndDate = value),
        subtitle: _pickerSubtitle(
          l10n.tournamentManagementRegistrationEnds,
          _registrationStartDate,
          l10n.tournamentManagementDateLimitDeadlineMin,
        ),
        minDate: _laterOf(_registrationStartDate, DateTime.now()),
        endOfDayChip: true,
      ),
      _RegistrationField.opening => _pickDate(
        _startDate,
        (value) => setState(() => _startDate = value),
        subtitle: _pickerSubtitle(
          l10n.tournamentManagementStartDate,
          _registrationEndDate,
          l10n.tournamentManagementDateLimitOpeningMin,
        ),
        minDate: _registrationEndDate,
      ),
      _RegistrationField.closing => _pickDate(
        _endDate,
        (value) => setState(() => _endDate = value),
        subtitle: _pickerSubtitle(
          l10n.tournamentManagementEndDate,
          _startDate,
          l10n.tournamentManagementDateLimitClosingMin,
        ),
        minDate: _startDate,
      ),
    };
    if (picked && widget.popup && mounted) await _save();
    return picked;
  }

  Future<bool> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onSelected, {
    required String subtitle,
    DateTime? minDate,
    DateTime? maxDate,
    bool endOfDayChip = false,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await SocialDateTimePickerSheet.show(
      context,
      current?.toLocal() ?? _laterOf(minDate?.toLocal(), today),
      subtitle: subtitle,
      minDate: minDate?.toLocal(),
      maxDate: maxDate?.toLocal(),
      showEndOfDayChip: endOfDayChip,
    );
    if (picked == null || !mounted) return false;
    onSelected(picked);
    return true;
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
      if (_isInformation) {
        _baseline = _current;
        widget.unsavedChanges?.value = false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
      if (widget.popup) Navigator.of(context).pop();
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
    String? requiredAcknowledgement,
  }) async {
    if (_isActing) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: confirmation,
      confirmLabel: l10n.tournamentManagementConfirm,
      destructive: destructive,
      requiredAcknowledgement: requiredAcknowledgement,
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
  const TournamentLifecycleCard({
    super.key,
    required this.tournament,
    this.showLifecycle = true,
    this.onShare,
    this.onDelete,
  });

  final Tournament tournament;

  /// False renders only the "Khác" group (the step bar and the next-step
  /// button then live in the page header instead).
  final bool showLifecycle;

  /// Rows of the "Khác" group; the group is hidden when both are null.
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

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
    if (!widget.showLifecycle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _otherRows(l10n),
      );
    }
    final id = widget.tournament.id;
    // Entity lưu mã đã chuẩn hoá ("registration", không phải "REGISTRATION_OPEN").
    final status = StatusHelper.normalizeTournamentStatus(
      widget.tournament.status,
    );
    final divisionMatches = widget.tournament.divisions.isEmpty
        ? null
        : ref.watch(matchesProvider(id)).asData?.value;
    final hasDivisionWithoutBracket =
        divisionMatches != null &&
        widget.tournament.divisions.any(
          (division) =>
              division.status?.toUpperCase() != 'CANCELLED' &&
              !divisionMatches.any((match) => match.divisionId == division.id),
        );
    // Phí công bố do Backend cấu hình: còn phí thì khoá nút Công bố (Backend
    // cũng từ chối), App không tự tính hay thanh toán phí này.
    final publishFee = status == AppConstants.statusDraft
        ? ref
                  .watch(
                    lifecyclePublishFeeProvider((
                      isClub: widget.tournament.communityId?.isNotEmpty == true,
                      isRanked: widget.tournament.isRanked,
                    )),
                  )
                  .asData
                  ?.value ??
              0
        : 0;
    final fullCapacity = status == AppConstants.statusRegistration
        ? lifecycleCapacityFull(widget.tournament)
        : null;
    // Mỗi lúc một nút theo việc tiếp theo (như Web). Khoá/mở từng nội dung nằm ở mục Nội dung.
    final primary = switch (status) {
      AppConstants.statusDraft => _lifecycleButton(
        l10n.tournamentManagementPublish,
        () => _runAction(
          () => ref
              .read(tournamentManagementRepositoryProvider)
              .publishTournament(id),
          l10n.tournamentManagementPublishConfirm,
        ),
        blocked: publishFee > 0,
      ),
      AppConstants.statusUpcoming => _lifecycleButton(
        l10n.tournamentManagementOpenRegistrationNow,
        () => _reopen(id, l10n.tournamentManagementOpenRegistrationConfirm),
      ),
      AppConstants.statusRegistration => _lifecycleButton(
        l10n.tournamentManagementCloseRegistration,
        () => _closeRegistration(id, l10n),
      ),
      AppConstants.statusRegistrationClosed => _lifecycleButton(
        l10n.tournamentManagementStartTournament,
        () => _startTournament(id, hasDivisionWithoutBracket),
      ),
      AppConstants.statusInProgress => _lifecycleButton(
        l10n.tournamentManagementCompleteTournament,
        () => _runAction(
          () => ref
              .read(tournamentManagementRepositoryProvider)
              .completeTournament(id),
          l10n.tournamentManagementCompleteTournamentConfirm,
        ),
      ),
      _ => null,
    };
    // Đã kết thúc vẫn hiện thanh bước (không còn nút); đã huỷ thì ẩn thẻ.
    if (primary == null && lifecycleStepIndex(status) == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifecycleStepBar(status: status),
        if (fullCapacity != null)
          LifecycleCapacityBanner(
            occupied: fullCapacity.occupied,
            max: fullCapacity.max,
          ),
        if (primary != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Expanded(child: primary),
                // Đã đóng hết: vẫn cần lối mở lại cả giải; chỉ là nút viền, không phải nút chính.
                if (status == AppConstants.statusRegistrationClosed) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: LavishButton(
                      dense: true,
                      kind: LavishButtonKind.outline,
                      label: l10n.tournamentManagementReopenRegistration,
                      onPressed: _isActing
                          ? null
                          : () => _reopen(
                              id,
                              l10n.tournamentManagementReopenConfirm,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        // The fee is configured by the Backend and paid on the Web: the App
        // only states the status and why publishing is locked.
        if (publishFee > 0) ...[
          LavishGroupHeader(l10n.lifecyclePublishFeeGroup),
          LavishRow(
            key: const ValueKey('lifecycle-publish-blocked'),
            leading: const LavishIconBox(
              tone: LavishTone.bad,
              child: Text('₫', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            title: l10n.lifecyclePublishFeeUnpaid,
            subtitle: l10n.lifecyclePublishFeeBlocked(
              lifecycleMoney(context, publishFee),
            ),
            subtitleMaxLines: 6,
          ),
        ],
        if (_isActing)
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: LinearProgressIndicator(),
          ),
        if (_actionError case final error?)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _InlineError(text: error),
          ),
        ..._otherRows(l10n),
      ],
    );
  }

  /// The "Khác" group (share / delete); empty when neither action is wired.
  List<Widget> _otherRows(AppLocalizations l10n) => [
    if (widget.onShare != null || widget.onDelete != null) ...[
      LavishGroupHeader(l10n.manageSettingsOtherSection),
      if (widget.onShare != null)
        LavishRow(
          key: const ValueKey('lifecycle-share'),
          leading: const LavishIconBox(
            tone: LavishTone.neutral,
            child: Icon(Icons.share_outlined),
          ),
          title: l10n.share,
          onTap: widget.onShare,
        ),
      if (widget.onDelete != null)
        LavishRow(
          key: const ValueKey('lifecycle-delete'),
          leading: const LavishIconBox(
            tone: LavishTone.bad,
            child: Icon(Icons.delete_outline_rounded),
          ),
          title: l10n.deleteTournament,
          titleColor: LavishColors.bad,
          onTap: _isActing ? null : widget.onDelete,
        ),
    ],
  ];

  Future<void> _closeRegistration(String id, AppLocalizations l10n) =>
      _runAction(
        () => ref
            .read(tournamentManagementRepositoryProvider)
            .closeRegistration(id),
        l10n.tournamentManagementCloseRegistrationConfirm,
      );

  /// Mở (lại) đăng ký cả giải. Hạn cấp giải đã qua thì hỏi hạn mới trước,
  /// vì server từ chối mở lại khi thiếu hạn mới.
  Future<void> _reopen(String id, String confirmation) async {
    final currentDeadline = widget.tournament.registrationEndDate;
    DateTime? newDeadline;
    if (currentDeadline != null && !currentDeadline.isAfter(DateTime.now())) {
      newDeadline = await pickTournamentManagementDeadline(context);
      if (newDeadline == null || !mounted) return;
    }
    await _runAction(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .reopenRegistration(id, registrationEndDate: newDeadline),
      confirmation,
    );
  }

  /// Khai mạc: còn hạng mục mở đăng ký thì mở sheet chọn hạng mục cần đóng
  /// trước khi khai mạc; không hạng mục nào mở thì giữ hộp thoại xác nhận cũ.
  Future<void> _startTournament(
    String id,
    bool hasDivisionWithoutBracket,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isActing) return;
    setState(() {
      _isActing = true;
      _actionFailed = false;
      _actionError = null;
    });
    List<Map<String, dynamic>> divisions;
    try {
      divisions = await ref
          .read(tournamentManagementRepositoryProvider)
          .getManageDivisions(id);
    } catch (error) {
      if (mounted) {
        setState(() {
          _actionFailed = true;
          _actionError =
              _serverMessage(error) ?? l10n.tournamentManagementActionError;
          _isActing = false;
        });
      }
      return;
    }
    if (!mounted) return;
    final status = StatusHelper.normalizeTournamentStatus(
      widget.tournament.status,
    );
    final hasOpenDivision = divisions.any(
      (division) => divisionRegistrationOpen(division, status),
    );
    if (!hasOpenDivision) {
      setState(() => _isActing = false);
      await _runAction(
        () => ref
            .read(tournamentManagementRepositoryProvider)
            .startTournament(id),
        hasDivisionWithoutBracket
            ? l10n.tournamentManagementStartTournamentMissingBracketConfirm
            : l10n.tournamentManagementStartTournamentConfirm,
        // Khai mạc khoá đăng ký mọi nội dung: BTC phải tick đồng ý mới bấm được.
        requiredAcknowledgement: l10n.tournamentManagementStartCloseAll,
      );
      return;
    }
    setState(() => _isActing = false);
    final started = await LifecycleOpeningSheet.show(
      context,
      tournament: widget.tournament,
      divisions: divisions,
    );
    if (!mounted || started != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
  }

  /// The one next-step button (design `.btn`); [blocked] greys it out.
  Widget _lifecycleButton(
    String label,
    VoidCallback onPressed, {
    bool blocked = false,
  }) => LavishButton(
    dense: true,
    label: label,
    onPressed: _isActing || blocked ? null : onPressed,
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
