// Tests for BracketGraphService
// Covers: BRACKET-016, BRACKET-017

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/services/bracket_graph_service.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

MatchModel _makeMatch(String id, {
  String nextMatchId = '', String status = 'scheduled',
  String team1 = 'Team A', String team2 = 'Team B',
  String bracket = 'winners',
}) {
  return MatchModel(
    id: id, round: 1, matchNumber: 1,
    team1Id: team1 == 'BYE' ? 'BYE' : 't1',
    team2Id: team2 == 'BYE' ? 'BYE' : 't2',
    team1Name: team1, team2Name: team2,
    status: status,
    nextMatchId: nextMatchId,
    bracketPosition: BracketPosition(bracket: bracket, round: 1, position: 0),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('TC-FLUTTER-BRACKET-016: BracketGraphService - Single Elimination', () {
    test('should build graph from match list with nextMatchId links', () {
      // Match tree: m1 -> m3, m2 -> m3
      final matches = [
        _makeMatch('m1', nextMatchId: 'm3'),
        _makeMatch('m2', nextMatchId: 'm3'),
        _makeMatch('m3'),
      ];
      final graph = BracketGraphService.buildSingleEliminationGraph(matches);
      expect(graph.nodeCount(), 3);
      expect(graph.edges.length, 2);
    });

    test('should filter BYE-vs-BYE matches', () {
      final matches = [
        _makeMatch('bye1', team1: 'BYE', team2: 'BYE'),
        _makeMatch('m1', nextMatchId: 'm2'),
        _makeMatch('m2'),
      ];
      final graph = BracketGraphService.buildSingleEliminationGraph(matches);
      expect(graph.nodeCount(), 2); // bye1 excluded
    });

    test('should add DUMMY_ROOT for multiple roots', () {
      // Two disconnected matches: m1 -> m2, m3 -> m4 (no links between groups)
      final matches = [
        _makeMatch('m1', nextMatchId: 'm2'),
        _makeMatch('m2'),
        _makeMatch('m3', nextMatchId: 'm4'),
        _makeMatch('m4'),
      ];
      final graph = BracketGraphService.buildSingleEliminationGraph(matches);
      expect(graph.nodeCount(), 5); // 4 + 1 dummy root
    });

    test('should return empty graph for empty list', () {
      final graph = BracketGraphService.buildSingleEliminationGraph([]);
      expect(graph.nodeCount(), 0);
    });
  });

  group('TC-FLUTTER-BRACKET-017: BracketGraphService - Double Elimination', () {
    test('should filter by winners bracket', () {
      final matches = [
        _makeMatch('w1', bracket: 'winners', nextMatchId: 'gf'),
        _makeMatch('l1', bracket: 'losers'),
        _makeMatch('gf', bracket: 'grand_final'),
      ];
      final graph = BracketGraphService.buildDoubleEliminationGraph(matches, bracketType: 'winners');
      expect(graph.nodeCount(), 1); // only w1
    });

    test('should filter by losers bracket', () {
      final matches = [
        _makeMatch('w1', bracket: 'winners'),
        _makeMatch('l1', bracket: 'losers', nextMatchId: 'l2'),
        _makeMatch('l2', bracket: 'losers'),
      ];
      final graph = BracketGraphService.buildDoubleEliminationGraph(matches, bracketType: 'losers');
      expect(graph.nodeCount(), 2); // l1, l2
    });
  });
}
