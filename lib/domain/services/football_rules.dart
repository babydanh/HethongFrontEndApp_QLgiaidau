import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';

/// Pure football rules: cards, players on the field, substitutions and when a
/// goal may be recorded. Mirrors the Football part of
/// openspec/changes/cach-bam-diem-cac-mon/reference/scoring-engine.js.
/// Everything is derived from [FootballLiveState.events], so data saved before
/// shirt numbers existed keeps working.

const footballTeamSize = 11;
const footballMinPlayers = 7;

/// Default substitution cap per team. `sportRules` has no key for it yet, so
/// callers pass `subsLimit` only when a real setting appears.
const footballDefaultSubsLimit = 5;

const _yellowCard = 'YELLOW_CARD';
const _redCard = 'RED_CARD';
const _substitution = 'SUBSTITUTION';

/// Phases where the ball is in play (regular halves, stoppage time, extra
/// time halves). Half-time, full-time, breaks and the shootout are excluded.
const _goalPhases = <String>{
  'FIRST_HALF',
  'SECOND_HALF',
  'STOPPAGE_TIME',
  'EXTRA_TIME_FIRST_HALF',
  'EXTRA_TIME_SECOND_HALF',
};

/// Why a football action was refused; the UI maps it to a warning.
enum FootballBlockReason {
  goalOutsidePlay,
  matchStopped,
  alreadySentOff,
  substitutionLimit,
}

bool footballGoalAllowed(String phase) => _goalPhases.contains(phase);

int _countEvents(
  FootballLiveState s,
  bool isTeam1,
  String type, {
  int? shirt,
}) => s.events
    .where(
      (e) =>
          e.type == type &&
          e.isTeam1 == isTeam1 &&
          (shirt == null || e.shirt == shirt),
    )
    .length;

int footballPlayersOnField(FootballLiveState s, bool isTeam1) =>
    footballTeamSize - _countEvents(s, isTeam1, _redCard);

int footballSubsUsed(FootballLiveState s, bool isTeam1) =>
    _countEvents(s, isTeam1, _substitution);

bool footballCanSubstitute(
  FootballLiveState s,
  bool isTeam1, {
  int subsLimit = footballDefaultSubsLimit,
}) => footballSubsUsed(s, isTeam1) < subsLimit;

/// Records a card. A second yellow for the same shirt adds a red right after
/// it. Fewer than [footballMinPlayers] players stops the match in favour of
/// the other team. Returns [s] itself (same instance) when nothing changes:
/// the match is already stopped or that shirt is already sent off.
FootballLiveState footballApplyCard(
  FootballLiveState s, {
  required bool isTeam1,
  required int? shirt,
  required bool red,
}) {
  if (s.stoppedWinnerTeam != 0) return s;
  if (shirt != null && _countEvents(s, isTeam1, _redCard, shirt: shirt) > 0) {
    return s;
  }

  FootballEvent card(String type) => FootballEvent(
    type: type,
    isTeam1: isTeam1,
    minute: s.minute,
    addedMinute: s.addedMinute,
    shirt: shirt,
  );

  final secondYellow =
      !red &&
      shirt != null &&
      _countEvents(s, isTeam1, _yellowCard, shirt: shirt) >= 1;
  final next = s.copyWith(
    events: [
      ...s.events,
      card(red ? _redCard : _yellowCard),
      if (secondYellow) card(_redCard),
    ],
  );
  return next.copyWith(stoppedWinnerTeam: footballStoppedWinnerTeam(next));
}

/// 0 = both teams have enough players, otherwise the team that wins because
/// the other one has fewer than [footballMinPlayers] players on the field.
int footballStoppedWinnerTeam(FootballLiveState s) {
  if (footballPlayersOnField(s, true) < footballMinPlayers) return 2;
  if (footballPlayersOnField(s, false) < footballMinPlayers) return 1;
  return 0;
}
