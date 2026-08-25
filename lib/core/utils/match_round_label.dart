import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'dart:ui';

import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class MatchRoundLabel {
  const MatchRoundLabel._();

  static String knockoutRoundName(
    int round,
    int totalRounds, {
    AppLocalizations? l10n,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final fromEnd = totalRounds - round;
    if (fromEnd <= 0) return strings.matchTableRoundFinal;
    if (fromEnd == 1) return strings.matchTableRoundSemifinal;
    if (fromEnd == 2) return strings.matchTableRoundQuarterfinal;
    if (fromEnd >= 3 && fromEnd <= 6) {
      return strings.matchTableRoundOf(1 << (fromEnd + 1));
    }
    return strings.matchTableRoundQualifying;
  }

  static String groupOrRoundRobinName(
    MatchModel match, {
    AppLocalizations? l10n,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final groupName = match.groupName?.trim();
    final title = groupName == null || groupName.isEmpty
        ? strings.bracketView_groupStage
        : groupName;
    return strings.crossTableLegTitle(title, match.leg ?? 1);
  }

  static String doubleUpperHeader(int fromEnd, {AppLocalizations? l10n}) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    if (fromEnd <= 0) return strings.matchRoundWinnersFinal;
    if (fromEnd == 1) return strings.matchRoundWinnersSemifinal;
    if (fromEnd == 2) return strings.matchRoundWinnersQuarterfinal;
    if (fromEnd >= 3 && fromEnd <= 6) {
      return strings.matchRoundWinnersRoundOf(1 << (fromEnd + 1));
    }
    return strings.matchRoundWinnersQualifying;
  }

  static String doubleLowerHeader(
    int fromEnd,
    int displayRound, {
    AppLocalizations? l10n,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    if (fromEnd <= 0) return strings.matchRoundLosersFinal;
    if (fromEnd == 1) return strings.matchRoundLosersSemifinal;
    return strings.matchRoundLosersRound(displayRound);
  }

  static String forMatch({
    required MatchModel match,
    required String bracketType,
    int? totalRounds,
    bool includeBranch = true,
    AppLocalizations? l10n,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final branch = match.bracketPosition.bracket.toLowerCase();

    if (branch == 'grand_final' || branch == 'final') {
      return strings.matchRoundGrandFinal;
    }
    if (branch == 'grand_final_reset') {
      return strings.matchRoundGrandFinalReset;
    }

    if (bracketType == AppConstants.bracketRoundRobin) {
      return groupOrRoundRobinName(match, l10n: strings);
    }

    final resolvedTotalRounds = totalRounds ?? match.round;
    final base = knockoutRoundName(
      match.round,
      resolvedTotalRounds,
      l10n: strings,
    );

    if (bracketType == AppConstants.bracketDoubleElimination) {
      if (branch == 'losers') {
        return includeBranch
            ? strings.matchRoundLosersMatch(match.round)
            : strings.matchTableRound(match.round);
      }
      return includeBranch ? strings.matchRoundWinnersMatch(base) : base;
    }

    if (bracketType == AppConstants.bracketGroupStageKnockout) {
      final isGroupStage =
          branch == 'group' || branch == 'groups' || branch == 'round_robin';
      if (isGroupStage) {
        return groupOrRoundRobinName(match, l10n: strings);
      }
    }

    return base;
  }
}
