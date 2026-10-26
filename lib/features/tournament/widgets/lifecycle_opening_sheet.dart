import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hạng mục còn mở đăng ký theo dữ liệu `GET /tournaments/:id/divisions`
/// (cùng luật với Web `countOpenRegistrationDivisions`): server tính sẵn
/// `registrationOpen`; server cũ không gửi cờ thì tính lại theo khoá riêng,
/// hạn đăng ký và trạng thái giải. Nội dung đã huỷ không bao giờ tính là mở.
bool divisionRegistrationOpen(
  Map<String, dynamic> division,
  String normalizedTournamentStatus,
) {
  if (division['status']?.toString().toUpperCase() == 'CANCELLED') return false;
  final serverFlag =
      division['registrationOpen'] ?? division['registration_open'];
  if (serverFlag is bool) return serverFlag;
  if (division['effectiveIsRegistrationLocked'] == true) return false;
  final deadline =
      division['effectiveRegistrationEndDate'] ??
      division['registrationEndDate'];
  final deadlineTime = deadline is String ? DateTime.tryParse(deadline) : null;
  final withinDeadline =
      deadlineTime == null || DateTime.now().isBefore(deadlineTime);
  final registrationPhase =
      normalizedTournamentStatus == AppConstants.statusRegistration ||
      normalizedTournamentStatus == AppConstants.statusInProgress;
  return withinDeadline && registrationPhase;
}

/// Sheet khai mạc checklist (OpenSpec `quan-ly-giai-web-parity` task 1.1):
/// khi khai mạc mà vẫn còn hạng mục mở đăng ký, liệt kê từng hạng mục kèm
/// toggle "đóng đăng ký hạng mục này" (mặc định chọn đóng hết) và các cảnh báo
/// (hạng mục chưa có sơ đồ, lượt đăng ký đang chờ duyệt). Xác nhận:
/// có hạng mục được chọn đóng thì gửi `close-registration` (đúng danh sách
/// id chọn) rồi `start`; không chọn hạng mục nào thì vẫn cho khai mạc nhưng
/// phải bấm qua cảnh báo một lần nữa.
///
/// Stateful và bọc khung [TournamentManageSheet] trong `build` để `busy` đổi
/// được bên trong sheet (helper `TournamentManageSheet.show` chốt busy một
/// lần lúc mở, không cập nhật được sau này).
class LifecycleOpeningSheet extends ConsumerStatefulWidget {
  const LifecycleOpeningSheet({
    super.key,
    required this.tournament,
    required this.divisions,
  });

  final Tournament tournament;

  /// Toàn bộ hạng mục từ `GET /tournaments/:id/divisions`: sheet tự lọc hạng
  /// mục đang mở cho toggle, và dùng danh sách đầy đủ cho cảnh báo chưa sơ đồ.
  final List<Map<String, dynamic>> divisions;

  /// Mở sheet khai mạc. Trả về `true` khi giải đã khai mạc thành công.
  ///
  /// Mở bằng `showModalBottomSheet` trực tiếp (thay vì helper của khung) vì
  /// `builder` phải trả sheet stateful này — khung [TournamentManageSheet]
  /// nằm trong `build` của state để nhận `busy` động. Drag tắt từ đầu: sheet
  /// có thể vào trạng thái busy ngay khi bấm khai mạc, mà tham số drag của
  /// route chốt lúc mở không đổi được sau này.
  static Future<bool?> show(
    BuildContext context, {
    required Tournament tournament,
    required List<Map<String, dynamic>> divisions,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) =>
        LifecycleOpeningSheet(tournament: tournament, divisions: divisions),
  );

  @override
  ConsumerState<LifecycleOpeningSheet> createState() =>
      _LifecycleOpeningSheetState();
}

class _LifecycleOpeningSheetState extends ConsumerState<LifecycleOpeningSheet> {
  /// Id các hạng mục được chọn đóng đăng ký; mặc định đóng hết hạng mục đang mở.
  late final Set<String> _selectedCloseIds;

  /// Số lượt đăng ký đang chờ duyệt; null = chưa tải xong hoặc tải lỗi (chỉ
  /// bỏ cảnh báo, không chặn khai mạc vì số liệu phụ).
  int? _pendingCount;

  /// Đang gọi `close-registration`/`start`.
  bool _busy = false;

  /// Đã bấm qua cảnh báo "chưa chọn hạng mục nào để đóng" lần thứ nhất.
  bool _forceConfirmed = false;

  String? _actionError;

