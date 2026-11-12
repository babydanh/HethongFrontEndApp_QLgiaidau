import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';

const _knockoutStages = {'SINGLE_ELIMINATION', 'DOUBLE_ELIMINATION'};

/// Final match(es) of a knockout bracket, for the public "Kết quả" tab of a
/// finished division (port of the Web `pickFinalMatches`). The grand final
/// when there is one, else the last round of the winners/main bracket. Null
/// when there is no knockout final (round robin, swiss, empty): the caller
/// keeps the full list.
List<MatchModel>? pickFinalMatches(List<MatchModel> matches) {
  final real = matches.where((m) => !m.isBye).toList();

  final grandFinals = real
      .where((m) => branchOfMatch(m) == ResultsBranch.grandFinal)
      .toList();
  if (grandFinals.isNotEmpty) return grandFinals;

  final knockout = real
      .where(
        (m) =>
            _knockoutStages.contains((m.stageType ?? '').toUpperCase()) &&
            branchOfMatch(m) != ResultsBranch.losers,
      )
      .toList();
  if (knockout.isEmpty) return null;

  final lastRound = knockout
      .map((m) => m.round)
      .reduce((a, b) => a > b ? a : b);
  return knockout.where((m) => m.round == lastRound).toList();
}
