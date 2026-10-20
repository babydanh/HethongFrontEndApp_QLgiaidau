import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';

class MatchesTab extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isLite;
  final Map<String, dynamic> scheduleSettings;

  /// Địa điểm của giải; sân của chúng là cột lưới kể cả khi chưa có trận xếp.
  final List<String> venueIds;
  final String? tournamentVenueName;
  final String? tournamentLocationAddress;
  final Map<String, String> divisionNameById;

  const MatchesTab({
    super.key,
    required this.tournamentId,
    this.isLite = false,
    this.scheduleSettings = const {},
    this.venueIds = const [],
    this.tournamentVenueName,
    this.tournamentLocationAddress,
    this.divisionNameById = const {},
  });

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab> {
  static final RegExp _clockTimePattern = RegExp(
    r'^([01]?\d|2[0-3]):([0-5]\d)$',
  );
  String? _selectedScheduleDateKey;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(
      widget.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );
    // Sân của các địa điểm gắn với giải; lỗi mạng/khách chưa đăng nhập chỉ
    // làm thiếu cột cấu hình, cột từ trận đã xếp vẫn còn.
    final venueCourtNames = [
      for (final venueId in widget.venueIds)
        ...?ref.watch(publicVenueCourtNamesProvider(venueId)).value,
    ];

    return matchesAsync.when(
      data: (allMatches) {
        final configuredDate = _parseScheduleDate(
          widget.scheduleSettings['scheduleDate'],
        );
        final scheduleDates = _availableScheduleDates(
          allMatches,
          configuredDate,
        );

        DateTime? selectedDate;
        for (final date in scheduleDates) {
          if (_scheduleDateKey(date) == _selectedScheduleDateKey) {
            selectedDate = date;
            break;
          }
        }
        selectedDate ??= _defaultScheduleDate(allMatches, configuredDate);
        final selectedDateKey = selectedDate == null
            ? null
            : _scheduleDateKey(selectedDate);

        var matches = allMatches;
        final query = _searchQuery.trim().toLowerCase();
        if (query.isNotEmpty) {
          matches = matches.where((match) {
            final sides = [
              participantLabel(
                teamName: matchSideTeamName(match, 1),
                players: matchSidePlayers(match, 1),
              ),
              participantLabel(
                teamName: matchSideTeamName(match, 2),
                players: matchSidePlayers(match, 2),
              ),
            ].join(' ').toLowerCase();
            return sides.contains(query) ||
                match.court.toLowerCase().contains(query) ||
                (match.courtName ?? '').toLowerCase().contains(query) ||
                (match.refereeName ?? '').toLowerCase().contains(query);
          }).toList();
        }

        final scheduledMatches =
            matches.where((match) {
                final scheduledTime = match.scheduledTime;
                return scheduledTime != null &&
                    (selectedDateKey == null ||
                        _scheduleDateKey(scheduledTime.toLocal()) ==
                            selectedDateKey);
              }).toList()
              ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));

        final matchesByCourt = <String, List<MatchModel>>{};
        final courtLabels = <String, String>{};
        for (final match in scheduledMatches) {
          final courtName = _courtDisplayName(match);
          if (courtName == null) continue;

          final courtId = match.courtId?.trim();
          final groupKey = courtId != null && courtId.isNotEmpty
              ? 'id:$courtId'
              : 'name:${courtName.toLowerCase()}';
          courtLabels[groupKey] = courtName;
          (matchesByCourt[groupKey] ??= <MatchModel>[]).add(match);
        }

        final courtGroups = matchesByCourt.entries.toList()
          ..sort(
            (a, b) => courtLabels[a.key]!.toLowerCase().compareTo(
              courtLabels[b.key]!.toLowerCase(),
            ),
          );
        final hours = _configuredHours(l10n);


        // ── Dữ liệu cho lưới ──
        // Cột sân = sân của địa điểm giải + sân từ TOÀN BỘ trận, KHÔNG lọc theo
        // ngày: sân không có trận hôm nay vẫn giữ cột, số cột không nhảy theo
        // ngày. Trận chưa xếp (thiếu giờ/sân) không bao giờ vẽ vào ô; lịch chỉ
        // có trận chưa xếp vẫn hiện lưới trống nếu biết sân.
        final gridCourts = <String>{
          ...venueCourtNames,
          for (final match in allMatches) ?_courtDisplayName(match),
        }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final gridMatches = courtGroups
            .expand((g) => g.value)
            .where((m) => m.scheduledTime != null)
            .toList();
        final gridStartHour = _operatingHour(
          widget.scheduleSettings['operatingStart'],
          fallback: 7,
        );
        final gridEndHour = _operatingHour(
          widget.scheduleSettings['operatingEnd'],
          fallback: 22,
        );
        // Tên vòng tính trên toàn bộ trận cùng hạng mục (không lọc ngày/tìm kiếm),
        // để số trận mỗi vòng đúng như sơ đồ: 8 trận → "Vòng 1/8".
        final matchesByDivision = <String?, List<MatchModel>>{};
        for (final match in allMatches) {
          (matchesByDivision[match.divisionId] ??= []).add(match);
        }
        String roundLabelOf(MatchModel match) => MatchRoundLabel.formatRound(
          match: match,
          allMatches: matchesByDivision[match.divisionId],
          l10n: l10n,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: _buildSearchField(colors, l10n),
            ),
            if (scheduleDates.length > 1)
              _buildDateSelector(scheduleDates, selectedDate, colors),
            if (selectedDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  DateFormat.yMMMMd(
                    Localizations.localeOf(context).toString(),
                  ).format(selectedDate),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (hours != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hours,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (gridCourts.isEmpty)
              _buildEmptyState(
                l10n,
                colors,
                hasSourceMatches: allMatches.any(_isPlaced),
              )
            else ...[
              // Lưới sân nằm trong một khung bo viền duy nhất.
              Container(
                key: const ValueKey('schedule-frame'),
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ScheduleGrid(
                    courts: gridCourts,
                    matches: gridMatches,
                    startHour: gridStartHour,
                    endHour: gridEndHour,
                    minutesPerSet: _minutesPerSetOf(
                      widget.scheduleSettings['minutesPerSet'],
                    ),
                    divisionNameById: widget.divisionNameById,
                    slotHeight: 120,
                    emphasizeTimeLabels: true,
                    onTapMatch: _openMatchById,
                    roundLabelOf: roundLabelOf,
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (_, _) => Center(
        child: Text(
          l10n.matchesLoadError,
          style: TextStyle(color: colors.textSecondary),
        ),
      ),
    );
  }

  List<DateTime> _availableScheduleDates(
    List<MatchModel> matches,
    DateTime? configuredDate,
  ) {
    final dates = <String, DateTime>{};
    for (final match in matches) {
      final scheduledTime = match.scheduledTime;
      if (scheduledTime == null) continue;
      final date = _dateOnly(scheduledTime.toLocal());
      dates[_scheduleDateKey(date)] = date;
    }
    if (configuredDate != null) {
      dates[_scheduleDateKey(configuredDate)] = configuredDate;
    }
    return dates.values.toList()..sort((a, b) => a.compareTo(b));
  }

  /// Ngày mặc định: ngày cấu hình nếu có trận; không thì ngày sớm nhất có trận.
  DateTime? _defaultScheduleDate(
    List<MatchModel> matches,
    DateTime? configuredDate,
  ) {
    final matchDates = _availableScheduleDates(matches, null);
    if (configuredDate != null &&
        matchDates.any(
          (date) => _scheduleDateKey(date) == _scheduleDateKey(configuredDate),
        )) {
      return configuredDate;
    }
    return matchDates.isEmpty ? configuredDate : matchDates.first;
  }

  DateTime? _parseScheduleDate(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? null : _dateOnly(parsed.toLocal());
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _scheduleDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String? _courtDisplayName(MatchModel match) {
    final explicitName = match.courtName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) return explicitName;

    final displayCourt = match.court.trim();
    if (displayCourt.isEmpty) return null;
    final normalizedCourt = displayCourt.toLowerCase();
    final venueName = widget.tournamentVenueName?.trim().toLowerCase();
    final locationAddress = widget.tournamentLocationAddress
        ?.trim()
        .toLowerCase();
    if (normalizedCourt == venueName || normalizedCourt == locationAddress) {
      return null;
    }
    return displayCourt;
  }

  String? _configuredHours(AppLocalizations l10n) {
    final start = _validClockTime(widget.scheduleSettings['operatingStart']);
    final end = _validClockTime(widget.scheduleSettings['operatingEnd']);
    if (start == null || end == null) return null;
    return l10n.tournamentScheduleHours(start, end);
  }

  String? _validClockTime(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null) return null;
    final match = _clockTimePattern.firstMatch(raw);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    return '${hour.toString().padLeft(2, '0')}:${match.group(2)}';
  }

  Widget _buildSearchField(AppColorsExtension colors, AppLocalizations l10n) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: l10n.matchesSearchHint,
          hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 19,
            color: colors.textMuted,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: l10n.matchesSearchHint,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    List<DateTime> dates,
    DateTime? selectedDate,
    AppColorsExtension colors,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final selectedKey = selectedDate == null
        ? null
        : _scheduleDateKey(selectedDate);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final date in dates) ...[
            Semantics(
              button: true,
              selected: _scheduleDateKey(date) == selectedKey,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(
                  () => _selectedScheduleDateKey = _scheduleDateKey(date),
                ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _scheduleDateKey(date) == selectedKey
                        ? AppTheme.primary
                        : colors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _scheduleDateKey(date) == selectedKey
                          ? AppTheme.primary
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    DateFormat.MMMd(locale).format(date),
                    style: TextStyle(
                      color: _scheduleDateKey(date) == selectedKey
                          ? Colors.white
                          : colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// Giờ mở cửa từ scheduleSettings, rơi về [fallback] khi thiếu/sai định dạng.
  int _operatingHour(Object? value, {required int fallback}) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return fallback;
    final match = _clockTimePattern.firstMatch(raw);
    if (match == null) return fallback;
    final hour = int.tryParse(match.group(1)!);
    if (hour == null || hour < 0 || hour > 23) return fallback;
    return hour;
  }

  /// Phút mỗi set từ scheduleSettings; thiếu/sai thì 15, tối thiểu 5 (như web).
  int _minutesPerSetOf(Object? value) {
    final parsed = value is num && value.isFinite
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '');
    if (parsed == null || parsed == 0) return 15;
    return parsed < 5 ? 5 : parsed;
  }

  /// Trận đã xếp = có giờ và có sân; chỉ những trận này lên lịch công khai.
  bool _isPlaced(MatchModel match) =>
      match.scheduledTime != null && _courtDisplayName(match) != null;

  /// Mở màn chi tiết trận từ thẻ trong lưới — dùng chung đường dẫn với thẻ thường.
  void _openMatchById(String matchId) {
    context.push(
      NavigationHelper.getLiveMatchRoute(widget.tournamentId, matchId),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    AppColorsExtension colors, {
    required bool hasSourceMatches,
  }) {
    final title = hasSourceMatches
        ? l10n.liveMatchesFilteredEmpty
        : l10n.liveMatchesNoMatches;
    final description = hasSourceMatches
        ? l10n.matchesTryChangeFilter
        : l10n.liveMatchesNoMatchesDescription;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_rounded,
              size: 48,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
