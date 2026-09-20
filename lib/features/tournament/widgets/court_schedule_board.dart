import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Mobile counterpart of the web PublicCourtScheduleBoard.
///
/// The board deliberately uses the MatchModel contract already consumed by
/// the list and bracket views. This keeps schedule changes realtime through
/// the existing matches stream and avoids a second schedule API.
class CourtScheduleBoard extends StatefulWidget {
  final List<MatchModel> matches;
  final ValueChanged<MatchModel>? onMatchTap;

  const CourtScheduleBoard({super.key, required this.matches, this.onMatchTap});

  @override
  State<CourtScheduleBoard> createState() => _CourtScheduleBoardState();
}

class _CourtScheduleBoardState extends State<CourtScheduleBoard> {
  String? _selectedDate;
  double _zoom = 1;

  @override
  Widget build(BuildContext context) {
    final config = _scheduleConfig(widget.matches);
    final dates = _scheduleDates(widget.matches, config);
    final selectedDate = dates.contains(_selectedDate)
        ? _selectedDate!
        : dates.first;
    final scheduled =
        widget.matches
            .where(
              (match) =>
                  match.scheduledTime != null &&
                  _dateKey(match.scheduledTime!) == selectedDate,
            )
            .toList()
          ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));
    final courts = _courtsFor(scheduled);
    final timeRange = _timeRange(config);
    final stepMinutes = _positiveInt(
      config['stepMinutes'] ?? config['gridIncrementMinutes'],
      15,
    ).clamp(5, 60).toInt();
    final minutesPerSet = _positiveInt(config['minutesPerSet'], 15);
    final cellHeight = 52 * _zoom * stepMinutes / 60;
    final slotCount = math.max(
      1,
      ((timeRange.$2 - timeRange.$1) * 60 / stepMinutes).ceil(),
    );
    final gridHeight = slotCount * cellHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateStrip(context, dates, selectedDate, widget.matches),
        const SizedBox(height: 10),
        _buildBoardToolbar(context, scheduled.length, courts.length),
        const SizedBox(height: 8),
        if (scheduled.isEmpty)
          _buildEmptySchedule(context)
        else
          _buildGrid(
            context,
            scheduled,
            courts,
            timeRange,
            stepMinutes,
            cellHeight,
            gridHeight,
            minutesPerSet,
          ),
        _buildUnscheduledQueue(context, selectedDate),
      ],
    );
  }

  Widget _buildDateStrip(
    BuildContext context,
    List<String> dates,
    String selectedDate,
    List<MatchModel> allMatches,
  ) {
    final colors = context.colors;
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date == selectedDate;
          final count = allMatches
              .where(
                (match) =>
                    match.scheduledTime != null &&
                    _dateKey(match.scheduledTime!) == date,
              )
              .length;
          final parsed = DateTime.tryParse(date);
          final dayLabel = parsed == null
              ? date
              : _isToday(parsed)
              ? 'Hôm nay'
              : '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
          return Semantics(
            button: true,
            selected: isSelected,
            label: '$dayLabel, $count trận',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedDate = date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 92,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : colors.border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: .18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count trận',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withValues(alpha: .85)
                            : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoardToolbar(
    BuildContext context,
    int matchCount,
    int courtCount,
  ) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(AppIcons.calendar, size: 18, color: AppTheme.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$matchCount trận · $courtCount sân',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _zoomButton(
          context,
          icon: AppIcons.remove,
          enabled: _zoom > .7,
          onTap: () => setState(() => _zoom = math.max(.7, _zoom - .1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            '${(_zoom * 100).round()}%',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ),
        _zoomButton(
          context,
          icon: AppIcons.add,
          enabled: _zoom < 1.4,
          onTap: () => setState(() => _zoom = math.min(1.4, _zoom + .1)),
        ),
      ],
    );
  }

  Widget _zoomButton(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? colors.textSecondary : colors.textMuted,
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<MatchModel> scheduled,
    List<String> courts,
    (int, int) timeRange,
    int stepMinutes,
    double cellHeight,
    double gridHeight,
    int minutesPerSet,
  ) {
    const timeWidth = 54.0;
    const courtWidth = 184.0;
    final colors = context.colors;
    final contentWidth = timeWidth + courts.length * courtWidth;
    return Container(
      height: 560,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Container(
                        width: timeWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          border: Border(
                            right: BorderSide(color: colors.border),
                          ),
                        ),
                        child: Text(
                          'Giờ',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...courts.map(
                        (court) => Container(
                          width: courtWidth,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: .06),
                            border: Border(
                              right: BorderSide(color: colors.border),
                            ),
                          ),
                          child: Text(
                            court,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: gridHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeColumn(
                        context,
                        timeRange,
                        stepMinutes,
                        cellHeight,
                        gridHeight,
                      ),
                      ...courts.map(
                        (court) => _buildCourtColumn(
                          context,
                          court,
                          scheduled
                              .where((match) => _courtName(match) == court)
                              .toList(),
                          timeRange,
                          stepMinutes,
                          cellHeight,
                          gridHeight,
                          minutesPerSet,
                          courtWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(
    BuildContext context,
    (int, int) timeRange,
    int stepMinutes,
    double cellHeight,
    double gridHeight,
  ) {
    final colors = context.colors;
    final slotCount = ((timeRange.$2 - timeRange.$1) * 60 / stepMinutes).ceil();
    return SizedBox(
      width: 54,
      height: gridHeight,
      child: Stack(
        children: [
          for (var index = 0; index <= slotCount; index++)
            Positioned(
              top: math.min(index * cellHeight, gridHeight - 1),
              left: 0,
              right: 0,
              height: 1,
              child: Container(color: colors.border.withValues(alpha: .8)),
            ),
          for (var index = 0; index < slotCount; index++)
            Positioned(
              top: index * cellHeight - 8,
              left: 4,
              child: Text(
                _formatMinutes(timeRange.$1 * 60 + index * stepMinutes),
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourtColumn(
    BuildContext context,
    String court,
    List<MatchModel> matches,
    (int, int) timeRange,
    int stepMinutes,
    double cellHeight,
    double gridHeight,
    int minutesPerSet,
    double courtWidth,
  ) {
    final colors = context.colors;
    final slotCount = ((timeRange.$2 - timeRange.$1) * 60 / stepMinutes).ceil();
    return SizedBox(
      width: courtWidth,
      height: gridHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index <= slotCount; index++)
            Positioned(
              top: math.min(index * cellHeight, gridHeight - 1),
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                color: index % (60 ~/ stepMinutes) == 0
                    ? colors.border
                    : colors.border.withValues(alpha: .45),
              ),
            ),
          for (final match in matches)
            _buildMatchCard(
              context,
              match,
              timeRange,
              cellHeight,
              gridHeight,
              minutesPerSet,
            ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchModel match,
    (int, int) timeRange,
    double cellHeight,
    double gridHeight,
    int minutesPerSet,
  ) {
    final colors = context.colors;
    final start = match.scheduledTime!;
    final minutesFromStart = start.hour * 60 + start.minute - timeRange.$1 * 60;
    final top = (minutesFromStart / 60 * 52 * _zoom)
        .clamp(0.0, gridHeight - 44)
        .toDouble();
    final duration = _durationMinutes(match, minutesPerSet);
    final height = math.min(
      gridHeight - top,
      math.max(50.0, duration / 60 * 52 * _zoom),
    );
    final isLive = match.isLive;
    final isCompleted = match.isCompleted;
    final accent = isLive
        ? colors.warning
        : isCompleted
        ? colors.textMuted
        : AppTheme.primary;
    final background = isLive
        ? const Color(0xFFFFF4D6)
        : isCompleted
        ? colors.bgSurface
        : Colors.white;
    return Positioned(
      top: top,
      left: 6,
      right: 6,
      height: height,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9),
        elevation: 1,
        child: InkWell(
          onTap: widget.onMatchTap == null
              ? null
              : () => widget.onMatchTap!(match),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border(
                left: BorderSide(color: accent, width: 4),
                right: BorderSide(color: colors.border),
              ),
            ),
            child: _buildCardContent(context, match, accent, height),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    MatchModel match,
    Color accent,
    double height,
  ) {
    final colors = context.colors;
    final compact = height < 78;
    final statusLabel = match.isLive
        ? 'LIVE'
        : match.isCompleted
        ? 'Đã xong'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _stageLabel(match),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (statusLabel != null)
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 8.5,
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${_formatTime(match.scheduledTime!)} · ${_durationMinutes(match, 15)} phút',
          style: TextStyle(fontSize: 9, color: colors.textMuted),
        ),
        if (!compact) ...[
          const SizedBox(height: 5),
          _teamRow(context, match.team1Name, match.score1, accent),
          const SizedBox(height: 2),
          _teamRow(context, match.team2Name, match.score2, accent),
        ] else ...[
          const SizedBox(height: 3),
          Text(
            '${match.team1Name}  ·  ${match.team2Name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _teamRow(BuildContext context, String name, int score, Color accent) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            name.isEmpty ? 'TBD' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (score > 0 || accent == colors.textMuted)
          Text(
            '$score',
            style: TextStyle(
              fontSize: 11,
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySchedule(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(AppIcons.calendarX, size: 36, color: colors.textMuted),
          const SizedBox(height: 8),
          Text(
            'Chưa có trận được xếp lịch trong ngày này',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Các trận chưa có giờ hoặc sân sẽ nằm ở danh sách chờ bên dưới.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUnscheduledQueue(BuildContext context, String selectedDate) {
    final colors = context.colors;
    final queue = widget.matches.where((match) {
      return match.scheduledTime == null || !match.hasAssignedCourt;
    }).toList();
    if (queue.isEmpty) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chưa xếp vào bảng (${queue.length})',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          ...queue
              .take(8)
              .map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _queueCard(context, match),
                ),
              ),
          if (queue.length > 8)
            Text(
              'Còn ${queue.length - 8} trận khác',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _queueCard(BuildContext context, MatchModel match) {
    final colors = context.colors;
    return InkWell(
      onTap: widget.onMatchTap == null ? null : () => widget.onMatchTap!(match),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(AppIcons.clock, size: 17, color: colors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${match.team1Name}  ·  ${match.team2Name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _courtName(match).isEmpty ? 'Chưa có sân' : _courtName(match),
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _scheduleConfig(List<MatchModel> matches) {
    for (final match in matches) {
      final config = match.tournamentConfig;
      if (config != null && config.isNotEmpty) return config;
    }
    return const {};
  }

  List<String> _scheduleDates(
    List<MatchModel> matches,
    Map<String, dynamic> config,
  ) {
    final dates = <String>{};
    final configuredDate = config['scheduleDate']?.toString();
    if (configuredDate != null && configuredDate.isNotEmpty) {
      final parsed = DateTime.tryParse(configuredDate);
      if (parsed != null) dates.add(_dateKey(parsed));
    }
    for (final match in matches) {
      if (match.scheduledTime != null) {
        dates.add(_dateKey(match.scheduledTime!));
      }
    }
    if (dates.isEmpty) dates.add(_dateKey(DateTime.now()));
    final result = dates.toList()..sort();
    return result;
  }

  List<String> _courtsFor(List<MatchModel> matches) {
    final courts = <String>{};
    for (final match in matches) {
      final court = _courtName(match);
      if (court.isNotEmpty) courts.add(court);
    }
    return courts.isEmpty ? const ['Sân 1'] : courts.toList();
  }

  String _courtName(MatchModel match) =>
      match.hasAssignedCourt ? match.court.trim() : '';

  (int, int) _timeRange(Map<String, dynamic> config) {
    final start = _parseTime(config['operatingStart']?.toString()) ?? 8 * 60;
    var end = _parseTime(config['operatingEnd']?.toString()) ?? 22 * 60;
    if (end <= start) end = start + 12 * 60;
    return (start ~/ 60, end ~/ 60 + (end % 60 == 0 ? 0 : 1));
  }

  int _durationMinutes(MatchModel match, int minutesPerSet) {
    final raw = match.tournamentConfig?['durationMinutes'];
    final configured = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    return math.max(
      30,
      match.timeLimitMinutes ?? configured ?? minutesPerSet * 2,
    );
  }

  String _stageLabel(MatchModel match) {
    final value = match.stageName?.trim();
    if (value != null && value.isNotEmpty) return value;
    final group = match.groupName?.trim();
    if (group != null && group.isNotEmpty) return group;
    return 'Vòng ${match.round} · Trận ${match.matchNumber}';
  }

  int _positiveInt(dynamic value, int fallback) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return now.year == date.year &&
      now.month == date.month &&
      now.day == date.day;
}

int? _parseTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.trim().split(':');
  final hour = int.tryParse(parts.first);
  if (hour == null) return null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (hour < 0 || hour > 24 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

String _formatMinutes(int totalMinutes) {
  final hour = (totalMinutes ~/ 60) % 24;
  final minute = totalMinutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime value) =>
    _formatMinutes(value.hour * 60 + value.minute);

/// Stable helpers used by schedule tests and other mobile schedule surfaces.
String scheduleDateKey(DateTime date) => _dateKey(date);

String scheduleTimeLabel(int totalMinutes) => _formatMinutes(totalMinutes);
