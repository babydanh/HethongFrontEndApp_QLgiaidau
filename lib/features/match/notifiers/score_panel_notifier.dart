import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/football_rules.dart';
import 'package:app_quanly_giaidau/domain/services/rally_serve_rules.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/domain/services/tennis_rules.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_racket.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_tennis.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
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
  final read = FootballLiveState(
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
                  shirt: _parseOptionalFootballInt(event['shirt']),
                ),
              )
              .toList()
        : const [],
    shootoutTeam1Goals: _parseOptionalFootballInt(shootout?['team1Goals']),
    shootoutTeam2Goals: _parseOptionalFootballInt(shootout?['team2Goals']),
  );
  // The stopped-match flag is derived from the red cards, so it survives a
  // server that only stores the original event fields.
  return read.copyWith(stoppedWinnerTeam: footballStoppedWinnerTeam(read));
}

String? scorePanelWriteErrorMessage(AppLocalizations l10n, Object error) {
  if (error is TournamentNotStartedException) {
    return l10n.scorePanel_tournamentNotStarted;
  }
  return null;
}

/// Quản lý scoring logic cho tất cả môn thể thao (Tennis, Pickleball, Rally).
class ScorePanelNotifier extends Notifier<ScorePanelState> {
  static const _log = AppLogger('ScorePanelNotifier');
  /// Bound free/Lite scorecards so repeated taps or socket retries cannot
  /// append an unbounded number of set placeholders.
  static const maxMatchSets = 10;
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
  bool _isDisposed = false;

  ScorePanelNotifier(this.arg);

  int get _closedSetCount =>
      state.config.scoringModel == SportScoringModel.tennisSet
          ? state.finishedSets.where((set) => set.isFinished).length
          : state.finishedSets.length;

  bool get _hasReachedMaxSets => _closedSetCount >= maxMatchSets;

  bool _rejectIfMaxSetsReached() {
    if (!_hasReachedMaxSets) return false;
    state = state.copyWith(errorMessage: 'Đã đạt tối đa $maxMatchSets set.');
    return true;
  }

  AppLocalizations get _l10n =>
      lookupAppLocalizations(ref.read(localeProvider));

  @override
  ScorePanelState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _liveSyncTimer?.cancel();
      _footballSyncTimer?.cancel();
      if (_pendingFootballSync != null) {
        // The notifier Ref is already disposing here. The owning match
        // controller remains alive for explicit writes; do not start a new
        // Ref-dependent request from onDispose.
        _pendingFootballSync = null;
      }
      _liveSyncPending = false;
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

  /// Feeds a server snapshot through the same path as the match stream.
  @visibleForTesting
  void applyMatchSnapshot(MatchModel match) => _updateStateFromMatch(match);

  bool _scoringChangeInFlight = false;

  /// Lite pickleball: saves this match's scoring rule (Side-out or Rally).
  /// Only while the match has no point (the server checks it too). Returns the
  /// error when the save fails (the rule stays as it was), null on success or
  /// when there is nothing to send. A second call while one is in flight is a
  /// no-op.
  Future<Object?> setPickleballScoring(SportScoringModel model) async {
    if (_scoringChangeInFlight ||
        !state.isOpenScoring ||
        !state.hasNoPoints ||
        state.config.scoringModel == model) {
      return null;
    }
    _scoringChangeInFlight = true;
    try {
      final saved = await ref
          .read(matchRepositoryProvider)
          .setPickleballScoring(arg.matchId, model);
      if (_isDisposed) return null;
      // Switch the board now instead of waiting for the socket echo; the
      // refetch brings the same flag from the server.
      state = state.copyWith(
        config: resolveSportConfig(
          _effectiveSportRules(saved, ref, arg),
          SportRuleKind.fromString(saved.sportKey),
        ),
      );
      ref.invalidate(singleMatchProvider(arg));
      return null;
    } catch (error) {
      return error;
    } finally {
      _scoringChangeInFlight = false;
    }
  }

