import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Provider cho ScorePanelNotifier.
final scorePanelNotifierProvider = NotifierProvider.autoDispose
    .family<ScorePanelNotifier, ScorePanelState, MatchControlParams>(
      (arg) => ScorePanelNotifier(arg),
    );

/// Quản lý scoring logic cho tất cả môn thể thao (Tennis, Pickleball, Rally).
class ScorePanelNotifier extends Notifier<ScorePanelState> {
  static const _log = AppLogger('ScorePanelNotifier');
  final MatchControlParams arg;
  Timer? _liveSyncTimer;

  ScorePanelNotifier(this.arg);

  @override
  ScorePanelState build() {
    ref.onDispose(() => _liveSyncTimer?.cancel());
    final config = _initConfig(ref, arg);
    ref.listen<AsyncValue<MatchModel?>>(singleMatchProvider(arg), (prev, next) {
      final match = next.value;
      if (match != null) {
        _updateStateFromMatch(match);
      }
    });

    final initialMatch = ref.read(singleMatchProvider(arg)).value;
    var initialState = ScorePanelState(
      config: config,
      isLite: _isLiteMatch(initialMatch),
    );
    if (initialMatch != null) {
      initialState = _hydrateState(initialState, initialMatch);
    }

    return initialState;
  }

  void _updateStateFromMatch(MatchModel match) {
    state = _hydrateState(state, match);
  }

  ScorePanelState _hydrateState(ScorePanelState current, MatchModel match) {
    final details = match.scoreDetails;
    final config = resolveSportConfig(
      match.sportRules,
      SportRuleKind.fromString(match.sportKey),
    );
    if (details == null) {
      return current.copyWith(
        config: config,
        isLite: _isLiteMatch(match),
      );
    }

    // 1. Finished Sets
    final rawSets = details['sets'] is List ? details['sets'] as List : const [];
    final allSets = rawSets
        .whereType<Map>()
        .map((s) => SetScoreData.fromJson(Map<String, dynamic>.from(s)))
        .toList();
    final finishedSets = allSets.where((set) => set.isFinished).toList();

    // 2. Tennis point state
    TennisGameState? tennisState;
    final liveState = details['liveState'] is Map
        ? Map<String, dynamic>.from(details['liveState'] as Map)
        : null;
    final rawTennis = liveState?['tennisPointState'] is Map
        ? Map<String, dynamic>.from(liveState!['tennisPointState'] as Map)
        : null;
    if (rawTennis != null) {
      final mode = rawTennis['mode']?.toString();
      final isTiebreak = mode == 'tiebreak';

      int parseTennisPoint(dynamic val) {
        if (val is int) return val;
        final s = val.toString();
        switch (s) {
          case '15':
            return 1;
          case '30':
            return 2;
          case '40':
            return 3;
          case 'A':
            return 4;
          default:
            return 0;
        }
      }

      tennisState = TennisGameState(
        team1GamePoints: parseTennisPoint(rawTennis['team1Point']),
        team2GamePoints: parseTennisPoint(rawTennis['team2Point']),
        isTiebreak: isTiebreak,
      );
    }

    // 3. Pickleball serve state
    PickleballServeState? pbState;
    final rawPb = liveState?['sideOutState'] is Map
        ? Map<String, dynamic>.from(liveState!['sideOutState'] as Map)
        : null;
    if (rawPb != null) {
      pbState = PickleballServeState(
        isTeam1Serving: rawPb['servingTeam'] == 1,
        serverNumber: rawPb['serverNumber'] as int? ?? 1,
      );
    }

    // 4. Rally Point state
    RallySetState? rallyState;
    if (config.scoringModel == SportScoringModel.rallyPointSet ||
        config.scoringModel == SportScoringModel.pickleballSideOut) {
      final activeSet = allSets.where((s) => !s.isFinished).firstOrNull;
      if (activeSet != null) {
        rallyState = RallySetState(
          currentP1: activeSet.score1,
          currentP2: activeSet.score2,
        );
      } else {
        rallyState = RallySetState(
          currentP1: details['p1SetsWon'] as int? ?? 0,
          currentP2: details['p2SetsWon'] as int? ?? 0,
        );
      }
    }

    return current.copyWith(
      config: config,
      isLite: _isLiteMatch(match),
      finishedSets: finishedSets,
      tennis: tennisState,
      pickleball: pbState,
      rally: rallyState,
    );
  }

