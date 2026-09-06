import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Trạng thái game point cho Tennis (0,1,2,3 = 0,15,30,40, 4+ = Ad/Deuce).
class TennisGameState {
  final int team1GamePoints;
  final int team2GamePoints;
  final bool isTiebreak;

  const TennisGameState({
    this.team1GamePoints = 0,
    this.team2GamePoints = 0,
    this.isTiebreak = false,
  });

  TennisGameState copyWith({
    int? team1GamePoints,
    int? team2GamePoints,
    bool? isTiebreak,
  }) => TennisGameState(
    team1GamePoints: team1GamePoints ?? this.team1GamePoints,
    team2GamePoints: team2GamePoints ?? this.team2GamePoints,
    isTiebreak: isTiebreak ?? this.isTiebreak,
  );
}

/// Trạng thái giao bóng cho Pickleball Side-Out.
class PickleballServeState {
  final bool isTeam1Serving;
  final int serverNumber; // 1 | 2

  const PickleballServeState({
    this.isTeam1Serving = true,
    this.serverNumber = 1,
  });

  PickleballServeState copyWith({bool? isTeam1Serving, int? serverNumber}) =>
      PickleballServeState(
        isTeam1Serving: isTeam1Serving ?? this.isTeam1Serving,
        serverNumber: serverNumber ?? this.serverNumber,
      );
}

/// Trạng thái set hiện tại cho Rally Point (Badminton, Table Tennis, Pickleball Rally).
class RallySetState {
  final int currentP1;
  final int currentP2;

  const RallySetState({this.currentP1 = 0, this.currentP2 = 0});

  RallySetState copyWith({int? currentP1, int? currentP2}) => RallySetState(
    currentP1: currentP1 ?? this.currentP1,
    currentP2: currentP2 ?? this.currentP2,
  );
}

const Object _footballUnset = Object();

const footballPhases = <String>{
  'FIRST_HALF',
  'HALFTIME',
  'SECOND_HALF',
  'STOPPAGE_TIME',
  'FULL_TIME',
  'EXTRA_TIME_FIRST_HALF',
  'EXTRA_TIME_BREAK',
  'EXTRA_TIME_SECOND_HALF',
  'PENALTY_SHOOTOUT',
  'COMPLETED',
};

const footballEditablePhases = <String>[
  'FIRST_HALF',
  'HALFTIME',
  'SECOND_HALF',
  'STOPPAGE_TIME',
  'FULL_TIME',
  'EXTRA_TIME_FIRST_HALF',
  'EXTRA_TIME_BREAK',
  'EXTRA_TIME_SECOND_HALF',
  'PENALTY_SHOOTOUT',
];

class FootballLiveState {
  final int team1Goals;
  final int team2Goals;
  final String phase;
  final int minute;
  final int addedMinute;
  final List<FootballEvent> events;
  final int? shootoutTeam1Goals;
  final int? shootoutTeam2Goals;

  const FootballLiveState({
    this.team1Goals = 0,
    this.team2Goals = 0,
    this.phase = 'FIRST_HALF',
    this.minute = 0,
    this.addedMinute = 0,
    this.events = const [],
    this.shootoutTeam1Goals,
    this.shootoutTeam2Goals,
  });

  /// Compatibility getter: a decisive Football result is score-based now.
  /// The phase and match clock do not participate in completion readiness.
  bool get isDecisivePhase => isMatchComplete;

  bool get hasValidShootout =>
      shootoutTeam1Goals != null &&
      shootoutTeam2Goals != null &&
      shootoutTeam1Goals != shootoutTeam2Goals;

  /// 0 = undecidable, 1 = team 1, 2 = team 2.
  /// Football completion is based on goals; a draw needs an unequal shootout.
  /// The phase and match clock are informational only.
  int get winnerTeam {
    if (team1Goals != team2Goals) {
      return team1Goals > team2Goals ? 1 : 2;
    }
    if (!hasValidShootout) return 0;
    return shootoutTeam1Goals! > shootoutTeam2Goals! ? 1 : 2;
  }

  bool get isMatchComplete => winnerTeam != 0;

