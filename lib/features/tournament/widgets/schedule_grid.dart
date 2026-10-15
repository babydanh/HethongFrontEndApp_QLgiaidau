import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_team_label.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

typedef _ScheduledMatchLane = ({MatchModel match, int lane});

typedef _CardStyle = ({
  BoxDecoration decoration,
  Color headerBg,
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
  final double slotHeight;
  final bool emphasizeTimeLabels;
  final int startHour;
  final int endHour;
  final String? selectedMatchId;
  final ValueChanged<String> onTapMatch;

  /// Tên vòng chuẩn theo sơ đồ (vd. "Vòng 1/8", "Tứ kết") làm footer thẻ.
  /// Null thì footer giữ "Vòng R • Trận N" theo số vòng thô (lưới BTC).
  final String Function(MatchModel match)? roundLabelOf;

  /// Rút gọn tên đội như lịch web (lịch công khai). Lưới BTC giữ tên đầy đủ.
  final bool shortTeamNames;

  /// Phút mỗi set BTC cấu hình; dùng khi trận chưa có `durationMinutes`.
  final int minutesPerSet;

  /// Ngày đang xem. Dùng để tính giờ khi thả trận vào lưới.
  final DateTime? day;

  /// Có giá trị thì lưới mở chế độ xếp lịch: mỗi ô 15 phút của mỗi sân nhận
  /// thẻ trận được kéo thả. Null (mặc định) giữ nguyên lưới chỉ đọc.
  final void Function(String matchId, String court, DateTime scheduledAt)?
  onDropMatch;

  /// Có giá trị thì nhấn giữ rồi kéo trên lưới để chọn một vùng ô.
  final void Function(ScheduleRange range)? onRangeSelected;

  const ScheduleGrid({
    super.key,
    required this.courts,
    required this.matches,
    required this.startHour,
    required this.endHour,
    this.selectedMatchId,
    required this.onTapMatch,
    this.divisionNameById = const {},
    this.slotHeight = 144,
    this.emphasizeTimeLabels = false,
    this.minutesPerSet = 15,
    this.day,
    this.onDropMatch,
    this.onRangeSelected,
    this.roundLabelOf,
    this.shortTeamNames = false,
  });

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  /// Shared-grid default is 144dp; the public schedule opts into 120dp.
  /// `BASE_PIXELS_PER_MINUTE` remains the web grid's separate layout scale.
  double get _slotHeight => widget.slotHeight;
  static const double _timeColumnWidth = 56;
  static const double _minCourtLaneWidth = 120;
  static const double _minimumCardHeight = 44;
  static const double _minimumCompactDivisionCardHeight = 60;
  static const double _minimumFullCardHeight = 76;

  /// Thẻ dưới 8 phút chỉ hiện một dòng; từ 8 phút trở lên hiện đủ hai đội.
  static const int _compactBelowMinutes = 8;

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

  void _beginRange(Offset local) {
    _rangeAnchor = _cellAt(local);
    _rangeFocus = _rangeAnchor;
  }

  void _extendRange(Offset local) {
    if (_rangeAnchor == null) return;
    _rangeFocus = _cellAt(local);
  }

  void _commitRange() {
    final anchor = _rangeAnchor;
    final focus = _rangeFocus;
    _rangeAnchor = null;
    _rangeFocus = null;
    if (anchor == null || focus == null) return;
    widget.onRangeSelected?.call((
      firstCourt: anchor.$1 < focus.$1 ? anchor.$1 : focus.$1,
      lastCourt: anchor.$1 > focus.$1 ? anchor.$1 : focus.$1,
      firstSlot: anchor.$2 < focus.$2 ? anchor.$2 : focus.$2,
      lastSlot: anchor.$2 > focus.$2 ? anchor.$2 : focus.$2,
    ));
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

  /// Số ô 15 phút trong khung giờ vận hành.
  int get _slotCount => (widget.endHour - widget.startHour) * 4;

  double get _pixelsPerMinute => _slotHeight / 15;

  /// Nhãn từng ô 15 phút: 00:00, 00:15, 00:30…
  List<String> get _slotLabels => [
    for (var i = 0; i < _slotCount; i++)
      () {
        final total = widget.startHour * 60 + i * 15;
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: colors.textMuted,
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
                                  widget.courts[index],
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
      child: Text(
        court,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _timeColumn(AppColorsExtension colors) {
    return Container(
      width: _timeColumnWidth,
      decoration: BoxDecoration(
        color: colors.bgCard,
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
                      ? FontWeight.w700
                      : widget.emphasizeTimeLabels
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: label.endsWith(':00')
                      ? colors.textPrimary
                      : widget.emphasizeTimeLabels
                      ? colors.textSecondary
                      : colors.textMuted,
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
    String court,
    _CourtLayout layout,
    AppColorsExtension colors,
    double laneWidth,
  ) {
    final dropEnabled = widget.onDropMatch != null;
    return Container(
      height: _slotHeight * _slotCount,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Stack(
        children: [
          // Lưới nền 15 phút.
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
          // Ô nhận thả nằm DƯỚI thẻ trận để bấm mở trận vẫn hoạt động.
          if (dropEnabled)
            Positioned.fill(
              child: Column(
                children: [
                  for (var index = 0; index < _slotCount; index++)
                    DragTarget<String>(
                      key: ValueKey('schedule-slot-$court-$index'),
                      onWillAcceptWithDetails: (details) =>
                          details.data.trim().isNotEmpty,
                      onAcceptWithDetails: (details) => widget.onDropMatch!(
                        details.data,
                        court,
                        _slotStart(index),
                      ),
                      builder: (context, candidates, rejected) => Container(
                        height: _slotHeight,
                        color: candidates.isEmpty
                            ? null
                            : AppTheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ),
            ),
          for (final placement in layout.placements)
            _matchCard(placement.match, placement.lane, colors, laneWidth),
        ],
      ),
    );
  }

  /// Giờ bắt đầu của ô 15 phút thứ [index] trong ngày đang xem.
  DateTime _slotStart(int index) {
    final day = widget.day ?? DateTime.now();
    return DateTime(
      day.year,
      day.month,
      day.day,
      widget.startHour,
    ).add(Duration(minutes: index * 15));
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
    final minimumHeight = _minimumHeightFor(duration, divisionName);
    final height = calculatedHeight < minimumHeight
        ? minimumHeight
        : calculatedHeight;
    final style = _cardStyle(match, colors);

    return Positioned(
      key: ValueKey('schedule-match-${match.id}'),
      top: top + 1.5,
      left: lane * laneWidth + 3,
      width: laneWidth - 6,
      height: height,
      child: GestureDetector(
        onTap: () => widget.onTapMatch(match.id),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: style.decoration,
          child: duration < _compactBelowMinutes
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (divisionName != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _divisionChip(
                            divisionName,
                            _divisionColorFor(match) ?? style.fg,
                          ),
                        ),
                      Expanded(child: _compactContent(match, style)),
                    ],
                  ),
                )
              : _fullContent(match, start, style, divisionName),
        ),
      ),
    );
  }

  /// Hạng mục của trận. Trận không mang `divisionId` mà giải chỉ có một hạng
  /// mục thì đó chính là hạng mục của trận.
  String? _divisionIdFor(MatchModel match) {
    final names = widget.divisionNameById;
    final divisionId = match.divisionId;
    if (divisionId != null)
      return names.containsKey(divisionId) ? divisionId : null;
    return names.length == 1 ? names.keys.single : null;
  }

  String? _divisionNameFor(MatchModel match) {
    final divisionId = _divisionIdFor(match);
    final name = divisionId == null
        ? null
        : widget.divisionNameById[divisionId]?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  /// Mỗi hạng mục một màu cố định theo thứ tự hạng mục của giải (Đôi Nam, Đôi Nữ…
  /// khác màu). Chỉ dùng token theme; không dùng màu lỗi để khỏi lẫn với LIVE.
  Color? _divisionColorFor(MatchModel match) {
    final divisionId = _divisionIdFor(match);
    if (divisionId == null) return null;
    final colors = context.colors;
    final palette = [
      AppTheme.primary,
      colors.warning,
      colors.success,
      AppTheme.secondaryDark,
      AppTheme.primaryDark,
      colors.info,
    ];
    final index = widget.divisionNameById.keys.toList().indexOf(divisionId);
    return palette[index % palette.length];
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

  /// Tên trên thẻ. Lịch công khai ([ScheduleGrid.shortTeamNames]) rút gọn như
  /// lịch web (mỗi VĐV 2 từ cuối, cặp nối " / "); lưới BTC giữ tên đầy đủ.
  String _shortName(MatchModel match, int side) {
    final name = side == 0 ? match.team1Name : match.team2Name;
    if (!widget.shortTeamNames) return name;
    final members =
        (side == 0 ? match.team1Members : match.team2Members) ?? const [];
    return scheduleShortTeamName(name, members: members);
  }

  double _minimumHeightFor(int duration, String? divisionName) {
    if (divisionName == null) return _minimumCardHeight;
    return duration < _compactBelowMinutes
        ? _minimumCompactDivisionCardHeight
        : _minimumFullCardHeight;
  }

  int _layoutDurationOf(MatchModel match) {
    final duration = _durationOf(match);
    final divisionName = _divisionNameFor(match);
    if (divisionName == null) return duration;

    final calculatedHeight = duration * _pixelsPerMinute - 3;
    final minimumHeight = _minimumHeightFor(duration, divisionName);
    final renderedHeight = calculatedHeight < minimumHeight
        ? minimumHeight
        : calculatedHeight;
    final renderedMinutes = (renderedHeight / _pixelsPerMinute).ceil();
    return renderedMinutes > duration ? renderedMinutes : duration;
  }

  /// Thân/header/footer trung tính, không mã hoá trạng thái bằng màu.
  /// Chỉ viền chọn là phản hồi tương tác; LIVE được biểu thị bằng badge.
  _CardStyle _cardStyle(MatchModel match, AppColorsExtension colors) {
    final selected = match.id == widget.selectedMatchId;
    return (
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? colors.warning : colors.border,
          width: selected ? 2.0 : 1.0,
        ),
      ),
      headerBg: colors.bgSurface,
      winnerBg: colors.bgSurface,
      accent: Colors.transparent,
      fg: colors.textPrimary,
    );
  }

  /// Thẻ một dòng (dưới _compactBelowMinutes phút); giờ đã có ở cột giờ.
  Widget _compactContent(MatchModel match, _CardStyle style) {
    return Row(
      children: [
        _teamName(match, match.team1Id, _shortName(match, 0), style),
        _compactCenter(match, style),
        _teamName(match, match.team2Id, _shortName(match, 1), style),
      ],
    );
  }

  Widget _compactCenter(MatchModel match, _CardStyle style) {
    if (match.isLive) return _liveBadge();
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
        _fullHeader(
          match,
          start,
          style,
          divisionName,
          _divisionColorFor(match),
        ),
        // Hai đội căn giữa giữa header và footer, như justify-between của web.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _competitorRow(
                match,
                match.team1Id,
                _shortName(match, 0),
                0,
                style,
              ),
              Divider(height: 1, thickness: 1, color: colors.borderLight),
              _competitorRow(
                match,
                match.team2Id,
                _shortName(match, 1),
                1,
                style,
              ),
            ],
          ),
        ),
        _fullFooter(match, style),
      ],
    );
  }

  /// Header thẻ: giờ bên trái, nhãn hạng mục (màu riêng mỗi hạng mục) và LIVE
  /// bên phải; vạch trái cùng màu hạng mục để lướt là phân biệt được.
  Widget _fullHeader(
    MatchModel match,
    DateTime start,
    _CardStyle style,
    String? divisionName,
    Color? divisionColor,
  ) {
    final time =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
      decoration: BoxDecoration(
        color: style.headerBg,
        border: Border(
          left: BorderSide(color: divisionColor ?? style.accent, width: 3),
          bottom: BorderSide(color: context.colors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: style.fg.withValues(alpha: 0.75),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (divisionName != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _divisionChip(divisionName, divisionColor ?? style.fg),
              ),
            ),
          if (match.isLive) _liveBadge(),
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
        ],
      ),
    );
  }

  /// Hàng đội: tên bên trái, một ô điểm cho mỗi set đã có; trận chưa đấu không có ô nào.
  /// Đội thắng được tô nền và accent như `row.won` của web.
  Widget _competitorRow(
    MatchModel match,
    String teamId,
    String name,
    int side,
    _CardStyle style,
  ) {
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
          _teamName(match, teamId, name, style),
          for (var index = 0; index < _scoreColumnsOf(match); index++)
            SizedBox(
              width: 16,
              child: Text(
                _setScoreLabel(match, index, side),
                textAlign: TextAlign.center,
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
  Widget _teamName(
    MatchModel match,
    String teamId,
    String name,
    _CardStyle style,
  ) {
    final isWinner = _isWinner(match, teamId);
    return Flexible(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
          color: style.fg,
        ),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        gradient: context.liveGradient,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
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
