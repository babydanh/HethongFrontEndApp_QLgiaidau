import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sheet cài đặt khung giờ sân (OpenSpec `quan-ly-giai-web-parity`, task 4.3;
/// port popup "Cài đặt khung giờ" của Web `CourtScheduleBoard.tsx`): giờ mở
/// cửa và đóng cửa sân trong ngày + bước ô thời gian 5/10/15/30/60 phút
/// ([scheduleStepOptions]).
///
/// Lưu bằng `PATCH /tournaments/:id` với object `tournamentConfig` GỐC đã
/// merge các trường đổi (đúng `handleSaveScheduleSettings` của Web) — server
/// ghi đè toàn bộ JSONB nên phải gửi đủ. Sheet pop `true` khi lưu thành công;
/// màn gọi invalidate nguồn giải để lưới vẽ lại theo cấu hình mới.
///
/// Stateful và bọc khung [TournamentManageSheet] trong `build` để `busy` đổi
/// được bên trong sheet (khung chốt busy một lần lúc mở, không cập nhật được
/// sau này).
class ScheduleSettingsSheet extends ConsumerStatefulWidget {
  const ScheduleSettingsSheet({super.key, required this.tournament});

  /// Giải đang quản lý: nguồn cấu hình ban đầu và object config gửi lên server.
  final Tournament tournament;

  /// Mở sheet cài đặt khung giờ. Trả về `true` khi đã lưu thành công.
  ///
  /// Mở bằng `showModalBottomSheet` trực tiếp (thay vì helper của khung) vì
  /// `builder` phải trả sheet stateful này — khung nằm trong `build` của state
  /// để nhận `busy` động. Drag tắt từ đầu: sheet có thể vào trạng thái busy
  /// ngay khi bấm lưu, mà tham số drag của route chốt lúc mở không đổi được.
  static Future<bool?> show(
    BuildContext context, {
    required Tournament tournament,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => ScheduleSettingsSheet(tournament: tournament),
  );

  @override
  ConsumerState<ScheduleSettingsSheet> createState() =>
      _ScheduleSettingsSheetState();
}

class _ScheduleSettingsSheetState extends ConsumerState<ScheduleSettingsSheet> {
  late int _startMinute;

  late int _endMinute;

  /// Bước ô đang chọn; chỉ nhận giá trị trong [scheduleStepOptions].
  late int _step;

  bool _busy = false;
  String? _actionError;

  static final List<int> _hourChoices = [
    for (var minute = 0; minute < 24 * 60; minute += 30) minute,
  ];

  @override
  void initState() {
    super.initState();
    final settings = widget.tournament.scheduleSettings;
    _startMinute = _parseMinutes(settings['operatingStart'], fallback: 7 * 60);
    _endMinute = _parseMinutes(settings['operatingEnd'], fallback: 22 * 60);
    _step = scheduleStepMinutesOf(settings);
  }

  /// Giờ mở/đóng trong cấu hình: số phút trong ngày ("07:30", 7, 7.5 đều
  /// đọc được), thiếu thì [fallback].
  static int _parseMinutes(Object? value, {required int fallback}) {
    if (value is num) return (value * 60).round();
    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return fallback;
      final parts = raw.split(':');
      final hour = int.tryParse(parts.first.trim());
      if (hour == null) return fallback;
      final minute = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
      return hour * 60 + minute;
    }
    return fallback;
  }

  static String _hhmm(int minute) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _timesValid => _endMinute > _startMinute;

  bool get _canSubmit => !_busy && _timesValid;

  Future<void> _save() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final config = {...widget.tournament.tournamentConfig};
      config['operatingStart'] = _hhmm(_startMinute);
      config['operatingEnd'] = _hhmm(_endMinute);
      config['stepMinutes'] = _step;
      await ref.read(tournamentManagementRepositoryProvider).updateTournament(
        widget.tournament.id,
        {'tournamentConfig': config},
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = tournamentSheetServerMessage(error);
      setState(() {
        _busy = false;
        _actionError = message ?? l10n.tournamentManagementSaveError;
      });
      return;
    }
    // Thông báo thành công nằm ở màn gọi (nó cần tải lại nguồn giải trước).
    messenger?.clearSnackBars();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return TournamentManageSheet(
      title: l10n.scheduleSettingsTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('schedule-settings-save'),
          onPressed: _canSubmit ? _save : null,
          child: Text(l10n.tournamentManagementSave),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Khung giờ mở sân trong ngày ───
          _sectionTitle(
            l10n.scheduleSettingsOpeningHours,
            icon: Icons.schedule_rounded,
            color: colors.info,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _timeDropdown(
                  // "Giờ bắt đầu" tái dùng nhãn xếp nhanh có sẵn.
                  l10n.scheduleQuickStart,
                  'start',
                  _startMinute,
                  (value) => setState(() => _startMinute = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeDropdown(
                  l10n.scheduleSettingsEndTime,
                  'end',
                  _endMinute,
                  (value) => setState(() => _endMinute = value),
                ),
              ),
            ],
          ),
          if (!_timesValid) ...[
            const SizedBox(height: 8),
            Text(
              l10n.scheduleSettingsTimeInvalid,
              key: const ValueKey('schedule-settings-time-invalid'),
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          // ─── 2. Bước nhảy ô thời gian ───
          _sectionTitle(
            l10n.scheduleSettingsStepLabel,
            icon: Icons.grid_on_rounded,
            color: colors.info,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in scheduleStepOptions)
                ChoiceChip(
                  key: ValueKey('schedule-settings-step-$option'),
                  label: Text(l10n.scheduleSettingsStepChip(option)),
                  selected: _step == option,
                  onSelected: _busy
                      ? null
                      : (selected) {
                          if (selected) setState(() => _step = option);
                        },
                ),
            ],
          ),
          if (_actionError != null) ...[
            const SizedBox(height: 12),
            Text(
              _actionError!,
              key: const ValueKey('schedule-settings-error'),
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String text, {
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Chọn giờ dạng dropdown các mốc 30 phút — thay input `type="time"` của
  /// Web (bàn phím phần cứng không có trên điện thoại).
  Widget _timeDropdown(
    String label,
    String keyName,
    int value,
    ValueChanged<int> onChanged,
  ) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: ValueKey('schedule-settings-time-$keyName'),
              value: _hourChoices.contains(value)
                  ? value
                  : _hourChoices.reduce(
                      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
                    ),
              isExpanded: true,
              items: [
                for (final minute in _hourChoices)
                  DropdownMenuItem(
                    value: minute,
                    child: Text(
                      _hhmm(minute),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (next) {
                      if (next != null) onChanged(next);
                    },
            ),
          ),
        ),
      ],
    );
  }
}
