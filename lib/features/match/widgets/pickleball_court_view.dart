import 'dart:math' as math;

import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_scoreboard.dart';
import 'package:flutter/material.dart';

export 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_drag_widgets.dart'
    show courtPlayerDisplayName, courtSurfaceKey;

/// Sơ đồ sân pickleball: dọc (hai đội trên/dưới) khi [axis] là dọc, ngang 2:1
/// khi [axis] là ngang. Điểm nằm trong dải bếp của mỗi nửa; lưới giữ lời hô và
/// các icon (⋯, chốt set, cúp, mất giao). Kéo thả người và trái bóng bằng nhấn
/// giữ.
///
/// Chỉ vẽ từ [CourtLayout]; luật cú thả nằm ở [resolveCourtDrop], việc áp dụng
/// nằm ở người gọi qua các callback. Callback null = không có quyền/không áp
/// dụng: ẩn nút tương ứng và tắt kéo thả.
class PickleballCourtView extends StatelessWidget {
  const PickleballCourtView({
    super.key,
    required this.layout,
    required this.team1Players,
    required this.team2Players,
    required this.team1Score,
    required this.team2Score,
    this.axis = Axis.horizontal,
    this.isSideOut = false,
    this.isDoubles = true,
    this.receiverCanScore = false,
    this.autoSwitchEnds = true,
    this.overrideEnabled = false,
    this.startedAt,
    this.setNumber,
    this.finishSetEnabled = true,
    this.pickWinnerEnabled = true,
    this.onScoreChange,
    this.onDrop,
    this.onSwitchEnds,
    this.onUndo,
    this.onRestoreAutomatic,
    this.onToggleAutoSwitch,
    this.onFinishSet,
    this.onPickWinner,
    this.onLoseServe,
    this.onToggleOverride,
    this.onForceWin,
  });

  static const _motion = Duration(milliseconds: 240);

  /// A horizontal scoreboard is never shorter than this; a shorter slot
  /// scrolls.
  static const _minHorizontalHeight = 260.0;

  /// A vertical court is never shorter than this; a shorter slot scrolls.
  static const _minVerticalHeight = 360.0;

  /// Hướng xếp hai nửa sân: dọc khi cầm dọc, ngang khi cầm ngang.
  final Axis axis;
  final CourtLayout layout;
  final List<String> team1Players;
  final List<String> team2Players;
  final int team1Score;
  final int team2Score;

  /// Side-out: chỉ đội đang giao được cộng điểm và được đổi đội giao.
  final bool isSideOut;

  /// Singles have no left/right swap: those drops do nothing.
  final bool isDoubles;

  /// Side-out but open scoring: the receiving team may score as well.
  final bool receiverCanScore;
  final bool autoSwitchEnds;
  final bool overrideEnabled;

  /// When the match started; drives the clock of the horizontal scoreboard.
  /// Null hides the clock.
  final DateTime? startedAt;

  /// Number of the set being played, shown on the horizontal scoreboard.
  final int? setNumber;

  /// Chốt set bị khoá khi set chưa kết thúc được (vd. 0-0).
  final bool finishSetEnabled;

  /// Cúp bị khoá khi đang lưu kết quả.
  final bool pickWinnerEnabled;

  /// Null thì ẩn nút − và +.
  final void Function(int team, bool increment)? onScoreChange;

  /// Gọi trước [onDrop] khi trái bóng được thả sang đội kia (đổi đội giao).
  /// Null thì không cho thả trái bóng sang đội kia.

  /// Null thì tắt kéo thả.
  final void Function(CourtDropAction action)? onDrop;
  final VoidCallback? onSwitchEnds;
  final VoidCallback? onUndo;
  final VoidCallback? onRestoreAutomatic;
  final VoidCallback? onToggleAutoSwitch;
  final VoidCallback? onFinishSet;
  final VoidCallback? onPickWinner;

  /// Null ở rally và Lite: không có lượt giao để mất.
  final VoidCallback? onLoseServe;

  /// Null ở Lite: không có ngoại lệ.
  final VoidCallback? onToggleOverride;
  final VoidCallback? onForceWin;

  int _scoreOf(int team) => team == 1 ? team1Score : team2Score;

  CourtDropAction? _resolve(CourtDragSource source, CourtDropTarget target) {
    final action = resolveCourtDrop(source, target);
    if (action is SwapPlaces && !isDoubles) return null;
    return action;
  }

  /// The court fills its slot: halves, cells and the net band are all flexible,
  /// so any aspect ratio works and no blank margin is left around it. Only an
  /// unbounded height falls back to a default shape, and a slot below the
  /// minimum height scrolls.
  Size _courtSize(BoxConstraints constraints) {
    final vertical = axis == Axis.vertical;
    final minHeight = vertical ? _minVerticalHeight : _minHorizontalHeight;
    final height = constraints.hasBoundedHeight
        ? math.max(constraints.maxHeight, minHeight)
        : constraints.maxWidth * (vertical ? 1.5 : 0.5);
    return Size(constraints.maxWidth, height);
  }

  String? get _callText {
    final serving = layout.servingScore;
    final receiving = layout.receivingScore;
    if (serving == null || receiving == null) return null;
    final server = layout.callServerNumber;
    return server == null
        ? '$serving-$receiving'
        : '$serving-$receiving-$server';
  }

  CourtNetActions get _net => CourtNetActions(
    menu: CourtMenuActions(
      onSwitchEnds: onSwitchEnds,
      onUndo: onUndo,
      onRestoreAutomatic: onRestoreAutomatic,
      onToggleAutoSwitch: onToggleAutoSwitch,
      autoSwitchEnds: autoSwitchEnds,
      onToggleOverride: onToggleOverride,
      overrideEnabled: overrideEnabled,
      onForceWin: onForceWin,
    ),
    onFinishSet: onFinishSet,
    finishSetEnabled: finishSetEnabled,
    onPickWinner: onPickWinner,
    pickWinnerEnabled: pickWinnerEnabled,
    onLoseServe: onLoseServe,
  );

  /// The same scoreboard on both axes: sideways halves, or stacked when upright.
  Widget _surface(Duration motion) {
    return CourtScoreboard(
      axis: axis,
      layout: layout,
      team1Players: team1Players,
      team2Players: team2Players,
      scoreOf: _scoreOf,
      lockReceiverPlus: isSideOut && !receiverCanScore,
      onScoreChange: onScoreChange,
      callText: _callText,
      net: _net,
      onSwitchEnds: onSwitchEnds,
      overrideEnabled: overrideEnabled,
      startedAt: startedAt,
      setNumber: setNumber,
      motion: motion,
      dragEnabled: onDrop != null,
      resolve: _resolve,
      onDrop: (action) => onDrop?.call(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _motion;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _courtSize(constraints);
        final court = SizedBox(
          width: size.width,
          height: size.height,
          child: _surface(motion),
        );
        final scrolls =
            constraints.hasBoundedHeight &&
            size.height > constraints.maxHeight + 0.5;
        return Align(
          alignment: Alignment.center,
          child: scrolls ? SingleChildScrollView(child: court) : court,
        );
      },
    );
  }
}
