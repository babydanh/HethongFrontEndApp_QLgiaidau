import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';

/// Provider cho ScorePanelNotifier.
final scorePanelNotifierProvider = NotifierProvider.autoDispose
    .family<ScorePanelNotifier, ScorePanelState, MatchControlParams>(
      (arg) => ScorePanelNotifier(arg),
    );

int _parseFootballInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _parseOptionalFootballInt(dynamic value) {
  if (value == null) return null;
  final parsed = _parseFootballInt(value, fallback: -1);
  return parsed < 0 ? null : parsed;
}

String _parseFootballPhase(dynamic value) {
  final phase = value?.toString().trim().toUpperCase();
  return footballPhases.contains(phase) ? phase! : 'FIRST_HALF';
}

FootballLiveState? _readFootballState(Map<String, dynamic> details) {
  final raw = details['football'];
  if (raw is! Map) return null;
  final shootout = raw['shootout'] is Map ? raw['shootout'] as Map : null;
  return FootballLiveState(
    team1Goals: _parseFootballInt(raw['team1Goals']),
    team2Goals: _parseFootballInt(raw['team2Goals']),
    phase: _parseFootballPhase(raw['phase']),
    minute: _parseFootballInt(raw['minute']),
    addedMinute: _parseFootballInt(raw['addedMinute']),
    events: raw['events'] is List
        ? (raw['events'] as List)
              .whereType<Map>()
              .map(
                (event) => FootballEvent(
                  type: event['type']?.toString() ?? 'NOTE',
                  isTeam1: _parseFootballInt(event['team']) == 1,
                  minute: _parseFootballInt(event['minute']),
                  addedMinute: _parseFootballInt(event['addedMinute']),
                ),
              )
              .toList()
        : const [],
    shootoutTeam1Goals: _parseOptionalFootballInt(shootout?['team1Goals']),
    shootoutTeam2Goals: _parseOptionalFootballInt(shootout?['team2Goals']),
  );
}

/// Quản lý scoring logic cho tất cả môn thể thao (Tennis, Pickleball, Rally).
class ScorePanelNotifier extends Notifier<ScorePanelState> {
  static const _log = AppLogger('ScorePanelNotifier');
  final MatchControlParams arg;
  Timer? _liveSyncTimer;
  Timer? _footballSyncTimer;
  FootballLiveState? _pendingFootballSync;
  bool _footballSyncInFlight = false;
  bool _footballSyncHealthy = true;
  String? _pendingScoreSignature;
  int? _pendingBaseRevision;
  bool _liveSyncPending = false;
  bool _liveSyncInFlight = false;
  int? _lastLocalWriteRevision;

  ScorePanelNotifier(this.arg);

  AppLocalizations get _l10n =>
      lookupAppLocalizations(ref.read(localeProvider));

  @override
  ScorePanelState build() {
    ref.onDispose(() {
      _liveSyncTimer?.cancel();
      _footballSyncTimer?.cancel();
      if (_pendingFootballSync != null) {
        unawaited(_flushFootballSync().then<void>((_) {}));
      }
      // Do not lose the last tap when the scoring panel is popped before the
      // 250ms debounce fires. The request is best-effort and is protected by
      // expectedRevision on the API.
      if (_liveSyncPending) unawaited(_syncLiveScore());
    });
    final config = _initConfig(ref, arg);
    ref.listen<AsyncValue<MatchModel?>>(singleMatchProvider(arg), (prev, next) {
      final match = next.value;
      if (match != null) {
        _updateStateFromMatch(match);
      }
    });
    if (arg.tournamentId.isNotEmpty) {
      ref.listen(tournamentProvider(arg.tournamentId), (prev, next) {
        final match = ref.read(singleMatchProvider(arg)).value;
        if (match == null) return;
        // The match can arrive before the tournament rules request. Rehydrate
        // when that request completes so an older snapshot cannot fall back to
        // the default BO3/setsToWin=2 and auto-complete a Quick/Lite match.
        state = _hydrateState(state, match);
      });
    }

    final initialMatch = ref.read(singleMatchProvider(arg)).value;
    var initialState = ScorePanelState(
      config: config,
      isLite: _isLiteMatch(initialMatch, ref, arg),
      football:
          SportRuleKind.fromString(initialMatch?.sportKey) ==
              SportRuleKind.football
          ? const FootballLiveState()
          : null,
    );
    if (initialMatch != null) {
      initialState = _hydrateState(initialState, initialMatch);
    }

    return initialState;
  }

