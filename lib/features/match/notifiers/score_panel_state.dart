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
  }) =>
      TennisGameState(
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

  RallySetState copyWith({int? currentP1, int? currentP2}) =>
      RallySetState(
        currentP1: currentP1 ?? this.currentP1,
        currentP2: currentP2 ?? this.currentP2,
      );
}

/// State tổng thể của ScorePanelNotifier.
class ScorePanelState {
  final SportConfig config;
  final List<SetScoreData> finishedSets;
  final TennisGameState? tennis;
  final PickleballServeState? pickleball;
  final RallySetState? rally;
  final bool isSubmitting;
  final String? errorMessage;
  final bool overrideEnabled;
  final String overrideReason;

  const ScorePanelState({
    required this.config,
    this.finishedSets = const [],
    this.tennis,
    this.pickleball,
    this.rally,
    this.isSubmitting = false,
    this.errorMessage,
    this.overrideEnabled = false,
    this.overrideReason = '',
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

  /// Kiểm tra trận đã kết thúc chưa (số set thắng >= setsToWin).
  bool get isMatchComplete =>
      team1SetWins >= config.setsToWin || team2SetWins >= config.setsToWin;

  /// Đội thắng (0 = chưa, 1 = Đội 1, 2 = Đội 2).
  int get winnerTeam {
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
    bool? isSubmitting,
    String? errorMessage,
    bool? overrideEnabled,
    String? overrideReason,
  }) =>
      ScorePanelState(
        config: config ?? this.config,
        finishedSets: finishedSets ?? this.finishedSets,
        tennis: tennis ?? this.tennis,
        pickleball: pickleball ?? this.pickleball,
        rally: rally ?? this.rally,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: errorMessage,
        overrideEnabled: overrideEnabled ?? this.overrideEnabled,
        overrideReason: overrideReason ?? this.overrideReason,
      );
}
