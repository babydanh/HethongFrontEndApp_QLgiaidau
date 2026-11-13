import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-MATCHTITLE-01..03: "A VS B" title of a match; a side without a team or
/// player reads "Chưa xác định" instead of leaving only a bare "VS".
MatchModel _match({String team1 = '', String team2 = ''}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: 'm1',
  round: 1,
  matchNumber: 1,
  team1Id: 't1',
  team2Id: 't2',
  team1Name: team1,
  team2Name: team2,
  status: 'SCHEDULED',
  bracketPosition: BracketPosition(round: 1, position: 1),
);

String _title(MatchModel match) =>
    matchSidesTitle(match, separator: 'VS', undetermined: 'Chưa xác định');

void main() {
  test('TC-MATCHTITLE-01 both sides known: names around the separator', () {
    expect(_title(_match(team1: 'Alpha', team2: 'Beta')), 'Alpha VS Beta');
  });

  test('TC-MATCHTITLE-02 no side known: never a bare VS', () {
    expect(_title(_match()), 'Chưa xác định VS Chưa xác định');
  });

  test('TC-MATCHTITLE-03 only one side known: the other reads undetermined', () {
    expect(_title(_match(team1: 'Alpha')), 'Alpha VS Chưa xác định');
    expect(_title(_match(team2: 'Beta')), 'Chưa xác định VS Beta');
  });
}
