import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

class MatchRoundLabel {
  const MatchRoundLabel._();

  static String knockoutRoundName(int round, int totalRounds) {
    final fromEnd = totalRounds - round;
    if (fromEnd <= 0) return 'Chung kết';
    if (fromEnd == 1) return 'Bán kết';
    if (fromEnd == 2) return 'Tứ kết';
    if (fromEnd >= 3 && fromEnd <= 6) return 'Vòng ${1 << (fromEnd + 1)}';
    return 'Vòng loại';
  }

  static String groupOrRoundRobinName(int round) => 'Vòng $round';

  static String doubleUpperHeader(int fromEnd) {
    if (fromEnd <= 0) return 'CK nhánh thắng';
    if (fromEnd == 1) return 'BK nhánh thắng';
    if (fromEnd == 2) return 'Tứ kết nhánh thắng';
    if (fromEnd >= 3 && fromEnd <= 6) {
      return 'Vòng ${1 << (fromEnd + 1)} nhánh thắng';
    }
    return 'Vòng loại nhánh thắng';
  }

  static String doubleLowerHeader(int fromEnd, int displayRound) {
    if (fromEnd <= 0) return 'CK nhánh thua';
    if (fromEnd == 1) return 'BK nhánh thua';
    return 'Lượt nhánh thua $displayRound';
  }

  static String forMatch({
    required MatchModel match,
    required String bracketType,
    int? totalRounds,
    bool includeBranch = true,
  }) {
    final branch = match.bracketPosition.bracket.toLowerCase();

    if (branch == 'grand_final' || branch == 'final') {
      return 'Chung kết tổng';
    }
    if (branch == 'grand_final_reset') {
      return 'Chung kết tổng (đấu lại)';
    }

    if (bracketType == AppConstants.bracketRoundRobin) {
      return groupOrRoundRobinName(match.round);
    }

    final resolvedTotalRounds = totalRounds ?? match.round;
    final base = knockoutRoundName(match.round, resolvedTotalRounds);

    if (bracketType == AppConstants.bracketDoubleElimination) {
      if (branch == 'losers') {
        return includeBranch ? 'Nhánh thua - Lượt ${match.round}' : 'Lượt ${match.round}';
      }
      return includeBranch ? 'Nhánh thắng - $base' : base;
    }

    if (bracketType == AppConstants.bracketGroupStageKnockout) {
      final isGroupStage = branch == 'group' || branch == 'groups' || branch == 'round_robin';
      if (isGroupStage) return groupOrRoundRobinName(match.round);
    }

    return base;
  }
}
