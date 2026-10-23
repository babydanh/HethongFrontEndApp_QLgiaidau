import 'dart:async';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gắn sơ đồ sân vào màn ghi điểm. Tự đồng bộ lượt giao và mốc đổi sân sau
/// mỗi điểm; chỉ ghi server khi cài đặt sân thực sự đổi.
class PickleballCourtPanel extends ConsumerStatefulWidget {
  const PickleballCourtPanel({
    super.key,
    required this.params,
    required this.canScore,
  });

  final MatchControlParams params;

  /// Quyền ghi điểm: chỉ người có quyền mới chấm điểm và kéo thả trên sân.
  final bool canScore;

  @override
  ConsumerState<PickleballCourtPanel> createState() =>
      _PickleballCourtPanelState();
}

class _PickleballCourtPanelState extends ConsumerState<PickleballCourtPanel> {
  static const _log = AppLogger('PickleballCourtPanel');

  /// Every court write (user action or automatic sync) runs through this one
  /// chain, so two writes are never in flight together and always reach the
  /// server in the order they were made.
  Future<void> _chain = Future<void>.value();

  /// User actions queued or running. While > 0 an automatic sync is skipped
  /// and, if one was asked for, run once the last action is done.
  int _pendingApplies = 0;
  bool _syncSkipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_sync());
    });
  }

  Future<void> _enqueue(Future<void> Function() job) {
    final run = _chain.then((_) => job());
    // A failed job must not break the chain for the writes behind it, but it
    // is logged: it is a bug, not a normal save error.
    _chain = run.catchError((Object error, StackTrace stack) {
      _log.error('Court write step failed', error, stack);
    });
    return run;
  }

  /// A finished or cancelled match: nothing is edited or written any more.
  static bool _isOver(MatchModel? match) =>
      (match?.isCompleted ?? false) || match?.normalizedStatus == 'CANCELLED';

  /// Automatic sync after a score change.
  Future<void> _sync() {
    if (_pendingApplies > 0) {
      _syncSkipped = true;
      return Future<void>.value();
    }
    return _enqueue(_runSync);
  }

  Future<void> _runSync() async {
    // Only a user who can score writes the court; a viewer or a finished match
    // that merely receives a score change over the socket must not.
    final match = ref.read(singleMatchProvider(widget.params)).value;
    if (!mounted || !widget.canScore || _isOver(match)) return;
    final notifier = ref.read(
      pickleballCourtNotifierProvider(widget.params).notifier,
    );
    await _reportError(notifier, await notifier.syncAutomatic(), dedupe: true);
  }

  /// Chạy một hành động cài đặt sân qua notifier (ghi server, hoàn tác được).
  Future<void> _apply(
    CourtState Function(CourtState state, CourtContext context) action,
  ) {
    _pendingApplies++;
    return _enqueue(() async {
      try {
        if (!mounted) return;
        final notifier = ref.read(
          pickleballCourtNotifierProvider(widget.params).notifier,
        );
        await _reportError(notifier, await notifier.apply(action));
      } finally {
        _pendingApplies--;
        if (_pendingApplies == 0 && _syncSkipped && mounted) {
          _syncSkipped = false;
          unawaited(_sync());
        }
      }
    });
  }

  /// [dedupe]: the automatic sync repeats on every point, so the same error is
  /// shown once. A user action always explains why it was not saved.
  Future<void> _reportError(
    PickleballCourtNotifier notifier,
    Object? error, {
    bool dedupe = false,
  }) async {
    if (error == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = ErrorParser.parse(
      error,
      l10n.pickleballCourtSaveError,
      l10n,
    );
    if (dedupe && !notifier.claimErrorReport(message)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  void _changeScore(int team, bool increment, {required bool isSideOut}) {
    final score = ref.read(scorePanelNotifierProvider(widget.params).notifier);
    final isTeam1 = team == 1;
    if (!increment) {
      score.rallyRemovePoint(isTeam1);
    } else if (isSideOut) {
      score.pickleballAwardPoint(isTeam1);
    } else {
      score.rallyAddPoint(isTeam1);
    }
  }

  /// Đổi đội giao (side-out) bằng logic điểm có sẵn; người giao do [_applyDrop]
  /// đặt ngay sau đó.
  void _setServingTeam(int team, CourtContext court) {
    if (court.servingTeam == team) return;
    ref
        .read(scorePanelNotifierProvider(widget.params).notifier)
        .pickleballSideOut();
  }

  void _applyDrop(CourtDropAction action) {
    switch (action) {
      case SwapPlaces(:final team):
        unawaited(
          _apply(
            (state, context) => setStartingRight(
              state,
              context,
              team,
              1 - state.startingRightOf(team),
            ),
          ),
        );
      case SwitchEnds():
        unawaited(_apply(swapEndsNow));
      case SetServer(:final team, :final playerIndex):
        unawaited(
          _apply(
            (state, context) =>
                setServerOverride(state, context, team, playerIndex),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pickleballCourtContextProvider(widget.params), (previous, next) {
      if (next != null) unawaited(_sync());
    });

    final courtContext = ref.watch(
      pickleballCourtContextProvider(widget.params),
    );
    if (courtContext == null) return const SizedBox.shrink();
    final score = ref.watch(scorePanelNotifierProvider(widget.params));
    final court = ref.watch(pickleballCourtNotifierProvider(widget.params));
    final match = ref.watch(singleMatchProvider(widget.params)).value;

    final isSideOut =
        score.config.scoringModel == SportScoringModel.pickleballSideOut;

    // A cancelled match is over: the repository maps it to 'cancelled', which
    // is neither isCompleted nor isScheduled.
    final canEdit = widget.canScore && !_isOver(match);
    final canChangeScore = canEdit && !(match?.isScheduled ?? false);

    return PickleballCourtView(
      layout: resolveCourtLayout(court, courtContext),
      team1Players: match?.team1Members ?? const <String>[],
      team2Players: match?.team2Members ?? const <String>[],
      team1Score: courtContext.score1,
      team2Score: courtContext.score2,
      isSideOut: isSideOut,
      isDoubles: courtContext.isDoubles,
      receiverCanScore: score.isOpenScoring,
      autoSwitchEnds: court.autoSwitchEnds,
      onScoreChange: canChangeScore
          ? (team, increment) =>
                _changeScore(team, increment, isSideOut: isSideOut)
          : null,
      onSetServingTeam: canEdit && isSideOut
          ? (team) => _setServingTeam(team, courtContext)
          : null,
      onDrop: canEdit ? _applyDrop : null,
      onUndo: canEdit && court.history.isNotEmpty
          ? () => unawaited(_apply((state, _) => undoCourtChange(state)))
          : null,
      onRestoreAutomatic: canEdit
          ? () => unawaited(_apply(restoreAutomaticCourt))
          : null,
      onToggleAutoSwitch: canEdit
          ? () => unawaited(
              _apply(
                (state, ctx) =>
                    setAutoSwitchEnds(state, ctx, !state.autoSwitchEnds),
              ),
            )
          : null,
    );
  }
}
