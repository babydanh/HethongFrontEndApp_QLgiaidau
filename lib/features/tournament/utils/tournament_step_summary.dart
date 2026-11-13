import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';

/// Progress numbers for the four steps of the organiser stepper, a reduced
/// port of the Web `tournament-step-summary*.ts`. Pure: no providers, no
/// network. Not ported: the Swiss next-round todo and the draft publish todos
/// (a draft has every step disabled here).

enum StepKey { registration, schedule, inProgress, completed }

enum StepStatus {
  done,
  attention,
  missing,
  current,
  upcoming,
  loading,
  disabled,
}

enum SummaryLoad { loading, ready, error }

/// Hub tabs a step todo can point at.
enum StepHubTab {
  overview,
  divisions,
  athletes,
  bracket,
  schedule,
  settings,
  results,
}

/// Where a todo or a division row leads: a hub tab plus, when it matters, the
/// results chip and the division to preselect.
class StepTarget {
  const StepTarget(this.tab, {this.resultsFilter, this.divisionId});

  final StepHubTab tab;
  final ResultsBoardFilter? resultsFilter;
  final String? divisionId;
}

class StepTodo {
  const StepTodo({
    required this.key,
    required this.labelKey,
    required this.target,
    this.params = const {},
    this.count,
    this.retry = false,
  });

  final String key;

  /// Suffix of the `stepTodo_*` l10n key, e.g. `unpaid` for `stepTodo_unpaid`.
  final String labelKey;
  final Map<String, Object> params;
  final int? count;

  /// True for the "load failed" row: tapping reloads instead of navigating.
  final bool retry;
  final StepTarget target;
}

class StepProgress {
  const StepProgress({
    required this.key,
    required this.state,
    required this.percent,
    required this.todos,
  });

  final StepKey key;
  final StepStatus state;

  /// 0-100; always 0 while the step is loading or failed to load.
  final int percent;
  final List<StepTodo> todos;
}

class StepDivisionRow {
  const StepDivisionRow({
    required this.id,
    required this.name,
    required this.missing,
    required this.target,
  });

  final String id;
  final String name;

  /// The division has something to fix (Web tone bad or warn).
  final bool missing;
  final StepTarget target;
}

class StepSummary {
  const StepSummary({required this.steps, required this.divisions});

  final List<StepProgress> steps;
  final List<StepDivisionRow> divisions;
}

int toPercent(int done, int total) =>
    total <= 0 ? 0 : (done / total * 100).round();

const _doneStatuses = {'COMPLETED', 'FINISHED', 'CANCELLED'};
const _activeParticipant = {
  'COMPLETE',
  'PENDING_APPROVAL',
  'PENDING',
  'PENDING_PARTNER',
};
const _payable = {'COMPLETE', 'PENDING_APPROVAL', 'PENDING'};
const _waiting = {'PENDING_APPROVAL', 'PENDING', 'PENDING_PARTNER'};

/// Matches that can still get a court or a time: two sides, not played yet.
bool _needsPlacement(MatchModel m) =>
    m.hasTeams && !isMatchClosed(m) && !isLiveMatch(m);

class _Facts {
  _Facts({
    required this.division,
    required this.cancelled,
    required this.entrants,
    required this.hasEntrants,
    required this.playable,
    required this.done,
    required this.live,
    required this.notPlayed,
    required this.disputed,
    required this.late,
    this.directFee = false,
  });

  final TournamentDivision division;
  final bool cancelled;
  final List<OrganizerOpsParticipant> entrants;
  final bool hasEntrants;

  /// Real matches that are not cancelled.
  final List<MatchModel> playable;
  final int done;
  final int live;
  final int notPlayed;
  final int disputed;
  final int late;

  /// DIRECT fee collection: the organizer collects fees offline, so nothing
  /// is "unpaid" on the platform.
  final bool directFee;

  int get total => done + live + notPlayed + disputed;

  List<OrganizerOpsParticipant> get unpaid => directFee
      ? const []
      : entrants
            .where(
              (p) =>
                  _payable.contains(p.teamStatus.toUpperCase()) &&
                  !p.isPaid &&
                  (p.entryFee ?? 1) > 0,
            )
            .toList();

  int get waiting => entrants
      .where((p) => _waiting.contains(p.teamStatus.toUpperCase()))
      .length;