  FootballLiveState copyWith({
    int? team1Goals,
    int? team2Goals,
    String? phase,
    int? minute,
    int? addedMinute,
    List<FootballEvent>? events,
    Object? shootoutTeam1Goals = _footballUnset,
    Object? shootoutTeam2Goals = _footballUnset,
  }) => FootballLiveState(
    team1Goals: team1Goals ?? this.team1Goals,
    team2Goals: team2Goals ?? this.team2Goals,
    phase: phase ?? this.phase,
    minute: minute ?? this.minute,
    addedMinute: addedMinute ?? this.addedMinute,
    events: events ?? this.events,
    shootoutTeam1Goals: identical(shootoutTeam1Goals, _footballUnset)
        ? this.shootoutTeam1Goals
        : shootoutTeam1Goals as int?,
    shootoutTeam2Goals: identical(shootoutTeam2Goals, _footballUnset)
        ? this.shootoutTeam2Goals
        : shootoutTeam2Goals as int?,
  );
}

class FootballEvent {
  final String type;
  final bool isTeam1;
  final int minute;
  final int addedMinute;
  const FootballEvent({
    required this.type,
    required this.isTeam1,
    required this.minute,
    this.addedMinute = 0,
  });
}

/// State tổng thể của ScorePanelNotifier.
class ScorePanelState {
  final SportConfig config;
  final List<SetScoreData> finishedSets;
  final TennisGameState? tennis;
  final PickleballServeState? pickleball;
  final RallySetState? rally;
  final FootballLiveState? football;
  final bool isSubmitting;
  final bool isServerTerminal;
  final String? errorMessage;
  final bool overrideEnabled;
  final String overrideReason;
  final bool isLite;

  const ScorePanelState({
    required this.config,
    this.finishedSets = const [],
    this.tennis,
    this.pickleball,
    this.rally,
    this.football,
    this.isSubmitting = false,
    this.isServerTerminal = false,
    this.errorMessage,
    this.overrideEnabled = false,
    this.overrideReason = '',
    this.isLite = false,
  });

  /// Số set thắng.
  int get team1SetWins {
    int t = 0;
    for (final s in finishedSets) {
      if (s.score1 > s.score2) t++;
    }
    return t;
  }

  int get team2SetWins {
    int t = 0;
    for (final s in finishedSets) {
      if (s.score2 > s.score1) t++;
    }
    return t;
  }

  /// A scoring preset can be open even when the legacy `isLite` flag was not
  /// carried by an older match snapshot. Keep the resolved rule as a second
  /// source so a stale snapshot cannot silently fall back to BO3.
  bool get isOpenScoring => isLite || config.isOpenScoring;

  /// Football uses its own phase/goal state instead of finished sets.
  ///
  /// Super Lite is an open scorecard: each manually closed set is history,
  /// not a signal that the match is over. The server-terminal flag is the
  /// only terminal state for Lite; otherwise the configured set target applies
  /// to strict presets only.
  bool get isMatchComplete =>
      isServerTerminal ||
      (football?.isMatchComplete ??
          (!isOpenScoring &&
              (team1SetWins >= config.setsToWin ||
                  team2SetWins >= config.setsToWin)));

  /// Đội thắng (0 = chưa, 1 = Đội 1, 2 = Đội 2).
  int get winnerTeam {
    final footballWinner = football?.winnerTeam;
    if (footballWinner != null) return footballWinner;
    if (isOpenScoring && !isServerTerminal) return 0;
    if (team1SetWins >= config.setsToWin) return 1;
    if (team2SetWins >= config.setsToWin) return 2;
    return 0;
  }

  ScorePanelState copyWith({
    SportConfig? config,
    List<SetScoreData>? finishedSets,
    TennisGameState? tennis,
    PickleballServeState? pickleball,
    RallySetState? rally,
    FootballLiveState? football,
    bool? isSubmitting,
    bool? isServerTerminal,
    String? errorMessage,
    bool? overrideEnabled,
    String? overrideReason,
    bool? isLite,
  }) => ScorePanelState(
    config: config ?? this.config,
    finishedSets: finishedSets ?? this.finishedSets,
    tennis: tennis ?? this.tennis,
    pickleball: pickleball ?? this.pickleball,
    rally: rally ?? this.rally,
    football: football ?? this.football,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isServerTerminal: isServerTerminal ?? this.isServerTerminal,
    errorMessage: errorMessage,
    overrideEnabled: overrideEnabled ?? this.overrideEnabled,
    overrideReason: overrideReason ?? this.overrideReason,
    isLite: isLite ?? this.isLite,
  );
}
