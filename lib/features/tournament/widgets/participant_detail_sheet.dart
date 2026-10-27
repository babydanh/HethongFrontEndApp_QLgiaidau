import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sheet hồ sơ VĐV chi tiết của BTC (task 3.2, đối chiếu modal chi tiết của
/// Web `RegistrationTab`): trạng thái + thanh toán, liên hệ từng thành viên
/// (khách sửa được tên/email/SĐT qua `PATCH .../entry`), ghi chú nội bộ
/// (`PATCH .../note`), câu trả lời form tùy chỉnh, gán seed, khoá/mở roster
/// bóng đá, xoá VĐV ảo, duyệt/từ chối. Mọi thao tác ghi chống gửi lặp và lỗi
/// server hiển thị nguyên văn (`tournamentSheetServerMessage`).
class ParticipantDetailSheet extends ConsumerStatefulWidget {
  const ParticipantDetailSheet({
    super.key,
    required this.tournamentId,
    required this.participant,
    required this.tournamentStatus,
    this.divisionName,
    this.pairFormat = false,
    this.onRefresh,
  });

  final String tournamentId;
  final OrganizerOpsParticipant participant;

  /// Trạng thái giải, giữ tham số cho nơi gọi (màn quản lý) — Web footer modal
  /// không khoá nút theo trạng thái giải nên sheet cũng không dùng để ẩn nút.
  final String tournamentStatus;
  final String? divisionName;

  /// Nội dung đôi: tiêu đề kèm badge "Cặp" như Web.
  final bool pairFormat;

  /// Làm mới danh sách VĐV ở nơi mở sheet (gọi sau mỗi thao tác ghi thành công).
  final Future<void> Function()? onRefresh;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required OrganizerOpsParticipant participant,
    required String tournamentStatus,
    String? divisionName,
    bool pairFormat = false,
    Future<void> Function()? onRefresh,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => ParticipantDetailSheet(
      tournamentId: tournamentId,
      participant: participant,
      tournamentStatus: tournamentStatus,
      divisionName: divisionName,
      pairFormat: pairFormat,
      onRefresh: onRefresh,
    ),
  );

  @override
  ConsumerState<ParticipantDetailSheet> createState() =>
      _ParticipantDetailSheetState();
}

