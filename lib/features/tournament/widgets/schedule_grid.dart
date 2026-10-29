import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_court_label.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_gender_tint.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

typedef _ScheduledMatchLane = ({MatchModel match, int lane});

typedef _CardStyle = ({
  BoxDecoration decoration,
  ScheduleGenderTint tint,
  Color winnerBg,
  Color accent,
  Color fg,
});

/// Vùng ô được chọn bằng nhấn giữ rồi kéo trên lưới: chỉ số cột sân và hàng giờ,
/// đã chuẩn hoá (first <= last).
typedef ScheduleRange = ({
  int firstCourt,
  int lastCourt,
  int firstSlot,
  int lastSlot,
});

/// Lịch thi đấu dạng lưới: cột giờ khoá sát trái, mỗi nhóm sân có thể có nhiều lane.
///
/// Bố cục đáp ứng ba yêu cầu đặt ra:
///  * Cột giờ nằm ngoài `SingleChildScrollView` ngang nên luôn dính trái.
///  * Tên sân và các lane cuộn ngang với nhau: thân giữ cử chỉ cuộn, header
///    nghe thân rồi `jumpTo` theo (một chiều, không phản hồi vòng).
///  * Thân cuộn dọc; các trận có thời lượng giao nhau được đặt vào lane riêng
///    để card không che card khác và nhãn giờ gốc vẫn giữ nguyên.
class ScheduleGrid extends StatefulWidget {
  /// Các sân theo đúng thứ tự cột.
  ///
  /// Danh sách này quyết định số cột của lưới, nên phải ổn định theo ngày
  /// đang xem — nếu derive từ trận của ngày đó thì sân không có trận sẽ biến mất.
  final List<String> courts;
  final List<MatchModel> matches;
  final Map<String, String> divisionNameById;
  final Map<String, TournamentDivision> divisionMetadataById;
  final double slotHeight;
  final bool emphasizeTimeLabels;
  final int startHour;
  final int endHour;
  final String? selectedMatchId;
  final ValueChanged<String> onTapMatch;

  /// Tên vòng chuẩn theo sơ đồ (vd. "Vòng 1/8", "Tứ kết") làm footer thẻ.
  /// Null thì footer giữ "Vòng R • Trận N" theo số vòng thô (lưới BTC).
  final String Function(MatchModel match)? roundLabelOf;

  /// Phút mỗi set BTC cấu hình; dùng khi trận chưa có `durationMinutes`.
  final int minutesPerSet;

  /// Phút mỗi ô của lưới (cấu hình giải, task 4.3): vẽ nhãn giờ, ô trống và
  /// giờ khi thả trận theo bước này. Mặc định 15 — lưới sẵn có.
  final int stepMinutes;

  /// Ngày đang xem. Dùng để tính giờ khi thả trận vào lưới.
  final DateTime? day;

  /// Có giá trị thì lưới mở chế độ xếp lịch: mỗi ô theo [stepMinutes] của mỗi
  /// sân nhận thẻ trận được kéo thả. Null (mặc định) giữ nguyên lưới chỉ đọc.
  final void Function(String matchId, String court, DateTime scheduledAt)?
  onDropMatch;

  /// Có giá trị thì nhấn giữ rồi kéo trên lưới để chọn một vùng ô.
  final void Function(ScheduleRange range)? onRangeSelected;

  /// Chế độ "Chọn nhiều": chạm ô đầu rồi ô cuối để chọn vùng (không cần nhấn
  /// giữ). Chạm thẻ trận cũng tính là chạm ô bắt đầu của trận đó.
  final bool selectMode;

  /// Vùng đang chọn do host giữ; lưới tô sáng vùng này.
  final ScheduleRange? selectedRange;

  /// Kéo tay nắm ở cạnh dưới thẻ để đổi thời lượng: báo số phút mới (làm tròn
  /// theo [stepMinutes]). Null thì thẻ không có tay nắm.
  final void Function(MatchModel match, int minutes)? onResizeMatch;

  /// Nút ✕ nằm ngay trên vùng đang chọn để bỏ chọn; null thì không hiện.
  final VoidCallback? onClearRange;

  /// Chạm vào một ô trống (sân, giờ): mở chọn trận chờ để xếp vào ô đó.
  final void Function(String court, DateTime at)? onTapEmptyCell;

  /// Thả một trận lên thẻ của trận khác: đổi chỗ hai trận.
  final void Function(String draggedMatchId, String targetMatchId)?
  onDropOnMatch;

  /// Các trận là bản nháp xếp tự động: vẽ khác biệt và không tương tác.
  final Set<String> draftMatchIds;

  /// Kéo tay nắm ở cột giờ để đổi chiều cao hàng: lưới báo chiều cao mới, host
  /// giữ state (lưới không tự đổi). Null thì không hiện tay nắm.
  final ValueChanged<double>? onSlotHeightChanged;

  /// Giới hạn chiều cao một ô 15 phút khi kéo giãn.
  static const double minSlotHeight = 80;
  static const double maxSlotHeight = 224;

