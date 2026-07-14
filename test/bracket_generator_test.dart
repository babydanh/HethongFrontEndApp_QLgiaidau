import 'dart:math';

import 'package:app_quanly_giaidau/core/utils/bracket_generator.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:flutter_test/flutter_test.dart';

List<Team> buildTeams(int count) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return List.generate(
    count,
    (index) => Team(
      id: 'team-${index + 1}',
      name: 'Đội ${index + 1}',
      seed: index + 1,
      createdAt: createdAt,
    ),
  );
}

void main() {
  group('DoubleEliminationGenerator topology', () {
    for (var participantCount = 4; participantCount <= 64; participantCount++) {
      test('tạo graph đầy đủ cho $participantCount đội', () {
        final matches = DoubleEliminationGenerator().generate(
          'tournament-$participantCount',
          buildTeams(participantCount),
        );
        final bracketSize = pow(
          2,
          (log(participantCount) / log(2)).ceil(),
        ).toInt();
        final matchIds = matches.map((match) => match.id).toSet();
        final winners = matches
            .where((match) => match.bracketPosition.bracket == 'winners')
            .toList();
        final losers = matches
            .where((match) => match.bracketPosition.bracket == 'losers')
            .toList();
        final grandFinal = matches.singleWhere(
          (match) => match.bracketPosition.bracket == 'grand_final',
        );
        final resetFinal = matches.singleWhere(
          (match) => match.bracketPosition.bracket == 'grand_final_reset',
        );

        expect(winners.length, bracketSize - 1);
        expect(losers.length, bracketSize - 2);
        expect(matches.length, 2 * bracketSize - 1);
        expect(grandFinal.nextMatchId, resetFinal.id);
        expect(resetFinal.nextMatchId, isEmpty);

        for (final match in matches) {
          if (match.nextMatchId.isNotEmpty) {
            expect(matchIds, contains(match.nextMatchId));
          }
          if (match.loserNextMatchId.isNotEmpty) {
            expect(matchIds, contains(match.loserNextMatchId));
          }
        }

        for (final target in losers) {
          final feederCount = matches
              .where(
                (source) =>
                    source.nextMatchId == target.id ||
                    source.loserNextMatchId == target.id,
              )
              .length;
          expect(
            feederCount,
            2,
            reason:
                'L${target.round}-M${target.matchNumber} phải có đúng 2 nguồn',
          );
        }

        final grandFinalFeeders = matches.where(
          (source) => source.nextMatchId == grandFinal.id,
        );
        expect(grandFinalFeeders.length, 2);
        expect(
          grandFinalFeeders
              .map((match) => match.bracketPosition.bracket)
              .toSet(),
          {'winners', 'losers'},
        );
      });
    }
  });
}
