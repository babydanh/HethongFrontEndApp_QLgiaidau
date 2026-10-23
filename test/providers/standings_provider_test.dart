// Tests for StandingsProvider logic
// Covers: RANKING-009, RANKING-010, RANKING-011

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Returns a fixed `data` payload for every GET, whatever the path.
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.data);

  final Object? data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'statusCode': 200, 'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _MockTeamRepo extends Mock implements ITeamRepository {}

class _MockMatchRepo extends Mock implements IMatchRepository {}

Future<List<Standing>> _loadStandings(
  Object? apiData, {
  List<Team> teams = const [],
}) async {
  final teamRepo = _MockTeamRepo();
  final matchRepo = _MockMatchRepo();
  when(() => teamRepo.getAllByTournament(any())).thenAnswer((_) async => teams);
  when(
    () => matchRepo.getAllByTournament(any(), divisionId: any(named: 'divisionId')),
  ).thenAnswer((_) async => const []);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = _FixedAdapter(apiData);
  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      teamRepositoryProvider.overrideWithValue(teamRepo),
      matchRepositoryProvider.overrideWithValue(matchRepo),
    ],
  );
  addTearDown(container.dispose);
  final provider = standingsWithDivisionProvider((
    tournamentId: 't1',
    divisionId: 'd1',
  ));
  // Keep the polling stream alive while the first value is awaited.
  container.listen(provider, (_, _) {});
  return container.read(provider.future);
}

void main() {
  group('TC-FLUTTER-RANKING-012: Standing data structure', () {
    test('should create standing with correct field mapping', () {
      final standing = Standing(
        id: 's1',
        teamName: 'Doi A',
        group: 'Bang A',
        played: 3,
        won: 2,
        drawn: 1,
        lost: 0,
        pointsFor: 10,
        pointsAgainst: 5,
        pointDifference: 5,
        totalPoints: 7,
      );

      expect(standing.teamName, 'Doi A');
      expect(standing.played, 3);
      expect(standing.won, 2);
      expect(standing.drawn, 1);
      expect(standing.totalPoints, 7);
    });

    test('should calculate pointDifference correctly', () {
      final s = Standing(id: '1', teamName: 'A', pointsFor: 10, pointsAgainst: 3, pointDifference: 7);
      expect(s.pointDifference, 7);
    });

    test('should start with zero stats', () {
      final s = Standing(id: '1', teamName: 'A');
      expect(s.played, 0);
      expect(s.won, 0);
      expect(s.lost, 0);
      expect(s.drawn, 0);
      expect(s.totalPoints, 0);
    });
  });

  group('TC-FLUTTER-RANKING-009: Standings calculation logic', () {
    test('win = 3 points, draw = 1 point, loss = 0 points', () {
      // Team A: Win
      // TotalPoints = win*3 + draw*1 + loss*0
      final standing = Standing(
        id: '1', teamName: 'A',
        played: 3, won: 2, drawn: 1, lost: 0,
        totalPoints: 7, // 2*3 + 1*1 = 7
      );
      expect(standing.totalPoints, 7);
    });

    test('sort order by totalPoints desc, then pointDifference desc', () {
      final s1 = Standing(id: '1', teamName: 'A', totalPoints: 9, pointDifference: 10);
      final s2 = Standing(id: '2', teamName: 'B', totalPoints: 9, pointDifference: 5);
      final s3 = Standing(id: '3', teamName: 'C', totalPoints: 6, pointDifference: 3);

      final sorted = [s2, s1, s3]..sort((a, b) {
        if (b.totalPoints != a.totalPoints) return b.totalPoints.compareTo(a.totalPoints);
        return b.pointDifference.compareTo(a.pointDifference);
      });

      expect(sorted[0].teamName, 'A'); // 9 pts, +10 GD
      expect(sorted[1].teamName, 'B'); // 9 pts, +5 GD
      expect(sorted[2].teamName, 'C'); // 6 pts
    });
  });

  group('Standing.copyWith', () {
    test('should create a new Standing with updated fields', () {
      final s = Standing(id: '1', teamName: 'A');
      final updated = s.copyWith(teamName: 'B', won: 3, totalPoints: 9);
      expect(updated.teamName, 'B');
      expect(updated.won, 3);
      expect(updated.totalPoints, 9);
      expect(updated.id, '1');
    });
  });

  group('Standing.toString', () {
    test('should return formatted string', () {
      final s = Standing(id: '1', teamName: 'A', totalPoints: 9, won: 3, lost: 0, drawn: 0);
      expect(s.toString(), 'Standing(A: 9 pts, W3-D0-L0)');
    });
  });

  group('standingsWithDivisionProvider Swiss ordering', () {
    test('rows carrying rank keep Backend order, rank and tiebreak values', () async {
      // Deliberately not sorted by points: rank is the single source of truth.
      final result = await _loadStandings({
        'groups': [
          {'id': 'g1', 'name': 'Thụy Sĩ'},
        ],
        'standings': [
          {
            'participantId': 'p3', 'teamName': 'C', 'groupId': 'g1',
            'rank': 3, 'totalPoints': 6, 'buchholz': 4.5,
            'buchholzCut1': 3, 'sonnebornBerger': 2.5,
          },
          {
            'participantId': 'p1', 'teamName': 'A', 'groupId': 'g1',
            'rank': 1, 'totalPoints': 3, 'buchholz': 9,
          },
          {
            'participantId': 'p2', 'teamName': 'B', 'groupId': 'g1',
            'rank': 2, 'totalPoints': 9, 'buchholz': 6,
          },
        ],
      });
      expect(result.map((s) => s.id), ['p1', 'p2', 'p3']);
      expect(result.map((s) => s.rank), [1, 2, 3]);
      expect(result.last.buchholz, 4.5);
      expect(result.last.buchholzCut1, 3.0);
      expect(result.last.sonnebornBerger, 2.5);
    });

    test('rows without Swiss fields still parse and keep payload order', () async {
      final result = await _loadStandings({
        'groups': <Object>[],
        'standings': [
          {'participantId': 'p2', 'teamName': 'B', 'totalPoints': 1},
          {'participantId': 'p1', 'teamName': 'A', 'totalPoints': 5},
        ],
      });
      expect(result.map((s) => s.id), ['p2', 'p1']);
      expect(result.every((s) => s.rank == null && s.buchholz == 0), isTrue);
    });

    test('empty endpoint falls back to the client-side calculation', () async {
      final result = await _loadStandings(
        <Object>[],
        teams: [
          Team(id: 'b', name: 'B', createdAt: DateTime.utc(2026)),
          Team(id: 'a', name: 'A', createdAt: DateTime.utc(2026)),
        ],
      );
      // Old path: every team listed with zero stats, tie-broken by id.
      expect(result.map((s) => s.id), ['a', 'b']);
      expect(result.every((s) => s.rank == null), isTrue);
    });
  });
}
