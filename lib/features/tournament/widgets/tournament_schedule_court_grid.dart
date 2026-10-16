import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/core/services/schedule_print_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Sân của giải: cần cả id để ghi lịch và tên để ghép vào cột lưới.
typedef ScheduleCourt = ({String id, String name});

/// Một nội dung thi đấu để chọn trong thanh công cụ.
typedef ScheduleDivision = ({String id, String name});

/// Đọc sân của giải từ danh sách cơ sở (mỗi cơ sở có mảng `courts`). Sân thiếu
/// tên bị bỏ qua; trùng tên thì giữ bản ghi sau cùng. Kết quả sắp theo tên.
List<ScheduleCourt> parseScheduleCourts(List<Map<String, dynamic>> venues) {
  final byName = <String, ScheduleCourt>{};
  for (final venue in venues) {
    final courts = venue['courts'];
    if (courts is! List) continue;
    for (final court in courts) {
      if (court is! Map) continue;
      final name = (court['name'] ?? court['courtName'] ?? '')
          .toString()
          .trim();
      if (name.isEmpty) continue;
      byName[name] = (
        id: (court['id'] ?? court['courtId'] ?? '').toString(),
        name: name,
      );
    }
  }
  final sorted = byName.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return sorted;
}

/// Lưới lịch thi đấu cho BTC: cột là **sân của giải** (lấy từ mục Sân, không
/// suy từ trận), kèm chọn ngày, chọn sân, và khay trận chưa xếp để kéo lên lưới.
///
/// Khác lưới ở trang công khai: sân trống vẫn có cột, và khi có [onScheduleDrop]
/// thì mới bật chế độ xếp lịch (kéo thả).
class TournamentScheduleCourtGrid extends ConsumerStatefulWidget {
  const TournamentScheduleCourtGrid({
    super.key,
    required this.tournamentId,
    required this.matches,
    this.scheduleSettings = const {},
    this.selectedMatchId,
    this.onTapMatch,
    this.onScheduleDrop,
    this.onOpenFullscreen,
    this.onBulkSchedule,
    this.onPrint,
    this.divisions = const [],
    this.selectedDivisionId,
    this.onDivisionSelected,
    this.onTapEmptyCell,
    this.onScheduleSwap,
    this.onBulkDuration,
    this.onBulkMoveCourt,
    this.onAutoSchedule,
    this.draftMatches = const [],
    this.draftSkippedCount = 0,
    this.onApplyDraft,
    this.onCancelDraft,
    this.draftProgress,
  });

  final String tournamentId;

  /// Trận đã lọc theo nội dung và trạng thái ở màn gọi.
  final List<MatchModel> matches;
  final Map<String, dynamic> scheduleSettings;
  final String? selectedMatchId;
  final ValueChanged<String>? onTapMatch;

  /// Null = chỉ xem. Có giá trị = bật kéo thả xếp lịch.
  final void Function(
    String matchId,
    String courtId,
    String courtName,
    DateTime scheduledAt,
  )?
  onScheduleDrop;

  /// Mở không gian toàn màn hình (màn riêng, xoay ngang). Null thì không hiện nút.
  final VoidCallback? onOpenFullscreen;

  /// Xếp nhiều trận vào vùng ô đã chọn: nhận danh sách ô trống (theo thứ tự giờ
  /// rồi tới sân) và danh sách trận chưa xếp. Null thì không hiện nút.
  final void Function(
    List<({String courtId, String courtName, DateTime at})> cells,
    List<MatchModel> waiting,
  )?
  onBulkSchedule;

  /// Ghi đè thao tác in (dùng cho test). Null thì in bằng [SchedulePrintService]
  /// với chính dữ liệu lưới đang hiện.
  final Future<void> Function()? onPrint;

  /// Nội dung thi đấu để chọn trong thanh công cụ (như dropdown của web).
  final List<ScheduleDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<String>? onDivisionSelected;

  /// Chạm vào ô trống: mở chọn trận chờ để xếp vào đúng sân và giờ đó.
  final void Function(String courtId, String courtName, DateTime at)?
  onTapEmptyCell;

  /// Thả trận lên thẻ trận khác để đổi chỗ hai trận (kể cả trận từ khay).
  final void Function(String draggedMatchId, String targetMatchId)?
  onScheduleSwap;