  int get noCourt => playable
      .where(
        (m) =>
            _needsPlacement(m) &&
            (m.courtId ?? '').isEmpty &&
            (m.courtName ?? '').isEmpty,
      )
      .length;

  int get noTime => playable
      .where((m) => _needsPlacement(m) && m.scheduledTime == null)
      .length;
}

bool _isMockParticipant(OrganizerOpsParticipant p) =>
    p.members.isNotEmpty && p.members.every((m) => m.isMock);

_Facts _collectFacts({
  required TournamentDivision division,
  required List<MatchModel> matches,
  required List<OrganizerOpsParticipant> entrantsOfDivision,
  required bool participantsReady,
  required bool inProgress,
  required DateTime now,
  bool directFee = false,
}) {
  final entrants = participantsReady
      ? entrantsOfDivision
            .where(
              (p) =>
                  !_isMockParticipant(p) &&
                  _activeParticipant.contains(p.teamStatus.toUpperCase()),
            )
            .toList()
      : <OrganizerOpsParticipant>[];
  final real = matches.where((m) => !m.isBye).toList();
  var done = 0, live = 0, notPlayed = 0, disputed = 0, late = 0;
  for (final m in real) {
    if (_doneStatuses.contains(m.normalizedStatus)) {
      done++;
    } else if (isDisputedMatch(m)) {
      disputed++;
    } else if (isLiveMatch(m)) {
      live++;
    } else {
      notPlayed++;
      if (inProgress && isLateMatch(m, now)) late++;
    }
  }
  return _Facts(
    division: division,
    cancelled: division.status?.toUpperCase() == 'CANCELLED',
    entrants: entrants,
    hasEntrants: participantsReady
        ? entrants.isNotEmpty
        : division.participantCount > 0,
    playable: real.where((m) => m.normalizedStatus != 'CANCELLED').toList(),
    done: done,
    live: live,
    notPlayed: notPlayed,
    disputed: disputed,
    late: late,
    directFee: directFee,
  );
}

/// Loading beats error beats ok across several sources.
SummaryLoad _worst(Iterable<SummaryLoad> loads) {
  if (loads.contains(SummaryLoad.loading)) return SummaryLoad.loading;
  return loads.contains(SummaryLoad.error)
      ? SummaryLoad.error
      : SummaryLoad.ready;
}

const _loadFailed = StepTodo(
  key: 'loadFailed',
  labelKey: 'loadFailed',
  retry: true,
  target: StepTarget(StepHubTab.overview),
);

bool _hasValidDates(Tournament t) {
  final start = t.registrationStartDate;
  final end = t.registrationEndDate;
  final open = t.startDate;
  if (start == null || end == null || open == null) return false;
  return start.isBefore(end) && end.isBefore(open);
}

bool _registrationOpen(Tournament t, String status, DateTime now) {
  final deadline = t.registrationEndDate;
  if (deadline != null && deadline.isBefore(now)) return false;
  return status == AppConstants.statusRegistration ||
      status == AppConstants.statusInProgress;
}

StepTodo _countTodo(
  String key,
  int count,
  StepTarget target, {
  Map<String, Object> params = const {},
}) => StepTodo(
  key: key,
  labelKey: key,
  count: count,
  target: target,
  params: params,
);