  void _updateStateFromMatch(MatchModel match) {
    final incomingRevision = match.revision;
    final hydrated = _hydrateState(state, match);

    // A tap that is still waiting for its write is newer than any snapshot,
    // whatever revision the snapshot carries (a court-state PATCH can bump the
    // revision without containing the tap). Dropping the snapshot keeps the
    // number from jumping back and forth; the write response syncs it again.
    if ((_liveSyncPending || _pendingFootballSync != null) &&
        _scoreSignature(hydrated) != _scoreSignature(state) &&
        !_isServerTerminal(match)) {
      return;
    }

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
    final finishedSets = (config.scoringModel == SportScoringModel.tennisSet
            ? allSets
            : allSets.where((set) => set.isFinished).toList())
        .take(maxMatchSets)
        .toList();

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
    final rawPb = liveState?['sideOutState'] is Map
        ? Map<String, dynamic>.from(liveState!['sideOutState'] as Map)
        : null;

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

    // Data saved before `openingDone` existed: a 0-0 set is still an opening
    // serve, any point scored means the opening is over.
    PickleballServeState? pbState;
    if (rawPb != null) {
      final hasPoints =
          rallyState != null &&
          (rallyState.currentP1 > 0 || rallyState.currentP2 > 0);
      pbState = PickleballServeState(
        isTeam1Serving: rawPb['servingTeam'] == 1,
        serverNumber: rawPb['serverNumber'] as int? ?? 1,
        openingDone: rawPb['openingDone'] as bool? ?? hasPoints,
      );
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
    if (_rejectIfMaxSetsReached()) return;
    _racketRemember();
    final gamesBefore = _tennisGames();
    final current = state.tennis ?? const TennisGameState();
    // A match tie-break has no game to start it: it begins with the first point.
    final t = state.tennisMatchTiebreakDue && !current.isTiebreak
        ? current.copyWith(isTiebreak: true)
        : current;
    state = state.copyWith(
      tennis: t.copyWith(
        team1GamePoints: isTeam1 ? t.team1GamePoints + 1 : t.team1GamePoints,
        team2GamePoints: !isTeam1 ? t.team2GamePoints + 1 : t.team2GamePoints,
      ),
      errorMessage: null,
    );
    _checkTennisGameEnd();
    _racketEndsAfterTennisPoint(gamesBefore);
    if (state.isMatchComplete) {
      // Strict tennis completes only after the configured number of sets.
      // Open/Lite tennis never reaches this branch from a set count.
      unawaited(_syncSetsToBackend());
    } else {
      _scheduleLiveSync();
    }
  }

  void tennisRemovePoint(bool isTeam1) {
    _racketRemember();
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
    bool won(int a, int b) => tennisGameWon(
      a: a,
      b: b,
      noAd: state.config.noAd,
      tiebreak: t.isTiebreak,
      tiebreakTarget: state.tennisPlan.tiebreakTarget,
    );
    if (won(t.team1GamePoints, t.team2GamePoints)) {
      _finishTennisGame(1);
    } else if (won(t.team2GamePoints, t.team1GamePoints)) {
      _finishTennisGame(2);
    }
  }

  void _finishTennisGame(int winnerTeam) {
    if (state.isMatchComplete || _hasReachedMaxSets) return;
    final curSet = state.finishedSets.isNotEmpty
        ? state.finishedSets.last
        : null;
    List<SetScoreData> newSets;
    if (state.tennisMatchTiebreakDue) {
      // The Backend only accepts 7-6 / 6-7 as a tie-break set, so the match
      // tie-break is stored that way, replacing a live 0-0 placeholder.
      final done = winnerTeam == 1
          ? const SetScoreData(score1: 7, score2: 6, isFinished: true)
          : const SetScoreData(score1: 6, score2: 7, isFinished: true);
      newSets = [...state.finishedSets.where((set) => set.isFinished), done];
    } else if (curSet != null && !curSet.isFinished) {
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
    // Strict tournament tennis can close a set automatically at the preset
    // limit. Lite/Free tennis is intentionally open-ended: reaching 6 games
    // only makes the set ready; the scorer must press "Chốt set N" so the
    // current set remains editable and the next set can be started manually.
    final plan = state.tennisPlan;
    final tiebreakAtGames =
        state.config.tiebreakAtGames ?? state.config.tiebreakAt;
    // Without a tie-break (tiebreakMode NONE / NO_TIEBREAK final set) the set
    // is won at the target with a 2 game lead; the 7-6 cap does not apply.
    final setComplete = plan.tiebreakEnabled
        ? isSetComplete(curSet, state.config)
        : _setWonByTwoGames(curSet);
    if (!state.isOpenScoring && !state.overrideEnabled && setComplete) {
      final idx = state.finishedSets.length - 1;
      final newSets = [...state.finishedSets];
      newSets[idx] = newSets[idx].copyWith(isFinished: true);
      state = state.copyWith(
        finishedSets: newSets,
        tennis: const TennisGameState(),
      );
    } else if (plan.tiebreakEnabled &&
        curSet.score1 >= tiebreakAtGames &&
        curSet.score2 >= tiebreakAtGames &&
        curSet.score1 == curSet.score2) {
      state = state.copyWith(
        tennis: (state.tennis ?? const TennisGameState()).copyWith(
          isTiebreak: true,
        ),
      );
    }
  }

  bool _setWonByTwoGames(SetScoreData set) {
    final high = set.score1 > set.score2 ? set.score1 : set.score2;
    final low = set.score1 > set.score2 ? set.score2 : set.score1;
    return high >= state.config.pointsPerSet && high - low >= 2;
  }

  // ════════════════ PICKLEBALL ════════════════

  bool pickleballAwardPoint(bool isTeam1) {
    if (_rejectIfMaxSetsReached()) return false;
    final pb = state.pickleball ?? const PickleballServeState();
    if (state.isPickleballSideOut && pb.isTeam1Serving != isTeam1) {
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
      // A point keeps the same server: server 2 stays server 2 until a fault.
      // Lite/rally lets the receiver score: the serve then goes to that team.
      pickleball: pb.isTeam1Serving == isTeam1
          ? pb
          : pb.copyWith(
              isTeam1Serving: isTeam1,
              serverNumber: 1,
              openingDone: true,
            ),
      errorMessage: null,
    );
    _checkPickleballGameEnd();
    _scheduleLiveSync();
    return true;
  }

  /// The serving team loses a rally. Doubles: server 1 -> server 2 -> other
  /// team. The opening serve of a game has a single fault, so it passes
  /// straight to the other team (server 1).
  void pickleballSwitchServer() {
    final pb = state.pickleball ?? const PickleballServeState();
    final handsOver = !pb.openingDone || pb.serverNumber != 1;
    state = state.copyWith(
      pickleball: handsOver
          ? pb.copyWith(
              isTeam1Serving: !pb.isTeam1Serving,
              serverNumber: 1,
              openingDone: true,
            )
          : pb.copyWith(serverNumber: 2),
      errorMessage: null,
    );
    _scheduleLiveSync();
  }

  /// Referee correction in doubles: serve number 1 or 2 of the serving team.
  /// The team and the score stay; [openingDone] is left as it is so the
  /// opening serve keeps its single fault.
  void pickleballSetServerNumber(int number) {
    final pb = state.pickleball ?? const PickleballServeState();
    if (pb.serverNumber == number || (number != 1 && number != 2)) return;
    state = state.copyWith(
      pickleball: pb.copyWith(serverNumber: number),
      errorMessage: null,
    );
    _scheduleLiveSync();
  }

  void pickleballSideOut() {
    final pb = state.pickleball ?? const PickleballServeState();
    state = state.copyWith(
      pickleball: pb.copyWith(
        isTeam1Serving: !pb.isTeam1Serving,
        serverNumber: 1,
        openingDone: true,
      ),
      errorMessage: null,
    );
    _scheduleLiveSync();
  }

  /// Picks who serves first. At 0-0 this is the opening serve (one fault
  /// only); once points were scored it is a plain side-out.
  void pickleballSetServingTeam(bool isTeam1) {
    final pb = state.pickleball ?? const PickleballServeState();
    if (pb.isTeam1Serving == isTeam1) return;
    final r = state.rally ?? const RallySetState();
    if (r.currentP1 != 0 || r.currentP2 != 0) {
      pickleballSideOut();
      return;
    }
    state = state.copyWith(
      pickleball: pb.copyWith(
        isTeam1Serving: isTeam1,
        serverNumber: 1,
        openingDone: false,
      ),
      errorMessage: null,
    );
    _scheduleLiveSync();
  }

  /// Undo: puts the points and the serve of the current game back as they
  /// were before a step the referee took (point, lose-serve, server pick).
  void pickleballRestoreStep({
    required RallySetState rally,
    required PickleballServeState serve,
  }) {
    state = state.copyWith(rally: rally, pickleball: serve, errorMessage: null);
    _scheduleLiveSync();
  }

  /// Who serves, in the shape `_hydrateState` reads back: without it the serve
  /// falls back to team 1 at the opening serve whenever the match is reopened.
  Map<String, dynamic>? _pickleballLiveState() {
    final pb = state.pickleball;
    if (pb == null) return null;
    return {
      'sideOutState': {
        'servingTeam': pb.isTeam1Serving ? 1 : 2,
        'serverNumber': pb.serverNumber,
        'openingDone': pb.openingDone,
      },
    };
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
        // A new game opens at server 1 with a single fault (openingDone false).
        pickleball: (state.pickleball ?? const PickleballServeState())
            .copyWith(serverNumber: 1, openingDone: false),
      );
      _syncSetsToBackend();
    }
  }