  /// Đặt thời lượng cho các trận đã xếp trong vùng chọn. Null thì không hiện nút.
  final void Function(List<MatchModel> matches, int minutes)? onBulkDuration;

  /// Dời các trận đã xếp trong vùng chọn sang sân khác, giữ nguyên giờ.
  final void Function(List<MatchModel> matches, ScheduleCourt court)?
  onBulkMoveCourt;

  /// Mở xếp tự động (nút ⚡). Null thì không hiện nút.
  final VoidCallback? onAutoSchedule;

  /// Bản nháp xếp tự động: hiện đứt nét, không kéo được, chưa tính là đã xếp.
  final List<MatchModel> draftMatches;

  /// Số trận server bỏ qua trong lần xem trước gần nhất.
  final int draftSkippedCount;

  /// Áp dụng bản nháp (ghi xuống server). Null thì thanh bản nháp không có nút.
  final VoidCallback? onApplyDraft;

  /// Huỷ bản nháp, không ghi gì xuống server.
  final VoidCallback? onCancelDraft;

  /// Tiến độ khi đang ghi bản nháp (đã ghi / tổng). Null khi không ghi.
  final ({int done, int total})? draftProgress;

  @override
  ConsumerState<TournamentScheduleCourtGrid> createState() =>
      _TournamentScheduleCourtGridState();
}