StepProgress _registrationStep({
  required Tournament tournament,
  required String status,
  required SummaryLoad participantsLoad,
  required List<_Facts> facts,
  required DateTime now,
}) {
  final live = facts.where((f) => !f.cancelled).toList();
  final relevant = live.where((f) => f.hasEntrants).toList();
  final open = _registrationOpen(tournament, status, now);
  final closedCount = open ? 0 : relevant.length;
  final ready = participantsLoad == SummaryLoad.ready;
  final todos = <StepTodo>[];

  final empty = live.length - relevant.length;
  if (empty > 0) {
    todos.add(
      _countTodo(
        'emptyDivisions',
        empty,
        const StepTarget(StepHubTab.divisions),
      ),
    );
  }
  final unpaid = ready ? facts.fold(0, (s, f) => s + f.unpaid.length) : 0;
  if (unpaid > 0) {
    todos.add(
      _countTodo('unpaid', unpaid, const StepTarget(StepHubTab.athletes)),
    );
  }
  final waiting = ready ? facts.fold(0, (s, f) => s + f.waiting) : 0;
  if (waiting > 0) {
    todos.add(
      _countTodo(
        'teamsWaiting',
        waiting,
        const StepTarget(StepHubTab.athletes),
      ),
    );
  }
  if (tournament.registrationEndDate == null) {
    todos.add(
      const StepTodo(
        key: 'deadline',
        labelKey: 'deadline',
        target: StepTarget(StepHubTab.overview),
      ),
    );
  }
  if (status == AppConstants.statusInProgress && open && relevant.isNotEmpty) {
    todos.add(
      _countTodo(
        'openDuringPlay',
        relevant.length,
        const StepTarget(StepHubTab.divisions),
      ),
    );
  }
  if (participantsLoad == SummaryLoad.error) todos.add(_loadFailed);

  final StepStatus state;
  if (participantsLoad == SummaryLoad.loading) {
    state = StepStatus.loading;
  } else if (live.isEmpty) {
    state = StepStatus.missing;
  } else if (participantsLoad == SummaryLoad.error ||
      relevant.isEmpty ||
      todos.isNotEmpty) {
    state = StepStatus.attention;
  } else {
    state = open ? StepStatus.current : StepStatus.done;
  }
  return StepProgress(
    key: StepKey.registration,
    state: state,
    percent: ready ? toPercent(closedCount, relevant.length) : 0,
    todos: todos,
  );
}

StepProgress _scheduleStep({
  required Tournament tournament,
  required SummaryLoad load,
  required List<_Facts> facts,
}) {
  final relevant = facts.where((f) => !f.cancelled && f.hasEntrants).toList();
  final withBracket = relevant.where((f) => f.playable.isNotEmpty).length;
  final todos = <StepTodo>[
    for (final f in relevant.where((f) => f.playable.isEmpty))
      StepTodo(
        key: 'noBracket:${f.division.id}',
        labelKey: 'noBracket',
        params: {'name': f.division.name},
        target: StepTarget(StepHubTab.bracket, divisionId: f.division.id),
      ),
  ];
  final noCourt = relevant.fold(0, (s, f) => s + f.noCourt);
  final noTime = relevant.fold(0, (s, f) => s + f.noTime);
  if (noCourt > 0) {
    todos.add(
      _countTodo('noCourt', noCourt, const StepTarget(StepHubTab.schedule)),
    );
  }
  if (noTime > 0) {
    todos.add(
      _countTodo('noTime', noTime, const StepTarget(StepHubTab.schedule)),
    );
  }
  if (!_hasValidDates(tournament)) {
    todos.add(
      const StepTodo(
        key: 'dates',
        labelKey: 'dates',
        target: StepTarget(StepHubTab.overview),
      ),
    );
  }
  if (load == SummaryLoad.error) todos.add(_loadFailed);

  final noDivisions = facts.every((f) => f.cancelled);
  final StepStatus state;
  if (load == SummaryLoad.loading) {
    state = StepStatus.loading;
  } else if (noDivisions) {
    state = StepStatus.missing;
  } else if (load == SummaryLoad.error) {
    state = StepStatus.attention;
  } else if (relevant.isEmpty) {
    state = StepStatus.missing;
  } else if (withBracket == 0) {
    state = StepStatus.upcoming;
  } else {
    state = todos.isEmpty && withBracket == relevant.length
        ? StepStatus.done
        : StepStatus.attention;
  }
  return StepProgress(
    key: StepKey.schedule,
    state: state,
    percent: load == SummaryLoad.ready
        ? toPercent(withBracket, relevant.length)
        : 0,
    todos: todos,
  );
}

StepTarget _resultsTarget(ResultsBoardFilter filter) =>
    StepTarget(StepHubTab.results, resultsFilter: filter);

/// No chip holds disputed matches (closed, yet not finished): open the whole
/// board, where the row is marked.
const _disputedTarget = StepTarget(StepHubTab.results);

/// Gate shared by the two playing steps: null means there is data to count.
StepProgress? _playGate(StepKey key, SummaryLoad load, List<_Facts> facts) {
  if (load == SummaryLoad.loading) {
    return StepProgress(
      key: key,
      state: StepStatus.loading,
      percent: 0,
      todos: const [],
    );
  }
  if (facts.every((f) => f.cancelled)) {
    return StepProgress(
      key: key,
      state: StepStatus.missing,
      percent: 0,
      todos: const [],
    );
  }
  return null;
}

