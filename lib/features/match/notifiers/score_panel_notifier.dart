import 'package:flutter/foundation.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

/// Provider cho ScorePanelNotifier — dùng legacy.ChangeNotifierProvider.family.
final scorePanelNotifierProvider =
    legacy.ChangeNotifierProvider.autoDispose.family<ScorePanelNotifier, MatchControlParams>((ref, arg) {
  return ScorePanelNotifier(arg, ref);
});

/// Quản lý scoring logic cho tất cả môn thể thao (Tennis, Pickleball, Rally).
///
/// Gọi notifyListeners() sau mỗi lần state thay đổi để widget rebuild.
class ScorePanelNotifier extends ChangeNotifier {
  static const _log = AppLogger('ScorePanelNotifier');

  final MatchControlParams arg;
  final Ref ref;
  ScorePanelState _state;

  ScorePanelNotifier(this.arg, this.ref)
      : _state = ScorePanelState(config: _initConfig(ref, arg)) {
    ref.listen<AsyncValue<MatchModel?>>(
      singleMatchProvider(arg),
      (prev, next) {
        final match = next.value;
        if (match != null) {
          _updateStateFromMatch(match);
        }
      },
      fireImmediately: true,
    );
  }

  ScorePanelState get state => _state;

  void _updateStateFromMatch(MatchModel match) {
    final details = match.scoreDetails;
    final config = resolveSportConfig(
      match.sportRules,
      SportRuleKind.fromString(match.sportKey),
    );
    if (details == null) {
      _state = _state.copyWith(config: config);
      notifyListeners();
      return;
    }

    // 1. Finished Sets
    final rawSets = details['sets'] as List? ?? [];
    final finishedSets = rawSets.map((s) => SetScoreData.fromJson(s as Map<String, dynamic>)).toList();

    // 2. Tennis point state
    TennisGameState? tennisState;
    final liveState = details['liveState'] as Map<String, dynamic>?;
    final rawTennis = liveState?['tennisPointState'] as Map<String, dynamic>?;
    if (rawTennis != null) {
      final mode = rawTennis['mode']?.toString();
      final isTiebreak = mode == 'tiebreak';

      int parseTennisPoint(dynamic val) {
        if (val is int) return val;
        final s = val.toString();
        switch (s) {
          case '15': return 1;
          case '30': return 2;
          case '40': return 3;
          case 'A': return 4;
          default: return 0;
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
    final rawPb = liveState?['sideOutState'] as Map<String, dynamic>?;
    if (rawPb != null) {
      pbState = PickleballServeState(
        isTeam1Serving: rawPb['servingTeam'] == 1,
        serverNumber: rawPb['serverNumber'] as int? ?? 1,
      );
    }

    // 4. Rally Point state
    RallySetState? rallyState;
    if (_state.config.scoringModel == SportScoringModel.rallyPointSet ||
        _state.config.scoringModel == SportScoringModel.pickleballSideOut) {
      final activeSet = finishedSets.where((s) => !s.isFinished).firstOrNull;
      if (activeSet != null) {
        rallyState = RallySetState(
          currentP1: activeSet.score1,
          currentP2: activeSet.score2,
        );
      } else {
        rallyState = const RallySetState();
      }
    }

    _state = _state.copyWith(
      config: config,
      finishedSets: finishedSets,
      tennis: tennisState,
      pickleball: pbState,
      rally: rallyState,
    );
    notifyListeners();
  }

  static SportConfig _initConfig(Ref ref, MatchControlParams arg) {
    final match = ref.read(singleMatchProvider(arg)).value;
    if (match?.sportRules != null && match!.sportRules!.isNotEmpty) {
      return resolveSportConfig(match.sportRules);
    }
    return resolveSportConfig(null, SportRuleKind.badminton);
  }

  // ════════════════ TENNIS ════════════════

  void tennisAwardPoint(bool isTeam1) {
    final t = _state.tennis ?? const TennisGameState();
    _state = _state.copyWith(
      tennis: t.copyWith(
        team1GamePoints: isTeam1 ? t.team1GamePoints + 1 : t.team1GamePoints,
        team2GamePoints: !isTeam1 ? t.team2GamePoints + 1 : t.team2GamePoints,
      ),
      errorMessage: null,
    );
    _checkTennisGameEnd();
    notifyListeners();
  }

  void tennisRemovePoint(bool isTeam1) {
    final t = _state.tennis ?? const TennisGameState();
    _state = _state.copyWith(
      tennis: t.copyWith(
        team1GamePoints: isTeam1 ? (t.team1GamePoints > 0 ? t.team1GamePoints - 1 : 0) : t.team1GamePoints,
        team2GamePoints: !isTeam1 ? (t.team2GamePoints > 0 ? t.team2GamePoints - 1 : 0) : t.team2GamePoints,
      ),
      errorMessage: null,
    );
    notifyListeners();
  }

  void _checkTennisGameEnd() {
    final t = _state.tennis;
    if (t == null) return;
    if (t.isTiebreak) {
      if (t.team1GamePoints >= 7 && (t.team1GamePoints - t.team2GamePoints) >= 2) {
        _finishTennisGame(1);
      } else if (t.team2GamePoints >= 7 && (t.team2GamePoints - t.team1GamePoints) >= 2) {
        _finishTennisGame(2);
      }
      return;
    }
    if (t.team1GamePoints >= 4 && (t.team1GamePoints - t.team2GamePoints) >= 2) {
      _finishTennisGame(1);
    } else if (t.team2GamePoints >= 4 && (t.team2GamePoints - t.team1GamePoints) >= 2) {
      _finishTennisGame(2);
    }
  }

  void _finishTennisGame(int winnerTeam) {
    final curSet = _state.finishedSets.isNotEmpty ? _state.finishedSets.last : null;
    List<SetScoreData> newSets;
    if (curSet != null && !curSet.isFinished) {
      newSets = [
        ..._state.finishedSets.sublist(0, _state.finishedSets.length - 1),
        winnerTeam == 1 ? curSet.copyWith(score1: curSet.score1 + 1) : curSet.copyWith(score2: curSet.score2 + 1),
      ];
    } else {
      newSets = [..._state.finishedSets, winnerTeam == 1
          ? const SetScoreData(score1: 1, score2: 0)
          : const SetScoreData(score1: 0, score2: 1)];
    }
    _state = _state.copyWith(finishedSets: newSets, tennis: const TennisGameState());
    _checkTennisSetEnd();
  }

  void _checkTennisSetEnd() {
    final curSet = _state.finishedSets.isNotEmpty ? _state.finishedSets.last : null;
    if (curSet == null) return;
    if (isSetComplete(curSet, _state.config)) {
      final idx = _state.finishedSets.length - 1;
      final newSets = [..._state.finishedSets];
      newSets[idx] = newSets[idx].copyWith(isFinished: true);
      _state = _state.copyWith(finishedSets: newSets, tennis: const TennisGameState());
    } else if (curSet.score1 >= _state.config.tiebreakAt && curSet.score2 >= _state.config.tiebreakAt && curSet.score1 == curSet.score2) {
      _state = _state.copyWith(tennis: (_state.tennis ?? const TennisGameState()).copyWith(isTiebreak: true));
    }
  }

  // ════════════════ PICKLEBALL ════════════════

  bool pickleballAwardPoint(bool isTeam1) {
    final pb = _state.pickleball ?? const PickleballServeState();
    if (pb.isTeam1Serving != isTeam1) {
      _state = _state.copyWith(errorMessage: 'Chỉ đội giao bóng mới được ghi điểm!');
      notifyListeners();
      return false;
    }
    final r = _state.rally ?? const RallySetState();
    _state = _state.copyWith(
      rally: RallySetState(currentP1: isTeam1 ? r.currentP1 + 1 : r.currentP1, currentP2: !isTeam1 ? r.currentP2 + 1 : r.currentP2),
      pickleball: pb.copyWith(serverNumber: 1),
      errorMessage: null,
    );
    _checkPickleballGameEnd();
    notifyListeners();
    return true;
  }

  void pickleballSwitchServer() {
    final pb = _state.pickleball ?? const PickleballServeState();
    _state = _state.copyWith(
      pickleball: pb.serverNumber == 1 ? pb.copyWith(serverNumber: 2) : pb.copyWith(isTeam1Serving: !pb.isTeam1Serving, serverNumber: 1),
      errorMessage: null,
    );
    notifyListeners();
  }

  void pickleballSideOut() {
    final pb = _state.pickleball ?? const PickleballServeState();
    _state = _state.copyWith(pickleball: pb.copyWith(isTeam1Serving: !pb.isTeam1Serving, serverNumber: 1), errorMessage: null);
    notifyListeners();
  }

  void _checkPickleballGameEnd() {
    final r = _state.rally;
    if (r == null) return;
    if (isSetComplete(
      SetScoreData(score1: r.currentP1, score2: r.currentP2),
      _state.config,
    )) {
      _state = _state.copyWith(finishedSets: [
        ..._state.finishedSets,
        SetScoreData(score1: r.currentP1, score2: r.currentP2, isFinished: true),
      ], rally: const RallySetState());
      notifyListeners();
    }
  }

  // ════════════════ RALLY ════════════════

  void rallyAddPoint(bool isTeam1) {
    final r = _state.rally ?? const RallySetState();
    _state = _state.copyWith(
      rally: RallySetState(currentP1: isTeam1 ? r.currentP1 + 1 : r.currentP1, currentP2: !isTeam1 ? r.currentP2 + 1 : r.currentP2),
      errorMessage: null,
    );
    _checkRallySetEnd();
    notifyListeners();
  }

  void rallyRemovePoint(bool isTeam1) {
    final r = _state.rally ?? const RallySetState();
    _state = _state.copyWith(
      rally: RallySetState(
        currentP1: isTeam1 ? (r.currentP1 > 0 ? r.currentP1 - 1 : 0) : r.currentP1,
        currentP2: !isTeam1 ? (r.currentP2 > 0 ? r.currentP2 - 1 : 0) : r.currentP2,
      ),
      errorMessage: null,
    );
    notifyListeners();
  }

  void _checkRallySetEnd() {
    final r = _state.rally;
    if (r == null) return;
    if (isSetComplete(
      SetScoreData(score1: r.currentP1, score2: r.currentP2),
      _state.config,
    )) {
      _state = _state.copyWith(finishedSets: [
        ..._state.finishedSets,
        SetScoreData(score1: r.currentP1, score2: r.currentP2, isFinished: true),
      ], rally: const RallySetState());
      notifyListeners();
    }
  }

  // ════════════════ COMMON ════════════════

  bool get isMatchComplete => _state.isMatchComplete;

  bool canCompleteAs(int winnerTeam) {
    if (winnerTeam != 1 && winnerTeam != 2) return false;
    if (!_state.overrideEnabled) {
      return _state.isMatchComplete && _state.winnerTeam == winnerTeam;
    }
    if (_state.overrideReason.trim().isEmpty) return false;

    final (team1Wins, team2Wins) = computeMatchSetsWon(_setsForSubmission());
    return winnerTeam == 1 ? team1Wins > team2Wins : team2Wins > team1Wins;
  }

  List<SetScoreData> _setsForSubmission() {
    final finalSets = List<SetScoreData>.from(_state.finishedSets);
    if (_state.config.scoringModel != SportScoringModel.tennisSet &&
        _state.rally != null) {
      final rally = _state.rally!;
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
      _state = _state.copyWith(
        errorMessage: _state.overrideEnabled
            ? 'Nhập lý do và bảo đảm đội được xử thắng đang dẫn theo số set/game.'
            : 'Trận chưa đạt điều kiện kết thúc theo cấu hình.',
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();
    try {
      final finalSets = _setsForSubmission();
      final match = ref.read(singleMatchProvider(arg)).value;
      final winnerId = winnerTeam == 1 ? match?.team1Id ?? '' : match?.team2Id ?? '';
      final loserId = winnerTeam == 1 ? match?.team2Id ?? '' : match?.team1Id ?? '';
      await ref.read(matchControllerProvider(arg)).completeMatchWithDetails(
        winnerId: winnerId, loserId: loserId, finalSets: finalSets,
        overrideReason:
            _state.overrideEnabled ? _state.overrideReason.trim() : null,
      );
      _state = _state.copyWith(isSubmitting: false);
      notifyListeners();
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận', e, stack);
      _state = _state.copyWith(isSubmitting: false, errorMessage: 'Lỗi: $e');
      notifyListeners();
    }
  }

  void setOverride(bool enabled, String reason) {
    _state = _state.copyWith(overrideEnabled: enabled, overrideReason: reason);
    notifyListeners();
  }
}

/// Helper: ánh xạ tennis game point (0,1,2,3,4+) sang hiển thị (0,15,30,40,Ad).
String tennisPointLabel(int points) {
  switch (points) {
    case 0: return '0';
    case 1: return '15';
    case 2: return '30';
    case 3: return '40';
    default: return 'Ad';
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
    case 0: return '0';
    case 1: return '15';
    case 2: return '30';
    case 3: return '40';
    default: return 'Ad';
  }
}
