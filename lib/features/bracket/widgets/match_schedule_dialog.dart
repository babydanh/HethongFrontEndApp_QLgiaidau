import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';

/// Opens the one-match schedule dialog (court, day, start time, duration).
/// Resolves to true once the schedule was saved or cleared, null when dismissed
/// and for matches that can no longer be scheduled.
Future<bool?> showMatchScheduleDialog(
  BuildContext context, {
  required String tournamentId,
  required MatchModel match,
}) {
  if (isScheduleLocked(match)) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.scheduleQuickLocked)));
    return Future.value();
  }
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _MatchScheduleDialog(tournamentId: tournamentId, match: match),
  );
}

class _MatchScheduleDialog extends ConsumerStatefulWidget {
  const _MatchScheduleDialog({required this.tournamentId, required this.match});

  final String tournamentId;
  final MatchModel match;

  @override
  ConsumerState<_MatchScheduleDialog> createState() =>
      _MatchScheduleDialogState();
}

class _MatchScheduleDialogState extends ConsumerState<_MatchScheduleDialog> {
  static const _fallbackMinutesPerSet = 15;

  List<ScheduleCourt>? _courts;
  String? _loadError;
  String? _saveError;
  bool _saving = false;

  late String _courtId;
  late DateTime _day;
  late int _startMinute;
  late int _duration;
  late List<int> _startOptions;
  late List<int> _durationOptions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> get _settings =>
      ref
          .read(tournamentProvider(widget.tournamentId))
          .value
          ?.scheduleSettings ??
      const <String, dynamic>{};

  Future<void> _load() async {
    try {
      final courts = parseScheduleCourts(
        await ref
            .read(tournamentManagementRepositoryProvider)
            .getVenues(widget.tournamentId),
      );
      if (!mounted) return;
      setState(() {
        _courts = courts;
        if (courts.isNotEmpty) _initFields(courts);
      });
    } on Exception catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _courts = const [];
        _loadError = ErrorParser.parse(error, l10n.matchSchedule_error, l10n);
      });
    }
  }

  void _initFields(List<ScheduleCourt> courts) {
    final match = widget.match;
    final settings = _settings;
    final minutesPerSet =
        (settings['minutesPerSet'] as num?)?.toInt() ?? _fallbackMinutesPerSet;
    final current = match.scheduledTime?.toLocal();
    final choices = quickScheduleMinutes(
      startHour: _hourOf(settings['operatingStart'], 7),
      endHour: _hourOf(settings['operatingEnd'], 22),
      stepMinutes: scheduleStepMinutesOf(settings),
    );
    _courtId = courts.any((c) => c.id == match.courtId)
        ? match.courtId!
        : courts.first.id;
    _day = DateUtils.dateOnly(current ?? DateTime.now());
    _startMinute = current == null
        ? (choices.isEmpty ? 7 * 60 : choices.first)
        : current.hour * 60 + current.minute;
    _duration = scheduledDurationMinutes(match, minutesPerSet: minutesPerSet);
    _startOptions = <int>{...choices, _startMinute}.toList()..sort();
    _durationOptions = <int>{...scheduleDurationOptions, _duration}.toList()
      ..sort();
  }

  /// Opening/closing hour from the settings: a number or a "07:00" string.
  static int _hourOf(Object? value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.split(':').first.trim()) ?? fallback;
    }
    return fallback;
  }

  Future<void> _submit({required bool clear}) async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final courts = _courts ?? const <ScheduleCourt>[];
    final court = courts.where((c) => c.id == _courtId).firstOrNull;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final repository = ref.read(matchRepositoryProvider);
      if (clear) {
        await repository.updateSchedule(
          widget.tournamentId,
          widget.match.id,
          clear: const {
            MatchScheduleField.courtId,
            MatchScheduleField.courtName,
            MatchScheduleField.scheduledAt,
          },
        );
      } else {
        await repository.updateSchedule(
          widget.tournamentId,
          widget.match.id,
          courtId: court?.id,
          courtName: court?.name,
          scheduledAt: DateTime(
            _day.year,
            _day.month,
            _day.day,
            _startMinute ~/ 60,
            _startMinute % 60,
          ),
          durationMinutes: _duration,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = ErrorParser.parse(error, l10n.matchSchedule_error, l10n);
      });
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _day,
    );
    if (picked == null || !mounted) return;
    setState(() => _day = DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courts = _courts;
    final ready = courts != null && courts.isNotEmpty;
    return AlertDialog(
      title: Text(l10n.matchSchedule_title),
      content: SingleChildScrollView(
        child: courts == null
            ? const _FormSkeleton()
            : ready
            ? _form(context, l10n, courts)
            : Text(_loadError ?? l10n.scheduleQuickNoCourts),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        if (ready && widget.match.scheduledTime != null)
          TextButton(
            onPressed: _saving ? null : () => _submit(clear: true),
            child: Text(l10n.scheduleQuickClear),
          ),
        if (ready)
          FilledButton(
            onPressed: _saving ? null : () => _submit(clear: false),
            child: Text(l10n.matchSchedule_save),
          ),
      ],
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    List<ScheduleCourt> courts,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _courtId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.scheduleQuickCourt),
          items: [
            for (final court in courts)
              DropdownMenuItem(
                value: court.id,
                child: Text(court.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _courtId = value ?? _courtId),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickDay,
          icon: const Icon(Icons.event_rounded),
          label: Text(
            '${l10n.scheduleQuickDate}: ${DateFormat('dd/MM/yyyy').format(_day)}',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _startMinute,
          decoration: InputDecoration(labelText: l10n.scheduleQuickStart),
          items: [
            for (final minute in _startOptions)
              DropdownMenuItem(value: minute, child: Text(_hhmm(minute))),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _startMinute = value ?? _startMinute),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _duration,
          decoration: InputDecoration(labelText: l10n.scheduleQuickDuration),
          items: [
            for (final minutes in _durationOptions)
              DropdownMenuItem(
                value: minutes,
                child: Text(l10n.scheduleQuickMinutes(minutes)),
              ),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _duration = value ?? _duration),
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 10),
          Text(
            _saveError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';
}

/// Khung form giả. Không dùng LayoutBuilder vì AlertDialog đo kích thước nội tại.
class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SkeletonScope(
      child: SizedBox(
        width: 280,
        child: Column(
          children: [
            SkeletonBox(height: 48, radius: 12),
            SizedBox(height: 12),
            SkeletonBox(height: 48, radius: 12),
            SizedBox(height: 12),
            SkeletonBox(height: 48, radius: 12),
          ],
        ),
      ),
    ),
  );
}
