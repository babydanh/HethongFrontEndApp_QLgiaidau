import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';

typedef _UnplacedSection = ({String heading, List<MatchModel> matches});

class MatchesTab extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final String? selectedDivision;
  final bool isLite;
  final Map<String, dynamic> scheduleSettings;
  final String? tournamentVenueName;
  final String? tournamentLocationAddress;

  const MatchesTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.selectedDivision,
    this.isLite = false,
    this.scheduleSettings = const {},
    this.tournamentVenueName,
    this.tournamentLocationAddress,
  });

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab> {
  static final RegExp _clockTimePattern = RegExp(
    r'^([01]?\d|2[0-3]):([0-5]\d)$',
  );
  String _statusFilter = 'all'; // all, live, scheduled, completed
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

    return matchesAsync.when(
      data: (allMatches) {
        final tournamentMatches = allMatches.where((match) {
          if (widget.selectedDivisionId == null ||
              widget.selectedDivisionId!.isEmpty) {
            return true;
          }
          final divisionId =
              match.tournamentConfig?['divisionId']?.toString() ??
              match.tournamentConfig?['tournamentDivisionId']?.toString();
          return divisionId == null ||
              divisionId.isEmpty ||
              divisionId == widget.selectedDivisionId;
        }).toList();

        final configuredDate = _parseScheduleDate(
          widget.scheduleSettings['scheduleDate'],
        );
        final scheduleDates = _availableScheduleDates(
          tournamentMatches,
          configuredDate,
        );

        DateTime? selectedDate;
        for (final date in scheduleDates) {
          if (_scheduleDateKey(date) == _selectedScheduleDateKey) {
            selectedDate = date;
            break;
          }
        }
        if (selectedDate == null && configuredDate != null) {
          selectedDate = configuredDate;
        }
        selectedDate ??= scheduleDates.isEmpty ? null : scheduleDates.first;
        final selectedDateKey = selectedDate == null
            ? null
            : _scheduleDateKey(selectedDate);

        var matches = tournamentMatches;
        final query = _searchQuery.trim().toLowerCase();
        if (query.isNotEmpty) {
          matches = matches.where((match) {
            return match.team1Name.toLowerCase().contains(query) ||
                match.team2Name.toLowerCase().contains(query) ||
                match.court.toLowerCase().contains(query) ||
                (match.courtName ?? '').toLowerCase().contains(query) ||
                (match.refereeName ?? '').toLowerCase().contains(query);
          }).toList();
        }

        if (_statusFilter == 'live') {
          matches = matches.where((match) => match.isLive).toList();
        } else if (_statusFilter == 'scheduled') {
          matches = matches
              .where(
                (match) =>
                    !match.isLive &&
                    !match.isCompleted &&
                    match.status != AppConstants.matchCompleted,
              )
              .toList();
        } else if (_statusFilter == 'completed') {
          matches = matches
              .where(
                (match) =>
                    match.isCompleted ||
                    match.status == AppConstants.matchCompleted,
              )
              .toList();
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
        final unscheduledMatches =
            matches.where((match) => match.scheduledTime == null).toList()
              ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

        final matchesByCourt = <String, List<MatchModel>>{};
        final courtLabels = <String, String>{};
        final scheduledWithoutCourt = <MatchModel>[];
        final scheduledWithoutCourtName = <MatchModel>[];
        for (final match in scheduledMatches) {
          final courtName = _courtDisplayName(match);
          if (courtName == null) {
            if (match.courtId?.trim().isNotEmpty == true) {
              scheduledWithoutCourtName.add(match);
            } else {
              scheduledWithoutCourt.add(match);
            }
            continue;
          }

          final courtId = match.courtId?.trim();
          final groupKey = courtId != null && courtId.isNotEmpty
              ? 'id:$courtId'
              : 'name:${courtName.toLowerCase()}';
          courtLabels[groupKey] = courtName;
          (matchesByCourt[groupKey] ??= <MatchModel>[]).add(match);
        }
        final unplacedSections = <_UnplacedSection>[
          if (scheduledWithoutCourt.isNotEmpty)
            (
              heading: l10n.matchesCourtNotAssigned,
              matches: scheduledWithoutCourt,
            ),
          if (scheduledWithoutCourtName.isNotEmpty)
            (
              heading: l10n.matchesCourtNameUnavailable,
              matches: scheduledWithoutCourtName,
            ),
          if (unscheduledMatches.isNotEmpty)
            (heading: l10n.matchNotScheduled, matches: unscheduledMatches),
        ];
        final unplacedMatchCount = unplacedSections.fold<int>(
          0,
          (count, section) => count + section.matches.length,
        );

        final courtGroups = matchesByCourt.entries.toList()
          ..sort(
            (a, b) => courtLabels[a.key]!.toLowerCase().compareTo(
              courtLabels[b.key]!.toLowerCase(),
            ),
          );
        final hours = _configuredHours(l10n);
        final hasVisibleMatches =
            courtGroups.isNotEmpty || unplacedMatchCount > 0;

        // ── Dữ liệu cho lưới ──
        // Cột sân gom từ TOÀN BỘ trận của division, KHÔNG lọc theo ngày: nếu lấy
        // từ courtGroups (đã lọc ngày) thì sân hôm nay không có trận sẽ mất
        // cột, và số cột nhảy theo từng ngày. Lọc ngày chỉ quyết định trận nào
        // hiện trong ô, không quyết định có bao nhiêu cột.
        final gridCourts = <String>{
          for (final match in tournamentMatches) ?_courtDisplayName(match),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            // Keep the expanded fallback scrollable without crowding the grid.
            final maxUnplacedListHeight = constraints.maxHeight < 960
                ? constraints.maxHeight * 0.25
                : 240.0;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      _buildSearchField(colors, l10n),
                      const SizedBox(height: 10),
                      _buildStatusFilters(allMatches, l10n),
                    ],
                  ),
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
                        Text(
                          hours,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!hasVisibleMatches)
                  Expanded(
                    child: _buildEmptyState(
                      l10n,
                      colors,
                      hasSourceMatches: tournamentMatches.isNotEmpty,
                    ),
                  )
                else ...[
                  // ScheduleGrid needs bounded height. The unplaced list below
                  // stays collapsed by default so it does not reserve grid space.
                  if (gridCourts.isNotEmpty)
                    Expanded(
                      child: ScheduleGrid(
                        courts: gridCourts,
                        matches: gridMatches,
                        startHour: gridStartHour,
                        endHour: gridEndHour,
                        onTapMatch: _openMatchById,
                      ),
                    ),
                  if (unplacedMatchCount > 0)
                    _buildUnplacedMatches(
                      sections: unplacedSections,
                      matchCount: unplacedMatchCount,
                      maxListHeight: maxUnplacedListHeight,
                      l10n: l10n,
                      colors: colors,
                    ),
                ],
              ],
            );
          },
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
      height: 44,
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
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: l10n.matchesSearchHint,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildStatusFilters(List<MatchModel> matches, AppLocalizations l10n) {
    final liveCount = matches.where((match) => match.isLive).length;
    final scheduledCount = matches
        .where(
          (match) =>
              !match.isLive &&
              !match.isCompleted &&
              match.status != AppConstants.matchCompleted,
        )
        .length;
    final completedCount = matches
        .where(
          (match) =>
              match.isCompleted || match.status == AppConstants.matchCompleted,
        )
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            'all',
            '${l10n.matchesStatusAll} (${matches.length})',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'live',
            '${l10n.matchesStatusLive} ($liveCount)',
            isLive: true,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'scheduled',
            '${l10n.matchesStatusScheduled} ($scheduledCount)',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'completed',
            '${l10n.matchesStatusCompleted} ($completedCount)',
          ),
        ],
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
                        ? AppTheme.primary.withValues(alpha: 0.14)
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
                          ? AppTheme.primary
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

  Widget _buildCourtHeading(
    String label,
    int count,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Icon(Icons.sports_tennis_rounded, size: 17, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnplacedMatches({
    required List<_UnplacedSection> sections,
    required int matchCount,
    required double maxListHeight,
    required AppLocalizations l10n,
    required AppColorsExtension colors,
  }) {
    final itemCount = sections.fold<int>(
      0,
      (count, section) => count + section.matches.length + 1,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ExpansionTile(
        key: const ValueKey('schedule-unplaced-matches'),
        leading: Icon(
          Icons.sports_tennis_rounded,
          size: 18,
          color: colors.textMuted,
        ),
        title: Text(
          l10n.matchesUnplacedSection(matchCount),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: EdgeInsets.zero,
        shape: shape,
        collapsedShape: shape,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: itemCount,
              itemBuilder: (_, index) {
                for (final section in sections) {
                  if (index == 0) {
                    return _buildCourtHeading(
                      section.heading,
                      section.matches.length,
                      colors,
                    );
                  }
                  index--;
                  if (index < section.matches.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                      child: _buildMatchCard(section.matches[index]),
                    );
                  }
                  index -= section.matches.length;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
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

  /// Mở màn chi tiết trận từ thẻ trong lưới — dùng chung đường dẫn với thẻ thường.
  void _openMatchById(String matchId) {
    context.push(
      NavigationHelper.getLiveMatchRoute(widget.tournamentId, matchId),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    final displayMatch = _courtDisplayName(match) == null
        ? match.copyWith(court: '')
        : match;
    return LiveMatchCardV2(
      match: displayMatch,
      isLive: match.isLive,
      isCompleted:
          match.isCompleted || match.status == AppConstants.matchCompleted,
      onTap: () {
        if (match.hasTeams) {
          context.push(
            NavigationHelper.getLiveMatchRoute(widget.tournamentId, match.id),
          );
        }
      },
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

  Widget _buildFilterChip(String key, String label, {bool isLive = false}) {
    final selected = _statusFilter == key;
    final colors = context.colors;

    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isLive ? colors.error : AppTheme.primary)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (isLive ? colors.error : AppTheme.primary)
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLive) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : colors.error,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