class _TournamentScheduleCourtGridState
    extends ConsumerState<TournamentScheduleCourtGrid> {
  late Future<List<ScheduleCourt>> _courtsFuture;

  /// Chiều cao một ô 15 phút; host giữ state, lưới chỉ báo khi kéo tay nắm.
  double _slotHeight = 144;

  /// Null = hiện tất cả sân.
  Set<String>? _selectedCourts;

  /// Ngày đang xem; chọn ngày đầu tiên có trận khi biết dữ liệu.
  DateTime? _day;

  /// Vùng ô đang được chọn bằng nhấn giữ kéo.
  ScheduleRange? _range;

  @override
  void initState() {
    super.initState();
    _courtsFuture = _loadCourts();
  }

  @override
  void didUpdateWidget(TournamentScheduleCourtGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bản nháp mở đúng ngày của nháp để người dùng thấy ngay.
    if (identical(oldWidget.draftMatches, widget.draftMatches)) return;
    final first = widget.draftMatches.isEmpty
        ? null
        : widget.draftMatches.first.scheduledTime;
    if (first != null) _day = _dayOnly(first.toLocal());
  }

  Future<List<ScheduleCourt>> _loadCourts() async {
    final venues = await ref
        .read(tournamentManagementRepositoryProvider)
        .getVenues(widget.tournamentId);
    return parseScheduleCourts(venues);
  }

  int get _startHour =>
      _hourOf(widget.scheduleSettings['operatingStart'], fallback: 7);

  int get _endHour =>
      _hourOf(widget.scheduleSettings['operatingEnd'], fallback: 22);

  int get _minutesPerSet =>
      (widget.scheduleSettings['minutesPerSet'] as num?)?.toInt() ?? 15;

  int _hourOf(Object? value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    final raw = value.toString().trim();
    if (raw.isEmpty) return fallback;
    final head = raw.contains(':') ? raw.split(':').first : raw;
    return int.tryParse(head) ?? fallback;
  }

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Trận đã có sân và giờ thì nằm trên lưới; còn lại vào khay chờ xếp.
  bool _isPlaced(MatchModel match) =>
      match.scheduledTime != null && _courtOf(match).isNotEmpty;

  static String _courtOf(MatchModel match) {
    final name = match.courtName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return match.court.trim();
  }

  /// Các ngày có trận đã xếp, cộng ngày đang chọn.
  List<DateTime> _daysOf(List<MatchModel> matches) {
    final days = <String, DateTime>{};
    for (final match in matches) {
      final at = match.scheduledTime;
      if (at == null) continue;
      final day = _dayOnly(at.toLocal());
      days['${day.year}-${day.month}-${day.day}'] = day;
    }
    final selected = _day;
    if (selected != null) {
      days['${selected.year}-${selected.month}-${selected.day}'] = selected;
    }
    return days.values.toList()..sort((a, b) => a.compareTo(b));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<ScheduleCourt>>(
      future: _courtsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.opsLoadFailed,
              style: TextStyle(color: colors.error),
            ),
          );
        }
        final allCourts = snapshot.data ?? const <ScheduleCourt>[];
        if (allCourts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Icon(
                  Icons.stadium_outlined,
                  size: 40,
                  color: colors.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.tournamentManagementVenuesEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          );
        }

        _allCourtNames = [for (final court in allCourts) court.name];
        _allCourts = allCourts;
        final selectedCourts =
            _selectedCourts ?? allCourts.map((c) => c.name).toSet();
        final visibleCourts = [
          for (final court in allCourts)
            if (selectedCourts.contains(court.name)) court.name,
        ];

        final days = _daysOf([...widget.matches, ...widget.draftMatches]);
        final day = _day ?? (days.isNotEmpty ? days.first : null);
        _day = day;

        final draftIds = {for (final match in widget.draftMatches) match.id};
        final placed = [
          for (final match in widget.matches)
            if (_isPlaced(match) &&
                !draftIds.contains(match.id) &&
                (day == null ||
                    _dayOnly(match.scheduledTime!.toLocal()) == day))
              match,
        ];
        final drafts = [
          for (final match in widget.draftMatches)
            if (match.scheduledTime != null &&
                (day == null ||
                    _dayOnly(match.scheduledTime!.toLocal()) == day))
              match,
        ];
        final waiting = [
          for (final match in widget.matches)
            if (!_isPlaced(match) && !draftIds.contains(match.id)) match,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onAutoSchedule != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const ValueKey('schedule-auto-button'),
                    onPressed: widget.onAutoSchedule,
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(l10n.scheduleQuickAutoButton),
                  ),
                ),
              ),
            _toolbar(
              context,
              l10n,
              allCourts,
              selectedCourts,
              placed.length,
              widget.matches.length,
            ),
            if (days.length > 1) _dayPicker(context, days, day),
            if (widget.draftMatches.isNotEmpty) _draftBar(context, l10n),
            if (visibleCourts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.opsFilteredNoMatches,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            else
              ScheduleGrid(
                courts: visibleCourts,
                matches: [...placed, ...drafts],
                draftMatchIds: draftIds,
                startHour: _startHour,
                endHour: _endHour,
                minutesPerSet: _minutesPerSet,
                selectedMatchId: widget.selectedMatchId,
                day: day,
                onTapMatch: widget.onTapMatch ?? (_) {},
                onDropMatch: widget.onScheduleDrop == null
                    ? null
                    : (matchId, courtName, scheduledAt) {
                        // Lưới chỉ biết tên sân; ghi lịch cần cả id sân.
                        var courtId = '';
                        for (final court in allCourts) {
                          if (court.name == courtName) {
                            courtId = court.id;
                            break;
                          }
                        }
                        widget.onScheduleDrop!(
                          matchId,
                          courtId,
                          courtName,
                          scheduledAt,
                        );
                      },
                onDropOnMatch: widget.onScheduleSwap,
                onTapEmptyCell: widget.onTapEmptyCell == null
                    ? null
                    : (courtName, at) => widget.onTapEmptyCell!(
                        _courtIdOf(courtName),
                        courtName,
                        at,
                      ),
                onRangeSelected: _hasRangeActions
                    ? (range) => setState(() => _range = range)
                    : null,
                slotHeight: _slotHeight,
                onSlotHeightChanged: (height) =>
                    setState(() => _slotHeight = height),
              ),
            if (_hasRangeActions && _range != null)
              _bulkBar(
                context,
                l10n,
                visibleCourts,
                placed,
                drafts,
                day,
                waiting,
              ),
            if (widget.onScheduleDrop != null && waiting.isNotEmpty)
              _waitingTray(context, l10n, waiting),
          ],
        );
      },
    );
  }

  bool _exporting = false;
  List<String> _allCourtNames = const [];
  List<ScheduleCourt> _allCourts = const [];

  /// Kế hoạch xếp hàng loạt: ô trống (theo thứ tự giờ rồi tới sân) và số trận
  /// vừa đủ cho các ô đó.
  ///
  /// Ô chỉ được nhận nếu khoảng thời gian của trận **không chồng lấn** với trận
  /// đã xếp trên cùng sân, kể cả trận vừa được xếp trong chính lô này.
  ({
    List<({String courtId, String courtName, DateTime at})> cells,
    List<MatchModel> batch,
  })
  _bulkPlan(
    ScheduleRange range,
    List<String> visibleCourts,
    List<MatchModel> placed,
    DateTime? day,
    List<MatchModel> waiting,
  ) {
    final cells = <({String courtId, String courtName, DateTime at})>[];
    final batch = <MatchModel>[];
    final base = day ?? DateTime.now();
    final dayStart = DateTime(base.year, base.month, base.day, _startHour);

    final busy = <({String court, int start, int end})>[];
    for (final match in placed) {
      final at = match.scheduledTime;
      if (at == null) continue;
      final start = at.hour * 60 + at.minute;
      busy.add((
        court: _courtNameOf(match),
        start: start,
        end:
            start +
            scheduledDurationMinutes(match, minutesPerSet: _minutesPerSet),
      ));
    }

    var next = 0;
    for (var slot = range.firstSlot; slot <= range.lastSlot; slot++) {
      for (var index = range.firstCourt; index <= range.lastCourt; index++) {
        if (next >= waiting.length) break;
        if (index < 0 || index >= visibleCourts.length) continue;
        final name = visibleCourts[index];
        // Sân chưa có id không ghi được lịch: không xếp trận vào sân này.
        if (_courtIdOf(name).isEmpty) continue;
        final start = slot * 15 + _startHour * 60;
        final match = waiting[next];
        final end =
            start +
            scheduledDurationMinutes(match, minutesPerSet: _minutesPerSet);
        if (busy.any(
          (b) => b.court == name && start < b.end && b.start < end,
        )) {
          continue;
        }
        busy.add((court: name, start: start, end: end));
        cells.add((
          courtId: _courtIdOf(name),
          courtName: name,
          at: dayStart.add(Duration(minutes: slot * 15)),
        ));
        batch.add(match);
        next++;
      }
    }
    return (cells: cells, batch: batch);
  }

  String _courtIdOf(String name) {
    for (final court in _allCourts) {
      if (court.name == name) return court.id;
    }
    return '';
  }

  static String _courtNameOf(MatchModel match) {
    final name = match.courtName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return match.court.trim();
  }

  /// Có thao tác theo vùng chọn (xếp hàng loạt, đặt thời lượng, dời sân) không.
  bool get _hasRangeActions =>
      widget.onBulkSchedule != null ||
      widget.onBulkDuration != null ||
      widget.onBulkMoveCourt != null;

  /// Các thời lượng chọn được khi đặt hàng loạt (phút).
  static const List<int> _bulkDurationOptions = [15, 30, 45, 60, 75, 90, 120];

  /// Trận đã xếp có ô bắt đầu nằm trong vùng chọn, trên các sân đang hiện.
  List<MatchModel> _matchesInRange(
    ScheduleRange range,
    List<String> visibleCourts,
    List<MatchModel> placed,
  ) {
    final result = <MatchModel>[];
    for (final match in placed) {
      final at = match.scheduledTime;
      if (at == null) continue;
      final courtIndex = visibleCourts.indexOf(_courtNameOf(match));
      if (courtIndex < range.firstCourt || courtIndex > range.lastCourt) {
        continue;
      }
      final minutes = at.hour * 60 + at.minute - _startHour * 60;
      if (minutes < 0) continue;
      final slot = minutes ~/ 15;
      if (slot < range.firstSlot || slot > range.lastSlot) continue;
      result.add(match);
    }
    return result;
  }

  /// Thanh thao tác theo vùng chọn: xếp các trận chờ vào ô trống, hoặc đặt
  /// thời lượng / dời sân cho các trận đã xếp nằm trong vùng.
  Widget _bulkBar(
    BuildContext context,
    AppLocalizations l10n,
    List<String> visibleCourts,
    List<MatchModel> placed,
    List<MatchModel> drafts,
    DateTime? day,
    List<MatchModel> waiting,
  ) {
    final colors = context.colors;
    final range = _range!;
    final plan = _bulkPlan(
      range,
      visibleCourts,
      [...placed, ...drafts],
      day,
      waiting,
    );
    final cells = plan.cells;
    final batch = plan.batch;
    final inRange = _matchesInRange(range, visibleCourts, placed);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          if (widget.onBulkSchedule != null) ...[
            Text(
              '${l10n.opsUnscheduled}: ${batch.length}/${cells.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('schedule-bulk-schedule-button'),
              onPressed: batch.isEmpty
                  ? null
                  : () {
                      final selected = cells;
                      setState(() => _range = null);
                      widget.onBulkSchedule!(selected, batch);
                    },
              icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
              label: Text('${batch.length}'),
            ),
          ],
          if (widget.onBulkDuration != null && inRange.isNotEmpty)
            TextButton.icon(
              key: const ValueKey('schedule-bulk-duration-button'),
              onPressed: () => _pickBulkDuration(context, inRange),
              icon: const Icon(Icons.timer_outlined, size: 16),
              label: Text(l10n.scheduleQuickBulkDuration),
            ),
          if (widget.onBulkMoveCourt != null && inRange.isNotEmpty)
            TextButton.icon(
              key: const ValueKey('schedule-bulk-court-button'),
              onPressed: () => _pickBulkCourt(context, inRange),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(l10n.scheduleQuickBulkMoveCourt),
            ),
        ],
      ),
    );
  }

  /// Chọn thời lượng rồi đặt cho các trận trong vùng chọn.
  Future<void> _pickBulkDuration(
    BuildContext context,
    List<MatchModel> matches,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.scheduleQuickBulkDurationTitle(matches.length),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in _bulkDurationOptions)
                    ListTile(
                      key: ValueKey('schedule-bulk-duration-$option'),
                      title: Text(l10n.scheduleQuickMinutes(option)),
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (minutes == null || !mounted) return;
    setState(() => _range = null);
    widget.onBulkDuration?.call(matches, minutes);
  }

  /// Chọn sân đích rồi dời các trận trong vùng sang sân đó, giữ nguyên giờ.
  Future<void> _pickBulkCourt(
    BuildContext context,
    List<MatchModel> matches,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final courts = _allCourts;
    final picked = await showModalBottomSheet<ScheduleCourt>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.scheduleQuickBulkMoveCourtTitle(matches.length),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final court in courts)
                    ListTile(
                      key: ValueKey('schedule-bulk-court-${court.id}'),
                      title: Text(court.name),
                      onTap: () => Navigator.of(sheetContext).pop(court),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _range = null);
    widget.onBulkMoveCourt?.call(matches, picked);
  }

  /// Thanh bản nháp xếp tự động: số trận sẽ ghi, số trận server bỏ qua, và nút
  /// áp dụng hoặc huỷ. Đang ghi thì hiện tiến độ và khoá hai nút.
  Widget _draftBar(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final count = widget.draftMatches.length;
    final progress = widget.draftProgress;
    final busy = progress != null;
    final status = progress == null
        ? l10n.scheduleQuickDraftSummary(count, widget.draftSkippedCount)
        : l10n.scheduleQuickDraftProgress(progress.done, progress.total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            TextButton(
              key: const ValueKey('schedule-draft-cancel'),
              onPressed: busy ? null : widget.onCancelDraft,
              child: Text(l10n.scheduleQuickDraftCancel),
            ),
            FilledButton(
              key: const ValueKey('schedule-draft-apply'),
              onPressed: busy ? null : widget.onApplyDraft,
              child: Text(l10n.scheduleQuickDraftApply(count)),
            ),
          ],
        ),
      ),
    );
  }

  /// In mặc định: dùng chính dữ liệu lưới đang hiện. Test truyền [onPrint] để
  /// thay thao tác này.
  Future<void> _printSchedule() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SchedulePrintService.printSchedule(
        title: l10n.tabSchedule,
        courts: _allCourtNames,
        matches: widget.matches,
        startHour: _startHour,
        endHour: _endHour,
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementExportError)),
      );
    }
  }

  /// Xuất lịch ra Excel (dùng lại dịch vụ xuất sẵn có của app).
  Future<void> _exportSchedule() async {
    if (_exporting) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      await ExcelExportService.exportSchedule(
        title: l10n.tabSchedule,
        courts: _allCourtNames,
        matches: widget.matches,
        startHour: _startHour,
        endHour: _endHour,
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.tournamentManagementExportError)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _toolbar(
    BuildContext context,
    AppLocalizations l10n,
    List<ScheduleCourt> allCourts,
    Set<String> selectedCourts,
    int placedCount,
    int totalCount,
  ) {
    final colors = context.colors;
    final visibleCount = selectedCourts.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
          // Bộ đếm tiến độ xếp lịch, như thanh công cụ của web.
          Icon(Icons.event_available_outlined, size: 16, color: colors.textMuted),
          const SizedBox(width: 6),
          Text(
            '${l10n.opsMatches} $placedCount/$totalCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          if (widget.divisions.length > 1 &&
              widget.onDivisionSelected != null) ...[
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: DropdownButton<String>(
                  key: const ValueKey('schedule-division-dropdown'),
                  value: widget.selectedDivisionId,
                  isDense: true,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  items: [
                    for (final division in widget.divisions)
                      DropdownMenuItem(
                        value: division.id,
                        child: Text(
                          division.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) widget.onDivisionSelected!(value);
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            key: const ValueKey('court-picker-button'),
            onPressed: () => _openCourtPicker(context, allCourts, selectedCourts),
            icon: const Icon(Icons.grid_view_rounded, size: 16),
            label: Text(
              '${l10n.tournamentManagementVenues} $visibleCount/${allCourts.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: BorderSide(color: colors.border),
            ),
          ),
          IconButton(
            key: const ValueKey('schedule-print-button'),
            tooltip: l10n.schedulePrint,
            onPressed: widget.onPrint ?? _printSchedule,
            icon: Icon(Icons.print_outlined, color: colors.textMuted),
          ),
          IconButton(
            key: const ValueKey('schedule-export-button'),
            tooltip: l10n.exportData,
            onPressed: _exporting ? null : _exportSchedule,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.file_download_outlined, color: colors.textMuted),
          ),
          if (widget.onOpenFullscreen != null) ...[
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('court-grid-fullscreen'),
              tooltip: l10n.tabSchedule,
              onPressed: widget.onOpenFullscreen,
              icon: Icon(
                Icons.open_in_full_rounded,
                color: colors.textMuted,
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }

  /// Hộp chọn sân: giống nút "Chọn sân" của web, chỉ hiện số đang bật trên thanh
  /// công cụ thay vì chiếm chỗ bằng một dải chip.
  Future<void> _openCourtPicker(
    BuildContext context,
    List<ScheduleCourt> allCourts,
    Set<String> selectedCourts,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var working = {...selectedCourts};
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tournamentManagementVenues,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('court-picker-all'),
                      onPressed: () => setSheetState(
                        () => working = allCourts.map((c) => c.name).toSet(),
                      ),
                      child: Text(l10n.filterAll),
                    ),
                    TextButton(
                      key: const ValueKey('court-picker-none'),
                      onPressed: () => setSheetState(() => working = <String>{}),
                      child: Text(l10n.opsFilterKicked),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final court in allCourts)
                      CheckboxListTile(
                        key: ValueKey('court-picker-item-${court.name}'),
                        dense: true,
                        value: working.contains(court.name),
                        title: Text(court.name),
                        onChanged: (checked) => setSheetState(() {
                          if (checked == true) {
                            working.add(court.name);
                          } else {
                            working.remove(court.name);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _selectedCourts = working);
  }

  Widget _dayPicker(
    BuildContext context,
    List<DateTime> days,
    DateTime? selected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final day in days)
            ChoiceChip(
              key: ValueKey('schedule-day-${day.day}-${day.month}'),
              label: Text('${day.day}/${day.month}'),
              selected: selected == day,
              onSelected: (_) => setState(() => _day = day),
              selectedColor: AppTheme.primary.withValues(alpha: 0.18),
            ),
        ],
      ),
    );
  }

  Widget _waitingTray(
    BuildContext context,
    AppLocalizations l10n,
    List<MatchModel> waiting,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.opsUnscheduled} (${waiting.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final match in waiting)
                LongPressDraggable<String>(
                  key: ValueKey('schedule-tray-${match.id}'),
                  data: match.id,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Chip(label: Text(_labelOf(match))),
                  ),
                  child: Chip(
                    label: Text(_labelOf(match)),
                    avatar: const Icon(Icons.drag_indicator_rounded, size: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelOf(MatchModel match) {
    final a = match.team1Name.trim();
    final b = match.team2Name.trim();
    if (a.isEmpty && b.isEmpty) return match.id;
    return '$a – $b';
  }
}