import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

void main() {
  test('Test API bracket parsing and duplicate removal', () async {
    final dio = Dio();
    final response = await dio.get('http://localhost:3000/api/v1/tournaments/1fe66fce-7121-4ab8-802b-7df8f445cd00/bracket');
    
    expect(response.statusCode, 200);
    
    final data = response.data['data'];
    expect(data, isNotNull);
    
    final stages = data['stages'] as List<dynamic>? ?? [];
    print('STAGES LENGTH: ${stages.length}');
    
    final allMatches = <MatchModel>[];
    if (stages.isNotEmpty) {
      final stage = stages.last;
      print('STAGE NAME: ${stage['name']}, STAGE TYPE: ${stage['type']}');
      final groups = stage['groups'] as List<dynamic>? ?? [];
      for (final group in groups) {
        final rawMatches = group['matches'] as List<dynamic>? ?? [];
        print('  GROUP NAME: ${group['name']}, MATCHES: ${rawMatches.length}');
        for (final json in rawMatches) {
          if (json is! Map<String, dynamic>) continue;
          
          final p1 = json['participant1'] as Map<String, dynamic>?;
          final p2 = json['participant2'] as Map<String, dynamic>?;
          final team1Name = p1?['teamName']?.toString() ?? '';
          final team2Name = p2?['teamName']?.toString() ?? '';
          
          final roundNumber = (json['roundNumber'] as int?) ?? 1;
          final matchOrder = (json['matchOrder'] as int?) ?? 1;
          
          final match = MatchModel(
            id: json['id']?.toString() ?? '',
            round: roundNumber,
            matchNumber: matchOrder,
            team1Id: p1?['id']?.toString() ?? '',
            team1Name: team1Name.isNotEmpty ? team1Name : 'TBD',
            team2Id: p2?['id']?.toString() ?? '',
            team2Name: team2Name.isNotEmpty ? team2Name : 'TBD',
            score1: (json['p1SetsWon'] as int?) ?? 0,
            score2: (json['p2SetsWon'] as int?) ?? 0,
            status: json['status']?.toString() ?? 'scheduled',
            bracketPosition: BracketPosition(
              bracket: json['bracketBranch']?.toString() ?? 'winners',
              round: roundNumber,
              position: matchOrder,
            ),
            nextMatchId: json['nextMatchId']?.toString() ?? '',
            winnerId: json['winnerId']?.toString() ?? '',
            isBye: json['isBye'] as bool? ?? false,
            court: json['courtName']?.toString() ?? '',
            updatedAt: DateTime.now(),
          );
          allMatches.add(match);
        }
      }
    }
    
    print('TOTAL PARSED MATCHES: ${allMatches.length}');
    for (var m in allMatches) {
      print('  Match: id=${m.id}, rnd=${m.round}, ord=${m.matchNumber}, p1=${m.team1Name}, p2=${m.team2Name}, isBye=${m.isBye}');
    }
    
    expect(allMatches.length, 15);
  });
}
