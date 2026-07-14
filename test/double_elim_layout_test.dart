import 'package:app_quanly_giaidau/core/utils/bracket_generator.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/bracket/layout/double_elim_layout.dart';
import 'package:flutter_test/flutter_test.dart';

List<Team> _teams(int count) {
  return List.generate(
    count,
    (index) => Team(
      id: 'team-${index + 1}',
      name: 'Đội ${index + 1}',
      seed: index + 1,
      createdAt: DateTime.utc(2026),
    ),
  );
}

Map<int, List<MatchModel>> _rounds(List<MatchModel> matches, String bracket) {
  final result = <int, List<MatchModel>>{};
  for (final match in matches.where(
    (match) =>
        match.bracketPosition.bracket == bracket && !match.isFullByeMatch,
  )) {
    result.putIfAbsent(match.round, () => []).add(match);
  }
  for (final round in result.values) {
    round.sort(
      (left, right) => left.bracketPosition.position.compareTo(
        right.bracketPosition.position,
      ),
    );
  }
  return result;
}

void main() {
  const calculator = DoubleElimLayoutCalculator();

  for (final participantCount in [13, 17]) {
    test('căn đúng double elimination cho $participantCount đội', () {
      final matches = DoubleEliminationGenerator().generate(
        'tournament-$participantCount',
        _teams(participantCount),
      );
      final winners = _rounds(matches, 'winners');
      final losers = _rounds(matches, 'losers');
      final finals =
          matches
              .where(
                (match) =>
                    match.bracketPosition.bracket == 'grand_final' ||
                    match.bracketPosition.bracket == 'grand_final_reset',
              )
              .toList()
            ..sort((left, right) => left.round.compareTo(right.round));

      final layout = calculator.calculate(
        winners: winners,
        losers: losers,
        finals: finals,
      );
      final columnWidth = layout.cardWidth + layout.columnGap;

      for (final round in layout.winnerRounds) {
        expect(layout.winnerColumnX(round), (round - 1) * 2 * columnWidth);
      }

      expect(
        layout.loserColumnX(layout.loserRounds.last),
        layout.winnerColumnX(layout.winnerRounds.last),
        reason: 'Hai trận chung kết nhánh phải cùng một cột',
      );

      _expectTargetsCentered(winners, layout);
      _expectTargetsCentered(losers, layout);

      final winnerFinal = winners[layout.winnerRounds.last]!.first;
      final loserFinal = losers[layout.loserRounds.last]!.first;
      final expectedGrandFinalCenter =
          (_center(layout, winnerFinal) + _center(layout, loserFinal)) / 2;
      expect(
        layout.grandFinalTop + layout.cardHeight / 2,
        closeTo(expectedGrandFinalCenter, 0.001),
      );
      expect(layout.positions[finals.first.id]!.dx, layout.grandFinalX);
      expect(
        layout.positions[finals.last.id]!.dx,
        layout.grandFinalX + columnWidth,
      );
    });
  }
}

void _expectTargetsCentered(
  Map<int, List<MatchModel>> rounds,
  DoubleElimLayout layout,
) {
  final sortedRounds = rounds.keys.toList()..sort();
  final allMatches = sortedRounds.expand((round) => rounds[round]!).toList();

  for (final round in sortedRounds.skip(1)) {
    for (final target in rounds[round]!) {
      final sources = allMatches
          .where((source) => source.nextMatchId == target.id)
          .toList();
      if (sources.isEmpty) continue;

      final expectedCenter =
          sources
              .map((source) => _center(layout, source))
              .reduce((sum, value) => sum + value) /
          sources.length;
      expect(
        _center(layout, target),
        closeTo(expectedCenter, 0.001),
        reason:
            '${target.bracketPosition.bracket} vòng $round phải ở tâm nguồn',
      );
    }
  }
}

double _center(DoubleElimLayout layout, MatchModel match) {
  return layout.positions[match.id]!.dy + layout.cardHeight / 2;
}
