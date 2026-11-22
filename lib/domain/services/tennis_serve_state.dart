/// Tennis doubles serve and receive order (ITF Rules of Tennis 2026: Rules 5b,
/// 14, 15, 17, 27c, 27e and Appendix VI) and the court state saved through
/// `PATCH /matches/:id/court-state` (shared with Backend and Web).
///
/// Ported from the approved reference engine (tennis-rules.js). Unlike the
/// reference, nothing blocks scoring: a missing choice means player 0, and a
/// missing first serving team means team 1. Teams are 1 and 2, players 0 and 1.
library;

const _kind = 'TENNIS';
const _version = 1;
const _maxSets = 5;

const Object _unset = Object();

int? _team(Object? raw) => raw == 1 || raw == 2 ? raw as int : null;
int? _player(Object? raw) => raw == 0 || raw == 1 ? raw as int : null;
Map _map(Object? raw) => raw is Map ? raw : const {};

/// What each team chose for one set: who serves its first service game and
/// who receives in the right (deuce) court. Null = not chosen (player 0).
class TennisSetChoice {
  const TennisSetChoice({
    this.serveFirst1,
    this.serveFirst2,
    this.receiveRight1,
    this.receiveRight2,
  });

  factory TennisSetChoice.fromJson(Object? raw) {
    final serve = _map(_map(raw)['serveFirst']);
    final receive = _map(_map(raw)['receiveRight']);
    return TennisSetChoice(
      serveFirst1: _player(serve['team1']),
      serveFirst2: _player(serve['team2']),
      receiveRight1: _player(receive['team1']),
      receiveRight2: _player(receive['team2']),
    );
  }

  final int? serveFirst1;
  final int? serveFirst2;
  final int? receiveRight1;
  final int? receiveRight2;

  int? serveFirstOf(int team) => team == 1 ? serveFirst1 : serveFirst2;
  int? receiveRightOf(int team) => team == 1 ? receiveRight1 : receiveRight2;

  TennisSetChoice withServeFirst(int team, int? player) => TennisSetChoice(
    serveFirst1: team == 1 ? player : serveFirst1,
    serveFirst2: team == 2 ? player : serveFirst2,
    receiveRight1: receiveRight1,
    receiveRight2: receiveRight2,
  );

  TennisSetChoice withReceiveRight(int team, int player) => TennisSetChoice(
    serveFirst1: serveFirst1,
    serveFirst2: serveFirst2,
    receiveRight1: team == 1 ? player : receiveRight1,
    receiveRight2: team == 2 ? player : receiveRight2,
  );

  Map<String, dynamic> toJson() => {
    'serveFirst': {'team1': serveFirst1, 'team2': serveFirst2},
    'receiveRight': {'team1': receiveRight1, 'team2': receiveRight2},
  };
}

/// A player of a team pinned to one game of one set (Rule 27e fix, No-Ad
/// deciding-point receiver).
class TennisPlayerMark {
  const TennisPlayerMark({
    required this.set,
    required this.game,
    required this.team,
    required this.playerIndex,
  });

  static TennisPlayerMark? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final set = raw['set'];
    final game = raw['game'];
    final team = _team(raw['team']);
    final player = _player(raw['playerIndex']);
    if (set is! int || set < 0 || game is! int || game < 0) return null;
    if (team == null || player == null) return null;
    return TennisPlayerMark(
      set: set,
      game: game,
      team: team,
      playerIndex: player,
    );
  }

  final int set;
  final int game;
  final int team;
  final int playerIndex;

  bool isAt(int setIndex, int gameIndex) =>
      set == setIndex && game == gameIndex;

  Map<String, dynamic> toJson() => {
    'set': set,
    'game': game,
    'team': team,
    'playerIndex': playerIndex,
  };
}

/// Referee choices for a tennis doubles match. `sets[i]` belongs to the set
/// played after i finished sets. [endsFlipped]: team 1 on the top half.
class TennisCourtState {
  const TennisCourtState({
    this.firstServerTeam,
    this.sets = const [],
    this.gameFix,
    this.decidingReceiver,
    this.endsFlipped = false,
  });

  /// Missing, foreign or invalid data falls back to the defaults; server
  /// fields such as `updatedAt` / `updatedBy` are ignored.
  factory TennisCourtState.fromJson(Object? raw) {
    if (raw is! Map || raw['kind'] != _kind) return const TennisCourtState();
    final sets = raw['sets'];
    return TennisCourtState(
      firstServerTeam: _team(raw['firstServerTeam']),
      sets: sets is List
          ? [for (final s in sets.take(_maxSets)) TennisSetChoice.fromJson(s)]
          : const [],
      gameFix: TennisPlayerMark.fromJson(raw['gameFix']),
      decidingReceiver: TennisPlayerMark.fromJson(raw['decidingReceiver']),
      endsFlipped: raw['endsFlipped'] == true,
    );
  }

