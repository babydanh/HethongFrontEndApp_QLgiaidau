import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_step_summary.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:flutter_test/flutter_test.dart';

// 12:00 in Vietnam on 2026-11-03.
final _now = DateTime.utc(2026, 11, 3, 5);

Tournament _tournament(
  String status, {
  DateTime? registrationEnd,
  DateTime? endDate,
  bool withDates = true,
}) => Tournament.fromJson({
  'name': 'Step summary cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  if (withDates) 'registrationStartDate': '2026-10-01T00:00:00Z',
  if (registrationEnd != null)
    'registrationEndDate': registrationEnd.toIso8601String(),
  if (withDates) 'startDate': '2026-11-01T00:00:00Z',
  if (endDate != null) 'endDate': endDate.toIso8601String(),
}, 't1');

TournamentDivision _division(
  String id, {
  String? status,
  int participantCount = 0,
}) => TournamentDivision(
  id: id,
  name: 'Division $id',
  matchType: 'SINGLES',
  status: status,
  participantCount: participantCount,
);

OrganizerOpsParticipant _participant(
  String id,
  String divisionId, {
  String status = 'COMPLETE',
  bool isPaid = true,
  double? entryFee,
  bool mock = false,
}) => OrganizerOpsParticipant(
  id: id,
  teamStatus: status,
  isPaid: isPaid,
  entryFee: entryFee,
  divisionId: divisionId,
  members: [
    OrganizerOpsMember(userId: 'u$id', fullName: 'Player $id', isMock: mock),
  ],
);

MatchModel _match(
  String id,
  String divisionId, {
  String status = 'SCHEDULED',
  String? courtName,
  DateTime? scheduledTime,
  bool isBye = false,
}) => MatchModel(
  id: id,
  round: 1,
  matchNumber: 1,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  team1Id: 'a$id',
  team2Id: 'b$id',
  team1Name: 'Team A',
  team2Name: 'Team B',
  status: status,
  isBye: isBye,
  divisionId: divisionId,
  courtName: courtName,
  scheduledTime: scheduledTime,
  updatedAt: DateTime.utc(2026, 1, 1),
);

StepSummary _build(
  Tournament tournament, {
  List<TournamentDivision> divisions = const [],
  List<OrganizerOpsParticipant> participants = const [],
  List<MatchModel> matches = const [],
  SummaryLoad participantsLoad = SummaryLoad.ready,
  SummaryLoad matchesLoad = SummaryLoad.ready,
}) => buildStepSummary(
  tournament: tournament,
  divisions: divisions,
  participants: participants,
  participantsLoad: participantsLoad,
  matches: matches,
  matchesLoad: matchesLoad,
  now: _now,
);

StepState _step(StepSummary s, StepKey key) =>
    s.steps.firstWhere((step) => step.key == key);

StepTodo? _todo(StepState step, String key) {
  for (final todo in step.todos) {
    if (todo.key == key) return todo;
  }
  return null;
}

final _past = DateTime.utc(2026, 10, 20);
final _future = DateTime.utc(2026, 12, 1);

