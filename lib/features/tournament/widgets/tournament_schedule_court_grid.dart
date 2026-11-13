import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/core/services/schedule_print_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/court_schedule_cascade.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_strip.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_manager_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

/// Sân của giải: cần cả id để ghi lịch và tên để ghép vào cột lưới.
typedef ScheduleCourt = ({String id, String name});

/// Một nội dung thi đấu để chọn trong thanh công cụ.
typedef ScheduleDivision = ({String id, String name});

/// Mục trong menu ⋯ của thanh công cụ lịch.
enum _ScheduleMenuAction { courts, print, export, ai, settings }

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
    this.onScheduleWaitingWrite,
    this.onWaitingBatchFinished,
    this.onAutoSchedule,
    this.onAiSchedule,
    this.onOpenScheduleSettings,
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

  /// Ghi lịch một trận chọn từ khay chờ lên sân đích; khay tự chạy dây chuyền
  /// giờ, tiến độ và cho huỷ giữa chừng, chỉ gọi xuống đây từng trận. Trả về
  /// false khi ghi lỗi — dây chuyền dừng và báo "đã xếp i/N". Null thì khay
  /// chỉ kéo-thả như cũ.
  final Future<bool> Function(
    MatchModel match,
    ScheduleCourt court,
    DateTime scheduledAt,
    int durationMinutes,
  )?
  onScheduleWaitingWrite;

  /// Khay chờ ghi xong một lô (dù xong hết, dừng giữa chừng hay bị huỷ): màn
  /// gọi tải lại nguồn trận quản lý.
  final VoidCallback? onWaitingBatchFinished;

  /// Mở xếp tự động (mục trong menu ⋯). Null thì không hiện mục.
  final VoidCallback? onAutoSchedule;

  /// Mở "Xếp bằng AI" (mục trong menu ⋯). Null thì không hiện mục.
  final VoidCallback? onAiSchedule;

  /// Mở sheet cài đặt khung giờ sân (giờ mở/đóng + bước ô). Null thì không
  /// hiện nút.
  final VoidCallback? onOpenScheduleSettings;

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
  double _slotHeight = 112;

  /// Null = hiện tất cả sân.
  Set<String>? _selectedCourts;

  /// Ngày đang xem; chọn ngày đầu tiên có trận khi biết dữ liệu.
  DateTime? _day;

  /// Vùng ô đang được chọn (nhấn giữ kéo, hoặc chạm hai ô ở chế độ chọn nhiều).
  ScheduleRange? _range;

  /// Chế độ "Chọn nhiều": chạm ô đầu rồi ô cuối để chọn vùng.
  bool _selectMode = false;

  /// Trận chờ được tích chọn từ khay, theo thứ tự bấm — quyết định thứ tự xếp.
  final List<String> _selectedWaitingIds = [];

  /// Sân đích và mốc giờ bắt đầu của lô xếp từ khay; null là mặc định (sân đầu
  /// tiên có id, giờ mở cửa).
  ScheduleCourt? _trayCourt;
  int? _trayStartMinute;

  /// Đang ghi tuần tự một lô từ khay chờ: hiện tiến độ và nút huỷ, khoá chọn.
  bool _writingBatch = false;
  ({int done, int total})? _trayProgress;
  bool _trayCancelRequested = false;
  String? _trayNotice;

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

  /// Bước ô của lưới theo cấu hình giải (task 4.3); chỉ nhận 5/10/15/30/60,
  /// khác thì 15 — đúng lưới sẵn có.
  int get _stepMinutes => scheduleStepMinutesOf(widget.scheduleSettings);

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
            padding: EdgeInsets.symmetric(vertical: 16),
            child: BoneListLoading(itemCount: 3, leadingAvatar: false),
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
                _divisionStrip(),
                const SizedBox(height: AppSpacing.md),
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
                // Chỉ người quản lý giải (không Lite) thấy; thanh tự ẩn với người khác.
                ScheduleManagerBar(
                  tournamentId: widget.tournamentId,
                  createCourtCta: true,
                  // The ops screen only passes onScheduleDrop to users it lets schedule.
                  hostGrantsManage: widget.onScheduleDrop != null,
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
            _divisionStrip(),
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
            // Thanh thao tác theo vùng chọn nằm NGAY trên lưới để luôn thấy.
            if (_hasRangeActions && _range != null)
              _bulkBar(
                context,
                l10n,
                visibleCourts,
                placed,
                drafts,
                day,
                waiting,
              )
            else if (_hasRangeActions && _selectMode)
              _selectHint(context, l10n),
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
                stepMinutes: _stepMinutes,
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
                selectMode: _hasRangeActions && _selectMode,
                selectedRange: _range,
                onClearRange: () => setState(() => _range = null),
                onResizeMatch: widget.onBulkDuration == null
                    ? null
                    : (match, minutes) =>
                          widget.onBulkDuration!([match], minutes),
                slotHeight: _slotHeight,
                onSlotHeightChanged: (height) =>
                    setState(() => _slotHeight = height),
              ),
            if (widget.onScheduleDrop != null && waiting.isNotEmpty)
              _waitingTray(context, l10n, waiting, day),
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
        final start = slot * _stepMinutes + _startHour * 60;
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
          at: dayStart.add(Duration(minutes: slot * _stepMinutes)),
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
      final slot = minutes ~/ _stepMinutes;
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

  /// Gợi ý cách chọn vùng khi đã bật chế độ "Chọn nhiều" mà chưa chọn ô nào.
  Widget _selectHint(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Text(
        l10n.scheduleSelectHint,
        key: const ValueKey('schedule-select-hint'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colors.textSecondary,
        ),
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
            Icon(
              Icons.event_available_outlined,
              size: 16,
              color: colors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${l10n.opsMatches} $placedCount/$totalCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const Spacer(),
            if (_hasRangeActions) ...[
              LavishIconBox(
                key: const ValueKey('schedule-select-mode-button'),
                tone: _selectMode ? LavishTone.accent : LavishTone.neutral,
                tooltip: l10n.scheduleSelectMode,
                onTap: () => setState(() {
                  _selectMode = !_selectMode;
                  _range = null;
                }),
                child: const Icon(Icons.checklist_rounded),
              ),
              const SizedBox(width: 6),
            ],
            if (widget.onAutoSchedule != null)
              LavishIconBox(
                key: const ValueKey('schedule-auto-button'),
                tone: LavishTone.neutral,
                tooltip: l10n.scheduleQuickAutoButton,
                onTap: widget.onAutoSchedule,
                child: const Icon(Icons.bolt_rounded),
              ),
            if (widget.onOpenFullscreen != null) ...[
              const SizedBox(width: 6),
              LavishIconBox(
                key: const ValueKey('court-grid-fullscreen'),
                tone: LavishTone.neutral,
                tooltip: l10n.tabSchedule,
                onTap: widget.onOpenFullscreen,
                child: const Icon(Icons.open_in_full_rounded),
              ),
            ],
            const SizedBox(width: 6),
            _moreMenu(context, l10n, allCourts, selectedCourts),
          ],
        ),
      ),
    );
  }

  /// Menu ⋯: các thao tác ít dùng nằm đây để thanh công cụ chỉ còn một hàng.
  Widget _moreMenu(
    BuildContext context,
    AppLocalizations l10n,
    List<ScheduleCourt> allCourts,
    Set<String> selectedCourts,
  ) {
    PopupMenuItem<_ScheduleMenuAction> item(
      _ScheduleMenuAction action,
      String key,
      IconData icon,
      String label, {
      bool enabled = true,
    }) => PopupMenuItem(
      key: ValueKey(key),
      value: action,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Flexible(child: Text(label)),
        ],
      ),
    );
    return PopupMenuButton<_ScheduleMenuAction>(
      key: const ValueKey('schedule-more-button'),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case _ScheduleMenuAction.courts:
            _openCourtPicker(context, allCourts, selectedCourts);
          case _ScheduleMenuAction.print:
            (widget.onPrint ?? _printSchedule)();
          case _ScheduleMenuAction.export:
            _exportSchedule();
          case _ScheduleMenuAction.ai:
            widget.onAiSchedule?.call();
          case _ScheduleMenuAction.settings:
            widget.onOpenScheduleSettings?.call();
        }
      },
      itemBuilder: (_) => [
        item(
          _ScheduleMenuAction.courts,
          'court-picker-button',
          Icons.grid_view_rounded,
          '${l10n.tournamentManagementVenues} '
              '${selectedCourts.length}/${allCourts.length}',
        ),
        item(
          _ScheduleMenuAction.print,
          'schedule-print-button',
          Icons.print_outlined,
          l10n.schedulePrint,
        ),
        item(
          _ScheduleMenuAction.export,
          'schedule-export-button',
          Icons.file_download_outlined,
          l10n.exportData,
          enabled: !_exporting,
        ),
        if (widget.onAiSchedule != null)
          item(
            _ScheduleMenuAction.ai,
            'schedule-ai-button',
            Icons.auto_awesome,
            l10n.scheduleAiButton,
          ),
        if (widget.onOpenScheduleSettings != null)
          item(
            _ScheduleMenuAction.settings,
            'schedule-settings-button',
            Icons.schedule_rounded,
            l10n.scheduleSettingsTitle,
          ),
      ],
      child: const LavishIconBox(
        tone: LavishTone.neutral,
        child: Icon(Icons.more_horiz_rounded),
      ),
    );
  }

  /// The shared division strip; nothing to pick (or nobody to tell) hides it.
  Widget _divisionStrip() {
    final onSelected = widget.onDivisionSelected;
    if (onSelected == null) return const SizedBox.shrink();
    return DivisionStrip(
      keyPrefix: 'schedule-division',
      items: [
        for (final division in widget.divisions)
          DivisionStripItem(id: division.id, name: division.name),
      ],
      selectedId: widget.selectedDivisionId,
      onChanged: (id) {
        if (id != null) onSelected(id);
      },
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
                      onPressed: () =>
                          setSheetState(() => working = <String>{}),
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
            LavishChipButton(
              key: ValueKey('schedule-day-${day.day}-${day.month}'),
              label: '${day.day}/${day.month}',
              selected: selected == day,
              onPressed: () => setState(() => _day = day),
            ),
        ],
      ),
    );
  }

  /// Khay trận chưa xếp: chip kéo-thả lên lưới như cũ; khi có
  /// [TournamentScheduleCourtGrid.onScheduleWaitingWrite] thì thêm tích chọn
  /// nhiều trận (checkbox + chọn tất cả), chọn sân đích và khung giờ bắt đầu,
  /// rồi xếp nối tiếp tuần tự có tiến độ và huỷ được giữa chừng (OpenSpec
  /// `quan-ly-giai-web-parity` task 4.2, spec `Xếp hàng loạt từ khay chờ có sân
  /// đích và khung giờ`). Bố cục giữ dạng dọc sẵn có — chỉ đưa chức năng của
  /// bảng ngang Web vào đây, không copy bố cục.
  Widget _waitingTray(
    BuildContext context,
    AppLocalizations l10n,
    List<MatchModel> waiting,
    DateTime? day,
  ) {
    final colors = context.colors;
    final writable = widget.onScheduleWaitingWrite != null;
    final selectable = writable
        ? [
            for (final match in waiting)
              if (!isScheduleLocked(match)) match,
          ]
        : const <MatchModel>[];
    final selectableIds = {for (final match in selectable) match.id};
    final selectedById = {for (final match in selectable) match.id: match};
    final selected = [
      for (final id in _selectedWaitingIds)
        if (selectedById.containsKey(id)) selectedById[id]!,
    ];
    final allSelected =
        selectable.isNotEmpty &&
        selectable.every((match) => _selectedWaitingIds.contains(match.id));

    // Sân không có id không ghi được lịch: chỉ đưa sân có id vào chọn đích.
    final writableCourts = [
      for (final court in _allCourts)
        if (court.id.isNotEmpty) court,
    ];
    final court = _trayCourt != null && writableCourts.contains(_trayCourt)
        ? _trayCourt
        : (writableCourts.isEmpty ? null : writableCourts.first);
    final startChoices = quickScheduleMinutes(
      startHour: _startHour,
      endHour: _endHour,
      // Các mốc giờ chọn nhanh theo bước ô cấu hình (task 4.3).
      stepMinutes: _stepMinutes,
    );
    final startMinute =
        _trayStartMinute != null && startChoices.contains(_trayStartMinute)
        ? _trayStartMinute!
        : (startChoices.isNotEmpty ? startChoices.first : _startHour * 60);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.opsUnscheduled} (${waiting.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (selectable.isNotEmpty)
                TextButton(
                  key: const ValueKey('schedule-tray-toggle-all'),
                  onPressed: _writingBatch
                      ? null
                      : () => _toggleAllWaiting(selectable),
                  child: Text(
                    allSelected
                        ? l10n.scheduleMultiDeselectVisible
                        : l10n.scheduleMultiSelectVisible,
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final match in waiting)
                _waitingChip(
                  match,
                  selectable: selectableIds.contains(match.id),
                  selected: _selectedWaitingIds.contains(match.id),
                ),
            ],
          ),
          if (_trayProgress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key: const ValueKey('schedule-tray-progress'),
                    l10n.scheduleQuickDraftProgress(
                      _trayProgress!.done,
                      _trayProgress!.total,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.info,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('schedule-tray-cancel'),
                  onPressed: _trayCancelRequested
                      ? null
                      : () => setState(() => _trayCancelRequested = true),
                  child: Text(l10n.tournamentManagementCancel),
                ),
              ],
            ),
          ],
          if (_trayNotice != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              key: const ValueKey('schedule-tray-notice'),
              _trayNotice!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (!_writingBatch && selected.isNotEmpty && court != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.scheduleQuickCourt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<ScheduleCourt>(
                    key: const ValueKey('schedule-tray-court'),
                    value: court,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    items: [
                      for (final item in writableCourts)
                        DropdownMenuItem(value: item, child: Text(item.name)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _trayCourt = value);
                    },
                  ),
                ),
                Text(
                  l10n.scheduleQuickStart,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<int>(
                    key: const ValueKey('schedule-tray-start'),
                    value: startMinute,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    items: [
                      for (final minute in startChoices)
                        DropdownMenuItem(
                          value: minute,
                          child: Text(_hhmm(minute)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _trayStartMinute = value);
                      }
                    },
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('schedule-tray-submit'),
                  onPressed: () => _submitWaitingBatch(
                    court: court,
                    day: day,
                    startMinute: startMinute,
                    selected: selected,
                  ),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                  label: Text(l10n.scheduleTraySubmit(selected.length)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Một chip trận chờ: giữ-kéo để thả lên lưới như cũ; khi [selectable] thì
  /// chạm để tích chọn/bỏ chọn (checkbox), chip đang chọn tô đậm viền.
  Widget _waitingChip(
    MatchModel match, {
    required bool selectable,
    required bool selected,
  }) {
    final colors = context.colors;
    return LongPressDraggable<String>(
      key: ValueKey('schedule-tray-${match.id}'),
      data: match.id,
      feedback: Material(
        color: Colors.transparent,
        child: Chip(label: Text(_labelOf(match))),
      ),
      child: selectable
          ? InkWell(
              onTap: () => _toggleWaiting(match),
              borderRadius: BorderRadius.circular(8),
              child: Chip(
                avatar: Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: selected ? colors.info : colors.textMuted,
                ),
                label: Text(_labelOf(match)),
                backgroundColor: selected
                    ? colors.info.withValues(alpha: 0.08)
                    : null,
                side: selected ? BorderSide(color: colors.info) : null,
              ),
            )
          : Chip(
              label: Text(_labelOf(match)),
              avatar: const Icon(Icons.drag_indicator_rounded, size: 16),
            ),
    );
  }

  void _toggleWaiting(MatchModel match) {
    if (_writingBatch) return;
    setState(() {
      if (!_selectedWaitingIds.remove(match.id)) {
        _selectedWaitingIds.add(match.id);
      }
    });
  }

  /// Chọn/bỏ chọn toàn bộ trận chờ có thể xếp (checkbox + chọn tất cả).
  void _toggleAllWaiting(List<MatchModel> selectable) {
    if (_writingBatch) return;
    setState(() {
      final allSelected = selectable.every(
        (match) => _selectedWaitingIds.contains(match.id),
      );
      if (allSelected) {
        final ids = {for (final match in selectable) match.id};
        _selectedWaitingIds.removeWhere(ids.contains);
      } else {
        for (final match in selectable) {
          if (!_selectedWaitingIds.contains(match.id)) {
            _selectedWaitingIds.add(match.id);
          }
        }
      }
    });
  }

  /// Xếp nối tiếp tuần tự các trận đang chọn lên sân đích từ khung giờ bắt
  /// đầu: giờ từng trận do [cascadeStartTimes] tính (trận sau bắt đầu sau khi
  /// trận trước kết thúc, thời lượng tính như server), ghi qua
  /// [TournamentScheduleCourtGrid.onScheduleWaitingWrite] từng trận với tiến độ
  /// "đang ghi i/N"; lỗi giữa chừng dừng và báo "đã xếp i/N"; huỷ được giữa
  /// chừng (dừng sau trận đang ghi).
  Future<void> _submitWaitingBatch({
    required ScheduleCourt court,
    required DateTime? day,
    required int startMinute,
    required List<MatchModel> selected,
  }) async {
    if (_writingBatch || selected.isEmpty || court.id.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final base = day ?? DateTime.now();
    final start = DateTime(
      base.year,
      base.month,
      base.day,
    ).add(Duration(minutes: startMinute));
    final durations = [
      for (final match in selected)
        serverEffectiveDurationMinutes(
          scheduledDurationMinutes(match, minutesPerSet: _minutesPerSet),
        ),
    ];
    final starts = cascadeStartTimes(start, durations);
    final total = selected.length;
    setState(() {
      _writingBatch = true;
      _trayProgress = (done: 0, total: total);
      _trayNotice = null;
      _trayCancelRequested = false;
    });

    // Captured before the awaits so the refresh still fires if the grid is
    // disposed after some matches were already written.
    final onFinished = widget.onWaitingBatchFinished;
    var done = 0;
    var stopped = false;
    var cancelled = false;
    for (var i = 0; i < selected.length; i++) {
      if (!mounted) {
        if (done > 0) onFinished?.call();
        return;
      }
      setState(() => _trayProgress = (done: done, total: total));
      final ok = await widget.onScheduleWaitingWrite!(
        selected[i],
        court,
        starts[i],
        durations[i],
      );
      if (!mounted) {
        if (done > 0 || ok) onFinished?.call();
        return;
      }
      if (!ok) {
        stopped = true;
        break;
      }
      done++;
      if (_trayCancelRequested && done < total) {
        cancelled = true;
        break;
      }
    }

    if (!mounted) {
      if (done > 0) onFinished?.call();
      return;
    }
    setState(() {
      _writingBatch = false;
      _trayProgress = null;
      _trayCancelRequested = false;
      if (stopped || cancelled) {
        // Các trận đã ghi sẽ rời khay sau khi tải lại; phần còn lại giữ chọn
        // để xếp tiếp.
        final written = {for (final match in selected.take(done)) match.id};
        _selectedWaitingIds.removeWhere(written.contains);
        _trayNotice = cancelled
            ? l10n.scheduleTrayCancelled(done, total)
            : l10n.scheduleMultiPartial(done, total);
      } else {
        _selectedWaitingIds.clear();
      }
    });
    if (!stopped && done > 0) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.scheduleMultiDone(done, total))),
        );
    }
    onFinished?.call();
  }

  String _labelOf(MatchModel match) {
    final a = match.team1Name.trim();
    final b = match.team2Name.trim();
    if (a.isEmpty && b.isEmpty) return match.id;
    return '$a – $b';
  }

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';
}