class _ParticipantDetailSheetState
    extends ConsumerState<ParticipantDetailSheet> {
  static const _noteMaxLength = 2000;
  static const _phoneMaxLength = 20;
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool _busy = false;
  String? _error;
  late final TextEditingController _noteController;
  late final TextEditingController _seedController;
  bool _rosterLocked = false;

  // Chỉnh sửa liên hệ: chỉ thành viên khách (không tài khoản) sửa được, giống
  // Web `ParticipantContactEditor` (tài khoản đã liên kết là chỉ đọc).
  bool _editingContacts = false;
  bool _savingContacts = false;
  String? _contactError;
  final _contactFields = <_GuestContactField>[];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: participantNote(participant));
    _seedController = TextEditingController(
      text: participant.seed?.toString() ?? '',
    );
    _rosterLocked = participant.rosterLockedAt != null;
  }

  OrganizerOpsParticipant get participant => widget.participant;

  /// BTC sửa được liên hệ chỉ khi server cho phép (`canOrganizerEdit`) và hồ
  /// sơ có thành viên khách (tài khoản đã liên kết là chỉ đọc, như Web).
  bool get _canEditContacts =>
      participant.canOrganizerEdit && _guestContacts(participant).isNotEmpty;

  @override
  void dispose() {
    _noteController.dispose();
    _seedController.dispose();
    for (final field in _contactFields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    bool closeOnSuccess = false,
  }) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
      if (!mounted) return true;
      if (closeOnSuccess) {
        Navigator.of(context).pop();
      }
      await widget.onRefresh?.call();
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _error = tournamentSheetServerMessage(error));
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ghi chú nội bộ BTC: sheet vẫn mở, danh sách được làm mới (spec 3.2).
  Future<void> _saveNote() async {
    final saved = await _run(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .updateParticipantNote(
            widget.tournamentId,
            participant.id,
            _noteController.text.trim(),
          ),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.participantDetailNoteSaved,
          ),
        ),
      );
    }
  }

  /// Gán seed nhanh (`PATCH /tournaments/:id/seeds`, một dòng).
  Future<void> _saveSeed() async {
    final l10n = AppLocalizations.of(context)!;
    final seed = int.tryParse(_seedController.text.trim());
    if (seed == null || seed < 1) {
      setState(() => _error = l10n.participantDetailSeedInvalid);
      return;
    }
    final saved = await _run(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .updateTournamentSeeds(widget.tournamentId, [
            {'participantId': participant.id, 'seed': seed},
          ]),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.participantDetailSeedSaved,
          ),
        ),
      );
    }
  }

  /// Duyệt / từ chối: từ chối có confirm, xong đóng sheet (Web đóng modal).
  Future<void> _setStatus(String status) async {
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
      if (!confirmed || !mounted || _busy) return;
    }
    await _run(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .updateParticipantStatus(widget.tournamentId, participant.id, status),
      closeOnSuccess: true,
    );
  }

  /// Khoá/mở roster đội bóng, sheet vẫn mở và nút đổi nhãn ngay.
  Future<void> _toggleRosterLock() async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(tournamentManagementRepositoryProvider);
    final lock = !_rosterLocked;
    final saved = await _run(
      () => lock
          ? repo.lockParticipantRoster(widget.tournamentId, participant.id)
          : repo.unlockParticipantRoster(widget.tournamentId, participant.id),
    );
    if (saved && mounted) {
      setState(() => _rosterLocked = lock);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lock
                ? l10n.participantDetailRosterLocked
                : l10n.participantDetailRosterUnlocked,
          ),
        ),
      );
    }
  }

  /// Xoá VĐV ảo (route `DELETE .../participants/:pid/mock` của Web), có confirm.
  Future<void> _deleteMock() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.participantDetailDeleteMock,
      message: l10n.participantDetailDeleteMockConfirm(
        participantLabel(
          teamName: participant.teamName,
          players: participant.players,
        ),
      ),
      confirmLabel: l10n.participantDetailDeleteMock,
      destructive: true,
    );
    if (!confirmed || !mounted || _busy) return;
    final saved = await _run(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .deleteMockParticipant(widget.tournamentId, participant.id),
      closeOnSuccess: true,
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.participantDetailMockDeleted,
          ),
        ),
      );
    }
  }

  void _startContactEdit() {
    for (final field in _contactFields) {
      field.dispose();
    }
    _contactFields
      ..clear()
      ..addAll(
        _guestContacts(participant).map(
          (guest) => _GuestContactField(
            slot: guest.slot,
            key: guest.key,
            name: TextEditingController(text: guest.name),
            email: TextEditingController(text: guest.email),
            phone: TextEditingController(text: guest.phone),
          ),
        ),
      );
    setState(() {
      _editingContacts = true;
      _contactError = null;
    });
  }

  void _cancelContactEdit() {
    for (final field in _contactFields) {
      field.dispose();
    }
    _contactFields.clear();
    setState(() {
      _editingContacts = false;
      _contactError = null;
    });
  }

  /// Lưu liên hệ khách đã sửa: chỉ gửi các dòng thật sự khác bản gốc, payload
  /// `{ members: [{ slot, name, email, phone, expectedKey }] }` như Web.
  Future<void> _saveContacts() async {
    final l10n = AppLocalizations.of(context)!;
    String? validationError;
    final emails = <String>{};
    final members = <Map<String, dynamic>>[];
    for (final field in _contactFields) {
      final name = field.name.text.trim();
      final email = field.email.text.trim();
      final phone = field.phone.text.trim();
      if (name.isEmpty) {
        validationError = l10n.participantDetailNameRequired;
      } else if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
        validationError = l10n.participantDetailEmailInvalid;
      } else if (phone.length > _phoneMaxLength) {
        validationError = l10n.participantDetailPhoneTooLong;
      } else if (email.isNotEmpty && !emails.add(email.toLowerCase())) {
        // Web bỏ qua email trống/không hợp lệ khi soi trùng
        // (entry-edit-draft.ts), nên hai khách cùng không email vẫn lưu được.
        validationError = l10n.participantDetailEmailDuplicate;
      }
      if (validationError != null) break;
      final original = _guestContacts(
        participant,
      ).firstWhere((guest) => guest.slot == field.slot);
      final changed =
          name != original.name ||
          email != original.email ||
          phone != original.phone;
      if (!changed) continue;
      members.add({
        'slot': field.slot,
        'name': name,
        'email': email.isEmpty ? null : email,
        'phone': phone.isEmpty ? null : phone,
        'expectedKey': field.key,
      });
    }
    if (validationError != null) {
      setState(() => _contactError = validationError);
      return;
    }
    if (members.isEmpty) {
      _cancelContactEdit();
      return;
    }
    setState(() {
      _savingContacts = true;
      _contactError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateOrganizerEntry(widget.tournamentId, participant.id, {
            'members': members,
          });
      if (!mounted) return;
      for (final field in _contactFields) {
        field.dispose();
      }
      _contactFields.clear();
      setState(() {
        _editingContacts = false;
        _savingContacts = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.participantDetailEntrySaved)));
      await widget.onRefresh?.call();
    } catch (error) {
      if (mounted) {
        setState(() {
          _contactError = tournamentSheetServerMessage(error);
          _savingContacts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = participant.teamStatus.toUpperCase();
    final pending = const {'PENDING', 'PENDING_APPROVAL'}.contains(status);
    final isFootball = participant.footballTeamId != null;
    final approved = status == 'COMPLETE';
    // Như Web footer: nút xoá VĐV ảo chỉ cần hồ sơ có mock; nút roster hiện
    // với đội bóng và CHỈ disable khi dòng chưa duyệt, không khoá theo
    // trạng thái giải (RegistrationTab.tsx:1825-1880).
    final canDeleteMock = participant.hasMockMember;

    final actions = <Widget>[
      if (pending) ...[
        FilledButton(
          key: const ValueKey('participant-detail-approve'),
          onPressed: _busy ? null : () => _setStatus('COMPLETE'),
          child: Text(l10n.tournamentManagementApprove),
        ),
        OutlinedButton(
          key: const ValueKey('participant-detail-reject'),
          onPressed: _busy ? null : () => _setStatus('REJECTED'),
          child: Text(l10n.tournamentManagementReject),
        ),
      ],
      if (isFootball)
        OutlinedButton.icon(
          key: const ValueKey('participant-detail-roster-lock'),
          onPressed: _busy || !approved ? null : _toggleRosterLock,
          icon: Icon(
            _rosterLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
          ),
          label: Text(
            _rosterLocked
                ? l10n.participantDetailUnlockRoster
                : l10n.participantDetailLockRoster,
          ),
        ),
      if (canDeleteMock)
        OutlinedButton(
          key: const ValueKey('participant-detail-delete-mock'),
          onPressed: _busy ? null : _deleteMock,
          style: OutlinedButton.styleFrom(foregroundColor: colors.error),
          child: Text(l10n.participantDetailDeleteMock),
        ),
    ];

    return TournamentManageSheet(
      title: participantLabel(
        teamName: participant.teamName,
        players: participant.players,
      ),
      busy: _busy,
      actions: actions.isEmpty ? null : actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: 12),
          _contactSection(context),
          const SizedBox(height: 12),
          _noteSection(context),
          if (participantFormAnswers(
            participant.customResponses,
            l10n,
          ).isNotEmpty) ...[
            const SizedBox(height: 12),
            _formAnswersSection(context),
          ],
          const SizedBox(height: 12),
          _seedSection(context),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = participant.teamStatus.toUpperCase();
    final (statusLabel, statusColor) = _statusStyle(l10n, colors, status);
    final free = participant.entryFee == null || participant.entryFee! <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: participant.isPaid
                    ? colors.bgSurface
                    : colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                participant.isPaid
                    ? (free
                          ? l10n.participantDetailFreeEntry
                          : l10n.participantDetailPaid)
                    : l10n.participantDetailUnpaid,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (participant.isWildcard)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.participantDetailWildcard,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          [
            widget.pairFormat
                ? l10n.participantDetailPairBadge
                : l10n.participantDetailSingleBadge,
            if (widget.divisionName?.isNotEmpty == true)
              widget.divisionName!
            else
              l10n.participantDetailUnassignedDivision,
            if (participant.registeredAt != null)
              DateFormat('dd/MM/yyyy HH:mm').format(participant.registeredAt!),
          ].join(' · '),
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        // Dòng nguồn import: "Nguồn hồ sơ: Excel · file.xlsx" (Web hiện một
        // dòng duy nhất, sourceFileName/SheetName/RowIndex chỉ để phục vụ dòng này).
        if (_registrationSourceLine(l10n) case final sourceLine?) ...[
          const SizedBox(height: 6),
          Text(
            sourceLine,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
        // Thanh toán: chỉ hiện khi có lệ phí hoặc có giao dịch (như Web).
        if ((participant.entryFee ?? 0) > 0 || participant.payment != null) ...[
          const SizedBox(height: 8),
          Text(
            [
              l10n.participantDetailPayment,
              if ((participant.entryFee ?? 0) > 0)
                '${NumberFormat.decimalPattern('vi_VN').format(participant.entryFee!.round())}₫',
              if (participant.payment?['transactionReference'] != null)
                '${l10n.participantDetailPaymentRef}: '
                    '${participant.payment!['transactionReference']}',
              // Ngày thanh toán của giao dịch hệ thống (Web formatDate).
              if (_paymentPaidAt != null)
                DateFormat('dd/MM/yyyy').format(_paymentPaidAt!),
            ].join(' · '),
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  DateTime? get _paymentPaidAt {
    final raw = participant.payment?['paidAt'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  /// Một dòng nguồn như Web (`selectedSourceLine`): nhãn nguồn đã biết hoặc
  /// key humanize, nối tên file nếu có. Null khi hồ sơ tự đăng ký.
  String? _registrationSourceLine(AppLocalizations l10n) {
    final source = participant.customResponses['importedFrom']
        ?.toString()
        .trim();
    final fileName = participant.customResponses['sourceFileName']
        ?.toString()
        .trim();
    if ((source == null || source.isEmpty) &&
        (fileName == null || fileName.isEmpty)) {
      return null;
    }
    final label = source == null || source.isEmpty
        ? null
        : switch (source) {
            'ORGANIZER_DIRECT' => l10n.participantSourceOrganizerDirect,
            'MANUAL_EMAIL' => l10n.participantSourceManualEmail,
            'EXCEL' => l10n.participantSourceExcel,
            'AI_EXCEL' => l10n.participantSourceAiExcel,
            'GOOGLE_FORM' => l10n.participantSourceGoogleForm,
            _ => _humanizeResponseKey(source),
          };
    return [
      l10n.participantDetailRegistrationSource,
      ?label,
      if (fileName != null && fileName.isNotEmpty) fileName,
    ].join(' · ');
  }

  (String, Color) _statusStyle(
    AppLocalizations l10n,
    AppColorsExtension colors,
    String status,
  ) => switch (status) {
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
    'REJECTED' => (l10n.tournamentManagementParticipantRejected, colors.error),
    'KICKED' => (l10n.tournamentManagementParticipantRemoved, colors.textMuted),
    _ => (l10n.tournamentManagementStatusOther, colors.textSecondary),
  };

  Widget _contactSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final guests = _guestContacts(participant);
    final members = participant.members;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.participantDetailContact,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Nút bút chì chỉ khi BTC sửa được và có khách để sửa.
                if (_canEditContacts && !_editingContacts)
                  IconButton(
                    key: const ValueKey('participant-contact-edit'),
                    tooltip: l10n.participantDetailEditContacts,
                    onPressed: _busy ? null : _startContactEdit,
                    icon: const Icon(Icons.edit_rounded, size: 20),
                  ),
              ],
            ),
            if (members.isEmpty && guests.isEmpty)
              Text(
                l10n.participantDetailNoMembers,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              )
            else ...[
              for (final member in members) _memberRow(context, member),
              // Thành viên khách: đọc, hoặc thành ô nhập khi đang sửa.
              if (!_editingContacts)
                for (final guest in guests) _guestRow(context, guest),
            ],
            if (_editingContacts) ...[
              for (final field in _contactFields) _guestEditRow(context, field),
              if (_contactError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _contactError!,
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('participant-contact-cancel'),
                    onPressed: _savingContacts ? null : _cancelContactEdit,
                    child: Text(l10n.tournamentManagementCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('participant-contact-save'),
                    onPressed: _savingContacts ? null : _saveContacts,
                    child: Text(l10n.participantDetailSave),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _memberRow(BuildContext context, OrganizerOpsMember member) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          UserAvatarTap(
            userId: member.userId,
            name: member.fullName,
            imageUrl: member.avatarUrl,
            size: 34,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    member.email ?? l10n.participantDetailHiddenEmail,
                    member.phoneNumber ?? l10n.participantDetailNoPhone,
                  ].join(' · '),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestRow(BuildContext context, _GuestContact guest) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Text(
              guest.name.trim().isNotEmpty ? guest.name.trim()[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    guest.email.isEmpty
                        ? l10n.participantDetailHiddenEmail
                        : guest.email,
                    guest.phone.isEmpty
                        ? l10n.participantDetailNoPhone
                        : guest.phone,
                  ].join(' · '),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestEditRow(BuildContext context, _GuestContactField field) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.participantDetailGuestSlot(field.slot),
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            key: ValueKey('participant-contact-name-${field.slot}'),
            controller: field.name,
            enabled: !_savingContacts,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: l10n.participantDetailName,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('participant-contact-email-${field.slot}'),
            controller: field.email,
            enabled: !_savingContacts,
            keyboardType: TextInputType.emailAddress,
            maxLength: 254,
            decoration: InputDecoration(
              labelText: l10n.participantDetailEmail,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('participant-contact-phone-${field.slot}'),
            controller: field.phone,
            enabled: !_savingContacts,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.participantDetailPhone,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.participantDetailNoteTitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('participant-detail-note'),
          controller: _noteController,
          enabled: !_busy,
          maxLength: _noteMaxLength,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.participantDetailNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            key: const ValueKey('participant-detail-note-save'),
            onPressed: _busy ? null : _saveNote,
            child: Text(l10n.participantDetailNoteSave),
          ),
        ),
      ],
    );
  }

  Widget _formAnswersSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final answers = participantFormAnswers(participant.customResponses, l10n);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.participantDetailFormAnswers,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final answer in answers)
              Padding(
                key: ValueKey('participant-answer-${answer.$1}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        answer.$1,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _answerValue(context, answer.$2, answer.$3),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _answerValue(BuildContext context, String value, String? url) {
    final colors = context.colors;
    final style = TextStyle(color: colors.textPrimary, fontSize: 13);
    // Tệp đính kèm: tên file (hoặc URL trần) bấm mở ngoài app như Web.
    final parsed = url != null ? Uri.tryParse(url) : null;
    if (parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        parsed.host.isNotEmpty) {
      return InkWell(
        onTap: () => launchUrl(parsed, mode: LaunchMode.externalApplication),
        child: Text(
          value,
          style: style.copyWith(
            color: AppTheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
    return Text(value, style: style);
  }

  Widget _seedSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Row(
      children: [
        Text(
          l10n.participantDetailSeedLabel,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: TextField(
            key: const ValueKey('participant-detail-seed'),
            controller: _seedController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          key: const ValueKey('participant-detail-seed-save'),
          onPressed: _busy ? null : _saveSeed,
          child: Text(l10n.participantDetailSeedSave),
        ),
      ],
    );
  }
}

class _GuestContactField {
  const _GuestContactField({
    required this.slot,
    required this.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  final int slot;
  final String key;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
  }
}

class _GuestContact {
  const _GuestContact({
    required this.slot,
    required this.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  final int slot;
  final String key;
  final String name;
  final String email;
  final String phone;
}

/// Ghi chú nội bộ BTC lưu ở `customResponses.notes` (Web `readParticipantNote`).
String participantNote(OrganizerOpsParticipant participant) =>
    participant.customResponses['notes'] is String
    ? participant.customResponses['notes'] as String
    : '';

/// Danh sách thành viên khách của hồ sơ, theo slot từ `players` (slot 1/2);
/// email/SĐT đọc từ `playerNEmail`/`playerNPhone` của `customResponses` —
/// nguồn Web `readGuestSlots`. `key` là expectedKey server kiểm (`guest: tên|email`).
List<_GuestContact> _guestContacts(OrganizerOpsParticipant participant) {
  final contacts = <_GuestContact>[];
  for (final player in participant.players) {
    if (!player.isGuest) continue;
    final slot = player.slot <= 0 ? contacts.length + 1 : player.slot;
    final email = participant.customResponses['player${slot}Email']?.toString();
    final phone = participant.customResponses['player${slot}Phone']?.toString();
    contacts.add(
      _GuestContact(
        slot: slot,
        key:
            'guest:${player.fullName.trim()}|${(email ?? '').trim().toLowerCase()}',
        name: player.fullName,
        email: email ?? '',
        phone: phone ?? '',
      ),
    );
  }
  return contacts;
}

/// Các key hệ thống không phải câu trả lời form: ghi chú có mục riêng, khóa
/// nguồn import hiện ở dòng hồ sơ, playerN* là dữ liệu ghép của server.
const Set<String> _systemResponseKeys = {
  'notes',
  'note',
  'importedFrom',
  'player1Name',
  'player1Email',
  'player1Phone',
  'player1UserId',
  'player2Name',
  'player2Email',
  'player2Phone',
  'player2UserId',
  'sourceFileName',
  'sourceRowIndex',
  'sourceSheetName',
  'is_wildcard',
  'importedElo',
  'eloSource',
};

String _humanizeResponseKey(String key) {
  final words = key
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
  if (words.isEmpty) return key;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String? _formatAnswerValue(
  Object? value,
  AppLocalizations l10n,
  List<String?> urlOut,
) {
  if (value == null) return null;
  if (value is bool) {
    return value
        ? l10n.participantDetailAnswerYes
        : l10n.participantDetailAnswerNo;
  }
  if (value is String || value is num) {
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
  if (value is List) {
    final items = value
        .where((item) => item is String || item is num)
        .map((item) => item.toString())
        .toList();
    return items.isEmpty ? null : items.join(', ');
  }
  if (value is Map) {
    // Tệp đính kèm: hiện tên file (originalName), bấm mở url.
    final url = value['url']?.toString().trim();
    final name = value['originalName']?.toString().trim();
    final link = url != null && url.isNotEmpty ? url : null;
    if (name != null && name.isNotEmpty) {
      urlOut.add(link);
      return name;
    }
    urlOut.add(link);
    return link;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Câu trả lời form tùy chỉnh của hồ sơ (loại key hệ thống và giá trị rỗng),
/// port `classifyCustomResponses` của Web nhưng không có cấu hình form nên
/// nhãn là key đã humanize. Giá trị bool dịch theo l10n (Có/Không); phần tử
/// thứ ba là URL đính kèm (nếu có) để bấm mở.
List<(String, String, String?)> participantFormAnswers(
  Map<String, dynamic> customResponses,
  AppLocalizations l10n,
) {
  final answers = <(String, String, String?)>[];
  final keys = customResponses.keys.toList()..sort();
  for (final key in keys) {
    if (_systemResponseKeys.contains(key)) continue;
    final urls = <String?>[];
    final formatted = _formatAnswerValue(customResponses[key], l10n, urls);
    if (formatted == null) continue;
    answers.add((_humanizeResponseKey(key), formatted, urls.firstOrNull));
  }
  return answers;
}