void main() {
  test('TC-STEP-01 a closed division without athletes is listed once', () {
    final summary = _build(
      _tournament('registration_closed', registrationEnd: _past),
      divisions: [_division('a'), _division('b'), _division('c')],
      participants: [_participant('1', 'a'), _participant('2', 'b')],
    );

    final step = _step(summary, StepKey.registration);
    expect(_todo(step, 'emptyDivisions')?.count, 1);
    expect(step.state, StepStatus.attention);
    // Two divisions have athletes and registration is closed for both.
    expect(step.percent, 100);
  });

  test('TC-STEP-02 only approved, unpaid, real entries count as unpaid', () {
    final summary = _build(
      _tournament('registration', registrationEnd: _future),
      divisions: [_division('a', participantCount: 4)],
      participants: [
        _participant('unpaid', 'a', isPaid: false, entryFee: 100000),
        _participant('free', 'a', isPaid: false, entryFee: 0),
        _participant('paid', 'a'),
        _participant('mock', 'a', isPaid: false, entryFee: 100000, mock: true),
        _participant(
          'rejected',
          'a',
          status: 'REJECTED',
          isPaid: false,
          entryFee: 100000,
        ),
      ],
    );

    final step = _step(summary, StepKey.registration);
    expect(_todo(step, 'unpaid')?.count, 1);
    expect(_todo(step, 'unpaid')?.target.tab, StepHubTab.athletes);
  });

  test('TC-STEP-03 a missing registration deadline asks for one', () {
    final without = _step(
      _build(
        _tournament('registration'),
        divisions: [_division('a')],
        participants: [_participant('1', 'a')],
      ),
      StepKey.registration,
    );
    final withDeadline = _step(
      _build(
        _tournament('registration', registrationEnd: _future),
        divisions: [_division('a')],
        participants: [_participant('1', 'a')],
      ),
      StepKey.registration,
    );

    expect(_todo(without, 'deadline')?.target.tab, StepHubTab.overview);
    expect(_todo(withDeadline, 'deadline'), isNull);
    // Registration still open, nothing to fix: the step is running, not done.
    expect(withDeadline.state, StepStatus.current);
  });

  test(
    'TC-STEP-04 matches without court or time, and a division without bracket',
    () {
      final summary = _build(
        _tournament('registration_closed', registrationEnd: _past),
        divisions: [_division('a'), _division('b')],
        participants: [_participant('1', 'a'), _participant('2', 'b')],
        matches: [
          _match('m1', 'a', courtName: 'Court 1'),
          _match('m2', 'a'),
          _match('bye', 'a', isBye: true),
        ],
      );

      final step = _step(summary, StepKey.schedule);
      // m1 has a court but no time, m2 has neither; the BYE never counts.
      expect(_todo(step, 'noCourt')?.count, 1);
      expect(_todo(step, 'noTime')?.count, 2);
      final noBracket = _todo(step, 'noBracket:b');
      expect(noBracket?.target.tab, StepHubTab.bracket);
      expect(noBracket?.target.divisionId, 'b');
      expect(noBracket?.params['name'], 'Division b');
      expect(step.state, StepStatus.attention);

      final clean = _build(
        _tournament('registration_closed', registrationEnd: _past),
        divisions: [_division('a')],
        participants: [_participant('1', 'a')],
        matches: [
          _match('m1', 'a', courtName: 'Court 1', scheduledTime: _future),
        ],
      );
      expect(_step(clean, StepKey.schedule).state, StepStatus.done);
    },
  );

  test(
    'TC-STEP-05 disputed, late and unfinished matches point at the board',
    () {
      final today = DateTime.utc(2026, 11, 3, 3); // 10:00 in Vietnam, past
      final summary = _build(
        _tournament('in_progress', registrationEnd: _past, endDate: _future),
        divisions: [_division('a')],
        participants: [_participant('1', 'a')],
        matches: [
          _match('done', 'a', status: 'COMPLETED'),
          _match('disputed', 'a', status: 'DISPUTED'),
          _match('late', 'a', courtName: 'Court 1', scheduledTime: today),
          _match('live', 'a', status: 'LIVE'),
        ],
      );

      final playing = _step(summary, StepKey.inProgress);
      expect(_todo(playing, 'disputed')?.count, 1);
      expect(
        _todo(playing, 'disputed')?.target.resultsFilter,
        ResultsBoardFilter.disputed,
      );
      expect(_todo(playing, 'late')?.count, 1);
      expect(_todo(playing, 'late')?.target.tab, StepHubTab.results);
      expect(
        _todo(playing, 'late')?.target.resultsFilter,
        ResultsBoardFilter.late,
      );
      expect(playing.state, StepStatus.attention);
      expect(playing.percent, 25);

      final closing = _step(summary, StepKey.completed);
      // Late + live are unfinished; the dispute is counted on its own.
      expect(_todo(closing, 'unfinishedMatches')?.count, 2);
      expect(_todo(closing, 'disputed')?.count, 1);
      expect(closing.state, StepStatus.attention);
    },
  );

  test('TC-STEP-06 steps that are not reached yet stay idle', () {
    final divisions = [_division('a')];
    final participants = [_participant('1', 'a')];

    final registration = _build(
      _tournament('registration', registrationEnd: _future),
      divisions: divisions,
      participants: participants,
    );
    expect(_step(registration, StepKey.inProgress).state, StepStatus.upcoming);
    expect(_step(registration, StepKey.completed).state, StepStatus.upcoming);

    final draft = _build(_tournament('draft'), divisions: divisions);
    expect(draft.steps.map((s) => s.state).toSet(), {StepStatus.disabled});

    final completed = _build(
      _tournament('completed', registrationEnd: _past),
      divisions: divisions,
      participants: participants,
      matches: [_match('m1', 'a', status: 'COMPLETED')],
    );
    expect(completed.steps.map((s) => s.state).toSet(), {StepStatus.done});
    expect(completed.steps.expand((s) => s.todos), isEmpty);
    expect(completed.steps.map((s) => s.percent).toSet(), {100});
  });

  test('TC-STEP-07 loading and failed sources never look finished', () {
    final divisions = [_division('a')];

    final loading = _build(
      _tournament('in_progress', registrationEnd: _past),
      divisions: divisions,
      participantsLoad: SummaryLoad.loading,
      matchesLoad: SummaryLoad.loading,
    );
    expect(_step(loading, StepKey.registration).state, StepStatus.loading);
    expect(_step(loading, StepKey.schedule).state, StepStatus.loading);
    expect(_step(loading, StepKey.inProgress).state, StepStatus.loading);
    expect(loading.steps.map((s) => s.percent).toSet(), {0});

    final failed = _build(
      _tournament('in_progress', registrationEnd: _past),
      divisions: divisions,
      participants: [_participant('1', 'a')],
      matchesLoad: SummaryLoad.error,
    );
    final schedule = _step(failed, StepKey.schedule);
    expect(schedule.state, StepStatus.attention);
    expect(_todo(schedule, 'loadFailed')?.retry, isTrue);
    expect(_step(failed, StepKey.inProgress).percent, 0);

    final completedLoading = _build(
      _tournament('completed', registrationEnd: _past),
      divisions: divisions,
      participants: [_participant('1', 'a')],
      matchesLoad: SummaryLoad.loading,
    );
    expect(completedLoading.steps.map((s) => s.state).toSet(), {
      StepStatus.loading,
    });
  });

  test('TC-STEP-08 empty lists give empty steps and never throw', () {
    final summary = _build(_tournament('in_progress'));

    expect(summary.divisions, isEmpty);
    expect(summary.steps, hasLength(4));
    expect(_step(summary, StepKey.registration).state, StepStatus.missing);
    expect(_step(summary, StepKey.schedule).state, StepStatus.missing);
    expect(_step(summary, StepKey.inProgress).state, StepStatus.missing);
    expect(_step(summary, StepKey.completed).state, StepStatus.missing);
    expect(summary.steps.map((s) => s.percent).toSet(), {0});
  });

  test(
    'TC-STEP-09 division rows put problems first and open the right tab',
    () {
      final summary = _build(
        _tournament('registration_closed', registrationEnd: _past),
        divisions: [
          _division('ok'),
          _division('empty'),
          _division('gone', status: 'CANCELLED'),
        ],
        participants: [_participant('1', 'ok')],
        matches: [
          _match('m1', 'ok', courtName: 'Court 1', scheduledTime: _future),
        ],
      );

      expect(summary.divisions.map((d) => d.id), ['empty', 'ok', 'gone']);
      expect(summary.divisions.map((d) => d.missing), [true, false, false]);
      final byId = {for (final d in summary.divisions) d.id: d};
      expect(byId['empty']!.target.tab, StepHubTab.divisions);
      expect(byId['ok']!.target.tab, StepHubTab.bracket);
      expect(byId['ok']!.target.divisionId, 'ok');
      expect(byId['gone']!.target.tab, StepHubTab.divisions);
    },
  );
}
