import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SocialDateTimePickerSheet extends StatefulWidget {
  const SocialDateTimePickerSheet({
    super.key,
    required this.initialDateTime,
    this.subtitle,
    this.minDate,
    this.maxDate,
    this.showEndOfDayChip = false,
  });

  final DateTime initialDateTime;

  /// Line under the title naming the milestone being picked and its limit.
  final String? subtitle;

  /// Inclusive day bounds; days outside are dimmed and cannot be confirmed.
  final DateTime? minDate;
  final DateTime? maxDate;

  /// Adds a "23:59" chip next to Confirm for deadline-style times.
  final bool showEndOfDayChip;

  static Future<DateTime?> show(
    BuildContext context,
    DateTime initialDateTime, {
    String? subtitle,
    DateTime? minDate,
    DateTime? maxDate,
    bool showEndOfDayChip = false,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SocialDateTimePickerSheet(
        initialDateTime: initialDateTime,
        subtitle: subtitle,
        minDate: minDate,
        maxDate: maxDate,
        showEndOfDayChip: showEndOfDayChip,
      ),
    );
  }

  @override
  State<SocialDateTimePickerSheet> createState() =>
      _SocialDateTimePickerSheetState();
}

class _SocialDateTimePickerSheetState extends State<SocialDateTimePickerSheet> {
  late final DateTime _firstDate;
  late final List<DateTime> _dates;
  late final List<int> _minutes;
  late final FixedExtentScrollController _dateController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = DateUtils.dateOnly(widget.initialDateTime);
    final minDay = _minDay;
    _firstDate = [
      initialDate,
      today,
      ?minDay,
    ].reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDay = _maxDay;
    final lastDate = [
      initialDate,
      today.add(const Duration(days: 365)),
      ?maxDay,
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    _dates = List.generate(
      lastDate.difference(_firstDate).inDays + 1,
      (index) => _firstDate.add(Duration(days: index)),
    );
    _selectedDate = initialDate;
    _selectedHour = widget.initialDateTime.hour;
    _selectedMinute = widget.initialDateTime.minute;
    _minutes = [
      ...{
        for (var minute = 0; minute < 60; minute += 5) minute,
        if (widget.showEndOfDayChip) 59,
        _selectedMinute,
      },
    ]..sort();
    _dateController = FixedExtentScrollController(
      initialItem: initialDate.difference(_firstDate).inDays,
    );
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _minutes.indexOf(_selectedMinute),
    );
  }

  DateTime? get _minDay =>
      widget.minDate == null ? null : DateUtils.dateOnly(widget.minDate!);

  DateTime? get _maxDay =>
      widget.maxDate == null ? null : DateUtils.dateOnly(widget.maxDate!);

  bool _inRange(DateTime day) {
    final minDay = _minDay;
    final maxDay = _maxDay;
    return (minDay == null || !day.isBefore(minDay)) &&
        (maxDay == null || !day.isAfter(maxDay));
  }

  void _pickEndOfDay() {
    _selectedHour = 23;
    _selectedMinute = 59;
    const duration = Duration(milliseconds: 250);
    _hourController.animateToItem(
      23,
      duration: duration,
      curve: Curves.easeOut,
    );
    _minuteController.animateToItem(
      _minutes.indexOf(59),
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(DateTime.now());
    final pickerStyle = TextStyle(
      color: colors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    Widget wheel({
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) label,
      required ValueChanged<int> onChanged,
      bool Function(int)? dimmed,
    }) {
      return CupertinoPicker.builder(
        scrollController: controller,
        itemExtent: 44,
        selectionOverlay: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colors.border, width: 1),
            ),
          ),
        ),
        onSelectedItemChanged: onChanged,
        childCount: count,
        itemBuilder: (_, index) => Center(
          child: Text(
            label(index),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: dimmed != null && dimmed(index)
                ? pickerStyle.copyWith(
                    color: colors.textMuted.withValues(alpha: 0.5),
                  )
                : pickerStyle,
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.socialCreatePickDateTime,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: wheel(
                      controller: _dateController,
                      count: _dates.length,
                      label: (index) => _dates[index] == today
                          ? l10n.notification_today
                          : DateFormat(
                              'EEE dd/MM',
                              locale,
                            ).format(_dates[index]),
                      dimmed: (index) => !_inRange(_dates[index]),
                      onChanged: (index) =>
                          setState(() => _selectedDate = _dates[index]),
                    ),
                  ),
                  Expanded(
                    child: wheel(
                      controller: _hourController,
                      count: 24,
                      label: (index) => index.toString().padLeft(2, '0'),
                      onChanged: (index) => _selectedHour = index,
                    ),
                  ),
                  Expanded(
                    child: wheel(
                      controller: _minuteController,
                      count: _minutes.length,
                      label: (index) =>
                          _minutes[index].toString().padLeft(2, '0'),
                      onChanged: (index) => _selectedMinute = _minutes[index],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.socialPlaceCancel),
                  ),
                ),
                if (widget.showEndOfDayChip)
                  ActionChip(
                    label: const Text('23:59'),
                    onPressed: _pickEndOfDay,
                  ),
                Expanded(
                  child: TextButton(
                    onPressed: _inRange(_selectedDate)
                        ? () => Navigator.of(context).pop(
                            DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedHour,
                              _selectedMinute,
                            ),
                          )
                        : null,
                    child: Text(l10n.socialPlaceConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
