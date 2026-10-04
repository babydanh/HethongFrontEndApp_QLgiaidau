import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

typedef _ScheduledMatchLane = ({MatchModel match, int lane});

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
  final int startHour;
  final int endHour;
  final String? selectedMatchId;
  final ValueChanged<String> onTapMatch;

  const ScheduleGrid({
    super.key,
    required this.courts,
    required this.matches,
    required this.startHour,
    required this.endHour,
    this.selectedMatchId,
    required this.onTapMatch,
  });

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  /// Chiều cao ô 30 phút — gọn để điện thoại thấy được nhiều giờ.
  static const double _slotHeight = 44;
  static const double _timeColumnWidth = 56;
  static const double _courtLaneWidth = 168;
  static const double _minimumCardHeight = 56;
  static const int _minimumCardDurationMinutes = 40;

  // Header và thân dùng hai controller riêng: một ScrollController chỉ gắn
  // được một ScrollPosition, dùng chung sẽ assert ngay lần swipe ngang đầu.
  // Chỉ thân nhận cử chỉ cuộn, header nghe thân rồi jumpTo theo — một chiều nên
  // không có vòng lặp phản hồi, và header bị chặn cuộn để không tranh gesture.
  final ScrollController _bodyCtrl = ScrollController();
  final ScrollController _headerCtrl = ScrollController();

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

  /// Số ô 30 phút trong khung giờ vận hành.
  int get _slotCount => (widget.endHour - widget.startHour) * 2;

  double get _pixelsPerMinute => _slotHeight / 30;

  /// Nhãn từng ô 30 phút: 00:00, 00:30, 01:00…
  List<String> get _slotLabels => [
    for (var i = 0; i < _slotCount; i++)
      () {
        final total = widget.startHour * 60 + i * 30;
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
                      for (var index = 0; index < widget.courts.length; index++)
                        SizedBox(
                          width:
                              courtLayouts[index].laneCount * _courtLaneWidth,
                          child: _courtHeader(widget.courts[index], colors),
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
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                                courtLayouts[index].laneCount * _courtLaneWidth,
                            child: _courtColumn(courtLayouts[index], colors),
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
  }

  Widget _courtHeader(String court, AppColorsExtension colors) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(color: colors.border),
          left: BorderSide(color: colors.border),
        ),
      ),
      child: Text(
        court,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
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
              padding: const EdgeInsets.only(right: 6, top: 1),
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
                  fontSize: 10.5,
                  fontWeight: label.endsWith(':00')
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: label.endsWith(':00')
                      ? colors.textPrimary
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
      final matchDuration = match.timeLimitMinutes ?? 45;
      final duration = matchDuration < _minimumCardDurationMinutes
          ? _minimumCardDurationMinutes
          : matchDuration;
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

  Widget _courtColumn(_CourtLayout layout, AppColorsExtension colors) {
    return Container(
      height: _slotHeight * _slotCount,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Stack(
        children: [
          // Lưới nền 30 phút.
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
          for (final placement in layout.placements)
            _matchCard(placement.match, placement.lane, colors),
        ],
      ),
    );
  }

  Widget _matchCard(MatchModel match, int lane, AppColorsExtension colors) {
    final start = match.scheduledTime;
    if (start == null) return const SizedBox.shrink();

    final minutesFromOpen = (start.hour - widget.startHour) * 60 + start.minute;
    final top = (minutesFromOpen * _pixelsPerMinute).clamp(
      0.0,
      double.infinity,
    );
    final duration = match.timeLimitMinutes ?? 45;
    final calculatedHeight = duration * _pixelsPerMinute - 3;
    final height = calculatedHeight < _minimumCardHeight
        ? _minimumCardHeight
        : calculatedHeight;

    // Dùng getter của domain model, không so chuỗi thô: backend gửi 'LIVE' /
    // 'COMPLETED' (hoa), so sánh thẳng sẽ tô sai màu và lệch với chip lọc
    // ngay phía trên — chip dùng match.isLive.
    final live = match.isLive;
    final done = match.isCompleted;
    final selected = match.id == widget.selectedMatchId;

    final (Color bg, Color border, Color fg) = selected
        ? (
            AppTheme.primary.withValues(alpha: 0.16),
            AppTheme.primary,
            AppTheme.primary,
          )
        : live
        ? (
            const Color(0xFFDCFCE7),
            const Color(0xFF4ADE80),
            const Color(0xFF166534),
          )
        : done
        ? (colors.bgCard, colors.border, colors.textMuted)
        : (
            AppTheme.primary.withValues(alpha: 0.07),
            AppTheme.primary.withValues(alpha: 0.35),
            colors.textPrimary,
          );

    return Positioned(
      key: ValueKey('schedule-match-${match.id}'),
      top: top + 1.5,
      left: lane * _courtLaneWidth + 3,
      width: _courtLaneWidth - 6,
      height: height,
      child: GestureDetector(
        onTap: () => widget.onTapMatch(match.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${start.hour.toString().padLeft(2, '0')}:'
                '${start.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: fg.withValues(alpha: 0.75),
                ),
              ),
              Flexible(
                child: Text(
                  match.team1Name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  match.team2Name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (done)
                Text(
                  '${match.score1} - ${match.score2}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
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