  List<Map<String, dynamic>> get _openDivisions {
    final status = StatusHelper.normalizeTournamentStatus(
      widget.tournament.status,
    );
    return widget.divisions
        .where((division) => divisionRegistrationOpen(division, status))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _selectedCloseIds = _openDivisions
        .map((division) => division['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final participants = await ref
          .read(tournamentRepositoryProvider)
          .getOrganizerParticipants(widget.tournament.id);
      if (!mounted) return;
      setState(() {
        _pendingCount = participants
            .where((participant) => participant.teamStatus == 'PENDING')
            .length;
      });
    } on Object {
      // Không chặn khai mạc vì thiếu số liệu phụ: chỉ bỏ cảnh báo chờ duyệt.
      if (mounted) setState(() => _pendingCount = null);
    }
  }

  void _toggleDivision(String id, bool? checked) {
    if (checked == null) return;
    setState(() {
      checked ? _selectedCloseIds.add(id) : _selectedCloseIds.remove(id);
      // Chọn lại hạng mục thì thôi cảnh báo "chưa chọn gì" nếu còn hiệu lực.
      _forceConfirmed = false;
    });
  }

  void _toggleAll(List<Map<String, dynamic>> openDivisions) {
    setState(() {
      if (_selectedCloseIds.length == openDivisions.length) {
        _selectedCloseIds.clear();
      } else {
        _selectedCloseIds
          ..clear()
          ..addAll(
            openDivisions
                .map((division) => division['id']?.toString() ?? '')
                .where((id) => id.isNotEmpty),
          );
      }
      _forceConfirmed = false;
    });
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final closeIds = _selectedCloseIds.toList(growable: false);
    // Không chọn hạng mục nào để đóng: vẫn cho khai mạc nhưng phải bấm qua
    // cảnh báo (bấm lần đầu chỉ hiện cảnh báo, bấm lần hai mới thực hiện).
    if (closeIds.isEmpty && !_forceConfirmed) {
      setState(() => _forceConfirmed = true);
      return;
    }
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final repository = ref.read(tournamentManagementRepositoryProvider);
    try {
      if (closeIds.isNotEmpty) {
        await repository.closeDivisionRegistrations(
          widget.tournament.id,
          closeIds,
        );
      }
      await repository.startTournament(widget.tournament.id);
      ref.invalidate(tournamentProvider(widget.tournament.id));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _actionError =
              _serverMessage(error) ??
              AppLocalizations.of(context)!.tournamentManagementActionError;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final openDivisions = _openDivisions;
    // Trận đấu cho cảnh báo chưa có sơ đồ; null = stream chưa trả dữ liệu,
    // chưa chắc để cảnh báo nên bỏ qua.
    final matches = ref
        .watch(matchesProvider(widget.tournament.id))
        .asData
        ?.value;
    return TournamentManageSheet(
      title: l10n.lifecycleOpeningTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('lifecycle-opening-confirm'),
          onPressed: _busy ? null : _confirm,
          child: Text(
            _forceConfirmed
                ? l10n.lifecycleOpeningOpenAnyway
                : l10n.lifecycleOpeningStart,
          ),
        ),
        TextButton(
          key: const ValueKey('lifecycle-opening-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: _buildBody(context, l10n, openDivisions, matches),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<Map<String, dynamic>> openDivisions,
    List<MatchModel>? matches,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final warning in _openingWarnings(l10n, matches))
        _OpeningWarning(text: warning),
      // Bấm khai mạc khi không chọn hạng mục nào: cảnh báo nổi bật trước khi
      // nút "Vẫn khai mạc" thực sự chạy.
      if (_forceConfirmed && _selectedCloseIds.isEmpty)
        _OpeningWarning(text: l10n.lifecycleOpeningForceWarning, error: true),
      if (openDivisions.isNotEmpty) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.lifecycleOpeningCloseHeading,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            // Nhiều hạng mục thì có nút chọn/bỏ hết một lần (như Web).
            if (openDivisions.length > 1)
              InkWell(
                key: const ValueKey('lifecycle-opening-select-all'),
                onTap: _busy ? null : () => _toggleAll(openDivisions),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _selectedCloseIds.length == openDivisions.length,
                        onChanged: _busy
                            ? null
                            : (_) => _toggleAll(openDivisions),
                      ),
                      Text(l10n.lifecycleOpeningCloseAll),
                    ],
                  ),
                ),
              ),
          ],
        ),
        for (final division in openDivisions)
          CheckboxListTile(
            key: ValueKey('lifecycle-opening-division-${division['id']}'),
            value: _selectedCloseIds.contains(division['id']?.toString()),
            onChanged: _busy
                ? null
                : (checked) => _toggleDivision(
                    division['id']?.toString() ?? '',
                    checked,
                  ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(division['name']?.toString() ?? ''),
          ),
      ],
      if (_actionError case final error?) ...[
        const SizedBox(height: 12),
        _OpeningError(text: error),
      ],
    ],
  );

  /// Cảnh báo trước khai mạc (đối chiếu Web `handleConfirmOpen`, thu về đúng
  /// hai loại task yêu cầu): hạng mục chưa có sơ đồ và lượt đăng ký chờ duyệt.
  List<String> _openingWarnings(
    AppLocalizations l10n,
    List<MatchModel>? matches,
  ) {
    final warnings = <String>[];
    if (matches != null) {
      final withoutBracket = widget.divisions
          .where(
            (division) =>
                division['status']?.toString().toUpperCase() != 'CANCELLED' &&
                !matches.any(
                  (match) => match.divisionId == division['id']?.toString(),
                ),
          )
          .map((division) => division['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
      if (withoutBracket.isNotEmpty) {
        warnings.add(l10n.lifecycleOpeningWarningNoBracket(withoutBracket));
      }
    }
    final pending = _pendingCount;
    if (pending != null && pending > 0) {
      warnings.add(l10n.lifecycleOpeningWarningPending(pending));
    }
    return warnings;
  }
}

/// Thông báo do máy chủ trả về (trường `message`), nếu có.
String? _serverMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final message = data['message'];
  return message is String && message.trim().isNotEmpty ? message : null;
}

/// Một dòng cảnh báo trong sheet khai mạc.
class _OpeningWarning extends StatelessWidget {
  const _OpeningWarning({required this.text, this.error = false});

  final String text;

  /// true: cảnh báo chốt (phải bấm qua) — tô đỏ thay vì vàng.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = error ? colors.error : colors.warning;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: error ? colors.error : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lỗi hành động hiển thị trong sheet (nguyên văn message server nếu có).
class _OpeningError extends StatelessWidget {
  const _OpeningError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(color: colors.error)),
    );
  }
}