  const ScheduleGrid({
    super.key,
    required this.courts,
    required this.matches,
    required this.startHour,
    required this.endHour,
    this.selectedMatchId,
    required this.onTapMatch,
    this.divisionNameById = const {},
    this.divisionMetadataById = const {},
    this.slotHeight = 112,
    this.emphasizeTimeLabels = false,
    this.minutesPerSet = 15,
    this.stepMinutes = 15,
    this.day,
    this.onDropMatch,
    this.onRangeSelected,
    this.selectMode = false,
    this.selectedRange,
    this.onResizeMatch,
    this.onClearRange,
    this.roundLabelOf,
    this.onTapEmptyCell,
    this.onDropOnMatch,
    this.draftMatchIds = const {},
    this.onSlotHeightChanged,
  });

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  /// Default is 112dp: the smallest 15-minute slot that still holds a doubles
  /// card (see `_minimumHeightFor`). `BASE_PIXELS_PER_MINUTE` remains the web
  /// grid's separate layout scale.
  double get _slotHeight => widget.slotHeight;
  static const double _timeColumnWidth = 56;
  static const double _minCourtLaneWidth = 120;
  static const double _minimumCardHeight = 44;
  static const double _minimumCompactDivisionCardHeight = 60;
  static const double _minimumFullCardHeight = 76;

  /// Header, footer và viền của thẻ đầy đủ; cộng hai khối đội ra chiều cao tối thiểu.
  static const double _fullCardChromeHeight = 43;

  /// Thẻ dưới 8 phút chỉ hiện một dòng; từ 8 phút trở lên hiện đủ hai đội.
  static const int _compactBelowMinutes = 8;
  static const double _stripeWidth = 5;

  /// Trần thời lượng khi kéo giãn thẻ (phút) và vùng chạm của tay nắm.
  static const int _maxResizeMinutes = 240;
  static const double _resizeHandleHeight = 18;

  // Header và thân dùng hai controller riêng: một ScrollController chỉ gắn
  // được một ScrollPosition, dùng chung sẽ assert ngay lần swipe ngang đầu.
  // Chỉ thân nhận cử chỉ cuộn, header nghe thân rồi jumpTo theo — một chiều nên
  // không có vòng lặp phản hồi, và header bị chặn cuộn để không tranh gesture.
  final ScrollController _bodyCtrl = ScrollController();
  final ScrollController _headerCtrl = ScrollController();

  // ── Chọn vùng ô (nhấn giữ rồi kéo) ──
  List<_CourtLayout> _bodyLayouts = const [];
  double _bodyLaneWidth = 0;
  (int court, int slot)? _rangeAnchor;
  (int court, int slot)? _rangeFocus;

  // Chế độ "Chọn nhiều": ô đã chạm đầu tiên, chờ ô cuối.
  (int court, int slot)? _tapAnchor;

  // Ô cuối cùng ngón tay chạm/nhả: nút ✕ bỏ chọn hiện ngay tại đó.
  (int court, int slot)? _clearCell;

  // Kéo tay nắm đổi thời lượng: trận đang kéo và quãng đã kéo (px).
  String? _resizeMatchId;
  double _resizeDeltaPx = 0;

  /// Vùng vẽ tô sáng: vùng đang kéo (chưa nhả tay) hoặc vùng host đang giữ.
  ScheduleRange? get _activeRange {
    final anchor = _rangeAnchor;
    final focus = _rangeFocus;
    if (anchor == null || focus == null) return widget.selectedRange;
    return _normalizedRange(anchor, focus);
  }

  ScheduleRange _normalizedRange(
    (int court, int slot) a,
    (int court, int slot) b,
  ) => (
    firstCourt: a.$1 < b.$1 ? a.$1 : b.$1,
    lastCourt: a.$1 > b.$1 ? a.$1 : b.$1,
    firstSlot: a.$2 < b.$2 ? a.$2 : b.$2,
    lastSlot: a.$2 > b.$2 ? a.$2 : b.$2,
  );

  void _beginRange(Offset local) {
    setState(() {
      _rangeAnchor = _cellAt(local);
      _rangeFocus = _rangeAnchor;
    });
  }

  void _extendRange(Offset local) {
    if (_rangeAnchor == null) return;
    final cell = _cellAt(local);
    if (cell == _rangeFocus) return;
    setState(() => _rangeFocus = cell);
  }

  /// Chạm ô (court, slot) ở chế độ "Chọn nhiều": chạm đầu đánh dấu một ô, chạm
  /// thứ hai chốt vùng chữ nhật, chạm thứ ba bắt đầu vùng mới.
  void _tapSelect(int court, int slot) {
    final anchor = _tapAnchor;
    final cell = (court, slot);
    _clearCell = cell;
    if (anchor == null) {
      _tapAnchor = cell;
      widget.onRangeSelected?.call(_normalizedRange(cell, cell));
      return;
    }
    _tapAnchor = null;
    widget.onRangeSelected?.call(_normalizedRange(anchor, cell));
  }

  @override
  void didUpdateWidget(ScheduleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Host xoá vùng thì bỏ ô chạm dở và vị trí nút ✕; tắt chế độ thì bỏ ô chạm dở.
    if (!widget.selectMode || widget.selectedRange == null) _tapAnchor = null;
    if (widget.selectedRange == null) _clearCell = null;
  }