  void _updateStateFromMatch(MatchModel match) {
    final incomingRevision = match.revision;
    final hydrated = _hydrateState(state, match);

    // The score write invalidates the match provider so the outer cards stay
    // fresh.  That provider can briefly emit the pre-write snapshot (or a
    // cached snapshot with the new revision but old score) before the socket
    // echo arrives.  Applying it here makes every tap appear to reset to 1:
    // tap 1 is rendered locally, the stale refetch replaces it with 0, and the
    // next tap starts from 0 again.  A snapshot at or before our last accepted
    // write may only replace local state when it actually contains that write.
    // Newer revisions remain authoritative, including a genuine terminal
    // status change.
    if (_lastLocalWriteRevision != null &&
        incomingRevision != null &&
        incomingRevision <= _lastLocalWriteRevision! &&
        _scoreSignature(hydrated) != _scoreSignature(state) &&
        !_isServerTerminal(match)) {
      return;
    }
    if (_lastLocalWriteRevision != null &&
        incomingRevision != null &&
        incomingRevision < _lastLocalWriteRevision!) {
      return;
    }
    final pending = _pendingScoreSignature;
    if (pending != null) {
      final isOurEcho = _scoreSignature(hydrated) == pending;
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      } else {
        // Only suppress a snapshot that is demonstrably stale (same revision
        // as the local tap). A newer revision is an authoritative update from
        // another scorer and must be rendered immediately.
        final baseRevision = _pendingBaseRevision;
        final remoteRevision = incomingRevision;
        if (_liveSyncInFlight &&
            _liveSyncPending &&
            baseRevision != null &&
            remoteRevision != null &&
            remoteRevision <= baseRevision + 1) {
          // This is the echo for the request already in flight. A newer tap
          // is still local and must not be replaced by that older snapshot.
          return;
        }
        if (baseRevision != null &&
            remoteRevision != null &&
            remoteRevision <= baseRevision) {
          return;
        }
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      }
    }
    if (incomingRevision != null &&
        (_lastLocalWriteRevision == null ||
            incomingRevision >= _lastLocalWriteRevision!)) {
      _lastLocalWriteRevision = incomingRevision;
    }
    // A socket echo normally changes only the server revision. Replacing the
    // whole notifier state for that identical score makes the lower action
    // bar visibly blink and briefly recompute its set/button labels.
    if (_scoreSignature(hydrated) == _scoreSignature(state) &&
        hydrated.isServerTerminal == state.isServerTerminal &&
        hydrated.isLite == state.isLite) {
      return;
    }
    state = hydrated;
  }

  String _scoreSignature(ScorePanelState value) {
    final sets = value.finishedSets
        .map((set) => '${set.score1}:${set.score2}:${set.isFinished}')
        .join('|');
    final rally = value.rally == null
        ? '-'
        : '${value.rally!.currentP1}:${value.rally!.currentP2}';
    final tennis = value.tennis == null
        ? '-'
        : '${value.tennis!.team1GamePoints}:${value.tennis!.team2GamePoints}:${value.tennis!.isTiebreak}';
    final football = value.football == null
        ? '-'
        : '${value.football!.team1Goals}:${value.football!.team2Goals}:${value.football!.phase}:${value.football!.minute}:${value.football!.addedMinute}:${value.football!.shootoutTeam1Goals}:${value.football!.shootoutTeam2Goals}:${value.football!.events.map((event) => '${event.type}:${event.isTeam1 ? 1 : 2}:${event.minute}:${event.addedMinute}').join('|')}';
    return '$sets#$rally#$tennis#$football';
  }

  void _markLocalScorePending() {
    _pendingScoreSignature = _scoreSignature(state);
    _pendingBaseRevision = _nextExpectedRevision();
  }

  int? _nextExpectedRevision() {
    final serverRevision = ref.read(singleMatchProvider(arg)).value?.revision;
    if (serverRevision == null) return _lastLocalWriteRevision;
    final localRevision = _lastLocalWriteRevision;
    if (localRevision == null || serverRevision >= localRevision) {
      return serverRevision;
    }
    return localRevision;
  }

  ScorePanelState _hydrateState(ScorePanelState current, MatchModel match) {
    final details = match.scoreDetails;
    final effectiveSportRules = _effectiveSportRules(match, ref, arg);
    final config = resolveSportConfig(
      effectiveSportRules,
      SportRuleKind.fromString(match.sportKey),
    );
    if (details == null) {
      return current.copyWith(
        config: config,
        isLite: _isLiteMatch(match, ref, arg),
        isServerTerminal: _isServerTerminal(match),
      );
    }

    // 1. Finished Sets
    final rawSets = details['sets'] is List
        ? details['sets'] as List
        : const [];
    final allSets = rawSets
        .whereType<Map>()
        .map((s) => SetScoreData.fromJson(Map<String, dynamic>.from(s)))
        .toList();
    // Tennis stores the current in-progress set in `sets` as well. Keep that
    // active set when hydrating; dropping it leaves only 40/deuce in
    // liveState and loses the game/set score on the next socket/refetch.
    final finishedSets = config.scoringModel == SportScoringModel.tennisSet
        ? allSets
        : allSets.where((set) => set.isFinished).toList();

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
        // `p1SetsWon`/`p2SetsWon` are match aggregates, not the current
        // rally score. When the server has only finished sets, start a new
        // live set at 0-0; copying the aggregates here makes a saved set
        // reappear as points and causes the next sync to drift.
        rallyState = const RallySetState();
      }
    }

    return current.copyWith(
      config: config,
      isLite: _isLiteMatch(match, ref, arg),
      isServerTerminal: _isServerTerminal(match),
      finishedSets: finishedSets,
      tennis: tennisState,
      pickleball: pbState,
      rally: rallyState,
      football: _readFootballState(details) ?? current.football,
    );
  }

  static SportConfig _initConfig(Ref ref, MatchControlParams arg) {
    final match = ref.read(singleMatchProvider(arg)).value;
    return resolveSportConfig(
      _effectiveSportRules(match, ref, arg),
      SportRuleKind.fromString(match?.sportKey),
    );
  }

  static Map<String, dynamic>? _effectiveSportRules(
    MatchModel? match,
    Ref? ref,
    MatchControlParams? arg,
  ) {
    Map<String, dynamic>? tournamentRules;
    if (ref != null && arg != null && arg.tournamentId.isNotEmpty) {
      tournamentRules = ref
          .read(tournamentProvider(arg.tournamentId))
          .value
          ?.sportRules;
    }

    final matchRules = match?.sportRules;
    Map<String, dynamic>? mergedRules;
    if (tournamentRules != null && tournamentRules.isNotEmpty) {
      // Match-level values (including a stage/match BO override) win, while
      // the tournament mode is retained when an older match snapshot omitted
      // it. This prevents Quick/Lite from being interpreted as the default BO3.
      mergedRules = {
        ...tournamentRules,
        if (matchRules != null && matchRules.isNotEmpty) ...matchRules,
      };
    } else {
      mergedRules = matchRules;
    }

    final config = match?.tournamentConfig;
    if (mergedRules == null && config == null) return null;

    // Older match/socket payloads can contain `mode: STRICT` in sportRules
    // while tournamentConfig carries the authoritative open marker. Preserve
    // that marker in the effective map so resolver state cannot fall back to
    // BO3/max-one-point behaviour.
    final marker =
        config?['scoringMode'] ??
        config?['scoring_mode'] ??
        config?['rulesPreset'];
    final configIsLite = config?['isLite'] == true;
    if (configIsLite || marker != null) {
      return {
        ...?mergedRules,
        ...?(configIsLite ? const {'mode': 'LITE'} : null),
        ...?(marker == null ? null : {'scoringMode': marker}),
      };
    }
    return mergedRules;
  }

  static bool _isLiteMatch(
    MatchModel? match, [
    Ref? ref,
    MatchControlParams? arg,
  ]) {
    final effectiveSportRules = _effectiveSportRules(match, ref, arg);
    if (isLiteScoringMode(
      tournamentConfig: match?.tournamentConfig,
      sportRules: effectiveSportRules,
    )) {
      return true;
    }
    if (ref != null && arg != null && arg.tournamentId.isNotEmpty) {
      final tournament = ref.read(tournamentProvider(arg.tournamentId)).value;
      if (isLiteScoringMode(
        sportRules: tournament?.sportRules,
        tournamentIsLite: tournament?.isLite == true,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool _isServerTerminal(MatchModel match) {
    final status = match.status.trim().toLowerCase();
    return status == 'completed' ||
        status == 'walkover' ||
        match.completedAt != null;
  }

  bool _canAddRallyPoint(int currentScore) {
    if (state.isOpenScoring || state.config.maxPoints <= 0) return true;
    if (state.overrideEnabled && state.overrideReason.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: _l10n.scorePanel_overrideReasonRequired,
      );
      return false;
    }
    if (state.overrideEnabled) return true;
    if (currentScore >= state.config.maxPoints) {
      state = state.copyWith(
        errorMessage: _l10n.scorePanel_maxPresetPoints(state.config.maxPoints),
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
    if (state.isMatchComplete) {
      // Strict tennis completes only after the configured number of sets.
      // Open/Lite tennis never reaches this branch from a set count.
      unawaited(_syncSetsToBackend());
    } else {
      _scheduleLiveSync();
    }
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
    _scheduleLiveSync();
  }

  void _checkTennisGameEnd() {
    if (state.isMatchComplete) return;
    final t = state.tennis;
    if (t == null) return;
    if (t.isTiebreak) {
      final target = state.config.tiebreakPoints ?? 7;
      if (t.team1GamePoints >= target &&
          (t.team1GamePoints - t.team2GamePoints) >= 2) {
        _finishTennisGame(1);
      } else if (t.team2GamePoints >= target &&
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
    if (state.isMatchComplete) return;
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
    if (!state.overrideEnabled && isSetComplete(curSet, state.config)) {
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
    if (!state.isOpenScoring && pb.isTeam1Serving != isTeam1) {
      state = state.copyWith(errorMessage: _l10n.scorePanel_servingTeamOnly);
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
    if (state.isMatchComplete) return;
    final r = state.rally;
    if (r == null) return;
    if (state.isOpenScoring || state.overrideEnabled) return;
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
    if (state.isMatchComplete) return;
    final r = state.rally;
    if (r == null) return;
    if (state.isOpenScoring || state.overrideEnabled) return;
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

  void footballAddGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final next = current.copyWith(
      team1Goals: isTeam1 ? current.team1Goals + 1 : current.team1Goals,
      team2Goals: isTeam1 ? current.team2Goals : current.team2Goals + 1,
      events: [
        ...current.events,
        FootballEvent(
          type: 'GOAL',
          isTeam1: isTeam1,
          minute: current.minute,
          addedMinute: current.addedMinute,
        ),
      ],
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void footballRemoveGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final events = [...current.events];
    for (var index = events.length - 1; index >= 0; index--) {
      final event = events[index];
      if (event.type == 'GOAL' && event.isTeam1 == isTeam1) {
        events.removeAt(index);
        break;
      }
    }
    final next = current.copyWith(
      team1Goals: isTeam1
          ? (current.team1Goals > 0 ? current.team1Goals - 1 : 0)
          : current.team1Goals,
      team2Goals: isTeam1
          ? current.team2Goals
          : (current.team2Goals > 0 ? current.team2Goals - 1 : 0),
      events: events,
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void footballSetPhase(String phase) {
    final normalized = phase.trim().toUpperCase();
    if (!footballEditablePhases.contains(normalized)) return;
    final next = (state.football ?? const FootballLiveState()).copyWith(
      phase: normalized,
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void footballSetMinute(int minute) {
    final next = (state.football ?? const FootballLiveState()).copyWith(
      minute: minute.clamp(0, 130),
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void footballSetAddedMinute(int addedMinute) {
    final next = (state.football ?? const FootballLiveState()).copyWith(
      addedMinute: addedMinute.clamp(0, 30),
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void footballAddEvent(String type, bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final next = current.copyWith(
      events: [
        ...current.events,
        FootballEvent(
          type: type,
          isTeam1: isTeam1,
          minute: current.minute,
          addedMinute: current.addedMinute,
        ),
      ],
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void footballSetShootout({
    required int? team1Goals,
    required int? team2Goals,
  }) {
    final current = state.football ?? const FootballLiveState();
    int? clampShootout(int? value) {
      if (value == null) return null;
      if (value < 0) return 0;
      if (value > 99) return 99;
      return value;
    }

    final next = current.copyWith(
      shootoutTeam1Goals: clampShootout(team1Goals),
      shootoutTeam2Goals: clampShootout(team2Goals),
    );
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
  }

  void _scheduleFootballSync(FootballLiveState value) {
    _footballSyncHealthy = true;
    _markLocalScorePending();
    _pendingFootballSync = value;
    _footballSyncTimer?.cancel();
    _footballSyncTimer = Timer(const Duration(milliseconds: 250), () {
      _footballSyncTimer = null;
      unawaited(_flushFootballSync().then<void>((_) {}));
    });
  }

  Future<bool> _flushFootballSync() async {
    if (_footballSyncInFlight) return true;
    final value = _pendingFootballSync;
    if (value == null) return _footballSyncHealthy;
    _pendingFootballSync = null;
    _footballSyncInFlight = true;

    final match = ref.read(singleMatchProvider(arg)).value;
    if (match == null) {
      _footballSyncInFlight = false;
      _footballSyncHealthy = false;
      return false;
    }

    try {
      await ref
          .read(matchControllerProvider(arg))
          .updateSetsWithDetails(
            p1SetsWon: 0,
            p2SetsWon: 0,
            scoreDetails: const [],
            scoreDetailsExtras: {
              'football': {
                'team1Goals': value.team1Goals,
                'team2Goals': value.team2Goals,
                'phase': value.phase,
                'minute': value.minute,
                'addedMinute': value.addedMinute,
                'events': value.events
                    .asMap()
                    .entries
                    .map(
                      (entry) => {
                        'id': 'app-${entry.key}-${value.minute}',
                        'type': entry.value.type,
                        'team': entry.value.isTeam1 ? 1 : 2,
                        'minute': entry.value.minute,
                        'addedMinute': entry.value.addedMinute,
                      },
                    )
                    .toList(),
                if (value.shootoutTeam1Goals != null &&
                    value.shootoutTeam2Goals != null)
                  'shootout': {
                    'team1Goals': value.shootoutTeam1Goals,
                    'team2Goals': value.shootoutTeam2Goals,
                  },
              },
            },
            expectedRevision: _nextExpectedRevision() ?? match.revision,
            refreshSurfaces: false,
          );
    } catch (error, stack) {
      _log.error('Football live score sync failed', error, stack);
      _footballSyncHealthy = false;
      state = state.copyWith(errorMessage: _l10n.scorePanel_footballSyncError);
    } finally {
      _footballSyncInFlight = false;
      if (_pendingFootballSync != null) {
        unawaited(_flushFootballSync().then<void>((_) {}));
      }
    }
    return _footballSyncHealthy;
  }

  Future<bool> _flushPendingFootballSync() async {
    _footballSyncTimer?.cancel();
    _footballSyncTimer = null;
    if (_pendingFootballSync != null && !_footballSyncInFlight) {
      await _flushFootballSync();
    }
    while (_footballSyncInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_pendingFootballSync != null) {
      await _flushFootballSync();
    }
    return _footballSyncHealthy;
  }

  bool canCompleteAs(int winnerTeam) {
    if (state.isServerTerminal) return false;
    if (winnerTeam != 1 && winnerTeam != 2) return false;
    if (state.football != null) {
      final football = state.football!;
      final match = ref.read(singleMatchProvider(arg)).value;
      if (match?.team1Id.isNotEmpty != true ||
          match?.team2Id.isNotEmpty != true) {
        return false;
      }

      // Football intentionally follows Lite-style completion: the clock and
      // phase are informational. A draw still requires a valid shootout.
      return football.winnerTeam == winnerTeam;
    }
    if (state.isOpenScoring) {
      final (team1Wins, team2Wins) = computeMatchSetsWon(_setsForSubmission());
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

  List<SetScoreData> _setsForSubmission({
    bool includeEmptyLiteActiveSet = false,
  }) {
    final finalSets = state.config.scoringModel == SportScoringModel.tennisSet
        ? state.finishedSets.where((set) => set.isFinished).toList()
        : List<SetScoreData>.from(state.finishedSets);
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
      } else if (state.isOpenScoring && includeEmptyLiteActiveSet) {
        // Keep the next Super Lite set explicitly present on the server after
        // the previous set is closed. Without this 0-0 open entry, a reload
        // can only see the last finished set and the live page falls back to
        // that old score instead of showing the new set at 0-0.
        finalSets.add(const SetScoreData(score1: 0, score2: 0));
      }
    }
    if (state.isOpenScoring &&
        includeEmptyLiteActiveSet &&
        state.config.scoringModel == SportScoringModel.tennisSet) {
      // Tennis Lite resets its point/game state after a manual set close, so
      // it has no rally object to trigger the branch above. Persist the next
      // open set here as well.
      finalSets.add(const SetScoreData(score1: 0, score2: 0));
    }
    return finalSets;
  }

  Future<void> completeMatch(int winnerTeam) async {
    if (!canCompleteAs(winnerTeam)) {
      state = state.copyWith(
        errorMessage: state.overrideEnabled
            ? _l10n.scorePanel_completeOverrideInvalid
            : _l10n.scorePanel_matchNotReady,
      );
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (state.football != null) {
        final flushed = await _flushPendingFootballSync();
        if (!flushed) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: _l10n.scorePanel_footballSyncError,
          );
          return;
        }
        final football = state.football!;
        final match = ref.read(singleMatchProvider(arg)).value;
        final winnerId = winnerTeam == 1
            ? match?.team1Id ?? ''
            : match?.team2Id ?? '';
        if (winnerId.isEmpty) {
          throw StateError(_l10n.scorePanel_footballWinnerNotFound);
        }
        final isDraw = football.team1Goals == football.team2Goals;
        final shootout1 = football.shootoutTeam1Goals;
        final shootout2 = football.shootoutTeam2Goals;
        if (isDraw &&
            (shootout1 == null ||
                shootout2 == null ||
                shootout1 == shootout2)) {
          throw StateError(_l10n.scorePanel_footballShootoutRequired);
        }
        final scoreDetails = <String, dynamic>{
          'football': {
            'team1Goals': football.team1Goals,
            'team2Goals': football.team2Goals,
            'phase': isDraw ? 'PENALTY_SHOOTOUT' : 'COMPLETED',
            'minute': football.minute,
            'addedMinute': football.addedMinute,
            'events': football.events
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'id': 'app-${entry.key}-${football.minute}',
                    'type': entry.value.type,
                    'team': entry.value.isTeam1 ? 1 : 2,
                    'minute': entry.value.minute,
                  },
                )
                .toList(),
            if (isDraw)
              'shootout': {
                'team1Goals': shootout1,
                'team2Goals': shootout2,
                'winnerId': winnerId,
              },
          },
        };
        await ref
            .read(matchControllerProvider(arg))
            .updateSetsWithDetails(
              p1SetsWon: 0,
              p2SetsWon: 0,
              scoreDetails: const [],
              scoreDetailsExtras: scoreDetails,
              winnerId: winnerId,
              expectedRevision: _nextExpectedRevision() ?? match?.revision,
            );
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        return;
      }
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
            expectedRevision: _nextExpectedRevision() ?? match?.revision,
          );
      state = state.copyWith(isSubmitting: false, errorMessage: null);
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận', e, stack);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _l10n.scorePanel_completeError(e.toString()),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  USER-ACTIONS: Finish Set & Override
  // ═══════════════════════════════════════════════════════════

  int? get _activeTennisSetIndex {
    if (state.config.scoringModel != SportScoringModel.tennisSet) return null;
    for (var index = state.finishedSets.length - 1; index >= 0; index--) {
      if (!state.finishedSets[index].isFinished) return index;
    }
    return null;
  }

  /// Number of the set currently being played, including a persisted 0-0
  /// placeholder created after closing the previous Super Lite set.
  int get currentSetNumber {
    final activeIndex = _activeTennisSetIndex;
    if (activeIndex != null) return activeIndex + 1;
    return state.finishedSets.length + 1;
  }

  /// Get confirmation message for finishing current set, or null if no set to finish.
  String? finishSetConfirmMessage() {
    final rally = state.rally;
    final tennis = state.tennis;
    if (state.config.scoringModel == SportScoringModel.tennisSet) {
      final activeIndex = _activeTennisSetIndex;
      final currentSet = activeIndex == null
          ? null
          : state.finishedSets[activeIndex];
      // Tennis point values (0/15/30/40/deuce) are not a set score. The
      // scorer must finish the current game first; this button closes the
      // whole set represented by the accumulated game score.
      if (tennis == null ||
          tennis.team1GamePoints != 0 ||
          tennis.team2GamePoints != 0 ||
          currentSet == null ||
          currentSet.isFinished ||
          currentSet.score1 + currentSet.score2 == 0) {
        return null;
      }
      final setNum = activeIndex! + 1;
      return _l10n.scorePanel_finishSetWithScore(
        setNum,
        currentSet.score1,
        currentSet.score2,
      );
    }
    if (rally != null && (rally.currentP1 > 0 || rally.currentP2 > 0)) {
      final setNum = state.finishedSets.length + 1;
      return _l10n.scorePanel_finishSetWithScore(
        setNum,
        rally.currentP1,
        rally.currentP2,
      );
    }
    if (state.config.scoringModel == SportScoringModel.tennisSet &&
        tennis != null) {
      final setNum = state.finishedSets.length + 1;
      return _l10n.scorePanel_finishSet(setNum);
    }
    return null;
  }

  Future<void> finishSet() async {
    if (state.isMatchComplete) {
      state = state.copyWith(
        errorMessage: _l10n.scorePanel_matchAlreadyComplete,
      );
      return;
    }
    final rally = state.rally;
    final tennis = state.tennis;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (state.config.scoringModel == SportScoringModel.tennisSet) {
      if (tennis == null) {
        state = state.copyWith(isSubmitting: false);
        return;
      }
      if (tennis.team1GamePoints != 0 || tennis.team2GamePoints != 0) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _l10n.scorePanel_matchNotReady,
        );
        return;
      }
      final activeSetIndex = _activeTennisSetIndex;
      final curSet = activeSetIndex == null
          ? null
          : state.finishedSets[activeSetIndex];
      List<SetScoreData> newSets;
      if (curSet != null && !curSet.isFinished) {
        if (!_validateSetBeforeFinish(curSet)) {
          state = state.copyWith(isSubmitting: false);
          return;
        }
        newSets = [
          ...state.finishedSets.sublist(0, activeSetIndex!),
          curSet.copyWith(isFinished: true),
          ...state.finishedSets.sublist(activeSetIndex + 1),
        ];
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _l10n.scorePanel_matchNotReady,
        );
        return;
      }
      state = state.copyWith(
        finishedSets: newSets,
        tennis: const TennisGameState(),
      );
    } else {
      if (rally == null) {
        state = state.copyWith(isSubmitting: false);
        return;
      }
      final currentSet = SetScoreData(
        score1: rally.currentP1,
        score2: rally.currentP2,
      );
      if (!_validateSetBeforeFinish(currentSet)) {
        state = state.copyWith(isSubmitting: false);
        return;
      }
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
    if (state.isSubmitting) {
      state = state.copyWith(isSubmitting: false);
    }
  }

  bool _validateSetBeforeFinish(SetScoreData set) {
    if (state.isOpenScoring || state.overrideEnabled) return true;
    try {
      final setNumber = state.finishedSets.length + 1;

      switch (state.config.scoringModel) {
        case SportScoringModel.tennisSet:
          validateTennisSet(set, state.config, setNumber: setNumber);
          break;
        case SportScoringModel.pickleballSideOut:
          validatePickleballSideOutSet(set, state.config, setNumber: setNumber);
          break;
        case SportScoringModel.rallyPointSet:
          validateRallyPointSet(set, state.config, setNumber: setNumber);
          break;
      }
      return true;
    } on FormatException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      return false;
    }
  }

  Future<void> _syncSetsToBackend() async {
    await _flushLiveScoreBeforeSetSync();
    _markLocalScorePending();
    final setsToSubmit = _setsForSubmission(includeEmptyLiteActiveSet: true);
    final (p1Sets, p2Sets) = computeMatchSetsWon(setsToSubmit);
    final expectedRevision = _nextExpectedRevision();
    try {
      if (state.isMatchComplete) {
        await completeMatch(state.winnerTeam);
      } else {
        await ref
            .read(matchControllerProvider(arg))
            .updateSetsWithDetails(
              p1SetsWon: p1Sets,
              p2SetsWon: p2Sets,
              scoreDetails: setsToSubmit,
              expectedRevision: expectedRevision,
            );
      }
      if (expectedRevision != null) {
        _lastLocalWriteRevision = expectedRevision + 1;
      }
      // PATCH returns success before the socket echo is guaranteed to reach
      // this client. Re-open the authoritative match stream immediately so
      // the newly closed set survives leaving/re-entering the live panel.
      ref.invalidate(singleMatchProvider(arg));
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('thay đổi từ thiết bị khác')) {
        _log.warning(
          'Conflict 409: điểm đã thay đổi từ thiết bị khác. Refetching latest match...',
        );
        ref.invalidate(singleMatchProvider(arg));
        _lastLocalWriteRevision = null;
        state = state.copyWith(errorMessage: _l10n.scorePanel_conflictRefresh);
      } else {
        _log.error('Lỗi đồng bộ tỉ số set lên backend', e);
        ref.invalidate(singleMatchProvider(arg));
        _lastLocalWriteRevision = null;
        state = state.copyWith(errorMessage: _l10n.scorePanel_liveSyncError);
      }
    }
  }

  Future<void> _flushLiveScoreBeforeSetSync() async {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = null;
    if (_liveSyncInFlight) {
      // Mark the post-request local state as newer so its socket echo cannot
      // replace it while the set-close write is waiting for the same match
      // revision.
      _liveSyncPending = true;
      while (_liveSyncInFlight) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
    _liveSyncTimer?.cancel();
    _liveSyncTimer = null;
    _liveSyncPending = false;
  }

  void setOverride(bool enabled, String reason) {
    state = state.copyWith(overrideEnabled: enabled, overrideReason: reason);
  }

  void _scheduleLiveSync() {
    _markLocalScorePending();
    _liveSyncPending = true;
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer(const Duration(milliseconds: 250), _syncLiveScore);
  }

  Future<void> _syncLiveScore() async {
    if (_liveSyncInFlight) return;
    final rally = state.rally;
    final tennis = state.tennis;
    if ((rally == null && tennis == null) || state.isMatchComplete) {
      _liveSyncPending = false;
      return;
    }
    if (rally != null && rally.currentP1 == 0 && rally.currentP2 == 0) {
      _liveSyncPending = false;
      return;
    }
    if (tennis != null &&
        tennis.team1GamePoints == 0 &&
        tennis.team2GamePoints == 0 &&
        state.finishedSets.isEmpty) {
      _liveSyncPending = false;
      return;
    }
    final sets = List<SetScoreData>.from(state.finishedSets);
    Map<String, dynamic>? liveState;
    if (rally != null) {
      sets.add(SetScoreData(score1: rally.currentP1, score2: rally.currentP2));
    } else if (tennis != null) {
      final hasActiveSet = sets.isNotEmpty && !sets.last.isFinished;
      if (!hasActiveSet &&
          (tennis.team1GamePoints > 0 || tennis.team2GamePoints > 0)) {
        // The first tennis game may have points before any game has been won.
        // Keep an explicit live 0-0 game/set so the point state survives a
        // reload and the viewer does not fall back to the previous set.
        sets.add(const SetScoreData(score1: 0, score2: 0));
      }
      liveState = {
        'tennisPointState': {
          'team1Point': tennis.team1GamePoints,
          'team2Point': tennis.team2GamePoints,
          'mode': tennis.isTiebreak ? 'tiebreak' : 'game',
        },
      };
    }
    final (p1Sets, p2Sets) = computeMatchSetsWon(state.finishedSets);
    final requestSignature = _scoreSignature(state);
    final expectedRevision = _nextExpectedRevision();
    _pendingScoreSignature = requestSignature;
    _pendingBaseRevision = expectedRevision;
    _liveSyncPending = false;
    _liveSyncInFlight = true;
    try {
      await ref
          .read(matchControllerProvider(arg))
          .updateSetsWithDetails(
            p1SetsWon: p1Sets,
            p2SetsWon: p2Sets,
            scoreDetails: sets,
            scoreDetailsExtras: liveState == null
                ? null
                : {'liveState': liveState},
            expectedRevision: expectedRevision,
            refreshSurfaces: false,
          );
      if (expectedRevision != null) {
        _lastLocalWriteRevision = expectedRevision + 1;
      }
      // A tap may have arrived while this request was in flight. Keep the
      // pending flag in that case so the latest local snapshot is sent next.
      _liveSyncPending = _scoreSignature(state) != requestSignature;
      // The websocket remains the fast path for other viewers. Do not
      // invalidate this provider for every tap: the panel already owns the
      // optimistic local state and a refetch here causes visible jitter and
      // can replay an older score before the socket echo arrives.
    } catch (e, stack) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('thay đổi từ thiết bị khác')) {
        _log.warning('Conflict 409 in live sync. Refetching latest match...');
        ref.invalidate(singleMatchProvider(arg));
        _lastLocalWriteRevision = null;
      }
      if (!msg.contains('409') && !msg.contains('thay đổi từ thiết bị khác')) {
        ref.invalidate(singleMatchProvider(arg));
      }
      _log.error('Lỗi đồng bộ điểm live', e, stack);
      state = state.copyWith(errorMessage: _l10n.scorePanel_liveSyncError);
    } finally {
      _liveSyncInFlight = false;
      if (_liveSyncPending && !state.isMatchComplete) {
        _liveSyncTimer?.cancel();
        _liveSyncTimer = Timer(
          const Duration(milliseconds: 50),
          _syncLiveScore,
        );
      }
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