  final int? firstServerTeam;
  final List<TennisSetChoice> sets;
  final TennisPlayerMark? gameFix;
  final TennisPlayerMark? decidingReceiver;
  final bool endsFlipped;

  TennisSetChoice choiceAt(int setIndex) =>
      setIndex < sets.length ? sets[setIndex] : const TennisSetChoice();

  /// Replaces the choice of [setIndex], adding empty sets before it if needed.
  TennisCourtState withChoice(int setIndex, TennisSetChoice choice) {
    final next = [
      for (var i = 0; i <= setIndex || i < sets.length; i++) choiceAt(i),
    ];
    next[setIndex] = choice;
    return copyWith(sets: List.unmodifiable(next));
  }

  TennisCourtState copyWith({
    Object? firstServerTeam = _unset,
    List<TennisSetChoice>? sets,
    Object? gameFix = _unset,
    Object? decidingReceiver = _unset,
    bool? endsFlipped,
  }) => TennisCourtState(
    firstServerTeam: identical(firstServerTeam, _unset)
        ? this.firstServerTeam
        : firstServerTeam as int?,
    sets: sets ?? this.sets,
    gameFix: identical(gameFix, _unset)
        ? this.gameFix
        : gameFix as TennisPlayerMark?,
    decidingReceiver: identical(decidingReceiver, _unset)
        ? this.decidingReceiver
        : decidingReceiver as TennisPlayerMark?,
    endsFlipped: endsFlipped ?? this.endsFlipped,
  );

  Map<String, dynamic> toJson() => {
    'version': _version,
    'kind': _kind,
    'firstServerTeam': firstServerTeam,
    'sets': [
      for (final s in sets.isEmpty ? const [TennisSetChoice()] : sets)
        s.toJson(),
    ].take(_maxSets).toList(),
    'gameFix': gameFix?.toJson(),
    'decidingReceiver': decidingReceiver?.toJson(),
    'endsFlipped': endsFlipped,
  };

  // Two states are equal when they save the same JSON.
  @override
  bool operator ==(Object other) =>
      other is TennisCourtState && '${other.toJson()}' == '${toJson()}';

  @override
  int get hashCode => '${toJson()}'.hashCode;
}

/// The score as the serve rules need it.
class TennisScoreInput {
  const TennisScoreInput({
    this.setIndex = 0,
    this.gamesBefore = 0,
    this.games1 = 0,
    this.games2 = 0,
    this.points1 = 0,
    this.points2 = 0,
    this.isTiebreak = false,
    this.noAd = false,
  });

  /// Finished sets.
  final int setIndex;

  /// Games of all finished sets (a tie-break counts as one game).
  final int gamesBefore;

  /// Games of the set being played.
  final int games1;
  final int games2;

  /// Points of the game (or tie-break) being played.
  final int points1;
  final int points2;
  final bool isTiebreak;
  final bool noAd;

  int get gameInSet => games1 + games2;
  int get pointsPlayed => points1 + points2;

  /// A tie-break at 0-0 in games is the match tie-break replacing a set.
  bool get isMatchTiebreak => isTiebreak && gameInSet == 0;
  bool get notStarted => setIndex == 0 && gameInSet == 0 && pointsPlayed == 0;
  bool get isDecidingPoint =>
      noAd && !isTiebreak && points1 == 3 && points2 == 3;
}

class TennisServe {
  const TennisServe({
    required this.team,
    required this.playerIndex,
    required this.serveRight,
  });

  final int team;
  final int playerIndex;

  /// Serving from the right (deuce) court.
  final bool serveRight;
}

class TennisReceiver {
  const TennisReceiver({required this.team, required this.playerIndex});

  final int team;
  final int playerIndex;
}

enum TennisRole { serve, receive }

/// What the court reminds the referee of; never blocks scoring.
enum TennisHint { pickServer, swapReceiver, decidingReceiver }

enum TennisCellActionKind {
  pickServer,
  correctServer,
  pickReceiveRight,
  fixReceiver,
  decidingReceiver,
  switchEnds,
}

/// One menu item for a tapped player. [playerIndex] is the player the action
/// puts in place: the server, or the new right-court receiver for a swap.
class TennisCellAction {
  const TennisCellAction(
    this.kind, {
    required this.team,
    required this.playerIndex,
  });

  final TennisCellActionKind kind;
  final int team;
  final int playerIndex;
}

int _other(int team) => 3 - team;

int _firstTeam(TennisCourtState c) => c.firstServerTeam ?? 1;

/// Team serving standard game [gi] of the set (Rule 14: alternate each game).
int _teamForGame(TennisScoreInput s, TennisCourtState c, int gi) =>
    (s.gamesBefore + gi).isEven ? _firstTeam(c) : _other(_firstTeam(c));