  static SportConfig _initConfig(Ref ref, MatchControlParams arg) {
    final match = ref.read(singleMatchProvider(arg)).value;
    if (match?.sportRules != null && match!.sportRules!.isNotEmpty) {
      return resolveSportConfig(match.sportRules);
    }
    return resolveSportConfig(null, SportRuleKind.badminton);
  }

  static bool _isLiteMatch(MatchModel? match) {
    final mode = match?.tournamentConfig?['mode']?.toString().toUpperCase();
    return mode == 'LITE';
  }

  bool _canAddRallyPoint(int currentScore) {
    if (state.isLite || state.config.maxPoints <= 0) return true;
    if (state.overrideEnabled && state.overrideReason.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Nhập lý do Ngoại lệ trước khi vượt trần preset.',
      );
      return false;
    }
    if (state.overrideEnabled) return true;
    if (currentScore >= state.config.maxPoints) {
      state = state.copyWith(
        errorMessage:
            'Đã chạm trần ${state.config.maxPoints} điểm của môn này. Bật Ngoại lệ nếu BTC cần ghi khác preset.',
      );
      return false;
    }
    return true;
  }

  // ════════════════ TENNIS ════════════════

  void tennisAwardPoint(bool isTeam1) {
    final t = state.tennis ?? const TennisGameState();
    state = state.copyWith(
      tennis: t.copyWith(
        team1GamePoints: isTeam1 ? t.team1GamePoints + 1 : t.team1GamePoints,
        team2GamePoints: !isTeam1 ? t.team2GamePoints + 1 : t.team2GamePoints,
      ),
      errorMessage: null,
    );
    _checkTennisGameEnd();
  }

  void tennisRemovePoint(bool isTeam1) {
    final t = state.tennis ?? const TennisGameState();
    state = state.copyWith(
      tennis: t.copyWith(
        team1GamePoints: isTeam1
            ? (t.team1GamePoints > 0 ? t.team1GamePoints - 1 : 0)
            : t.team1GamePoints,
        team2GamePoints: !isTeam1
            ? (t.team2GamePoints > 0 ? t.team2GamePoints - 1 : 0)
            : t.team2GamePoints,
      ),
      errorMessage: null,
    );
  }

  void _checkTennisGameEnd() {
    final t = state.tennis;
    if (t == null) return;
    if (t.isTiebreak) {
      if (t.team1GamePoints >= 7 &&
          (t.team1GamePoints - t.team2GamePoints) >= 2) {
        _finishTennisGame(1);
      } else if (t.team2GamePoints >= 7 &&
          (t.team2GamePoints - t.team1GamePoints) >= 2) {
        _finishTennisGame(2);
      }
      return;
    }
    if (t.team1GamePoints >= 4 &&
        (t.team1GamePoints - t.team2GamePoints) >= 2) {
      _finishTennisGame(1);
    } else if (t.team2GamePoints >= 4 &&
        (t.team2GamePoints - t.team1GamePoints) >= 2) {
      _finishTennisGame(2);
    }
  }

  void _finishTennisGame(int winnerTeam) {
    final curSet = state.finishedSets.isNotEmpty
        ? state.finishedSets.last
        : null;
    List<SetScoreData> newSets;
    if (curSet != null && !curSet.isFinished) {
      newSets = [
        ...state.finishedSets.sublist(0, state.finishedSets.length - 1),
        winnerTeam == 1
            ? curSet.copyWith(score1: curSet.score1 + 1)
            : curSet.copyWith(score2: curSet.score2 + 1),
      ];
    } else {
      newSets = [
        ...state.finishedSets,
        winnerTeam == 1
            ? const SetScoreData(score1: 1, score2: 0)
            : const SetScoreData(score1: 0, score2: 1),
      ];
    }
    state = state.copyWith(
      finishedSets: newSets,
      tennis: const TennisGameState(),
    );
    _checkTennisSetEnd();
  }

  void _checkTennisSetEnd() {
    final curSet = state.finishedSets.isNotEmpty
        ? state.finishedSets.last
        : null;
    if (curSet == null) return;
    if (!state.isLite &&
        !state.overrideEnabled &&
        isSetComplete(curSet, state.config)) {
      final idx = state.finishedSets.length - 1;
      final newSets = [...state.finishedSets];
      newSets[idx] = newSets[idx].copyWith(isFinished: true);
      state = state.copyWith(
        finishedSets: newSets,
        tennis: const TennisGameState(),
      );
    } else if (curSet.score1 >= state.config.tiebreakAt &&
        curSet.score2 >= state.config.tiebreakAt &&
        curSet.score1 == curSet.score2) {
      state = state.copyWith(
        tennis: (state.tennis ?? const TennisGameState()).copyWith(
          isTiebreak: true,
        ),
      );
    }
  }

  // ════════════════ PICKLEBALL ════════════════

  bool pickleballAwardPoint(bool isTeam1) {
    final pb = state.pickleball ?? const PickleballServeState();
    if (!state.isLite && pb.isTeam1Serving != isTeam1) {
      state = state.copyWith(
        errorMessage: 'Chỉ đội giao bóng mới được ghi điểm!',
      );
      return false;
    }
    final r = state.rally ?? const RallySetState();
    if (!_canAddRallyPoint(isTeam1 ? r.currentP1 : r.currentP2)) return false;
    state = state.copyWith(
      rally: RallySetState(
        currentP1: isTeam1 ? r.currentP1 + 1 : r.currentP1,
        currentP2: !isTeam1 ? r.currentP2 + 1 : r.currentP2,
      ),
      pickleball: pb.copyWith(serverNumber: 1),
      errorMessage: null,
    );
    _checkPickleballGameEnd();
    _scheduleLiveSync();
    return true;
  }

  void pickleballSwitchServer() {
    final pb = state.pickleball ?? const PickleballServeState();
    state = state.copyWith(
      pickleball: pb.serverNumber == 1
          ? pb.copyWith(serverNumber: 2)
          : pb.copyWith(isTeam1Serving: !pb.isTeam1Serving, serverNumber: 1),
      errorMessage: null,
    );
  }

  void pickleballSideOut() {
    final pb = state.pickleball ?? const PickleballServeState();
    state = state.copyWith(
      pickleball: pb.copyWith(
        isTeam1Serving: !pb.isTeam1Serving,
        serverNumber: 1,
      ),
      errorMessage: null,
    );
  }

  void _checkPickleballGameEnd() {
    final r = state.rally;
    if (r == null) return;
    if (state.isLite || state.overrideEnabled) return;
    if (isSetComplete(
      SetScoreData(score1: r.currentP1, score2: r.currentP2),
      state.config,
    )) {
      state = state.copyWith(
        finishedSets: [
          ...state.finishedSets,
          SetScoreData(
            score1: r.currentP1,
            score2: r.currentP2,
            isFinished: true,
          ),
        ],
        rally: const RallySetState(),
      );
      _syncSetsToBackend();
    }
  }

  // ════════════════ RALLY ════════════════

  void rallyAddPoint(bool isTeam1) {
    final r = state.rally ?? const RallySetState();
    if (!_canAddRallyPoint(isTeam1 ? r.currentP1 : r.currentP2)) return;
    state = state.copyWith(
      rally: RallySetState(
        currentP1: isTeam1 ? r.currentP1 + 1 : r.currentP1,
        currentP2: !isTeam1 ? r.currentP2 + 1 : r.currentP2,
      ),
      errorMessage: null,
    );
    _checkRallySetEnd();
    _scheduleLiveSync();
  }

  void rallyRemovePoint(bool isTeam1) {
    final r = state.rally ?? const RallySetState();
    state = state.copyWith(
      rally: RallySetState(
        currentP1: isTeam1
            ? (r.currentP1 > 0 ? r.currentP1 - 1 : 0)
            : r.currentP1,
        currentP2: !isTeam1
            ? (r.currentP2 > 0 ? r.currentP2 - 1 : 0)
            : r.currentP2,
      ),
      errorMessage: null,
    );
    _scheduleLiveSync();
  }

  void _checkRallySetEnd() {
    final r = state.rally;
    if (r == null) return;
    if (state.isLite || state.overrideEnabled) return;
    if (isSetComplete(
      SetScoreData(score1: r.currentP1, score2: r.currentP2),
      state.config,
    )) {
      state = state.copyWith(
        finishedSets: [
          ...state.finishedSets,
          SetScoreData(
            score1: r.currentP1,
            score2: r.currentP2,
            isFinished: true,
          ),
        ],
        rally: const RallySetState(),
      );
      _syncSetsToBackend();
    }
  }

  // ════════════════ COMMON ════════════════

  bool get isMatchComplete => state.isMatchComplete;

  bool canCompleteAs(int winnerTeam) {
    if (winnerTeam != 1 && winnerTeam != 2) return false;
    if (state.isLite) {
      final (team1Wins, team2Wins) = computeMatchSetsWon(
        _setsForSubmission(),
      );
      return team1Wins != team2Wins &&
          (winnerTeam == 1 ? team1Wins > team2Wins : team2Wins > team1Wins);
    }
    if (!state.overrideEnabled) {
      return state.isMatchComplete && state.winnerTeam == winnerTeam;
    }
    if (state.overrideReason.trim().isEmpty) return false;

    final (team1Wins, team2Wins) = computeMatchSetsWon(_setsForSubmission());
    return winnerTeam == 1 ? team1Wins > team2Wins : team2Wins > team1Wins;
  }

  List<SetScoreData> _setsForSubmission() {
    final finalSets = List<SetScoreData>.from(state.finishedSets);
    if (state.config.scoringModel != SportScoringModel.tennisSet &&
        state.rally != null) {
      final rally = state.rally!;
      if (rally.currentP1 > 0 || rally.currentP2 > 0) {
        finalSets.add(
          SetScoreData(
            score1: rally.currentP1,
            score2: rally.currentP2,
            isFinished: true,
          ),
        );
      }
    }
    return finalSets;
  }

  Future<void> completeMatch(int winnerTeam) async {
    if (!canCompleteAs(winnerTeam)) {
      state = state.copyWith(
        errorMessage: state.overrideEnabled
            ? 'Nhập lý do và bảo đảm đội được xử thắng đang dẫn theo số set/game.'
            : 'Trận chưa đạt điều kiện kết thúc theo cấu hình.',
      );
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final finalSets = _setsForSubmission();
      final match = ref.read(singleMatchProvider(arg)).value;
      final winnerId = winnerTeam == 1
          ? match?.team1Id ?? ''
          : match?.team2Id ?? '';
      final loserId = winnerTeam == 1
          ? match?.team2Id ?? ''
          : match?.team1Id ?? '';
      await ref
          .read(matchControllerProvider(arg))
          .completeMatchWithDetails(
            winnerId: winnerId,
            loserId: loserId,
            finalSets: finalSets,
            overrideReason: state.overrideEnabled
                ? state.overrideReason.trim()
                : null,
            expectedRevision: match?.revision,
          );
      state = state.copyWith(isSubmitting: false);
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận', e, stack);
      state = state.copyWith(isSubmitting: false, errorMessage: 'Lỗi: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  USER-ACTIONS: Finish Set & Override
  // ═══════════════════════════════════════════════════════════

  /// Get confirmation message for finishing current set, or null if no set to finish.
  String? finishSetConfirmMessage() {
    final rally = state.rally;
    final tennis = state.tennis;
    if (rally != null && (rally.currentP1 > 0 || rally.currentP2 > 0)) {
      final setNum = state.finishedSets.length + 1;
      return 'Kết thúc set $setNum với tỉ số ${rally.currentP1}-${rally.currentP2}?';
    }
    if (state.config.scoringModel == SportScoringModel.tennisSet &&
        tennis != null) {
      final setNum = state.finishedSets.length + 1;
      return 'Kết thúc set $setNum?';
    }
    return null;
  }

  Future<void> finishSet() async {
    final rally = state.rally;
    final tennis = state.tennis;

    if (state.config.scoringModel == SportScoringModel.tennisSet) {
      if (tennis == null) return;
      final curSet = state.finishedSets.isNotEmpty
          ? state.finishedSets.last
          : null;
      List<SetScoreData> newSets;
      if (curSet != null && !curSet.isFinished) {
        if (!_validateSetBeforeFinish(curSet)) return;
        newSets = [
          ...state.finishedSets.sublist(0, state.finishedSets.length - 1),
          curSet.copyWith(isFinished: true),
        ];
      } else {
        const emptySet = SetScoreData(score1: 0, score2: 0);
        if (!_validateSetBeforeFinish(emptySet)) return;
        newSets = [
          ...state.finishedSets,
          const SetScoreData(score1: 0, score2: 0, isFinished: true),
        ];
      }
      state = state.copyWith(
        finishedSets: newSets,
        tennis: const TennisGameState(),
      );
    } else {
      if (rally == null) return;
      final currentSet = SetScoreData(
        score1: rally.currentP1,
        score2: rally.currentP2,
      );
      if (!_validateSetBeforeFinish(currentSet)) return;
      final newFinishedSets = [
        ...state.finishedSets,
        currentSet.copyWith(isFinished: true),
      ];
      state = state.copyWith(
        finishedSets: newFinishedSets,
        rally: const RallySetState(),
      );
    }

    await _syncSetsToBackend();
  }

  bool _validateSetBeforeFinish(SetScoreData set) {
    if (state.isLite || state.overrideEnabled) return true;
    try {
      final label = state.config.scoringModel == SportScoringModel.tennisSet
          ? 'Set ${state.finishedSets.length + 1}'
          : 'Hiệp ${state.finishedSets.length + 1}';
      switch (state.config.scoringModel) {
        case SportScoringModel.tennisSet:
          validateTennisSet(set, state.config, label: label);
          break;
        case SportScoringModel.pickleballSideOut:
          validatePickleballSideOutSet(set, state.config, label: label);
          break;
        case SportScoringModel.rallyPointSet:
          validateRallyPointSet(set, state.config, label: label);
          break;
      }
      return true;
    } on FormatException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      return false;
    }
  }

  Future<void> _syncSetsToBackend() async {
    final setsToSubmit = _setsForSubmission();
    final (p1Sets, p2Sets) = computeMatchSetsWon(setsToSubmit);
    try {
      if (state.isMatchComplete) {
        await completeMatch(state.winnerTeam);
      } else {
        final rev = ref.read(singleMatchProvider(arg)).value?.revision;
        await ref.read(matchControllerProvider(arg)).updateSetsWithDetails(
          p1SetsWon: p1Sets,
          p2SetsWon: p2Sets,
          scoreDetails: setsToSubmit,
          expectedRevision: rev,
        );
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('thay đổi từ thiết bị khác')) {
        _log.warning('Conflict 409: điểm đã thay đổi từ thiết bị khác. Refetching latest match...');
        ref.invalidate(singleMatchProvider(arg));
        state = state.copyWith(
          errorMessage: 'Điểm đã thay đổi từ thiết bị khác. Đã làm mới số liệu.',
        );
      } else {
        _log.error('Lỗi đồng bộ tỉ số set lên backend', e);
      }
    }
  }

  void setOverride(bool enabled, String reason) {
    state = state.copyWith(overrideEnabled: enabled, overrideReason: reason);
  }

  void _scheduleLiveSync() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer(const Duration(milliseconds: 250), _syncLiveScore);
  }

  Future<void> _syncLiveScore() async {
    final rally = state.rally;
    if (rally == null || state.isMatchComplete) return;
    if (rally.currentP1 == 0 && rally.currentP2 == 0) return;
    final sets = [
      ...state.finishedSets,
      SetScoreData(score1: rally.currentP1, score2: rally.currentP2),
    ];
    final (p1Sets, p2Sets) = computeMatchSetsWon(state.finishedSets);
    try {
      final rev = ref.read(singleMatchProvider(arg)).value?.revision;
      await ref.read(matchControllerProvider(arg)).updateSetsWithDetails(
        p1SetsWon: p1Sets,
        p2SetsWon: p2Sets,
        scoreDetails: sets,
        expectedRevision: rev,
      );
    } catch (e, stack) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('thay đổi từ thiết bị khác')) {
        _log.warning('Conflict 409 in live sync. Refetching latest match...');
        ref.invalidate(singleMatchProvider(arg));
      }
      _log.error('Lỗi đồng bộ điểm live', e, stack);
      state = state.copyWith(errorMessage: 'Không đồng bộ được điểm live. Vui lòng thử lại.');
    }
  }
}

/// Helper: ánh xạ tennis game point (0,1,2,3,4+) sang hiển thị (0,15,30,40,Ad).
String tennisPointLabel(int points) {
  switch (points) {
    case 0:
      return '0';
    case 1:
      return '15';
    case 2:
      return '30';
    case 3:
      return '40';
    default:
      return 'Ad';
  }
}

/// Helper: Định dạng điểm tennis chuẩn (0, 15, 30, 40, Ad) dựa trên điểm số cả hai đội
String formatTennisPoint(int myPoints, int opponentPoints, bool isTiebreak) {
  if (isTiebreak) return '$myPoints';

  if (myPoints >= 3 && opponentPoints >= 3) {
    if (myPoints == opponentPoints) return '40';
    if (myPoints > opponentPoints) return 'Ad';
    return '40';
  }

  switch (myPoints) {
    case 0:
      return '0';
    case 1:
      return '15';
    case 2:
      return '30';
    case 3:
      return '40';
    default:
      return 'Ad';
  }
}