  /// Kéo tay nắm ở cột giờ: báo chiều cao hàng mới cho host (lưới không tự đổi).
  void _resizeSlots(double deltaY) {
    final next = (widget.slotHeight + deltaY)
        .clamp(ScheduleGrid.minSlotHeight, ScheduleGrid.maxSlotHeight)
        .toDouble();
    if (next == widget.slotHeight) return;
    widget.onSlotHeightChanged?.call(next);
  }

  void _commitRange() {
    final anchor = _rangeAnchor;
    final focus = _rangeFocus;
    setState(() {
      _rangeAnchor = null;
      _rangeFocus = null;
      _clearCell = focus;
    });
    if (anchor == null || focus == null) return;
    widget.onRangeSelected?.call(_normalizedRange(anchor, focus));
  }

  /// Kéo tay nắm cạnh dưới thẻ: cộng dồn quãng kéo để thẻ giãn theo ngón tay.
  void _resizeUpdate(MatchModel match, double deltaY) => setState(() {
    _resizeMatchId = match.id;
    _resizeDeltaPx += deltaY;
  });

  /// Cử chỉ bị huỷ (không phải nhả tay): bỏ quãng đã kéo, không báo host.
  void _resizeCancel() => setState(() {
    _resizeMatchId = null;
    _resizeDeltaPx = 0;
  });

  /// Nhả tay: đổi quãng đã kéo thành số phút (làm tròn theo bước ô, tối thiểu
  /// một bước, tối đa [_maxResizeMinutes]) rồi báo host nếu có thay đổi.
  void _resizeEnd(MatchModel match) {
    final step = widget.stepMinutes;
    final current = _durationOf(match);
    final raw = current + _resizeDeltaPx / _pixelsPerMinute;
    final snapped = ((raw / step).round() * step).clamp(
      step,
      _maxResizeMinutes,
    );
    setState(() {
      _resizeMatchId = null;
      _resizeDeltaPx = 0;
    });
    if (snapped != current) widget.onResizeMatch?.call(match, snapped);
  }

