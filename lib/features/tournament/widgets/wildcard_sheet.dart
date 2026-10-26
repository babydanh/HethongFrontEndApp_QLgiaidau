import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sheet gán suất đặc cách (task 3.5, đối chiếu Web `WildcardManagerCard` +
/// `handleAssignWildcard`): chọn hạng mục, nhập email/SĐT người chơi (nội
/// dung đôi thêm đồng đội) và tên đội rồi
/// `POST /tournaments/:id/reserve-slots`. Validate email + tên đội trước khi
/// gửi; lỗi server hiển thị nguyên văn.
class WildcardSheet extends ConsumerStatefulWidget {
  const WildcardSheet({
    super.key,
    required this.tournamentId,
    required this.divisions,
    required this.initialDivisionId,
    this.onRefresh,
  });

  final String tournamentId;

  /// Hạng mục để gán suất; trống thì để Backend tự chọn theo giải.
  final List<TournamentDivision> divisions;

  /// Hạng mục chọn sẵn khi mở sheet (dòng hạng mục bấm nút vào).
  final String initialDivisionId;

  /// Gọi sau khi gán xong để màn cha tải lại dữ liệu.
  final Future<void> Function()? onRefresh;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required List<TournamentDivision> divisions,
    required String initialDivisionId,
    Future<void> Function()? onRefresh,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => WildcardSheet(
      tournamentId: tournamentId,
      divisions: divisions,
      initialDivisionId: initialDivisionId,
      onRefresh: onRefresh,
    ),
  );

  @override
  ConsumerState<WildcardSheet> createState() => _WildcardSheetState();
}

class _WildcardSheetState extends ConsumerState<WildcardSheet> {
  late String _divisionId = widget.initialDivisionId;
  final _contactController = TextEditingController();
  final _partnerController = TextEditingController();
  final _teamNameController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Dòng vào luôn thuộc danh sách, nhưng nếu không khớp thì chọn hạng mục
    // đầu tiên thay vì gửi tham số lạ lên API.
    if (widget.divisions.isNotEmpty &&
        !widget.divisions.any((division) => division.id == _divisionId)) {
      _divisionId = widget.divisions.first.id;
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _partnerController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  TournamentDivision? get _selectedDivision {
    for (final division in widget.divisions) {
      if (division.id == _divisionId) return division;
    }
    return null;
  }

  bool get _isDoubles => _selectedDivision?.isDoubles ?? false;

  static final _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

  /// Web chỉ bắt nhập đủ, brief thêm validate email: giá trị chứa '@' thì
  /// phải là email hợp lệ, không có '@' coi như SĐT.
  String? _validate(AppLocalizations l10n) {
    if (widget.divisions.isNotEmpty && _divisionId.isEmpty) {
      return l10n.wildcardDivisionRequired;
    }
    final contact = _contactController.text.trim();
    if (contact.isEmpty) return l10n.wildcardContactRequired;
    if (contact.contains('@') && !_emailPattern.hasMatch(contact)) {
      return l10n.wildcardContactInvalid;
    }
    if (_teamNameController.text.trim().isEmpty) {
      return l10n.wildcardTeamNameRequired;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final problem = _validate(l10n);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final partner = _partnerController.text.trim();
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .reserveSlots(
            widget.tournamentId,
            userEmailOrPhone: _contactController.text.trim(),
            teamName: _teamNameController.text.trim(),
            partnerEmailOrPhone: _isDoubles && partner.isNotEmpty
                ? partner
                : null,
            divisionId: _divisionId.isEmpty ? null : _divisionId,
          );
      await widget.onRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.wildcardAssignedToast)));
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              tournamentSheetServerMessage(error) ??
              ErrorParser.parse(error, l10n.wildcardAssignFailed, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return TournamentManageSheet(
      title: l10n.wildcardSheetTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('wildcard-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.wildcardAssign),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.wildcardSheetDescription,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Web WildcardManagerCard chỉ hiện bộ chọn khi có nhiều hạng mục.
          if (widget.divisions.length > 1) ...[
            Text(
              l10n.wildcardDivisionLabel,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: const ValueKey('wildcard-division-select'),
              initialValue: _divisionId,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final division in widget.divisions)
                  DropdownMenuItem(
                    value: division.id,
                    child: Text(division.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      // Web xoá ô đồng đội khi đổi hạng mục.
                      _divisionId = value ?? '';
                      _partnerController.clear();
                    }),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const ValueKey('wildcard-contact'),
            controller: _contactController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.wildcardContactLabel,
              hintText: l10n.wildcardContactHint,
            ),
          ),
          if (_isDoubles) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('wildcard-partner'),
              controller: _partnerController,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.wildcardPartnerLabel,
                hintText: l10n.wildcardPartnerHint,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('wildcard-team-name'),
            controller: _teamNameController,
            enabled: !_busy,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.wildcardTeamNameLabel,
              hintText: l10n.wildcardTeamNameHint,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }
}
