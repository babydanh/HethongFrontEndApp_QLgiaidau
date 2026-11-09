import 'dart:async';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_undo.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_dialogs.dart';
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
    this.onForceWin,
    this.axis,
  });

  final MatchControlParams params;

  /// Xử thắng nhanh của màn gọi (null thì không có mục này trong menu).
  final VoidCallback? onForceWin;

  /// Hướng sân; null thì theo hướng màn hình (dọc khi cầm dọc).
  final Axis? axis;

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

  /// Scoring steps the referee can take back, oldest first (session only).
  List<ScoreUndoStep> _undoSteps = const [];

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

  /// Runs one scoring action and remembers how things were before it, so undo
  /// can take it back. Nothing is remembered when the action changed nothing
  /// (a rejected point) or closed a game (older steps no longer apply).
  void _runScoringStep(void Function() action) {
    final before = ref.read(scorePanelNotifierProvider(widget.params));
    final court = ref.read(pickleballCourtNotifierProvider(widget.params));
    action();
    final after = ref.read(scorePanelNotifierProvider(widget.params));
    if (after.finishedSets.length != before.finishedSets.length) return;
    final rally = before.rally ?? const RallySetState();
    final serve = before.pickleball ?? const PickleballServeState();
    final unchanged =
        after.rally?.currentP1 == rally.currentP1 &&
        after.rally?.currentP2 == rally.currentP2 &&
        after.pickleball?.isTeam1Serving == serve.isTeam1Serving &&
        after.pickleball?.serverNumber == serve.serverNumber &&
        after.pickleball?.openingDone == serve.openingDone;
    if (unchanged) return;
    setState(() {
      _undoSteps = pushUndoStep(
        _undoSteps,
        ScoreUndoStep(
          rally: rally,
          serve: serve,
          court: court,
          finishedSetCount: before.finishedSets.length,
        ),
      );
    });
  }

  /// Takes back the newest thing the referee did: a court edit made after the
  /// last scoring step first, then scoring steps one by one.
  void _undo() {
    final score = ref.read(scorePanelNotifierProvider(widget.params));
    final court = ref.read(pickleballCourtNotifierProvider(widget.params));
    final action = resolveUndoAction(
      _undoSteps,
      courtDepth: court.history.length,
      finishedSetCount: score.finishedSets.length,
    );
    if (action == UndoAction.court) {
      unawaited(_apply((state, _) => undoCourtChange(state)));
      return;
    }
    if (action != UndoAction.score) return;
    final step = _undoSteps.last;
    setState(() => _undoSteps = _undoSteps.sublist(0, _undoSteps.length - 1));
    ref
        .read(scorePanelNotifierProvider(widget.params).notifier)
        .pickleballRestoreStep(rally: step.rally, serve: step.serve);
    unawaited(_apply((_, _) => step.court));
  }

  void _changeScore(
    int team,
    bool increment, {
    required bool isSideOut,
    required CourtContext court,
  }) {
    _runScoringStep(
      () => _applyScoreChange(
        team,
        increment,
        isSideOut: isSideOut,
        court: court,
      ),
    );
  }

  void _applyScoreChange(
    int team,
    bool increment, {
    required bool isSideOut,
    required CourtContext court,
  }) {
    final score = ref.read(scorePanelNotifierProvider(widget.params).notifier);
    final isTeam1 = team == 1;
    if (!increment) {
      score.rallyRemovePoint(isTeam1);
    } else if (isSideOut && _receiverWonStrictRally(isTeam1)) {
      // Strict side-out: only the serving team scores. The receiver winning
      // the rally just takes the serve step, the score stays. No toast: it
      // floated over the lower "+" button; the serve badge already shows it.
      _loseServe(court);
    } else if (isSideOut) {
      score.pickleballAwardPoint(isTeam1);
    } else {
      score.rallyAddPoint(isTeam1);
    }
  }

  bool _receiverWonStrictRally(bool isTeam1) {
    final panel = ref.read(scorePanelNotifierProvider(widget.params));
    if (!panel.isPickleballSideOut) return false;
    final serve = panel.pickleball ?? const PickleballServeState();
    return serve.isTeam1Serving != isTeam1;
  }

  /// Chọn đội giao đầu ván (0-0: chỉ một lượt lỗi); người giao do [_applyDrop]
  /// đặt ngay sau đó.
  void _setServingTeam(int team, CourtContext court) {
    if (court.servingTeam == team) return;
    _runScoringStep(
      () => ref
          .read(scorePanelNotifierProvider(widget.params).notifier)
          .pickleballSetServingTeam(team == 1),
    );
  }

  /// Bên nhận thắng pha bóng: đôi đi từng bước (người giao 1 → 2 → đội kia) qua
  /// `pickleballSwitchServer`; đánh đơn chuyển thẳng sang đội kia.
  void _loseServe(CourtContext court) {
    final score = ref.read(scorePanelNotifierProvider(widget.params).notifier);
    if (court.isDoubles) {
      score.pickleballSwitchServer();
    } else {
      score.pickleballSideOut();
    }
  }

  /// Turning override on asks for the reason at once; cancelling puts the
  /// switch back off. Turning it off needs nothing.
  Future<void> _toggleOverride() async {
    final score = ref.read(scorePanelNotifierProvider(widget.params));
    final notifier = ref.read(
      scorePanelNotifierProvider(widget.params).notifier,
    );
    if (score.overrideEnabled) {
      notifier.setOverride(false, score.overrideReason);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => OverrideReasonDialog(params: widget.params),
    );
    if (confirmed != true) notifier.setOverride(false, '');
  }

  Future<void> _confirmFinishSet() async {
    if (ref.read(scorePanelNotifierProvider(widget.params)).isSubmitting) {
      return;
    }
    final score = ref.read(scorePanelNotifierProvider(widget.params).notifier);
    if (score.rejectTiedRallySet()) return;
    final message = score.finishSetConfirmMessage();
    if (message == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => FinishSetDialog(params: widget.params, message: message),
    );
    if (confirmed != true || !mounted) return;
    await score.finishSet();
  }

  /// Chọn đội thắng rồi lưu kết quả; lưu xong thì đóng màn chấm điểm, lỗi thì
  /// giữ màn để cảnh báo hiện ở tab.
  Future<void> _pickWinner() async {
    if (ref.read(scorePanelNotifierProvider(widget.params)).isSubmitting) {
      return;
    }
    final winner = await showDialog<int>(
      context: context,
      builder: (_) => PickWinnerDialog(params: widget.params),
    );
    if (winner == null || !mounted) return;
    final score = ref.read(scorePanelNotifierProvider(widget.params).notifier);
    await score.completeMatch(winner);
    if (!mounted) return;
    final latest = ref.read(scorePanelNotifierProvider(widget.params));
    if (!latest.isSubmitting && latest.errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  /// Lite only: asks which rule the match is scored by and saves it. The
  /// notifier refuses a second save while one is in flight; a failure shows
  /// the error and leaves the rule as it was.
  Future<void> _changeScoring() async {
    final current = ref.read(scorePanelNotifierProvider(widget.params)).config;
    final picked = await showDialog<SportScoringModel>(
      context: context,
      builder: (_) => PickleballScoringDialog(current: current.scoringModel),
    );
    if (picked == null || picked == current.scoringModel || !mounted) return;
    final error = await ref
        .read(scorePanelNotifierProvider(widget.params).notifier)
        .setPickleballScoring(picked);
    if (error == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          ErrorParser.parse(error, l10n.pickleballScoringSaveError, l10n),
        ),
      ),
    );
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
      // Handing the serve to the other team is one scoring step (taken just
      // before by onSetServingTeam, court included): the ball move must not
      // add a court undo entry, or undo would need two presses.
      case SetServer(
        :final team,
        :final playerIndex,
        :final changesServingTeam,
      ):
        unawaited(
          _apply(
            (state, context) => changesServingTeam
                ? setServerAfterTeamChange(state, context, team, playerIndex)
                : setServerOverride(state, context, team, playerIndex),
          ),
        );
      case SetServerNumber(:final number):
        _pickServerNumber(number);
    }
  }

  /// Referee picks serve 1 or 2: the number lives in the score panel, the ball
  /// moves to the partner of the player shown now.
  void _pickServerNumber(int number) {
    final context = ref.read(pickleballCourtContextProvider(widget.params));
    final court = ref.read(pickleballCourtNotifierProvider(widget.params));
    if (context == null) return;
    final layout = resolveCourtLayout(court, context);
    final server = layout.serverPlayerIndex;
    if (server == null || layout.callServerNumber == number) return;
    _runScoringStep(
      () => ref
          .read(scorePanelNotifierProvider(widget.params).notifier)
          .pickleballSetServerNumber(number),
    );
    unawaited(_apply((state, ctx) => setServerTurn(state, ctx, 1 - server)));
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

    // Serve turns show for every pickleball match; only the strict side-out
    // rule stops the receiving team from scoring.
    final isLite = score.isOpenScoring;
    const isSideOut = true;
    // The receiver's plus stays enabled in every mode: in strict side-out it
    // means "receiver won the rally" and moves the serve (see _changeScore).
    const receiverCanScore = true;
    final axis =
        widget.axis ??
        (MediaQuery.orientationOf(context) == Orientation.landscape
            ? Axis.horizontal
            : Axis.vertical);
    final scoreNotifier = ref.read(
      scorePanelNotifierProvider(widget.params).notifier,
    );

    // A cancelled match is over: the repository maps it to 'cancelled', which
    // is neither isCompleted nor isScheduled.
    final canEdit = widget.canScore && !_isOver(match);
    final canChangeScore = canEdit && !(match?.isScheduled ?? false);

    return PickleballCourtView(
      axis: axis,
      layout: resolveCourtLayout(court, courtContext),
      team1Players: match?.team1Members ?? const <String>[],
      team2Players: match?.team2Members ?? const <String>[],
      team1Score: courtContext.score1,
      team2Score: courtContext.score2,
      isSideOut: isSideOut,
      isDoubles: courtContext.isDoubles,
      receiverCanScore: receiverCanScore,
      autoSwitchEnds: court.autoSwitchEnds,
      overrideEnabled: score.overrideEnabled,
      startedAt: _isOver(match) ? null : match?.startedAt,
      setNumber: courtContext.setIndex + 1,
      finishSetEnabled:
          !score.isSubmitting &&
          scoreNotifier.finishSetConfirmMessage() != null,
      pickWinnerEnabled: !score.isSubmitting,
      onScoreChange: canChangeScore
          ? (team, increment) => _changeScore(
              team,
              increment,
              isSideOut: isSideOut,
              court: courtContext,
            )
          : null,
      onSetServingTeam: canEdit && isSideOut
          ? (team) => _setServingTeam(team, courtContext)
          : null,
      onDrop: canEdit ? _applyDrop : null,
      onSwitchEnds: canEdit ? () => unawaited(_apply(swapEndsNow)) : null,
      // A save in progress locks both icons (and the handlers refuse): a
      // second tap would save twice.
      onFinishSet: canChangeScore ? _confirmFinishSet : null,
      onPickWinner: canChangeScore ? _pickWinner : null,
      onToggleOverride: canEdit && !isLite ? _toggleOverride : null,
      onForceWin: canEdit ? widget.onForceWin : null,
      scoringMenu: canEdit && isLite
          ? CourtScoringMenu(
              currentLabel: pickleballScoringLabel(
                AppLocalizations.of(context)!,
                score.config.scoringModel,
              ),
              onTap: score.hasNoPoints ? _changeScoring : null,
            )
          : null,
      onUndo:
          canEdit &&
              resolveUndoAction(
                    _undoSteps,
                    courtDepth: court.history.length,
                    finishedSetCount: score.finishedSets.length,
                  ) !=
                  null
          ? _undo
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