  // ════════════════ RALLY ════════════════

  void rallyAddPoint(bool isTeam1) {
    if (_rejectIfMaxSetsReached()) return;
    final r = state.rally ?? const RallySetState();
    if (!_canAddRallyPoint(isTeam1 ? r.currentP1 : r.currentP2)) return;
    _racketRemember();
    final closedBefore = state.finishedSets.length;
    state = state.copyWith(
      rally: _rallyAfterPoint(r, isTeam1),
      errorMessage: null,
    );
    _checkRallySetEnd();
    _racketEndsAfterRally(r, closedBefore);
    _scheduleLiveSync();
  }

  /// Next rally state after a point. Badminton and table tennis also remember
  /// who won it (and how often a team won on serve) so the panel can show who
  /// serves; other sports keep only the score.
  RallySetState _rallyAfterPoint(RallySetState r, bool isTeam1) {
    final p1 = isTeam1 ? r.currentP1 + 1 : r.currentP1;
    final p2 = isTeam1 ? r.currentP2 : r.currentP2 + 1;
    final kind = state.config.kind;
    if (kind != SportRuleKind.badminton && kind != SportRuleKind.tableTennis) {
      return RallySetState(currentP1: p1, currentP2: p2);
    }
    final winner = isTeam1 ? 1 : 2;
    final opening = r.currentP1 + r.currentP2 == 0;
    final prev = state.finishedSets.isEmpty ? null : state.finishedSets.last;
    final server = opening
        ? rallyGameFirstServer(
            kind: kind,
            gameIndex: state.finishedSets.length,
            firstServer: state.racketPick.firstTeam,
            prevGameWinner: prev == null
                ? null
                : (prev.score1 > prev.score2 ? 1 : 2),
          )
        : r.lastWinner;
    int? swaps(int team, int? current) {
      final base = opening ? 0 : current;
      if (base == null) return null;
      return winner == team && server == team ? base + 1 : base;
    }

    return RallySetState(
      currentP1: p1,
      currentP2: p2,
      lastWinner: winner,
      swaps1: swaps(1, r.swaps1),
      swaps2: swaps(2, r.swaps2),
    );
  }

