import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SocialDateTimePickerSheet extends StatefulWidget {
  const SocialDateTimePickerSheet({super.key, required this.initialDateTime});

  final DateTime initialDateTime;

  static Future<DateTime?> show(
    BuildContext context,
    DateTime initialDateTime,
  ) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          SocialDateTimePickerSheet(initialDateTime: initialDateTime),
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
    _firstDate = initialDate.isBefore(today) ? initialDate : today;
    final lastDate = initialDate.isAfter(today.add(const Duration(days: 365)))
        ? initialDate
        : today.add(const Duration(days: 365));
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
            style: pickerStyle,
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
                      onChanged: (index) => _selectedDate = _dates[index],
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
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedHour,
                        _selectedMinute,
                      ),
                    ),
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