int _serviceGamesBefore(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int gi,
) {
  var count = 0;
  for (var j = 0; j < gi; j++) {
    if (_teamForGame(s, c, j) == team) count++;
  }
  return count;
}

/// Tie-break turn: point 0 is turn 0, points 1-2 turn 1, 3-4 turn 2 (Rule 5b).
int _tiebreakTurn(int points) => points == 0 ? 0 : (points + 1) ~/ 2;

int _serverTeam(TennisScoreInput s, TennisCourtState c) {
  final opener = _teamForGame(s, c, s.gameInSet);
  if (!s.isTiebreak) return opener;
  return _tiebreakTurn(s.pointsPlayed).isEven ? opener : _other(opener);
}

/// Service turns the serving [team] already had in this set (the tie-break
/// continues the rotation of the set, Rule 5b).
int _turnsBefore(TennisScoreInput s, TennisCourtState c, int team) {
  final gi = s.gameInSet;
  final games = _serviceGamesBefore(s, c, team, gi);
  if (!s.isTiebreak) return games;
  final turn = _tiebreakTurn(s.pointsPlayed);
  final opener = _teamForGame(s, c, gi);
  return games + (team == opener ? turn ~/ 2 : (turn - 1) ~/ 2);
}

TennisPlayerMark? _decidingChoice(TennisScoreInput s, TennisCourtState c) {
  final d = c.decidingReceiver;
  return d != null && d.isAt(s.setIndex, s.gameInSet) ? d : null;
}

/// Rule 17: right court first, then alternate. No-Ad deciding point: the
/// court of the receiver the receiving team chose.
bool _serveRight(TennisScoreInput s, TennisCourtState c, int servingTeam) {
  if (!s.isDecidingPoint) return s.pointsPlayed.isEven;
  final d = _decidingChoice(s, c);
  return d == null ||
      d.playerIndex == tennisRightReceiver(s, c, _other(servingTeam));
}

TennisServe tennisServeOf(TennisScoreInput s, TennisCourtState c) {
  final team = _serverTeam(s, c);
  final first = c.choiceAt(s.setIndex).serveFirstOf(team) ?? 0;
  return TennisServe(
    team: team,
    playerIndex: first ^ (_turnsBefore(s, c, team) % 2),
    serveRight: _serveRight(s, c, team),
  );
}

/// Player of [team] receiving in the right court: the Rule 27e fix of this
/// game, else the set choice, else player 0.
int tennisRightReceiver(TennisScoreInput s, TennisCourtState c, int team) {
  final fix = c.gameFix;
  if (fix != null && fix.team == team && fix.isAt(s.setIndex, s.gameInSet)) {
    return fix.playerIndex;
  }
  return c.choiceAt(s.setIndex).receiveRightOf(team) ?? 0;
}

TennisReceiver tennisReceiverOf(TennisScoreInput s, TennisCourtState c) {
  final serve = tennisServeOf(s, c);
  final team = _other(serve.team);
  final right = tennisRightReceiver(s, c, team);
  return TennisReceiver(
    team: team,
    playerIndex: serve.serveRight ? right : 1 - right,
  );
}

/// A team chooses freely until it took part in its first serving / receiving
/// turn of the set (Rules 14, 15).
bool tennisIsLocked(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  TennisRole role,
) {
  final opener = _teamForGame(s, c, 0);
  final opens = role == TennisRole.serve ? team == opener : team != opener;
  final first = opens ? 0 : 1;
  if (s.isMatchTiebreak) return s.pointsPlayed > first;
  final gi = s.gameInSet;
  return gi > first || (gi == first && s.pointsPlayed > 0);
}

/// Before the first point: the tapped team serves first (toss) with the tapped
/// player. Later: the team's first server of the set, until it is locked.
TennisCourtState? tennisPickServer(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  if (s.notStarted) {
    final current = c.choiceAt(0);
    final keep = c.firstServerTeam == team
        ? current
        : current.withServeFirst(1, null).withServeFirst(2, null);
    return c
        .copyWith(firstServerTeam: team)
        .withChoice(0, keep.withServeFirst(team, player));
  }
  if (tennisIsLocked(s, c, team, TennisRole.serve)) return null;
  return c.withChoice(
    s.setIndex,
    c.choiceAt(s.setIndex).withServeFirst(team, player),
  );
}

TennisCourtState? tennisPickReceiveRight(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  if (tennisIsLocked(s, c, team, TennisRole.receive)) return null;
  return c.withChoice(
    s.setIndex,
    c.choiceAt(s.setIndex).withReceiveRight(team, player),
  );
}

