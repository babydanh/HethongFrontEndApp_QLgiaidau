import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(
  String id, {
  int round = 1,
  int number = 1,
  String status = 'SCHEDULED',
  String team1Id = 't1',
  String team2Id = 't2',
  bool isBye = false,
  String winnerId = '',
  DateTime? scheduledTime,
  DateTime? completedAt,
  String? divisionId,
  Map<String, dynamic>? scoreDetails,
  Map<String, dynamic>? tournamentConfig,
  String bracket = 'winners',
  String? stageType,
}) {
  return MatchModel(
    id: id,
    round: round,
    matchNumber: number,
    bracketPosition: BracketPosition(
      bracket: bracket,
      round: round,
      position: number,
    ),
    stageType: stageType,
    team1Id: team1Id,
    team2Id: team2Id,
    status: status,
    isBye: isBye,
    winnerId: winnerId,
    scheduledTime: scheduledTime,
    completedAt: completedAt,
    divisionId: divisionId,
    scoreDetails: scoreDetails,
    tournamentConfig: tournamentConfig,
    updatedAt: DateTime(2026, 1, 1),
  );
}

String _label(MatchModel m) => 'R${m.round}';

void main() {
  group('matchDivisionId', () {
    test('prefers divisionId, then scoreDetails, then tournamentConfig', () {
      expect(matchDivisionId(_match('a', divisionId: 'd1')), 'd1');
      expect(
        matchDivisionId(_match('a', scoreDetails: {'division_id': 'd2'})),
        'd2',
      );
      expect(
        matchDivisionId(_match('a', tournamentConfig: {'division_id': 'd3'})),
        'd3',
      );
    });

    test('returns null when no source has a usable id', () {
      expect(matchDivisionId(_match('a')), isNull);
      expect(matchDivisionId(_match('a', divisionId: '')), isNull);
    });
  });

  group('canEnterScore', () {
    test('accepts a real scheduled or live match with both sides', () {
      expect(canEnterScore(_match('a')), isTrue);
      expect(canEnterScore(_match('a', status: 'ONGOING')), isTrue);
    });

    test('rejects BYE, missing side and closed statuses', () {
      expect(canEnterScore(_match('a', isBye: true)), isFalse);
      expect(canEnterScore(_match('a', team2Id: '')), isFalse);
      for (final s in ['COMPLETED', 'finished', ' Disputed ', 'CANCELLED']) {
        expect(canEnterScore(_match('a', status: s)), isFalse, reason: s);
      }
    });
  });

  group('isLiveMatch', () {
    test('true only for an open live match with both sides', () {
      expect(isLiveMatch(_match('a', status: 'LIVE')), isTrue);
      expect(isLiveMatch(_match('a', status: 'in_progress')), isTrue);
      expect(isLiveMatch(_match('a', status: 'SCHEDULED')), isFalse);
    });

    test('false when the live match is already closed or a BYE', () {
      expect(
        isLiveMatch(_match('a', status: 'ONGOING', winnerId: 't1')),
        isFalse,
      );
      expect(
        isLiveMatch(
          _match('a', status: 'ONGOING', completedAt: DateTime(2026, 1, 2)),
        ),
        isFalse,
      );
      expect(isLiveMatch(_match('a', status: 'ONGOING', isBye: true)), isFalse);
      expect(isLiveMatch(_match('a', status: 'ONGOING', team1Id: '')), isFalse);
    });
  });

  group('buildResultsRounds', () {
    test('drops BYE, counts pending and orders rounds then matches', () {
      final rounds = buildResultsRounds([
        _match('r2', round: 2, number: 1),
        _match('r1b', round: 1, number: 2, status: 'COMPLETED'),
        _match('bye', round: 1, number: 3, isBye: true),
        _match('r1a', round: 1, number: 1),
      ], _label);

      expect(rounds.map((r) => r.key), ['R1', 'R2']);
      expect(rounds.first.matches.map((m) => m.id), ['r1a', 'r1b']);
      expect(rounds.first.pending, 1);
      expect(rounds.last.pending, 1);
    });

    test('returns no rounds for an empty or all-BYE list', () {
      expect(buildResultsRounds(const [], _label), isEmpty);
      expect(buildResultsRounds([_match('b', isBye: true)], _label), isEmpty);
    });
  });

  group('splitResultsMatches', () {
    test('separates live, finished (latest first) and upcoming', () {
      final split = splitResultsMatches([
        _match(
          'late',
          number: 1,
          status: 'SCHEDULED',
          scheduledTime: DateTime(2026, 1, 1, 10),
        ),
        _match('none', number: 2, status: 'SCHEDULED'),
        _match(
          'early',
          number: 3,
          status: 'SCHEDULED',
          scheduledTime: DateTime(2026, 1, 1, 8),
        ),
        _match('live', number: 4, status: 'ONGOING'),
        _match(
          'old',
          number: 5,
          status: 'COMPLETED',
          completedAt: DateTime(2026, 1, 1, 7),
        ),
        _match(
          'new',
          number: 6,
          status: 'COMPLETED',
          completedAt: DateTime(2026, 1, 1, 9),
        ),
      ]);

      expect(split.live.map((m) => m.id), ['live']);
      expect(split.finished.map((m) => m.id), ['new', 'old']);
      expect(split.upcoming.map((m) => m.id), ['early', 'late', 'none']);
    });

    test('a live match never appears in upcoming', () {
      final split = splitResultsMatches([
        _match('a', number: 1, status: 'LIVE'),
        _match('b', number: 2, status: 'IN_PROGRESS'),
        _match('c', number: 3),
      ]);
      expect(split.live.map((m) => m.id), ['a', 'b']);
      expect(split.upcoming.map((m) => m.id), ['c']);
    });

    test('an ONGOING match that already has a winner is not live', () {
      final split = splitResultsMatches([
        _match('a', status: 'ONGOING', winnerId: 't1'),
      ]);
      expect(split.live, isEmpty);
    });
  });

  group('splitUpcomingByTime', () {
    test('keeps incoming order inside each group', () {
      final result = splitUpcomingByTime([
        _match('x', number: 1),
        _match('y', number: 2, scheduledTime: DateTime(2026, 1, 1, 8)),
        _match('z', number: 3),
      ]);
      expect(result.timed.map((m) => m.id), ['y']);
      expect(result.untimed.map((m) => m.id), ['x', 'z']);
    });
  });

  group('defaultResultsRoundKey', () {
    ResultsRound round(String key, int pending) =>
        ResultsRound(key: key, label: key, matches: const [], pending: pending);

    test('first round that still has pending matches', () {
      expect(
        defaultResultsRoundKey([
          round('R1', 0),
          round('R2', 2),
          round('R3', 1),
        ]),
        'R2',
      );
    });

    test('last round when nothing is pending, null when no rounds', () {
      expect(defaultResultsRoundKey([round('R1', 0), round('R2', 0)]), 'R2');
      expect(defaultResultsRoundKey(const []), isNull);
    });
  });

  group('waitingForCode', () {
    MatchModel feeder(String id, int position, {String? code}) => MatchModel(
      id: id,
      round: 1,
      matchNumber: position,
      bracketPosition: BracketPosition(round: 1, position: position),
      nextMatchId: 'final',
      matchCode: code,
      updatedAt: DateTime(2026, 1, 1),
    );

    MatchModel target({bool secondFilled = false}) => MatchModel(
      id: 'final',
      round: 2,
      matchNumber: 1,
      bracketPosition: const BracketPosition(round: 2, position: 1),
      team2Name: secondFilled ? 'Sam Set' : '',
      updatedAt: DateTime(2026, 1, 1),
    );

    test('two feeders fill side 1 and side 2 in bracket order', () {
      final all = [
        feeder('b', 2, code: 'V1602'),
        feeder('a', 1, code: 'V1601'),
        target(),
      ];

      expect(waitingForCode(target(), 1, all), 'V1601');
      expect(waitingForCode(target(), 2, all), 'V1602');
    });

    test('a single feeder only explains the one empty side', () {
      final all = [feeder('a', 1, code: 'V1601'), target(secondFilled: true)];

      expect(waitingForCode(target(secondFilled: true), 1, all), 'V1601');
      expect(waitingForCode(target(secondFilled: true), 2, all), isNull);
      expect(
        waitingForCode(target(), 1, [feeder('a', 1, code: 'V1601')]),
        isNull,
      );
    });

    test('no code or no feeder gives null instead of a made-up label', () {
      expect(waitingForCode(target(), 1, [feeder('a', 1), target()]), isNull);
      expect(waitingForCode(target(), 1, [target()]), isNull);
    });
  });

  group('branchOfMatch (TC-RBR-01)', () {
    test('losers and grand final come from the bracket position', () {
      expect(
        branchOfMatch(_match('a', bracket: 'losers')),
        ResultsBranch.losers,
      );
      expect(
        branchOfMatch(_match('a', bracket: 'grand_final')),
        ResultsBranch.grandFinal,
      );
      expect(
        branchOfMatch(_match('a', bracket: 'grand_final_reset')),
        ResultsBranch.grandFinal,
      );
    });

    test('winners only counts inside double elimination, else main', () {
      expect(
        branchOfMatch(_match('a', stageType: 'DOUBLE_ELIMINATION')),
        ResultsBranch.winners,
      );
      expect(
        branchOfMatch(_match('a', stageType: 'SINGLE_ELIMINATION')),
        ResultsBranch.main,
      );
      expect(branchOfMatch(_match('a')), ResultsBranch.main);
    });
  });

  group('buildResultsRounds by branch (TC-RBR-02)', () {
    test('orders winners, losers, grand final and splits losers rounds', () {
      const stage = 'DOUBLE_ELIMINATION';
      final rounds = buildResultsRounds([
        _match('gf', round: 9, bracket: 'grand_final', stageType: stage),
        _match('l2', round: 4, bracket: 'losers', stageType: stage),
        _match('l1', round: 2, bracket: 'losers', stageType: stage),
        _match('w2', round: 3, stageType: stage),
        _match('w1', round: 1, stageType: stage),
      ], (m) => m.bracketPosition.bracket == 'losers' ? 'Same' : 'R${m.round}');

      expect(rounds.map((r) => r.key), [
        'R1',
        'R3',
        'losers|2',
        'losers|4',
        'R9',
      ]);
      expect(rounds.map((r) => r.branch), [
        ResultsBranch.winners,
        ResultsBranch.winners,
        ResultsBranch.losers,
        ResultsBranch.losers,
        ResultsBranch.grandFinal,
      ]);
    });

    test('single elimination keeps one key per label on the main branch', () {
      final rounds = buildResultsRounds([
        _match('a', round: 1),
        _match('b', round: 2),
      ], _label);
      expect(rounds.map((r) => r.key), ['R1', 'R2']);
      expect(rounds.every((r) => r.branch == ResultsBranch.main), isTrue);
    });
  });

  group('matchTone (TC-RBR-03)', () {
    test('maps status to the row tone', () {
      expect(matchTone(_match('a', status: 'LIVE')), MatchTone.live);
      expect(matchTone(_match('a', status: 'COMPLETED')), MatchTone.done);
      expect(matchTone(_match('a', status: 'DISPUTED')), MatchTone.done);
      expect(matchTone(_match('a', status: 'CANCELLED')), MatchTone.cancel);
      expect(matchTone(_match('a')), MatchTone.ready);
      expect(matchTone(_match('a', team2Id: '')), MatchTone.wait);
    });
  });

  group('round box open state (TC-RBR-04)', () {
    test('a viewer choice always wins', () {
      expect(
        isRoundBoxOpen(choice: true, isDefault: false, searching: false),
        isTrue,
      );
      expect(
        isRoundBoxOpen(choice: false, isDefault: true, searching: true),
        isFalse,
      );
    });

    test('without a choice: default round or any round while searching', () {
      expect(
        isRoundBoxOpen(choice: null, isDefault: true, searching: false),
        isTrue,
      );
      expect(
        isRoundBoxOpen(choice: null, isDefault: false, searching: false),
        isFalse,
      );
      expect(
        isRoundBoxOpen(choice: null, isDefault: false, searching: true),
        isTrue,
      );
    });

    test('openOnlyRound opens the picked key and folds the rest', () {
      expect(openOnlyRound(['a', 'b', 'c'], 'b'), {
        'a': false,
        'b': true,
        'c': false,
      });
    });
  });
}
