import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/final_matches.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(
  String id, {
  required int round,
  String bracket = 'winners',
  String? stageType = 'SINGLE_ELIMINATION',
  bool isBye = false,
}) {
  return MatchModel(
    id: id,
    round: round,
    matchNumber: 1,
    bracketPosition: BracketPosition(bracket: bracket, round: round, position: 1),
    stageType: stageType,
    team1Id: 't1',
    team2Id: 't2',
    status: 'COMPLETED',
    isBye: isBye,
    updatedAt: DateTime(2026, 1, 1),
  );
}

List<String>? _ids(List<MatchModel>? matches) =>
    matches?.map((m) => m.id).toList();

void main() {
  group('TC-FINAL-01 pickFinalMatches', () {
    test('single elimination keeps only the last round', () {
      final matches = [
        _match('r1a', round: 1),
        _match('r1b', round: 1),
        _match('r2', round: 2),
        _match('final', round: 3),
      ];

      expect(_ids(pickFinalMatches(matches)), ['final']);
    });

    test('a BYE in the last round is not the final', () {
      final matches = [
        _match('semi', round: 2),
        _match('bye', round: 3, isBye: true),
      ];

      expect(_ids(pickFinalMatches(matches)), ['semi']);
    });

    test('double elimination prefers the grand final', () {
      final matches = [
        _match('w3', round: 3, stageType: 'DOUBLE_ELIMINATION'),
        _match(
          'l6',
          round: 6,
          bracket: 'losers',
          stageType: 'DOUBLE_ELIMINATION',
        ),
        _match(
          'gf',
          round: 4,
          bracket: 'grand_final',
          stageType: 'DOUBLE_ELIMINATION',
        ),
      ];

      expect(_ids(pickFinalMatches(matches)), ['gf']);
    });

    test('without a grand final the losers bracket is ignored', () {
      final matches = [
        _match('w3', round: 3, stageType: 'DOUBLE_ELIMINATION'),
        _match(
          'l6',
          round: 6,
          bracket: 'losers',
          stageType: 'DOUBLE_ELIMINATION',
        ),
      ];

      expect(_ids(pickFinalMatches(matches)), ['w3']);
    });

    test('round robin has no final: null keeps the full list', () {
      final matches = [
        _match('a', round: 1, stageType: 'ROUND_ROBIN'),
        _match('b', round: 2, stageType: 'ROUND_ROBIN'),
      ];

      expect(pickFinalMatches(matches), isNull);
    });

    test('empty list has no final', () {
      expect(pickFinalMatches(const []), isNull);
    });
  });
}
