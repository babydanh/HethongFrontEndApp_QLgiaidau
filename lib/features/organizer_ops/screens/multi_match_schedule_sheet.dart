import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/court_schedule_cascade.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sheet xếp NHIỀU trận nối tiếp từ một ô lưới (OpenSpec
/// `quan-ly-giai-web-parity` task 4.1, đối chiếu popup "Chọn nhiều trận đấu tự
/// động sắp nối tiếp nhau" của Web `CourtScheduleBoard`): tích chọn nhiều trận
/// chờ, từng trận có ô thời lượng (15–240 phút, bộ 5, validate tại chỗ), lọc
/// theo vòng, tìm theo tên; nút "Xếp N trận" xếp nối tiếp bắt đầu từ ô được
/// chọn — mỗi trận bắt đầu sau khi trận trước kết thúc — bằng cách gọi
/// [MultiMatchScheduleSheet.onWrite] tuần tự từng trận; lỗi giữa chừng dừng và
/// báo "đã xếp i/N".
///
/// Bố cục lưới sân giữ nguyên dạng dọc sẵn có; sheet này chỉ thay phần chọn
/// trận khi bấm vào ô trống.
class MultiMatchScheduleSheet extends StatefulWidget {
  const MultiMatchScheduleSheet({
    super.key,
    required this.courtName,
    required this.at,
    required this.waiting,
    required this.minutesPerSet,
    required this.onWrite,
  });

  /// Tên sân của ô được chọn (hiện tiêu đề).
  final String courtName;

  /// Giờ của ô được chọn: trận đầu tiên bắt đầu tại đây.
  final DateTime at;

  /// Trận chờ đủ điều kiện xếp (chưa có lịch, chưa đấu).
  final List<MatchModel> waiting;

  /// phút/set trong cài đặt lịch, dùng làm thời lượng mặc định khi trận chưa
  /// khai thời lượng.
  final int minutesPerSet;

  /// Ghi lịch một trận vào ô kế tiếp; trả về false khi ghi lỗi — dây chuyền
  /// dừng lại và báo "đã xếp i/N".
  final Future<bool> Function(
    MatchModel match,
    DateTime scheduledAt,
    int durationMinutes,
  )
  onWrite;

  static Future<void> show(
    BuildContext context, {
    required String courtName,
    required DateTime at,
    required List<MatchModel> waiting,
    required int minutesPerSet,
    required Future<bool> Function(
      MatchModel match,
      DateTime scheduledAt,
      int durationMinutes,
    )
    onWrite,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Busy có thể bật giữa chừng; drag-dismiss bypass PopScope nên tắt hẳn
    // như các sheet quản lý khác.
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => MultiMatchScheduleSheet(
      courtName: courtName,
      at: at,
      waiting: waiting,
      minutesPerSet: minutesPerSet,
      onWrite: onWrite,
    ),
  );

  @override
  State<MultiMatchScheduleSheet> createState() =>
      _MultiMatchScheduleSheetState();
}

class _MultiMatchScheduleSheetState extends State<MultiMatchScheduleSheet> {
  static const _maxDurationMinutes = 240;

  /// Tìm kiếm không dấu như Web (`pairing_sheet`): bỏ dấu tiếng Việt, đ→d.
  static final Map<String, String> _foldMap = _buildFoldMap();

  static Map<String, String> _buildFoldMap() {
    const baseLetters = {
      'a': 'àáảãạăằắẳẵặâầấẩẫậäå',
      'e': 'èéẻẽẹêềếểễệë',
      'i': 'ìíỉĩịîï',
      'o': 'òóỏõọôồốổỗộơờớởỡợöø',
      'u': 'ùúủũụưừứửữựûü',
      'y': 'ỳýỷỹỵÿ',
      'd': 'đ',
    };
    return {
      for (final entry in baseLetters.entries)
        for (final rune in entry.value.runes)
          String.fromCharCode(rune): entry.key,
    };
  }

  static String _normalizeSearch(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      final char = String.fromCharCode(rune);
      buffer.write(_foldMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Thời lượng người dùng gõ cho từng trận, còn thiếu lấy mặc định.
  final Map<String, TextEditingController> _durationControllers = {};
  final _searchController = TextEditingController();

  /// Lựa chọn theo thứ tự bấm — quyết định thứ tự xếp.
  final List<String> _selectedIds = [];
  String _query = '';

  /// Nhãn vòng đang lọc; 'all' là không lọc.
  String _roundFilter = 'all';
  bool _busy = false;

  /// Tiến độ ghi tuần tự đang chạy (done = số trận đã ghi xong).
  ({int done, int total})? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final match in widget.waiting) {
      _durationControllers[match.id] = TextEditingController(
        text: '${_defaultDuration(match)}',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _durationControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  int _defaultDuration(MatchModel match) => serverEffectiveDurationMinutes(
    scheduledDurationMinutes(match, minutesPerSet: widget.minutesPerSet),
  );

  int _durationOf(MatchModel match) {
    final controller = _durationControllers[match.id];
    final parsed = int.tryParse(controller?.text ?? '');
    return serverEffectiveDurationMinutes(parsed ?? _defaultDuration(match));
  }

  /// Ô thời lượng sai quy tắc 15–240 bộ 5: báo ngay tại dòng đó và chặn xác
  /// nhận (Web `durationInvalid`).
  bool _isInvalidDraft(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) return true;
    return value < serverMinDurationMinutes ||
        value > _maxDurationMinutes ||
        value % 5 != 0;
  }

  bool get _hasInvalidSelectedDraft => _selectedIds.any((id) {
    final controller = _durationControllers[id];
    return controller != null && _isInvalidDraft(controller.text);
  });

  bool get _canSubmit =>
      !_busy && _selectedIds.isNotEmpty && !_hasInvalidSelectedDraft;

  MatchModel? _matchById(String id) {
    for (final match in widget.waiting) {
      if (match.id == id) return match;
    }
    return null;
  }

  String _pairLabel(MatchModel match) {
    final first = _sideText(match, 1).trim();
    final second = _sideText(match, 2).trim();
    if (first.isEmpty && second.isEmpty) return match.id;
    return '${first.isEmpty ? '?' : first} – ${second.isEmpty ? '?' : second}';
  }

  String _sideText(MatchModel match, int side) => participantLabel(
    teamName: matchSideTeamName(match, side),
    players: matchSidePlayers(match, side),
    teamOnly: isFootballMatch(match),
  );

  /// Nhãn vòng để nhóm lọc; không truyền allMatches để tránh suy ra tên vòng
  /// loại trực tiếp từ số trận đang chờ. Không kèm mã trận vì mã riêng từng
  /// trận sẽ tách mỗi trận thành một nhóm vòng.
  String _roundLabel(MatchModel match, AppLocalizations l10n) =>
      MatchRoundLabel.formatRound(
        match: match,
        l10n: l10n,
        includeMatchCode: false,
      );

  /// ({nhãn vòng, số trận}) theo thứ tự xuất hiện trong danh sách chờ.
  List<(String, int)> get _rounds {
    final l10n = AppLocalizations.of(context)!;
    final counts = <String, int>{};
    for (final match in widget.waiting) {
      final label = _roundLabel(match, l10n);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return [for (final entry in counts.entries) (entry.key, entry.value)];
  }

  List<MatchModel> get _shown {
    final l10n = AppLocalizations.of(context)!;
    final needle = _normalizeSearch(_query);
    return [
      for (final match in widget.waiting)
        if (_roundFilter == 'all' || _roundLabel(match, l10n) == _roundFilter)
          if (needle.isEmpty ||
              _normalizeSearch(_pairLabel(match)).contains(needle) ||
              _normalizeSearch(_roundLabel(match, l10n)).contains(needle) ||
              _normalizeSearch(
                formatMatchCode(match, l10n: l10n),
              ).contains(needle) ||
              '#${match.matchNumber}'.contains(needle))
            match,
    ];
  }

  /// Giờ bắt đầu dự kiến của từng trận đang chọn, hoặc null khi có ô thời
  /// lượng sai (chưa đủ điều kiện xếp nên không hứa giờ).
  Map<String, DateTime>? get _plannedStarts {
    if (_hasInvalidSelectedDraft) return null;
    final selected = [for (final id in _selectedIds) ?_matchById(id)];
    if (selected.length != _selectedIds.length) return null;
    final starts = cascadeStartTimes(widget.at, [
      for (final match in selected) _durationOf(match),
    ]);
    return {
      for (var i = 0; i < selected.length; i++) selected[i].id: starts[i],
    };
  }

  void _toggle(MatchModel match) {
    if (_busy) return;
    setState(() {
      if (!_selectedIds.remove(match.id)) {
        _selectedIds.add(match.id);
      }
    });
  }

  /// Chọn/bỏ chọn toàn bộ các dòng đang thấy (giữ lựa chọn ngoài khung nhìn,
  /// như Web `selectVisible`/`deselectVisible`).
  void _toggleVisible() {
    if (_busy) return;
    final visibleIds = [for (final match in _shown) match.id];
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedIds.contains);
    setState(() {
      if (allSelected) {
        _selectedIds.removeWhere(visibleIds.contains);
      } else {
        for (final id in visibleIds) {
          if (!_selectedIds.contains(id)) _selectedIds.add(id);
        }
      }
    });
  }

  /// Ghi tuần tự theo dây chuyền giờ từ `cascadeStartTimes`; lỗi giữa chừng
  /// dừng và báo "đã xếp i/N" (spec `Xếp nhiều trận nối tiếp từ một ô`).
  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    final selected = [for (final id in _selectedIds) ?_matchById(id)];
    if (selected.isEmpty) return;
    final durations = [for (final match in selected) _durationOf(match)];
    final starts = cascadeStartTimes(widget.at, durations);

    setState(() {
      _busy = true;
      _error = null;
      _progress = (done: 0, total: selected.length);
    });

    var done = 0;
    for (var i = 0; i < selected.length; i++) {
      if (!mounted) return;
      setState(() => _progress = (done: done, total: selected.length));
      final ok = await widget.onWrite(selected[i], starts[i], durations[i]);
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _progress = null;
          _error = l10n.scheduleMultiPartial(done, selected.length);
        });
        return;
      }
      done++;
    }

    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.scheduleMultiDone(done, selected.length))),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final lavish = LavishColors.of(context);
    final rounds = _rounds;
    final shown = _shown;
    final planned = _plannedStarts;
    final allVisibleSelected =
        shown.isNotEmpty &&
        shown.every((match) => _selectedIds.contains(match.id));

    return TournamentManageSheet(
      title: l10n.scheduleQuickPickerTitle(
        widget.courtName,
        _hhmm(widget.at.hour * 60 + widget.at.minute),
      ),
      busy: _busy,
      actions: [
        LavishButton(
          buttonKey: const ValueKey('schedule-multi-submit'),
          label: l10n.scheduleMultiSubmit(_selectedIds.length),
          onPressed: _canSubmit ? _submit : null,
        ),
        LavishButton(
          kind: LavishButtonKind.outline,
          label: l10n.tournamentManagementCancel,
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.scheduleMultiSheetDescription,
            style: TextStyle(
              color: lavish.muted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_busy && _progress != null) ...[
            const SizedBox(height: 8),
            Text(
              key: const ValueKey('schedule-multi-progress'),
              l10n.scheduleQuickDraftProgress(
                _progress!.done,
                _progress!.total,
              ),
              style: TextStyle(
                color: colors.info,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              key: const ValueKey('schedule-multi-error'),
              _error!,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (widget.waiting.isEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.scheduleQuickPickerEmpty),
          ] else ...[
            const SizedBox(height: 12),
            if (rounds.length > 1) ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('schedule-multi-round-filter'),
                initialValue: _roundFilter,
                isExpanded: true,
                decoration: _lavishField(
                  lavish,
                  labelText: l10n.scheduleMultiRoundLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(
                      l10n.scheduleMultiAllRounds(widget.waiting.length),
                    ),
                  ),
                  for (final (label, count) in rounds)
                    DropdownMenuItem(
                      value: label,
                      child: Text('$label ($count)'),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _roundFilter = value ?? 'all'),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('schedule-multi-search'),
                    controller: _searchController,
                    enabled: !_busy,
                    onChanged: (value) => setState(() => _query = value),
                    style: TextStyle(fontSize: 13, color: lavish.text),
                    decoration:
                        _lavishField(
                          lavish,
                          hintText: l10n.scheduleMultiSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                        ).copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                LavishChipButton(
                  key: const ValueKey('schedule-multi-toggle-visible'),
                  selected: allVisibleSelected,
                  onPressed: shown.isEmpty ? null : _toggleVisible,
                  label: allVisibleSelected
                      ? l10n.scheduleMultiDeselectVisible
                      : l10n.scheduleMultiSelectVisible,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.scheduleQuickPickerEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shown.length,
                itemBuilder: (context, index) =>
                    _matchRow(shown[index], planned: planned),
              ),
          ],
        ],
      ),
    );
  }

  /// Web-style waiting card: tick + round on top, the two sides with avatars,
  /// then the duration field and planned start. The card toggles the match.
  Widget _matchRow(
    MatchModel match, {
    required Map<String, DateTime>? planned,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final lavish = LavishColors.of(context);
    final selected = _selectedIds.contains(match.id);
    final controller = _durationControllers[match.id]!;
    final invalidDraft = _isInvalidDraft(controller.text);
    final startAt = planned?[match.id];
    final border = selected ? LavishColors.accent : lavish.chipLine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? lavish.soft(LavishTone.accent) : lavish.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: selected ? 1.4 : 1),
        ),
        child: InkWell(
          key: ValueKey('schedule-picker-${match.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: _busy ? null : () => _toggle(match),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: selected ? LavishColors.accent : lavish.faint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        MatchRoundLabel.formatRound(match: match, l10n: l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lavish.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _sideRow(match, 1, lavish),
                const SizedBox(height: 4),
                _sideRow(match, 2, lavish),
                const SizedBox(height: 10),
                Container(height: 1, color: lavish.rowLine),
                const SizedBox(height: 8),
                _footer(match, controller, startAt, lavish, l10n),
                if (invalidDraft)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      key: ValueKey(
                        'schedule-multi-duration-error-${match.id}',
                      ),
                      l10n.scheduleMultiDurationInvalid,
                      style: const TextStyle(
                        color: LavishColors.bad,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One competitor line: stacked avatars + names (team name for team sides).
  Widget _sideRow(MatchModel match, int side, LavishColors lavish) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: ParticipantLabel(
        teamName: matchSideTeamName(match, side),
        players: matchSidePlayers(match, side),
        teamOnly: isFootballMatch(match),
        style: TextStyle(
          color: lavish.text,
          fontSize: 13,
          fontWeight: side == 1 ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  /// Card footer: duration field + "phút" on the left, planned start on the right.
  Widget _footer(
    MatchModel match,
    TextEditingController controller,
    DateTime? startAt,
    LavishColors lavish,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: TextField(
            key: ValueKey('schedule-multi-duration-${match.id}'),
            controller: controller,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: lavish.text,
            ),
            decoration: _lavishField(lavish, radius: 10).copyWith(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 8,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.scheduleMultiMinutesSuffix,
          style: TextStyle(
            color: lavish.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (startAt != null)
          LavishPill(
            key: ValueKey('schedule-multi-start-${match.id}'),
            '→ ${_hhmm(startAt.hour * 60 + startAt.minute)}',
          ),
      ],
    );
  }

  /// Lavish input: soft grey fill, no outline, accent ring on focus.
  InputDecoration _lavishField(
    LavishColors lavish, {
    double radius = 12,
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: lavish.dark ? lavish.rowLine : const Color(0xFFF2F4F7),
      hintText: hintText,
      hintStyle: TextStyle(color: lavish.faint, fontSize: 13),
      labelText: labelText,
      prefixIcon: prefixIcon,
      prefixIconColor: lavish.muted,
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(LavishColors.accent, 1.5),
      disabledBorder: border(Colors.transparent, 0),
    );
  }

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';
}