/// Rule 27c: [player] is serving now; the team's rotation goes on from there
/// for the rest of the set.
TennisCourtState? tennisCorrectServer(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  if (_serverTeam(s, c) != team) return null;
  final first = player ^ (_turnsBefore(s, c, team) % 2);
  return c.withChoice(
    s.setIndex,
    c.choiceAt(s.setIndex).withServeFirst(team, first),
  );
}

/// Rule 27e: [player] of the receiving [team] receives in the right court
/// until the end of this game only.
TennisCourtState? tennisFixReceiver(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  if (_serverTeam(s, c) == team) return null;
  return c.copyWith(gameFix: _mark(s, team, player));
}

/// Appendix VI (No-Ad): the receiving team picks who returns the deciding point.
TennisCourtState? tennisChooseDecidingReceiver(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  if (!s.isDecidingPoint || _serverTeam(s, c) == team) return null;
  return c.copyWith(decidingReceiver: _mark(s, team, player));
}

TennisPlayerMark _mark(TennisScoreInput s, int team, int player) =>
    TennisPlayerMark(
      set: s.setIndex,
      game: s.gameInSet,
      team: team,
      playerIndex: player,
    );

TennisCourtState tennisToggleEnds(TennisCourtState c) =>
    c.copyWith(endsFlipped: !c.endsFlipped);

/// [player] of [team] serves now: a free pick while allowed, a Rule 27c
/// correction once locked. Null when [team] is not serving (after the start).
TennisCourtState? tennisSetServer(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  if (s.notStarted) return tennisPickServer(s, c, team, player);
  if (_serverTeam(s, c) != team) return null;
  return tennisIsLocked(s, c, team, TennisRole.serve)
      ? tennisCorrectServer(s, c, team, player)
      : tennisPickServer(s, c, team, player);
}

/// A tap picks the server at once (no menu): before anyone was chosen, or
/// when [team] serves now and has not chosen for this set yet.
bool tennisQuickPick(TennisScoreInput s, TennisCourtState c, int team) {
  if (s.notStarted && c.firstServerTeam == null) return true;
  return _serverTeam(s, c) == team &&
      c.choiceAt(s.setIndex).serveFirstOf(team) == null &&
      !tennisIsLocked(s, c, team, TennisRole.serve);
}

TennisHint? tennisHint(TennisScoreInput s, TennisCourtState c) {
  final server = _serverTeam(s, c);
  if (s.isDecidingPoint && _decidingChoice(s, c) == null) {
    return TennisHint.decidingReceiver;
  }
  if (tennisQuickPick(s, c, server)) return TennisHint.pickServer;
  if (!tennisIsLocked(s, c, _other(server), TennisRole.receive)) {
    return TennisHint.swapReceiver;
  }
  return null;
}

/// Menu for a tap on [player] of [team]; always ends with switch ends.
List<TennisCellAction> tennisCellActions(
  TennisScoreInput s,
  TennisCourtState c,
  int team,
  int player,
) {
  TennisCellAction act(TennisCellActionKind kind, [int? target]) =>
      TennisCellAction(kind, team: team, playerIndex: target ?? player);
  final serve = tennisServeOf(s, c);
  if (serve.team == team) {
    final locked = tennisIsLocked(s, c, team, TennisRole.serve);
    return [
      if (serve.playerIndex != player)
        act(
          locked
              ? TennisCellActionKind.correctServer
              : TennisCellActionKind.pickServer,
        ),
      act(TennisCellActionKind.switchEnds),
    ];
  }
  final partner = 1 - tennisRightReceiver(s, c, team);
  final locked = tennisIsLocked(s, c, team, TennisRole.receive);
  return [
    if (s.isDecidingPoint) act(TennisCellActionKind.decidingReceiver),
    if (s.notStarted) act(TennisCellActionKind.pickServer),
    act(
      locked
          ? TennisCellActionKind.fixReceiver
          : TennisCellActionKind.pickReceiveRight,
      partner,
    ),
    act(TennisCellActionKind.switchEnds),
  ];
}

TennisCourtState? tennisApplyAction(
  TennisScoreInput s,
  TennisCourtState c,
  TennisCellAction a,
) => switch (a.kind) {
  TennisCellActionKind.pickServer => tennisPickServer(
    s,
    c,
    a.team,
    a.playerIndex,
  ),
  TennisCellActionKind.correctServer => tennisCorrectServer(
    s,
    c,
    a.team,
    a.playerIndex,
  ),
  TennisCellActionKind.pickReceiveRight => tennisPickReceiveRight(
    s,
    c,
    a.team,
    a.playerIndex,
  ),
  TennisCellActionKind.fixReceiver => tennisFixReceiver(
    s,
    c,
    a.team,
    a.playerIndex,
  ),
  TennisCellActionKind.decidingReceiver => tennisChooseDecidingReceiver(
    s,
    c,
    a.team,
    a.playerIndex,
  ),
  TennisCellActionKind.switchEnds => tennisToggleEnds(c),
};