StepProgress _inProgressStep(SummaryLoad load, List<_Facts> facts) {
  final gate = _playGate(StepKey.inProgress, load, facts);
  if (gate != null) return gate;
  final live = facts.where((f) => !f.cancelled).toList();
  final total = live.fold(0, (s, f) => s + f.total);
  final done = live.fold(0, (s, f) => s + f.done);
  final disputed = live.fold(0, (s, f) => s + f.disputed);
  final late = live.fold(0, (s, f) => s + f.late);
  final todos = <StepTodo>[
    if (disputed > 0) _countTodo('disputed', disputed, _disputedTarget),
    if (late > 0)
      _countTodo('late', late, _resultsTarget(ResultsBoardFilter.unfinished)),
    if (load == SummaryLoad.error) _loadFailed,
  ];
  return StepProgress(
    key: StepKey.inProgress,
    state: todos.isNotEmpty
        ? StepStatus.attention
        : (total > 0 && done == total ? StepStatus.done : StepStatus.current),
    percent: load == SummaryLoad.error ? 0 : toPercent(done, total),
    todos: todos,
  );
}

StepProgress _completedStep({
  required Tournament tournament,
  required SummaryLoad load,
  required List<_Facts> facts,
  required DateTime now,
}) {
  final gate = _playGate(StepKey.completed, load, facts);
  if (gate != null) return gate;
  final live = facts.where((f) => !f.cancelled).toList();
  final total = live.fold(0, (s, f) => s + f.total);
  final done = live.fold(0, (s, f) => s + f.done);
  final disputed = live.fold(0, (s, f) => s + f.disputed);
  final blocking = total - done;
  final unfinished = blocking - disputed;
  final end = tournament.endDate;
  final endPastUnfinished = end != null && end.isBefore(now) && blocking > 0;
  final todos = <StepTodo>[
    if (unfinished > 0)
      _countTodo(
        'unfinishedMatches',
        unfinished,
        _resultsTarget(ResultsBoardFilter.unfinished),
      ),
    if (disputed > 0) _countTodo('disputed', disputed, _disputedTarget),
    if (endPastUnfinished)
      const StepTodo(
        key: 'endDateExpected',
        labelKey: 'endDateExpected',
        target: StepTarget(StepHubTab.overview),
      ),
    if (load == SummaryLoad.error) _loadFailed,
  ];
  final relevant = live.where((f) => f.hasEntrants).toList();
  final finished = relevant
      .where((f) => f.total > 0 && f.done == f.total)
      .length;
  final StepStatus state;
  if (load == SummaryLoad.error || disputed > 0 || endPastUnfinished) {
    state = StepStatus.attention;
  } else if (unfinished > 0 || total == 0) {
    state = StepStatus.upcoming;
  } else {
    state = StepStatus.current;
  }
  return StepProgress(
    key: StepKey.completed,
    state: state,
    percent: load == SummaryLoad.error
        ? 0
        : toPercent(finished, relevant.length),
    todos: todos,
  );
}

StepProgress _idle(StepKey key, StepStatus state) =>
    StepProgress(key: key, state: state, percent: 0, todos: const []);

int _toneRank(_Facts f, bool openDuringPlay) {
  if (f.cancelled) return 4;
  if (!f.hasEntrants || f.disputed > 0) return 0;
  final warn =
      f.unpaid.isNotEmpty ||
      f.late > 0 ||
      f.noCourt + f.noTime > 0 ||
      openDuringPlay;
  if (warn) return 1;
  return f.playable.isEmpty ? 2 : 3;
}

List<StepDivisionRow> _divisionRows(List<_Facts> facts, bool openDuringPlay) {
  final ranked =
      [for (final f in facts) (facts: f, rank: _toneRank(f, openDuringPlay))]
        ..sort((a, b) {
          final byRank = a.rank.compareTo(b.rank);
          if (byRank != 0) return byRank;
          final byName = a.facts.division.name.toLowerCase().compareTo(
            b.facts.division.name.toLowerCase(),
          );
          return byName != 0
              ? byName
              : a.facts.division.id.compareTo(b.facts.division.id);
        });
  return [
    for (final r in ranked)
      StepDivisionRow(
        id: r.facts.division.id,
        name: r.facts.division.name,
        missing: r.rank <= 1,
        // Like the Web "Mở" button: no bracket yet (or cancelled) goes to the
        // divisions tab, otherwise to the bracket.
        target: StepTarget(
          r.facts.cancelled || r.facts.playable.isEmpty
              ? StepHubTab.divisions
              : StepHubTab.bracket,
          divisionId: r.facts.division.id,
        ),
      ),
  ];
}

