import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Kết quả sheet AI xếp lịch trả về màn gọi: bản nháp để hiện trên lưới, hoặc
/// [unavailable] khi route AI không có (màn gọi ẩn mục AI trong phiên này).
class AiScheduleSheetResult {
  const AiScheduleSheetResult({
    required this.drafts,
    this.skipped = 0,
    this.needsReview = false,
    this.unavailable = false,
  });

  const AiScheduleSheetResult.unavailable()
    : drafts = const [],
      skipped = 0,
      needsReview = false,
      unavailable = true;

  final List<MatchModel> drafts;

  /// Số trận AI không xếp được (bị bỏ qua hoặc không còn chờ xếp).
  final int skipped;

  /// AI đánh dấu câu lệnh mơ hồ, cần xem kỹ bản nháp.
  final bool needsReview;
  final bool unavailable;
}

/// Gọi xem trước AI cho [command] và [day]; ném [AiScheduleUnavailableException]
/// khi route AI không có.
typedef AiSchedulePreviewCallback =
    Future<AiScheduleSheetResult> Function(String command, DateTime day);

/// Sheet "AI xếp lịch" (OpenSpec `quan-ly-giai-web-parity`, task 4.5): BTC gõ
/// lệnh chữ tự nhiên, App gọi xem trước và trả bản nháp cho lưới (thanh
/// "Áp dụng N trận / Huỷ" có sẵn). Không ghi gì xuống server.
class AiScheduleSheet extends StatefulWidget {
  const AiScheduleSheet({
    super.key,
    required this.onPreview,
    required this.initialDay,
  });

  final AiSchedulePreviewCallback onPreview;
  final DateTime initialDay;

  /// Tắt kéo xuống từ đầu: sheet có thể bận ngay khi bấm Xem trước, mà tham số
  /// drag của route chốt lúc mở.
  static Future<AiScheduleSheetResult?> show(
    BuildContext context, {
    required AiSchedulePreviewCallback onPreview,
    required DateTime initialDay,
  }) => showModalBottomSheet<AiScheduleSheetResult>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) =>
        AiScheduleSheet(onPreview: onPreview, initialDay: initialDay),
  );

  @override
  State<AiScheduleSheet> createState() => _AiScheduleSheetState();
}

class _AiScheduleSheetState extends State<AiScheduleSheet> {
  static const _maxCommandLength = 4000;

  final _controller = TextEditingController();
  late DateTime _day = widget.initialDay;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_busy && _controller.text.trim().isNotEmpty;

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _day,
    );
    if (picked == null || !mounted) return;
    setState(() => _day = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onPreview(_controller.text.trim(), _day);
      if (!mounted) return;
      if (result.drafts.isEmpty) {
        setState(() {
          _busy = false;
          _error = l10n.scheduleAiNoPlan;
        });
        return;
      }
      Navigator.of(context).pop(result);
    } on AiScheduleUnavailableException {
      if (!mounted) return;
      Navigator.of(context).pop(const AiScheduleSheetResult.unavailable());
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            tournamentSheetServerMessage(failure) ??
            ErrorParser.parse(failure, l10n.scheduleAiFailed, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManageSheet(
      title: l10n.scheduleAiTitle,
      busy: _busy,
      actions: [
        FilledButton.icon(
          key: const ValueKey('ai-schedule-preview'),
          onPressed: _canSubmit ? _submit : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(l10n.scheduleQuickAutoPreview),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('ai-schedule-command'),
            controller: _controller,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            maxLength: _maxCommandLength,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.scheduleAiCommandLabel,
              hintText: l10n.scheduleAiCommandHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _pickDay,
              icon: const Icon(Icons.event_rounded),
              label: Text(
                '${l10n.scheduleQuickDate}: '
                '${MaterialLocalizations.of(context).formatMediumDate(_day)}',
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('ai-schedule-error'),
              style: TextStyle(color: context.colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
