import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:app_quanly_giaidau/features/series/widgets/series_legs_error_text.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Form thêm/sửa một vòng. Tự gọi [onSubmit] và chỉ đóng khi thành công; lỗi
/// (mạng, 409, từ chối của Backend) hiện ngay trong form để người dùng sửa lại.
class SeriesLegFormSheet extends StatefulWidget {
  const SeriesLegFormSheet({
    super.key,
    required this.initial,
    required this.defaultOrder,
    required this.onSubmit,
  });

  /// Vòng đang sửa; null là thêm mới.
  final SeriesLegRecord? initial;
  final int defaultOrder;
  final Future<void> Function(SeriesLegInput input) onSubmit;

  /// Trả `true` khi đã lưu thành công.
  static Future<bool?> show(
    BuildContext context, {
    required SeriesLegRecord? initial,
    required int defaultOrder,
    required Future<void> Function(SeriesLegInput input) onSubmit,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.bgCard,
    builder: (_) => SeriesLegFormSheet(
      initial: initial,
      defaultOrder: defaultOrder,
      onSubmit: onSubmit,
    ),
  );

  @override
  State<SeriesLegFormSheet> createState() => _SeriesLegFormSheetState();
}

class _SeriesLegFormSheetState extends State<SeriesLegFormSheet> {
  static const _maxNameLength = 100;

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _order = TextEditingController(
    text: '${widget.initial?.order ?? widget.defaultOrder}',
  );
  late final _direct = TextEditingController(
    text: '${widget.initial?.directEntrySlots ?? 2}',
  );
  late final _wildcard = TextEditingController(
    text: '${widget.initial?.wildcardSlots ?? 16}',
  );
  late DateTime? _start = widget.initial?.startDate?.toLocal();
  late DateTime? _end = widget.initial?.endDate?.toLocal();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _order.dispose();
    _direct.dispose();
    _wildcard.dispose();
    super.dispose();
  }

  String? _validateName(String? value, AppLocalizations l10n) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.seriesLegsNameRequired;
    if (text.length > _maxNameLength) return l10n.seriesLegsNameTooLong;
    return null;
  }

  String? _validateInt(String? value, int min, String message) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < min ? message : null;
  }

  SeriesLegInput _buildInput() => SeriesLegInput(
    name: _name.text.trim(),
    order: int.parse(_order.text.trim()),
    startDate: _start,
    endDate: _end,
    directEntrySlots: int.parse(_direct.text.trim()),
    wildcardSlots: int.parse(_wildcard.text.trim()),
  );

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      setState(() => _error = l10n.seriesLegsDateOrderInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_buildInput());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = seriesLegsErrorText(error, l10n);
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Widget _dateField(String label, DateTime? value, bool isStart, Key key) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: key,
            onPressed: _busy ? null : () => _pickDate(isStart: isStart),
            child: Text(
              value == null
                  ? label
                  : '$label: ${DateFormat('dd/MM/yyyy').format(value)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: l10n.seriesLegsClearDate,
            onPressed: _busy
                ? null
                : () => setState(() => isStart ? _start = null : _end = null),
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }

  Widget _intField(
    String label,
    TextEditingController controller,
    Key key,
    int min,
    String message,
  ) => TextFormField(
    key: key,
    controller: controller,
    enabled: !_busy,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (value) => _validateInt(value, min, message),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? l10n.seriesLegsAdd : l10n.seriesLegsEdit,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('leg-form-name'),
              controller: _name,
              enabled: !_busy,
              decoration: InputDecoration(labelText: l10n.seriesLegsFieldName),
              validator: (value) => _validateName(value, l10n),
            ),
            const SizedBox(height: 8),
            _intField(
              l10n.seriesLegsFieldOrder,
              _order,
              const ValueKey('leg-form-order'),
              1,
              l10n.seriesLegsOrderInvalid,
            ),
            const SizedBox(height: 8),
            _dateField(
              l10n.seriesLegsFieldStart,
              _start,
              true,
              const ValueKey('leg-form-start'),
            ),
            _dateField(
              l10n.seriesLegsFieldEnd,
              _end,
              false,
              const ValueKey('leg-form-end'),
            ),
            const SizedBox(height: 8),
            _intField(
              l10n.seriesLegsFieldDirectSlots,
              _direct,
              const ValueKey('leg-form-direct'),
              0,
              l10n.seriesLegsSlotsInvalid,
            ),
            const SizedBox(height: 8),
            _intField(
              l10n.seriesLegsFieldWildcardSlots,
              _wildcard,
              const ValueKey('leg-form-wildcard'),
              0,
              l10n.seriesLegsSlotsInvalid,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('leg-form-submit'),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.seriesLegsSave),
            ),
          ],
        ),
      ),
    );
  }
}
