import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_opening_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Số VĐV đã đăng ký của một hạng mục (payload quản lý), theo cùng các trường
/// mà Web đọc (`_summary.participantCount` hoặc `_count.participants`).
int registeredParticipantsOf(Map<String, dynamic> division) {
  final summary = division['_summary'];
  if (summary is Map && summary['participantCount'] != null) {
    return int.tryParse(summary['participantCount'].toString()) ?? 0;
  }
  final count = division['_count'];
  if (count is Map && count['participants'] != null) {
    return int.tryParse(count['participants'].toString()) ?? 0;
  }
  return 0;
}

/// Hạng mục đã đủ chỗ: có sức chứa > 0 và số VĐV đã đạt sức chứa — cùng luật
/// `isDivisionFull` của Web (đủ chỗ theo VĐV, không theo đội).
bool divisionIsFull(Map<String, dynamic> division) {
  final max = int.tryParse(division['maxParticipants']?.toString() ?? '');
  return max != null && max > 0 && registeredParticipantsOf(division) >= max;
}

/// Hạn đăng ký của hạng mục (ưu tiên hạn hiệu lực), dùng để biết hạng mục đã
/// quá hạn khi mở lại đăng ký.
DateTime? divisionDeadlineOf(Map<String, dynamic> division) {
  final raw =
      division['effectiveRegistrationEndDate'] ??
      division['registrationEndDate'];
  return raw is String ? DateTime.tryParse(raw) : null;
}

String _divisionIdOf(Map<String, dynamic> division) =>
    division['id']?.toString() ?? '';

String _divisionNameOf(Map<String, dynamic> division) =>
    division['name']?.toString() ?? '';

/// Prompt đề nghị đóng đăng ký các hạng mục đã đủ chỗ (task 1.3, đối chiếu
/// Web `getDivisionsNeedingCloseConfirmation` + prompt close-full-divisions):
/// mỗi hạng mục một hàng [Đóng đăng ký | Giữ mở]; quyết định xong hạng mục nào
/// là báo lại [onDecided] để màn không hỏi lại hạng mục đó trong phiên.
class FullDivisionsPromptSheet extends ConsumerStatefulWidget {
  const FullDivisionsPromptSheet({
    super.key,
    required this.tournamentId,
    required this.divisions,
    this.onDecided,
  });

  final String tournamentId;

  /// Hạng mục đã đủ chỗ VÀ còn mở đăng ký (màn đã lọc sẵn).
  final List<Map<String, dynamic>> divisions;

  /// Báo id hạng mục đã quyết xong (đóng hoặc giữ mở).
  final ValueChanged<String>? onDecided;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required List<Map<String, dynamic>> divisions,
    ValueChanged<String>? onDecided,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => FullDivisionsPromptSheet(
      tournamentId: tournamentId,
      divisions: divisions,
      onDecided: onDecided,
    ),
  );

  @override
  ConsumerState<FullDivisionsPromptSheet> createState() =>
      _FullDivisionsPromptSheetState();
}