  void rallyRemovePoint(bool isTeam1) {
    _racketRemember();
    final r = state.rally ?? const RallySetState();
    // A correction makes the serve history unknown; the panel hides the serve
    // line until the next point instead of showing a wrong server.
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
    if (state.isMatchComplete || _hasReachedMaxSets) return;
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

  // ════════════════ RACKET (badminton, tennis) ════════════════

  int _tennisGames() => state.finishedSets.fold<int>(
    0,
    (total, set) => total + set.score1 + set.score2,
  );

  /// Saves what Undo needs before a badminton or tennis step. Only the field
  /// of the sport in play is kept, so restoring never invents the other one.
  void _racketRemember() {
    if (!state.isRacket) return;
    final tennis = state.config.kind == SportRuleKind.tennis;
    final step = RacketUndoStep(
      rally: tennis ? null : (state.rally ?? const RallySetState()),
      tennis: tennis ? (state.tennis ?? const TennisGameState()) : null,
      finishedSets: state.finishedSets,
      pick: state.racketPick,
      closedSetCount: state.racketClosedSetCount,
    );
    state = state.copyWith(
      racketUndo: pushRacketUndo(state.racketUndo, step),
    );
  }

  void _racketFlipEnds() {
    final pick = state.racketPick;
    state = state.copyWith(
      racketPick: pick.copyWith(endsFlipped: !pick.endsFlipped),
    );
  }

  /// Badminton: the teams change ends after every game and in the deciding
  /// game when the first side reaches 11.
  void _racketEndsAfterRally(RallySetState before, int closedBefore) {
    if (state.config.kind != SportRuleKind.badminton) return;
    if (state.finishedSets.length > closedBefore) {
      _racketFlipEnds();
      return;
    }
    final after = state.rally;
    if (after == null) return;
    final deciding =
        state.config.bestOf > 1 && closedBefore == state.config.bestOf - 1;
    final highBefore = before.currentP1 > before.currentP2
        ? before.currentP1
        : before.currentP2;
    final highAfter = after.currentP1 > after.currentP2
        ? after.currentP1
        : after.currentP2;
    if (deciding && highBefore == 10 && highAfter == 11) _racketFlipEnds();
  }

  /// Tennis: change ends after every odd game of a set (a tie-break counts as
  /// one game) and every 6 points of a tie-break.
  void _racketEndsAfterTennisPoint(int gamesBefore) {
    if (state.config.kind != SportRuleKind.tennis) return;
    final games = _tennisGames();
    if (games > gamesBefore) {
      final set = state.finishedSets.isEmpty ? null : state.finishedSets.last;
      final inSet = set == null ? 0 : set.score1 + set.score2;
      if (tennisChangeEndsAfterGame(inSet)) _racketFlipEnds();
      return;
    }
    final t = state.tennis;
    if (t != null &&
        t.isTiebreak &&
        tennisTiebreakChangeEnds(t.team1GamePoints + t.team2GamePoints)) {
      _racketFlipEnds();
    }
  }

  /// Picks who serves first. Only before the first point of the match;
  /// returns false (and changes nothing) otherwise.
  bool racketPickFirstServer(int team, int playerIndex) {
    if (!state.racketCanPickFirstServer) return false;
    _racketRemember();
    var pick = state.racketPick
        .copyWith(firstTeam: team)
        .withFirstPlayer(team, playerIndex);
    if (state.config.kind == SportRuleKind.badminton) {
      pick = pick.withRightStarter(team, playerIndex);
    }
    state = state.copyWith(racketPick: pick, errorMessage: null);
    return true;
  }

  /// Referee correction of the server at any time. Returns false when it
  /// changes nothing. Badminton: the history becomes known again (no swaps
  /// yet). A later game cannot change the serving team, the rules decide it.
  bool racketCorrectServer(int team, int playerIndex) {
    if (!state.isRacket || state.isMatchComplete) return false;
    if (state.racketCanPickFirstServer) {
      return racketPickFirstServer(team, playerIndex);
    }
    if (state.config.kind == SportRuleKind.tennis) {
      return _racketCorrectTennisServer(team, playerIndex);
    }
    return _racketCorrectBadmintonServer(team, playerIndex);
  }

  bool _racketCorrectBadmintonServer(int team, int playerIndex) {
    final r = state.rally ?? const RallySetState();
    final opening = r.currentP1 + r.currentP2 == 0;
    if (opening && state.racketServerTeam != team) return false;
    _racketRemember();
    final score = team == 1 ? r.currentP1 : r.currentP2;
    state = state.copyWith(
      rally: RallySetState(
        currentP1: r.currentP1,
        currentP2: r.currentP2,
        lastWinner: team,
        swaps1: 0,
        swaps2: 0,
      ),
      racketPick: state.racketPick.withRightStarter(
        team,
        score.isEven ? playerIndex : 1 - playerIndex,
      ),
      errorMessage: null,
    );
    return true;
  }

  bool _racketCorrectTennisServer(int team, int playerIndex) {
    _racketRemember();
    var pick = state.racketPick;
    if (team != state.tennisServerTeam) {
      pick = pick.copyWith(firstTeam: 3 - pick.firstTeam);
    }
    final games = _tennisGames();
    final points =
        (state.tennis?.team1GamePoints ?? 0) +
        (state.tennis?.team2GamePoints ?? 0);
    final turns = state.tennisInTiebreak
        ? tennisTiebreakTurnsServed(
            tiebreakPoints: points,
            isGameServer:
                team ==
                tennisServer(
                  gamesPlayed: games,
                  tiebreak: false,
                  firstServer: pick.firstTeam,
                ),
          )
        : 0;
    final served = tennisTeamServiceGames(
      gamesPlayed: games,
      team: team,
      firstServer: pick.firstTeam,
    );
    state = state.copyWith(
      racketPick: pick.withFirstPlayer(team, (playerIndex - served - turns) % 2),
      errorMessage: null,
    );
    return true;
  }

  /// Changes the halves by hand (the swap button or a drag onto the other half).
  void racketSwitchEnds() {
    if (!state.isRacket) return;
    _racketRemember();
    _racketFlipEnds();
  }

  /// Applies a drop already accepted by `racketResolveDrop`.
  bool racketApplyDrop(CourtDropAction action) {
    if (!state.isRacket) return false;
    switch (action) {
      case SwapPlaces(:final team):
        _racketRemember();
        state = state.copyWith(
          racketPick: state.racketPick.withRightStarter(
            team,
            1 - state.racketPick.rightStarterOf(team),
          ),
        );
        return true;
      case SwitchEnds():
        racketSwitchEnds();
        return true;
      case SetServer(:final team, :final playerIndex):
        return racketCorrectServer(team, playerIndex);
      case SetServerNumber():
        return false;
    }
  }

  /// Takes back the newest step. Returns false when there is nothing to undo
  /// (or a set was closed since).
  bool racketUndoStep() {
    if (!state.canRacketUndo) return false;
    final stack = state.racketUndo;
    final step = stack.last;
    state = state.copyWith(
      rally: step.rally,
      tennis: step.tennis,
      finishedSets: step.finishedSets,
      racketPick: step.pick,
      racketUndo: stack.sublist(0, stack.length - 1),
      errorMessage: null,
    );
    _scheduleLiveSync();
    return true;
  }

  // ════════════════ COMMON ════════════════

  bool get isMatchComplete => state.isMatchComplete;

  /// Returns why the goal was refused (nothing is recorded), or null when the
  /// goal was added.
  FootballBlockReason? footballAddGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    if (current.stoppedWinnerTeam != 0) return FootballBlockReason.matchStopped;
    if (!footballGoalAllowed(current.phase)) {
      return FootballBlockReason.goalOutsidePlay;
    }
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
    return null;
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

  /// [shirt] is only used by card events (null = unknown number). Returns why
  /// the event was refused (nothing is recorded), or null when it was added.
  FootballBlockReason? footballAddEvent(
    String type,
    bool isTeam1, {
    int? shirt,
  }) {
    final current = state.football ?? const FootballLiveState();
    if (current.stoppedWinnerTeam != 0) return FootballBlockReason.matchStopped;
    final FootballLiveState next;
    switch (type) {
      case 'YELLOW_CARD':
      case 'RED_CARD':
        next = footballApplyCard(
          current,
          isTeam1: isTeam1,
          shirt: shirt,
          red: type == 'RED_CARD',
        );
        if (identical(next, current)) return FootballBlockReason.alreadySentOff;
      case 'SUBSTITUTION':
        if (!footballCanSubstitute(current, isTeam1)) {
          return FootballBlockReason.substitutionLimit;
        }
        next = _footballWithEvent(current, type, isTeam1);
      default:
        next = _footballWithEvent(current, type, isTeam1);
    }
    state = state.copyWith(football: next, errorMessage: null);
    _scheduleFootballSync(next);
    return null;
  }

  FootballLiveState _footballWithEvent(
    FootballLiveState current,
    String type,
    bool isTeam1,
  ) => current.copyWith(
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
                        if (entry.value.shirt != null)
                          'shirt': entry.value.shirt,
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
    if (finalSets.length > maxMatchSets) {
      finalSets.removeRange(maxMatchSets, finalSets.length);
    }
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
      } else if (
          state.isOpenScoring &&
          includeEmptyLiteActiveSet &&
          finalSets.length < maxMatchSets) {
        // Keep the next Super Lite set explicitly present on the server after
        // the previous set is closed. Without this 0-0 open entry, a reload
        // can only see the last finished set and the live page falls back to
        // that old score instead of showing the new set at 0-0.
        finalSets.add(const SetScoreData(score1: 0, score2: 0));
      }
    }
    if (state.isOpenScoring &&
        includeEmptyLiteActiveSet &&
        state.config.scoringModel == SportScoringModel.tennisSet &&
        finalSets.length < maxMatchSets) {
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
        // A match stopped for too few players is decided without a shootout.
        final isDraw =
            football.team1Goals == football.team2Goals &&
            football.stoppedWinnerTeam == 0;
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
                    if (entry.value.shirt != null) 'shirt': entry.value.shirt,
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
      if (_isDisposed) return;
      final controller = ref.read(matchControllerProvider(arg));
      await controller.completeMatchWithDetails(
        winnerId: winnerId,
        loserId: loserId,
        finalSets: finalSets,
        overrideReason: state.overrideEnabled
            ? state.overrideReason.trim()
            : null,
        expectedRevision: _nextExpectedRevision() ?? match?.revision,
      );
      if (_isDisposed) return;
      state = state.copyWith(isSubmitting: false, errorMessage: null);
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận', e, stack);
      if (!_isDisposed) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _l10n.scorePanel_completeError(e.toString()),
        );
      }
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

  /// A finished rally/side-out set needs a winner; the server rejects a tied
  /// one ("Không được phép hòa"). Returns true and sets a clear message when
  /// the open set is tied, so callers can stop before any write.
  bool rejectTiedRallySet() {
    final rally = state.rally;
    final model = state.config.scoringModel;
    final isRallyModel = model == SportScoringModel.pickleballSideOut ||
        model == SportScoringModel.rallyPointSet;
    if (!isRallyModel || rally == null) return false;
    if (rally.currentP1 != rally.currentP2) return false;
    state = state.copyWith(
      errorMessage: _l10n.scorePanel_pickleballTieNeedsWinner,
    );
    return true;
  }

  Future<void> finishSet() async {
    if (state.isMatchComplete) {
      state = state.copyWith(
        errorMessage: _l10n.scorePanel_matchAlreadyComplete,
      );
      return;
    }
    if (_rejectIfMaxSetsReached()) return;
    if (rejectTiedRallySet()) return;
    final rally = state.rally;
    final tennis = state.tennis;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (state.config.scoringModel == SportScoringModel.tennisSet) {
      if (tennis == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _l10n.scorePanel_matchNotReady,
        );
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
      // Keep the next open set locally for Lite/Free scoring. Without an
      // explicit 0-0 set, the footer has no active set after Set 1 is closed
      // and the next game can look like it disappeared until a refetch.
      if (state.isOpenScoring &&
          newSets.where((set) => set.isFinished).length < maxMatchSets) {
        newSets = [...newSets, const SetScoreData(score1: 0, score2: 0)];
      }
      state = state.copyWith(
        finishedSets: newSets,
        tennis: const TennisGameState(),
      );
    } else {
      if (rally == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _l10n.scorePanel_matchNotReady,
        );
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
    if (_isDisposed) return;
    _markLocalScorePending();
    final setsToSubmit = _setsForSubmission(includeEmptyLiteActiveSet: true);
    final (p1Sets, p2Sets) = computeMatchSetsWon(setsToSubmit);
    final expectedRevision = _nextExpectedRevision();
    try {
      if (state.isMatchComplete) {
        await completeMatch(state.winnerTeam);
      } else {
        if (_isDisposed) return;
        final controller = ref.read(matchControllerProvider(arg));
        await controller.updateSetsWithDetails(
          p1SetsWon: p1Sets,
          p2SetsWon: p2Sets,
          scoreDetails: setsToSubmit,
          expectedRevision: expectedRevision,
        );
      }
      if (_isDisposed) return;
      if (expectedRevision != null) {
        _lastLocalWriteRevision = expectedRevision + 1;
      }
      // PATCH returns success before the socket echo is guaranteed to reach
      // this client. Re-open the authoritative match stream immediately so
      // the newly closed set survives leaving/re-entering the live panel.
      ref.invalidate(singleMatchProvider(arg));
    } on Exception catch (e) {
      if (_isDisposed) return;
      final msg = e.toString();
      final tournamentNotStartedMessage = scorePanelWriteErrorMessage(
        _l10n,
        e,
      );
      if (tournamentNotStartedMessage != null) {
        state = state.copyWith(errorMessage: tournamentNotStartedMessage);
      } else if (msg.contains('409') ||
          msg.contains('thay đổi từ thiết bị khác')) {
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
    if (_isDisposed) {
      _liveSyncPending = false;
      return;
    }
    final sets = List<SetScoreData>.from(state.finishedSets);
    Map<String, dynamic>? liveState;
    if (rally != null) {
      sets.add(SetScoreData(score1: rally.currentP1, score2: rally.currentP2));
      liveState = _pickleballLiveState();
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
    if (sets.length > maxMatchSets) {
      sets.removeRange(maxMatchSets, sets.length);
    }
    final (p1Sets, p2Sets) = computeMatchSetsWon(state.finishedSets);
    final requestSignature = _scoreSignature(state);
    final expectedRevision = _nextExpectedRevision();
    _pendingScoreSignature = requestSignature;
    _pendingBaseRevision = expectedRevision;
    _liveSyncPending = false;
    _liveSyncInFlight = true;
    try {
      if (_isDisposed) return;
      final controller = ref.read(matchControllerProvider(arg));
      await controller.updateSetsWithDetails(
        p1SetsWon: p1Sets,
        p2SetsWon: p2Sets,
        scoreDetails: sets,
        scoreDetailsExtras: liveState == null
            ? null
            : {'liveState': liveState},
        expectedRevision: expectedRevision,
        refreshSurfaces: false,
      );
      if (_isDisposed) return;
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
      if (_isDisposed) return;
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
      if (!_isDisposed && _liveSyncPending && !state.isMatchComplete) {
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