  /// Ô nằm dưới điểm [local] (toạ độ trong thân lưới, gồm cả cột giờ).
  (int court, int slot) _cellAt(Offset local) {
    final scroll = _bodyCtrl.hasClients ? _bodyCtrl.offset : 0.0;
    final x = local.dx - _timeColumnWidth + scroll;
    var cursor = 0.0;
    var court = _bodyLayouts.isEmpty ? 0 : _bodyLayouts.length - 1;
    for (var i = 0; i < _bodyLayouts.length; i++) {
      final width = _bodyLayouts[i].laneCount * _bodyLaneWidth;
      if (x < cursor + width) {
        court = i;
        break;
      }
      cursor += width;
    }
    final slot = (local.dy ~/ _slotHeight).clamp(0, _slotCount - 1);
    return (court, slot);
  }

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(_syncHeader);
  }

  void _syncHeader() {
    if (!_headerCtrl.hasClients || !_bodyCtrl.hasClients) return;
    if ((_headerCtrl.offset - _bodyCtrl.offset).abs() < 0.5) return;
    _headerCtrl.jumpTo(_bodyCtrl.offset);
  }

  @override
  void dispose() {
    _bodyCtrl.removeListener(_syncHeader);
    _bodyCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  /// Số ô theo bước [ScheduleGrid.stepMinutes] trong khung giờ vận hành.
  int get _slotCount =>
      ((widget.endHour - widget.startHour) * 60) ~/ widget.stepMinutes;

  double get _pixelsPerMinute => _slotHeight / widget.stepMinutes;

  /// Nhãn từng ô theo bước: 00:00, 00:15, 00:30… (hoặc 00:10, 00:20… với
  /// bước 10 phút).
  List<String> get _slotLabels => [
    for (var i = 0; i < _slotCount; i++)
      () {
        final total = widget.startHour * 60 + i * widget.stepMinutes;
        final h = (total ~/ 60).toString().padLeft(2, '0');
        final m = (total % 60).toString().padLeft(2, '0');
        return '$h:$m';
      }(),
  ];

  String _courtOf(MatchModel match) =>
      (match.courtName?.trim().isNotEmpty ?? false)
      ? match.courtName!.trim()
      : match.court.trim();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.courts.isEmpty) return const SizedBox.shrink();
    final courtLayouts = [
      for (final court in widget.courts) _buildCourtLayout(court),
    ];
    final totalLanes = courtLayouts.fold<int>(
      0,
      (sum, layout) => sum + layout.laneCount,
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        final laneWidth = _laneWidthFor(
          constraints.maxWidth - _timeColumnWidth,
          totalLanes,
        );
        _bodyLayouts = courtLayouts;
        _bodyLaneWidth = laneWidth;
        return Column(
          children: [
            // Header tên sân — ghim trên, cuộn ngang dùng chung controller.
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  Container(
                    width: _timeColumnWidth,
                    decoration: BoxDecoration(
                      color: _timeColumnColor(colors),
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    // Timetable corner: clock (time axis) and "Sân" (court axis)
                    // split by a diagonal; dragging it still scales the rows.
                    child: Listener(
                      key: const ValueKey('schedule-scale-handle'),
                      behavior: HitTestBehavior.opaque,
                      onPointerMove: widget.onSlotHeightChanged == null
                          ? null
                          : (event) => _resizeSlots(event.delta.dy),
                      child: CustomPaint(
                        painter: _CornerDiagonalPainter(colors.border),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 3,
                              right: 6,
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.scheduleQuickCourt,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 6,
                              child: Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _headerCtrl,
                      scrollDirection: Axis.horizontal,
                      // Header không nhận cử chỉ cuộn: nó chỉ đi theo thân, tránh
                      // hai vùng cùng tranh một cú swipe ngang.
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < widget.courts.length;
                            index++
                          )
                            SizedBox(
                              width: courtLayouts[index].laneCount * laneWidth,
                              child: _courtHeader(widget.courts[index]),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Thân lưới — cột giờ khoá trái, khối sân cuộn ngang.
            SizedBox(
              height: _slotCount * _slotHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: widget.onRangeSelected == null
                    ? null
                    : (details) => _beginRange(details.localPosition),
                onLongPressMoveUpdate: widget.onRangeSelected == null
                    ? null
                    : (details) => _extendRange(details.localPosition),
                onLongPressEnd: widget.onRangeSelected == null
                    ? null
                    : (_) => _commitRange(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _timeColumn(colors),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _bodyCtrl,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              var index = 0;
                              index < widget.courts.length;
                              index++
                            )
                              SizedBox(
                                width:
                                    courtLayouts[index].laneCount * laneWidth,
                                child: _courtColumn(
                                  index,
                                  courtLayouts[index],
                                  colors,
                                  laneWidth,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Blue band with just the court number ("Sân 1" -> "1"); the full name
  /// stays in the tooltip.
  Widget _courtHeader(String court) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryDark),
          left: BorderSide(color: AppTheme.primaryDark),
        ),
      ),
      child: Tooltip(
        message: court,
        child: Text(
          formatCourtShortName(court),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Light grey for the time axis (the corner and the hour labels).
  Color _timeColumnColor(AppColorsExtension colors) =>
      Color.alphaBlend(colors.border.withValues(alpha: 0.7), colors.bgCard);

  /// Court label chip tinted by column index so a card can be tied to its column.
  Widget _courtChip(
    String court,
    int index, {
    required double fontSize,
    required double hPadding,
  }) {
    final chip = courtChipColors(index);
    return Container(
      constraints: const BoxConstraints(maxWidth: 80),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 1),
      decoration: BoxDecoration(
        color: chip.background,
        border: Border.all(color: chip.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formatCourtShortName(court),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: chip.foreground,
        ),
      ),
    );
  }

  Widget _timeColumn(AppColorsExtension colors) {
    return Container(
      width: _timeColumnWidth,
      decoration: BoxDecoration(
        color: _timeColumnColor(colors),
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          for (final label in _slotLabels)
            Container(
              height: _slotHeight,
              alignment: Alignment.topRight,
              padding: EdgeInsets.only(
                right: widget.emphasizeTimeLabels ? 0 : 6,
                top: 1,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: label.endsWith(':00')
                        ? colors.border
                        : colors.border.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: widget.emphasizeTimeLabels ? 12 : 10.5,
                  fontWeight: label.endsWith(':00')
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  _CourtLayout _buildCourtLayout(String court) {
    final matches =
        widget.matches
            .where(
              (match) =>
                  _courtOf(match) == court && match.scheduledTime != null,
            )
            .toList()
          ..sort((a, b) {
            final timeOrder = a.scheduledTime!.compareTo(b.scheduledTime!);
            return timeOrder != 0
                ? timeOrder
                : a.matchNumber.compareTo(b.matchNumber);
          });
    final laneEnds = <int>[];
    final placements = <_ScheduledMatchLane>[];

    for (final match in matches) {
      final start = match.scheduledTime!;
      final minutesFromOpen =
          (start.hour - widget.startHour) * 60 + start.minute;
      final startMinute = minutesFromOpen < 0 ? 0 : minutesFromOpen;
      final duration = _layoutDurationOf(match);
      var lane = 0;
      while (lane < laneEnds.length && laneEnds[lane] > startMinute) {
        lane++;
      }

      if (lane == laneEnds.length) {
        laneEnds.add(startMinute + duration);
      } else {
        laneEnds[lane] = startMinute + duration;
      }
      placements.add((match: match, lane: lane));
    }

    return _CourtLayout(
      placements: placements,
      laneCount: laneEnds.isEmpty ? 1 : laneEnds.length,
    );
  }

  /// Thời lượng trận: `durationMinutes` đã lưu, thiếu thì minutesPerSet × số set.
  /// Dùng chung với màn vận hành (xem `utils/schedule_duration.dart`).
  int _durationOf(MatchModel match) =>
      scheduledDurationMinutes(match, minutesPerSet: widget.minutesPerSet);

  /// Số cột điểm = số set đã có trong scoreHistory. Trận chưa có set thì không có cột.
  int _scoreColumnsOf(MatchModel match) => match.scoreHistory.length;

  /// Bề rộng một lane: vừa thì chia đều cho mọi lane. Không vừa thì chia đúng số
  /// lane trọn vẹn vừa màn (điện thoại = 2 sân), phần còn lại cuộn ngang — không
  /// cột nào bị cắt dở ở mép phải.
  double _laneWidthFor(double availableWidth, int totalLanes) {
    final fit = availableWidth / totalLanes;
    if (fit >= _minCourtLaneWidth) return fit;
    final visible = (availableWidth / _minCourtLaneWidth).floor().clamp(
      1,
      totalLanes,
    );
    return availableWidth / visible;
  }

  Widget _courtColumn(
    int courtIndex,
    _CourtLayout layout,
    AppColorsExtension colors,
    double laneWidth,
  ) {
    final court = widget.courts[courtIndex];
    final dropEnabled = widget.onDropMatch != null;
    return Container(
      height: _slotHeight * _slotCount,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Stack(
        children: [
          // Lưới nền theo bước ô cấu hình.
          Column(
            children: [
              for (final label in _slotLabels)
                Container(
                  height: _slotHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: label.endsWith(':00')
                            ? colors.border
                            : colors.border.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Ô trống nằm DƯỚI thẻ trận để bấm mở trận vẫn hoạt động.
          if (dropEnabled || widget.onTapEmptyCell != null || widget.selectMode)
            Positioned.fill(
              child: Column(
                children: [
                  for (var index = 0; index < _slotCount; index++)
                    _emptySlot(court, courtIndex, index, colors, dropEnabled),
                ],
              ),
            ),
          for (final placement in layout.placements)
            _matchCard(placement.match, placement.lane, colors, laneWidth),
          ..._rangeHighlight(courtIndex),
        ],
      ),
    );
  }

  /// Khung tô sáng vùng đang chọn trên cột sân [courtIndex]; không bắt cử chỉ
  /// nên thẻ và ô phía dưới vẫn nhận chạm.
  List<Widget> _rangeHighlight(int courtIndex) {
    final range = _activeRange;
    if (range == null ||
        courtIndex < range.firstCourt ||
        courtIndex > range.lastCourt) {
      return const [];
    }
    final rows = range.lastSlot - range.firstSlot + 1;
    // Only the host-held range (not the live drag) carries the ✕, and only
    // once: on the cell the finger last touched (falls back to the box's
    // top-right when the range was set without a touch).
    final touched = _clearCell;
    final clearCourt = touched?.$1 ?? range.lastCourt;
    final clearSlot = touched?.$2 ?? range.firstSlot;
    final showClear =
        widget.onClearRange != null &&
        widget.selectedRange == range &&
        courtIndex == clearCourt;
    return [
      Positioned(
        key: const ValueKey('schedule-range-highlight'),
        left: 0,
        right: 0,
        top: range.firstSlot * _slotHeight,
        height: rows * _slotHeight,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ),
      if (showClear)
        Positioned(
          right: 4,
          top: clearSlot * _slotHeight + 4,
          child: Tooltip(
            message: AppLocalizations.of(context)!.scheduleSelectClear,
            child: GestureDetector(
              key: const ValueKey('schedule-range-clear'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClearRange,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  /// Ô trống của sân [court] theo bước ô cấu hình: nhận thả trận để xếp lịch
  /// và nhận chạm để mở danh sách trận chờ. Thẻ trận đặt phía trên nên ô này
  /// không nuốt cử chỉ.
  Widget _emptySlot(
    String court,
    int courtIndex,
    int index,
    AppColorsExtension colors,
    bool dropEnabled,
  ) {
    final selecting = widget.selectMode;
    final tappable = selecting || widget.onTapEmptyCell != null;
    return DragTarget<String>(
      key: ValueKey('schedule-slot-$court-$index'),
      onWillAcceptWithDetails: (details) =>
          dropEnabled && details.data.trim().isNotEmpty,
      onAcceptWithDetails: (details) =>
          widget.onDropMatch!(details.data, court, _slotStart(index)),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: !tappable
              ? null
              : selecting
              ? () => _tapSelect(courtIndex, index)
              : () => widget.onTapEmptyCell!(court, _slotStart(index)),
          child: Container(
            height: _slotHeight,
            alignment: Alignment.center,
            color: hovering ? AppTheme.primary.withValues(alpha: 0.12) : null,
            child: tappable && !selecting && !hovering
                ? Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: colors.textMuted.withValues(alpha: 0.4),
                  )
                : null,
          ),
        );
      },
    );
  }

  /// Giờ bắt đầu của ô thứ [index] trong ngày đang xem, theo bước ô cấu hình.
  DateTime _slotStart(int index) {
    final day = widget.day ?? DateTime.now();
    return DateTime(
      day.year,
      day.month,
      day.day,
      widget.startHour,
    ).add(Duration(minutes: index * widget.stepMinutes));
  }

  Widget _matchCard(
    MatchModel match,
    int lane,
    AppColorsExtension colors,
    double laneWidth,
  ) {
    final start = match.scheduledTime;
    if (start == null) return const SizedBox.shrink();

    final minutesFromOpen = (start.hour - widget.startHour) * 60 + start.minute;
    final top = (minutesFromOpen * _pixelsPerMinute).clamp(
      0.0,
      double.infinity,
    );
    final duration = _durationOf(match);
    final divisionName = _divisionNameFor(match);
    final calculatedHeight = duration * _pixelsPerMinute - 3;
    final minimumHeight = _minimumHeightFor(match, duration, divisionName);
    final resizing = _resizeMatchId == match.id;
    final baseHeight = calculatedHeight < minimumHeight
        ? minimumHeight
        : calculatedHeight;
    final height = resizing
        ? (baseHeight + _resizeDeltaPx).clamp(minimumHeight, double.infinity)
        : baseHeight;
    final style = _cardStyle(match, colors);
    final isDraft = widget.draftMatchIds.contains(match.id);
    // Trận đã đấu hoặc đã kết thúc không được kéo đi và không nhận thả vào.
    final movable = !isDraft && !isScheduleLocked(match);

    final content = duration < _compactBelowMinutes
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (divisionName != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _divisionChip(divisionName, style.tint.headerText),
                  ),
                Expanded(child: _compactContent(match, style)),
              ],
            ),
          )
        : _fullContent(match, start, style, divisionName);

    Widget card = GestureDetector(
      onTap: isDraft ? null : () => _tapMatch(match, start),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: style.decoration,
        // Full-height gender stripe on the left; content is inset past it.
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: _stripeWidth),
              child: content,
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _stripeWidth,
              child: ColoredBox(
                key: ValueKey('schedule-match-stripe-${match.id}'),
                color: style.tint.stripe,
              ),
            ),
            if (movable && widget.onResizeMatch != null)
              _resizeHandle(match, resizing),
          ],
        ),
      ),
    );

    if (isDraft) {
      card = Opacity(
        opacity: 0.85,
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: AppTheme.primary,
            radius: 6,
          ),
          child: card,
        ),
      );
    }
    if (movable && widget.onDropMatch != null) {
      card = LongPressDraggable<String>(
        data: match.id,
        feedback: _dragFeedback(match, laneWidth, colors),
        childWhenDragging: Opacity(opacity: 0.35, child: card),
        child: card,
      );
    }
    if (movable && widget.onDropOnMatch != null) {
      final target = card;
      card = DragTarget<String>(
        onWillAcceptWithDetails: (details) =>
            details.data.trim().isNotEmpty && details.data != match.id,
        onAcceptWithDetails: (details) =>
            widget.onDropOnMatch!(details.data, match.id),
        builder: (context, candidates, rejected) => candidates.isEmpty
            ? target
            : Stack(
                children: [
                  target,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    return Positioned(
      key: ValueKey('schedule-match-${match.id}'),
      top: top + 1.5,
      left: lane * laneWidth + 3,
      width: laneWidth - 6,
      height: height,
      child: card,
    );
  }

  /// Chạm thẻ: mở trận, hoặc (chế độ "Chọn nhiều") tính là chạm ô bắt đầu của
  /// trận để chọn vùng chứa cả trận.
  void _tapMatch(MatchModel match, DateTime start) {
    if (!widget.selectMode) return widget.onTapMatch(match.id);
    final court = widget.courts.indexOf(_courtOf(match));
    if (court < 0) return;
    final minutes = (start.hour - widget.startHour) * 60 + start.minute;
    final slot = (minutes ~/ widget.stepMinutes).clamp(0, _slotCount - 1);
    _tapSelect(court, slot);
  }

  /// Tay nắm ở cạnh dưới thẻ: kéo xuống/lên để đổi thời lượng. Đang kéo thì hiện
  /// số phút sẽ áp dụng.
  Widget _resizeHandle(MatchModel match, bool resizing) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      left: _stripeWidth,
      right: 0,
      bottom: 0,
      height: _resizeHandleHeight,
      child: GestureDetector(
        key: ValueKey('schedule-resize-handle-${match.id}'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) =>
            _resizeUpdate(match, details.delta.dy),
        onVerticalDragEnd: (_) => _resizeEnd(match),
        onVerticalDragCancel: _resizeCancel,
        child: Center(
          child: resizing
              ? Text(
                  l10n.scheduleQuickMinutes(_pendingResizeMinutes(match)),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                )
              : Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ),
      ),
    );
  }

  /// Số phút sẽ áp dụng nếu nhả tay lúc này (cùng cách làm tròn với `_resizeEnd`).
  int _pendingResizeMinutes(MatchModel match) {
    final step = widget.stepMinutes;
    final raw = _durationOf(match) + _resizeDeltaPx / _pixelsPerMinute;
    return ((raw / step).round() * step).clamp(step, _maxResizeMinutes);
  }

  /// Hình theo ngón tay khi kéo thẻ: tên hai đội, nổi trên lưới.
  Widget _dragFeedback(
    MatchModel match,
    double laneWidth,
    AppColorsExtension colors,
  ) {
    return Material(
      elevation: 4,
      color: colors.bgCard,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: laneWidth - 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            '${_sideText(match, 1)} - ${_sideText(match, 2)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Hạng mục của trận. Trận không mang `divisionId` mà giải chỉ có một hạng
  /// mục thì đó chính là hạng mục của trận.
  String? _divisionIdFor(MatchModel match) {
    final names = widget.divisionNameById;
    final divisionId = match.divisionId;
    if (divisionId != null) {
      return names.containsKey(divisionId) ? divisionId : null;
    }
    return names.length == 1 ? names.keys.single : null;
  }

  String? _divisionNameFor(MatchModel match) {
    final divisionId = _divisionIdFor(match);
    final name = divisionId == null
        ? null
        : widget.divisionNameById[divisionId]?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  /// Card colours follow the division's gender restriction (same palette as the
  /// web schedule card); a missing division reads as "flexible".
  ScheduleGenderTint _tintFor(MatchModel match) {
    final divisionId = _divisionIdFor(match);
    return scheduleGenderTint(
      divisionId == null
          ? null
          : widget.divisionMetadataById[divisionId]?.genderRestriction,
    );
  }

  Widget _divisionChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  /// Tên đội dạng chuỗi (tiêu đề kéo thả); VĐV rút gọn như thẻ.
  String _sideText(MatchModel match, int side) => participantLabel(
    teamName: matchSideTeamName(match, side),
    players: matchSidePlayers(match, side),
    teamOnly: isFootballMatch(match),
    abbreviated: true,
  );

  /// Chiều cao tối thiểu của thẻ: trận ngắn chỉ một dòng; thẻ đủ hai đội phải
  /// chứa mọi VĐV (mỗi VĐV một dòng), không tràn.
  double _minimumHeightFor(
    MatchModel match,
    int duration,
    String? divisionName,
  ) {
    if (duration < _compactBelowMinutes) {
      return divisionName == null
          ? _minimumCardHeight
          : _minimumCompactDivisionCardHeight;
    }
    final contentHeight =
        _fullCardChromeHeight +
        _competitorBlockHeight(matchSidePlayers(match, 1).length) +
        _competitorBlockHeight(matchSidePlayers(match, 2).length) +
        1;
    return contentHeight > _minimumFullCardHeight
        ? contentHeight
        : _minimumFullCardHeight;
  }

  /// Chiều cao một hàng đội: mỗi VĐV một dòng có avatar; không có VĐV thì một dòng chữ.
  double _competitorBlockHeight(int players) {
    if (players == 0) return 16;
    const avatar = 14.0;
    const gap = 4.0;
    return players * avatar + (players - 1) * gap;
  }

  int _layoutDurationOf(MatchModel match) {
    final duration = _durationOf(match);
    final divisionName = _divisionNameFor(match);
    if (divisionName == null) return duration;

    final calculatedHeight = duration * _pixelsPerMinute - 3;
    final minimumHeight = _minimumHeightFor(match, duration, divisionName);
    final renderedHeight = calculatedHeight < minimumHeight
        ? minimumHeight
        : calculatedHeight;
    final renderedMinutes = (renderedHeight / _pixelsPerMinute).ceil();
    return renderedMinutes > duration ? renderedMinutes : duration;
  }

  /// Thẻ tô theo giới tính hạng mục (vạch trái, viền, header); trạng thái không
  /// đổi màu thẻ. Chỉ viền chọn là phản hồi tương tác; LIVE là chấm đỏ nhấp nháy.
  _CardStyle _cardStyle(MatchModel match, AppColorsExtension colors) {
    final selected = match.id == widget.selectedMatchId;
    final tint = _tintFor(match);
    return (
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? colors.warning : tint.border,
          width: selected ? 2.0 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      tint: tint,
      winnerBg: colors.bgSurface,
      accent: Colors.transparent,
      fg: colors.textPrimary,
    );
  }

  /// Thẻ một dòng (dưới _compactBelowMinutes phút); giờ đã có ở cột giờ.
  Widget _compactContent(MatchModel match, _CardStyle style) {
    return Row(
      children: [
        _teamName(match, 1, style),
        _compactCenter(match, style),
        _teamName(match, 2, style),
      ],
    );
  }

  Widget _compactCenter(MatchModel match, _CardStyle style) {
    if (match.isLive) return _LiveDot(key: _liveDotKey(match));
    final label = match.isCompleted
        ? '${match.score1} - ${match.score2}'
        : 'vs';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: style.fg.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _fullContent(
    MatchModel match,
    DateTime start,
    _CardStyle style,
    String? divisionName,
  ) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fullHeader(match, start, style, divisionName),
        // Hai đội căn giữa giữa header và footer, như justify-between của web.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _competitorRow(match, 0, style),
              Divider(height: 1, thickness: 1, color: colors.borderLight),
              _competitorRow(match, 1, style),
            ],
          ),
        ),
        _fullFooter(match, style),
      ],
    );
  }

  /// Header thẻ: "🕐 giờ / sân" một cụm bên trái (chip sân tô theo chỉ số sân), nhãn
  /// hạng mục và chấm LIVE bên phải; nền và chữ theo màu giới tính của hạng mục.
  Widget _fullHeader(
    MatchModel match,
    DateTime start,
    _CardStyle style,
    String? divisionName,
  ) {
    final time =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    final court = _courtOf(match);
    final muted = style.tint.headerText.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
      decoration: BoxDecoration(
        color: style.tint.header,
        border: Border(bottom: BorderSide(color: style.tint.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 10, color: muted),
          const SizedBox(width: 2),
          Text(
            time,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (court.isNotEmpty) ...[
            Text(' / ', style: TextStyle(fontSize: 10, color: muted)),
            Flexible(
              child: Semantics(
                label: court,
                excludeSemantics: true,
                child: _courtChip(
                  court,
                  widget.courts.indexOf(court),
                  fontSize: 9.5,
                  hPadding: 4,
                ),
              ),
            ),
          ],
          Expanded(
            flex: 2,
            child: divisionName == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _divisionChip(divisionName, style.tint.headerText),
                    ),
                  ),
          ),
          if (match.isLive) ...[
            const SizedBox(width: 4),
            _LiveDot(key: _liveDotKey(match)),
          ],
        ],
      ),
    );
  }

  /// Footer thẻ: tên vòng chuẩn (vd. "Vòng 1/8") trên nền xám nhạt như web. Trận đã
  /// có tỷ số nhưng không có dữ liệu set thì hiện tổng điểm bên phải.
  Widget _fullFooter(MatchModel match, _CardStyle style) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final roundLabelOf = widget.roundLabelOf;
    final title = roundLabelOf == null
        ? l10n.organizer_matchTitle(match.round, match.matchNumber)
        : roundLabelOf(match);
    final showTotal =
        match.scoreHistory.isEmpty && (match.isLive || match.isCompleted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
          ),
          if (showTotal)
            Text(
              '${match.score1} - ${match.score2}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: style.fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          if (match.isCompleted) ...[
            const SizedBox(width: 6),
            Text(
              l10n.organizer_statusCompleted,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Hàng đội: tên bên trái, một ô điểm cho mỗi set đã có; trận chưa đấu không có ô nào.
  /// Đội thắng được tô nền và accent như `row.won` của web.
  Widget _competitorRow(MatchModel match, int side, _CardStyle style) {
    final teamId = side == 0 ? match.team1Id : match.team2Id;
    final won = _isWinner(match, teamId);
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
      decoration: BoxDecoration(
        color: won ? style.winnerBg : null,
        border: Border(
          left: BorderSide(
            color: won ? style.accent : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          _teamName(match, side + 1, style),
          for (var index = 0; index < _scoreColumnsOf(match); index++)
            SizedBox(
              width: 16,
              child: Text(
                _setScoreLabel(match, index, side),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: style.fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Đội thắng khi trận đã kết thúc có winnerId; trận chưa xong không tô đậm ai.
  bool _isWinner(MatchModel match, String teamId) =>
      match.isCompleted &&
      match.winnerId.isNotEmpty &&
      match.winnerId == teamId;

  /// Điểm một set của một bên, đọc từ scoreHistory (cùng contract web).
  /// Chỉ gọi với index < scoreHistory.length (xem _scoreColumnsOf).
  String _setScoreLabel(MatchModel match, int index, int side) {
    final set = match.scoreHistory[index];
    return '${side == 0 ? set.score1 : set.score2}';
  }

  /// Tô đậm đội thắng khi trận đã có người thắng; không đổi màu chữ theo trạng thái.
  Widget _teamName(MatchModel match, int side, _CardStyle style) {
    final isWinner = _isWinner(
      match,
      side == 1 ? match.team1Id : match.team2Id,
    );
    final teamName = matchSideTeamName(match, side);
    final players = matchSidePlayers(match, side);
    final isFootball = isFootballMatch(match);

    final display = resolveParticipantDisplay(
      teamName: teamName,
      players: players,
      teamOnly: isFootball,
    );

    final textStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
      color: style.fg,
    );

    // Nếu là đội có tên (bóng đá hoặc tên đội đặt riêng): hiển thị 1 dòng tên đội
    if (display.isTeam) {
      return Flexible(
        child: Text(
          display.teamName!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      );
    }

    if (players.isEmpty) {
      return Flexible(
        child: Text(
          AppLocalizations.of(context)!.matchNotDetermined,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle.copyWith(color: context.colors.textMuted),
        ),
      );
    }

    // Đôi (2 người): Tách thành 2 dòng trên dưới gọn gàng kèm avatar
    if (players.length >= 2) {
      return Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _playerMiniRow(players[0], textStyle),
            const SizedBox(height: 1.5),
            _playerMiniRow(players[1], textStyle),
          ],
        ),
      );
    }

    // Đơn (1 người)
    return Flexible(child: _playerMiniRow(players[0], textStyle));
  }

  Widget _playerMiniRow(ParticipantPlayer player, TextStyle textStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 6.5,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
          backgroundImage:
              player.avatarUrl != null && player.avatarUrl!.isNotEmpty
              ? NetworkImage(player.avatarUrl!)
              : null,
          child: (player.avatarUrl == null || player.avatarUrl!.isEmpty)
              ? Text(
                  player.fullName.isNotEmpty
                      ? player.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 3.5),
        Flexible(
          child: Text(
            abbreviateName(player.fullName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  Key _liveDotKey(MatchModel match) =>
      ValueKey('schedule-live-dot-${match.id}');
}

/// Red dot that pulses while a match is live. Stays solid when the platform
/// asks to reduce animations.
class _LiveDot extends StatefulWidget {
  const _LiveDot({super.key});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  static const Color _liveRed = Color(0xFFEF4444);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
          color: _liveRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CourtLayout {
  const _CourtLayout({required this.placements, required this.laneCount});

  final List<_ScheduledMatchLane> placements;
  final int laneCount;
}

/// Viền nét đứt cho thẻ nháp xếp tự động.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.75);
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + _dash > metric.length
            ? metric.length
            : distance + _dash;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Top-left to bottom-right slash splitting the corner into time and court.
class _CornerDiagonalPainter extends CustomPainter {
  const _CornerDiagonalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CornerDiagonalPainter oldDelegate) =>
      oldDelegate.color != color;
}