class _FullDivisionsPromptSheetState
    extends ConsumerState<FullDivisionsPromptSheet> {
  /// Id hạng mục đang gửi close (spinner hàng đó).
  final _closingIds = <String>{};
  final _decidedIds = <String>{};
  String? _error;

  Future<void> _close(String divisionId) async {
    if (_closingIds.contains(divisionId)) return;
    setState(() {
      _closingIds.add(divisionId);
      _error = null;
    });
    var ok = false;
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .closeDivisionRegistrations(widget.tournamentId, [divisionId]);
      ref.invalidate(tournamentProvider(widget.tournamentId));
      ok = true;
    } catch (error) {
      if (mounted) {
        setState(() => _error = tournamentSheetServerMessage(error));
      }
    }
    if (!mounted) return;
    setState(() {
      _closingIds.remove(divisionId);
      if (ok) _decidedIds.add(divisionId);
    });
    if (ok) widget.onDecided?.call(divisionId);
    if (ok && _decidedIds.length >= widget.divisions.length) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final pending = widget.divisions
        .where((division) => !_decidedIds.contains(_divisionIdOf(division)))
        .toList(growable: false);
    return TournamentManageSheet(
      title: l10n.divisionFullPromptTitle,
      busy: false,
      actions: [
        FilledButton.icon(
          key: const ValueKey('division-full-close-all'),
          onPressed: pending.isEmpty
              ? null
              : () => _closeAll(pending.map(_divisionIdOf).toList()),
          icon: const Icon(Icons.lock_outline_rounded),
          label: Text(l10n.divisionFullPromptCloseAll(pending.length)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.divisionFullPromptMessage),
          const SizedBox(height: 12),
          for (final division in pending) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _divisionNameOf(division),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.divisionFullPromptCapacity(
                            registeredParticipantsOf(division),
                            int.parse(division['maxParticipants'].toString()),
                          ),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hai nút xếp dọc: đặt ngang sẽ tràn trên màn 400px.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FilledButton(
                        key: ValueKey(
                          'division-full-close-${_divisionIdOf(division)}',
                        ),
                        onPressed: _closingIds.contains(_divisionIdOf(division))
                            ? null
                            : () => _close(_divisionIdOf(division)),
                        child: _closingIds.contains(_divisionIdOf(division))
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.divisionFullPromptClose),
                      ),
                      TextButton(
                        key: ValueKey(
                          'division-full-keep-${_divisionIdOf(division)}',
                        ),
                        onPressed: () {
                          final id = _divisionIdOf(division);
                          setState(() => _decidedIds.add(id));
                          widget.onDecided?.call(id);
                          if (_decidedIds.length >= widget.divisions.length) {
                            Navigator.of(context).maybePop();
                          }
                        },
                        child: Text(l10n.divisionFullPromptKeepOpen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }

  Future<void> _closeAll(List<String> ids) async {
    for (final id in ids) {
      await _close(id);
      if (!mounted) return;
    }
  }
}

/// Chế độ của sheet đóng/mở đăng ký hàng loạt.
enum RegistrationDivisionsMode { close, open }

/// Sheet đóng/mở đăng ký THEO NHÓM HẠNG MỤC (task 1.4, đối chiếu Web
/// `RegistrationDivisionsModal`): checkbox từng hạng mục (chỉ áp dụng cho
/// hạng mục còn mở khi đóng, đang đóng khi mở lại) + chọn hết; mở lại hạng
/// mục đã quá hạn thì bắt chọn hạn mới ở tương lai ngay trong sheet; xác
/// nhận gửi MỘT lần `close-registration`/`reopen-registration` với
/// `divisionIds` (và `registrationEndDate` khi cần).
class RegistrationDivisionsBulkSheet extends ConsumerStatefulWidget {
  const RegistrationDivisionsBulkSheet({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
    required this.tournamentDeadline,
    required this.divisions,
    this.initialMode = RegistrationDivisionsMode.close,
    this.pickDeadline,
  });

  final String tournamentId;
  final String tournamentStatus;
  final DateTime? tournamentDeadline;
  final List<Map<String, dynamic>> divisions;
  final RegistrationDivisionsMode initialMode;

  /// Chọn hạn mới; mặc định dùng date+time picker của màn quản lý. Tiêm vào
  /// từ test để không phải lái picker trong widget test.
  final Future<DateTime?> Function(BuildContext)? pickDeadline;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required String tournamentStatus,
    required DateTime? tournamentDeadline,
    required List<Map<String, dynamic>> divisions,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => RegistrationDivisionsBulkSheet(
      tournamentId: tournamentId,
      tournamentStatus: tournamentStatus,
      tournamentDeadline: tournamentDeadline,
      divisions: divisions,
    ),
  );

  @override
  ConsumerState<RegistrationDivisionsBulkSheet> createState() =>
      _RegistrationDivisionsBulkSheetState();
}

class _RegistrationDivisionsBulkSheetState
    extends ConsumerState<RegistrationDivisionsBulkSheet> {
  late RegistrationDivisionsMode _mode = widget.initialMode;
  final _selected = <String>{};
  DateTime? _newDeadline;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Mở sheet là chọn sẵn mọi hạng mục áp dụng — cùng Web ("Mỗi lần mở là
    // một lần dựng mới nên lựa chọn luôn bắt đầu từ chọn sẵn tất cả").
    _resetSelection();
  }

  bool _isOpen(Map<String, dynamic> division) =>
      divisionRegistrationOpen(division, widget.tournamentStatus);

  /// Hạng mục áp dụng cho chế độ hiện tại (Web: close → đang mở, open → đang
  /// đóng), loại hạng mục đã huỷ.
  bool _applicable(Map<String, dynamic> division) {
    if (division['status']?.toString().toUpperCase() == 'CANCELLED') {
      return false;
    }
    return _mode == RegistrationDivisionsMode.close
        ? _isOpen(division)
        : !_isOpen(division);
  }

  void _resetSelection() {
    _selected
      ..clear()
      ..addAll(
        widget.divisions
            .where(_applicable)
            .map(_divisionIdOf)
            .where((id) => id.isNotEmpty),
      );
  }

  /// Mở lại hạng mục đã quá hạn (riêng hoặc theo hạn giải) thì bắt chọn hạn
  /// mới — cùng luật `needsDeadline` của Web.
  bool get _needsDeadline {
    if (_mode != RegistrationDivisionsMode.open) return false;
    return widget.divisions.any((division) {
      final id = _divisionIdOf(division);
      if (id.isEmpty || !_selected.contains(id)) return false;
      final deadline =
          divisionDeadlineOf(division) ?? widget.tournamentDeadline;
      return deadline != null && !deadline.isAfter(DateTime.now());
    });
  }

  bool get _deadlineInvalid =>
      _needsDeadline &&
      (_newDeadline == null || !_newDeadline!.isAfter(DateTime.now()));

  Future<void> _confirm() async {
    if (_busy || _selected.isEmpty || _deadlineInvalid) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ids = _selected.toList(growable: false);
    try {
      final repository = ref.read(tournamentManagementRepositoryProvider);
      if (_mode == RegistrationDivisionsMode.close) {
        await repository.closeDivisionRegistrations(widget.tournamentId, ids);
      } else {
        await repository.reopenRegistration(
          widget.tournamentId,
          divisionIds: ids,
          registrationEndDate: _needsDeadline ? _newDeadline : null,
        );
      }
      ref.invalidate(tournamentProvider(widget.tournamentId));
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = tournamentSheetServerMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDeadline() async {
    final picked =
        await (widget.pickDeadline ?? pickTournamentManagementDeadline)(
          context,
        );
    if (picked != null && mounted) {
      setState(() => _newDeadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final applicable = widget.divisions.where(_applicable).toList();
    final allSelected =
        applicable.isNotEmpty &&
        applicable.every(
          (division) => _selected.contains(_divisionIdOf(division)),
        );
    return TournamentManageSheet(
      title: l10n.divisionBulkTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('division-bulk-confirm'),
          onPressed: (_busy || _selected.isEmpty || _deadlineInvalid)
              ? null
              : _confirm,
          child: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _mode == RegistrationDivisionsMode.close
                      ? l10n.divisionBulkConfirmClose(_selected.length)
                      : l10n.divisionBulkConfirmOpen(_selected.length),
                ),
        ),
        TextButton(
          key: const ValueKey('division-bulk-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<RegistrationDivisionsMode>(
            key: const ValueKey('division-bulk-mode'),
            segments: [
              ButtonSegment(
                value: RegistrationDivisionsMode.close,
                label: Text(l10n.divisionBulkModeClose),
              ),
              ButtonSegment(
                value: RegistrationDivisionsMode.open,
                label: Text(l10n.divisionBulkModeOpen),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() {
              _mode = value.first;
              _newDeadline = null;
              _resetSelection();
            }),
          ),
          const SizedBox(height: 12),
          if (applicable.isEmpty)
            Text(
              _mode == RegistrationDivisionsMode.close
                  ? l10n.divisionBulkEmptyClose
                  : l10n.divisionBulkEmptyOpen,
              style: TextStyle(color: colors.textSecondary),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('division-bulk-select-all'),
                onPressed: _busy
                    ? null
                    : () => setState(
                        () =>
                            allSelected ? _selected.clear() : _resetSelection(),
                      ),
                icon: Icon(
                  allSelected
                      ? Icons.indeterminate_check_box_outlined
                      : Icons.check_box_outline_blank_rounded,
                ),
                label: Text(l10n.divisionBulkSelectAll),
              ),
            ),
            for (final division in widget.divisions) ...[
              _bulkRow(division),
              const SizedBox(height: 6),
            ],
          ],
          if (_needsDeadline) ...[
            const SizedBox(height: 8),
            Text(
              _deadlineInvalid
                  ? l10n.divisionBulkNewDeadlineMissing
                  : l10n.divisionBulkNewDeadline,
              style: TextStyle(
                color: _deadlineInvalid ? colors.error : colors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const ValueKey('division-bulk-pick-deadline'),
              onPressed: _busy ? null : _pickDeadline,
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _newDeadline == null
                    ? l10n.divisionBulkPickDeadline
                    : MaterialLocalizations.of(
                        context,
                      ).formatFullDate(_newDeadline!),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }

  Widget _bulkRow(Map<String, dynamic> division) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final id = _divisionIdOf(division);
    final applicable = _applicable(division);
    final open = _isOpen(division);
    return Opacity(
      opacity: applicable ? 1 : 0.5,
      child: InkWell(
        key: ValueKey('division-bulk-row-$id'),
        onTap: applicable && !_busy
            ? () => setState(
                () => _selected.contains(id)
                    ? _selected.remove(id)
                    : _selected.add(id),
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _selected.contains(id),
                onChanged: applicable && !_busy
                    ? (value) => setState(
                        () => value == true
                            ? _selected.add(id)
                            : _selected.remove(id),
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _divisionNameOf(division),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      open
                          ? l10n.tournamentManagementDivisionRegistrationOpen
                          : l10n.tournamentManagementDivisionRegistrationClosed,
                      style: TextStyle(
                        color: open ? colors.textSecondary : colors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