/// Builds the four step states and the per-division rows. Never throws on
/// empty lists; a source that is loading or failed keeps its steps off green.
StepSummary buildStepSummary({
  required Tournament tournament,
  required List<TournamentDivision> divisions,
  required List<OrganizerOpsParticipant> participants,
  required SummaryLoad participantsLoad,
  required List<MatchModel> matches,
  required SummaryLoad matchesLoad,
  required DateTime now,
}) {
  final status = StatusHelper.normalizeTournamentStatus(tournament.status);
  final inProgress = status == AppConstants.statusInProgress;
  final participantsReady = participantsLoad == SummaryLoad.ready;
  final matchesByDivision = <String, List<MatchModel>>{};
  for (final m in matches) {
    final id = matchDivisionId(m);
    if (id != null) matchesByDivision.putIfAbsent(id, () => []).add(m);
  }
  final entrantsByDivision = <String, List<OrganizerOpsParticipant>>{};
  for (final p in participants) {
    final id = p.divisionId;
    if (id != null) entrantsByDivision.putIfAbsent(id, () => []).add(p);
  }
  final facts = [
    for (final d in divisions)
      _collectFacts(
        division: d,
        matches: matchesByDivision[d.id] ?? const [],
        entrantsOfDivision: entrantsByDivision[d.id] ?? const [],
        participantsReady: participantsReady,
        inProgress: inProgress,
        now: now,
        directFee: tournament.isDirectFeeCollection,
      ),
  ];
  final openDuringPlay =
      inProgress && _registrationOpen(tournament, status, now);
  final rows = _divisionRows(facts, openDuringPlay);
  final matchStepLoad = _worst([participantsLoad, matchesLoad]);

  StepProgress registration() => _registrationStep(
    tournament: tournament,
    status: status,
    participantsLoad: participantsLoad,
    facts: facts,
    now: now,
  );
  StepProgress schedule() =>
      _scheduleStep(tournament: tournament, load: matchStepLoad, facts: facts);
  StepProgress playing() => _inProgressStep(matchStepLoad, facts);
  StepProgress closing() => _completedStep(
    tournament: tournament,
    load: matchStepLoad,
    facts: facts,
    now: now,
  );

  List<StepProgress> steps;
  switch (status) {
    case AppConstants.statusUpcoming ||
        AppConstants.statusRegistration ||
        AppConstants.statusRegistrationClosed ||
        AppConstants.statusDrawing:
      steps = [
        registration(),
        schedule(),
        _idle(StepKey.inProgress, StepStatus.upcoming),
        _idle(StepKey.completed, StepStatus.upcoming),
      ];
    case AppConstants.statusInProgress:
      steps = [registration(), schedule(), playing(), closing()];
    case AppConstants.statusCompleted:
      steps = _finishedSteps([
        registration(),
        schedule(),
        playing(),
        closing(),
      ], matchStepLoad);
    default:
      // Draft, cancelled, pending approval or deletion: nothing to do yet.
      steps = [for (final k in StepKey.values) _idle(k, StepStatus.disabled)];
  }
  return StepSummary(steps: steps, divisions: rows);
}

/// A completed tournament is read-only: every step is green with no todos,
/// except a step still loading, missing, or failed to load.
List<StepProgress> _finishedSteps(List<StepProgress> steps, SummaryLoad load) {
  return [
    for (final s in steps)
      if (s.state == StepStatus.loading || s.state == StepStatus.missing)
        s
      else if (load == SummaryLoad.error && s.state == StepStatus.attention)
        s
      else if (load == SummaryLoad.loading)
        StepProgress(
          key: s.key,
          state: StepStatus.loading,
          percent: 0,
          todos: const [],
        )
      else
        StepProgress(
          key: s.key,
          state: StepStatus.done,
          percent: 100,
          todos: const [],
        ),
  ];
}
