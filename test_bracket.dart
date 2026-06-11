import 'package:app_quanly_giaidau/core/utils/bracket_generator.dart';
import 'package:app_quanly_giaidau/data/models/team.dart';

void main() {
  final teams = List.generate(10, (i) => Team(
    id: 't${i+1}',
    name: 'Team ${i+1}',
    qrCode: '',
    members: [],
    group: '',
    photoUrl: '',
    createdAt: DateTime.now(),
  ));

  final gen = DoubleEliminationGenerator();
  final matches = gen.generate('tour1', teams);

  print('=== WINNERS BRACKET ===');
  for (var m in matches.where((m) => m.bracketPosition.bracket == 'winners')) {
    print('W_R${m.round}_M${m.matchNumber}: ${m.team1Name} vs ${m.team2Name} | Status: ${m.status} | Winner: ${m.winnerId} | LoserNext: ${m.loserNextMatchId}');
  }

  print('\n=== LOSERS BRACKET ===');
  for (var m in matches.where((m) => m.bracketPosition.bracket == 'losers')) {
    print('L_R${m.round}_M${m.matchNumber}: ${m.team1Name} vs ${m.team2Name} | Status: ${m.status} | Winner: ${m.winnerId}');
  }
}
