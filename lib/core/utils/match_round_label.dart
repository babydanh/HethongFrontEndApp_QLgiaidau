import 'dart:math' as math;
import 'dart:ui';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class MatchRoundLabel {
  const MatchRoundLabel._();

  static const Set<int> knockoutRoundSizes = {2, 4, 8, 16, 32, 64, 128};

  /// Tên vòng loại trực tiếp có [matches] trận: vi "Vòng 1/8", en "Round of 16".
  static String roundOfMatches(AppLocalizations l10n, int matches) =>
      l10n.matchTableRoundOf(matches, matches * 2);

  static String _normalize(String? text) =>
      (text ?? '').trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');

  static bool isGroupOrRoundRobin(MatchModel match, [String? bracketType]) {
    final stageType = _normalize(match.stageType);
    final stageName = _normalize(match.stageName);
    final groupName = _normalize(match.groupName);
    final branch = _normalize(match.bracketPosition.bracket);
    final format = _normalize(
      bracketType ?? match.tournamentConfig?['bracketType']?.toString(),
    );

    if (stageType == 'SWISS') return false;
    if (stageType == 'ROUND_ROBIN' ||
        stageType == 'GROUP_STAGE' ||
        format == 'ROUND_ROBIN') {
      return true;
    }
    if (stageType == 'SINGLE_ELIMINATION' ||
        stageType == 'DOUBLE_ELIMINATION') {
      return false;
    }
    if (branch == 'GROUP' ||
        branch == 'GROUPS' ||
        branch == 'GROUP_STAGE' ||
        branch == 'ROUND_ROBIN') {
      return true;
    }
    if (stageName.contains('GROUP') ||
        stageName.contains('VONG_BANG') ||
        stageName.contains('BẢNG')) {
      return true;
    }
    if (stageName.contains('KNOCKOUT') ||
        stageName.contains('PLAYOFF') ||
        stageName.contains('ELIMINATION') ||
        stageName.contains('MAIN')) {
      return false;
    }
    if (groupName.isNotEmpty &&
        !groupName.contains('KNOCKOUT') &&
        !groupName.contains('PLAYOFF') &&
        !groupName.contains('WINNERS') &&
        !groupName.contains('LOSERS') &&
        !groupName.contains('GRAND') &&
        !groupName.contains('MAIN') &&
        !groupName.contains('BRACKET')) {
      return true;
    }
    return false;
  }

  static String knockoutRoundName(
    int round,
    int totalRounds, {
    AppLocalizations? l10n,
    bool short = false,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final fromEnd = totalRounds - round;
    if (fromEnd <= 0) return strings.matchTableRoundFinal;
    if (fromEnd == 1) return strings.matchTableRoundSemifinal;
    if (fromEnd == 2) return strings.matchTableRoundQuarterfinal;
    if (fromEnd >= 3 && fromEnd <= 7) {
      // Vòng có 2^fromEnd trận = "Vòng 1/2^fromEnd" (16 VĐV → Vòng 1/8), như web.
      return roundOfMatches(strings, 1 << fromEnd);
    }
    return strings.matchTableRoundQualifying;
  }

  static String groupOrRoundRobinName(
    MatchModel match, {
    AppLocalizations? l10n,
    bool short = false,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final groupName = match.groupName?.trim();
    if (groupName != null && groupName.isNotEmpty) {
      final normGroup = _normalize(groupName);
      if (!normGroup.contains('DEFAULT') &&
          !normGroup.contains('CHUNG') &&
          !normGroup.contains('VONG_BANG') &&
          !normGroup.contains('MAIN') &&
          !normGroup.contains('BRACKET')) {
        // Như Web (`match-round-label.ts`): "Bảng B • Lượt 1"; thẻ hẹp "Bảng B".
        final display = groupDisplayName(groupName, l10n: strings);
        if (short) return display;
        return strings.matchRoundGroupLeg(display, match.leg ?? 1);
      }
    }
    final title = strings.bracketView_groupStage;
    if (short || match.leg == null || match.leg! <= 1) {
      return title;
    }
    return strings.crossTableLegTitle(title, match.leg ?? 1);
  }

  static final RegExp _groupLetter = RegExp(
    r'^(?:bảng|group)?\s*([a-z0-9]+)$',
    caseSensitive: false,
  );

  /// Tên bảng chỉ là ký hiệu ("B", "Bảng b", "Group B") thành "Bảng B"; tên
  /// khác giữ nguyên.
  static String groupDisplayName(String groupName, {AppLocalizations? l10n}) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final letter = _groupLetter.firstMatch(groupName.trim())?.group(1);
    if (letter == null) return groupName.trim();
    return strings.matchRoundGroupPrefix(letter.toUpperCase());
  }

  static String formatStageOrGroupName(String? raw, {AppLocalizations? l10n}) {
    if (raw == null || raw.trim().isEmpty) return '';
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);

    if (upper == 'MAIN BRACKET' ||
        upper == 'MAIN' ||
        upper == 'WINNERS BRACKET' ||
        upper == 'WINNERS') {
      return strings.bracketView_winners;
    }
    if (upper == 'LOSERS BRACKET' || upper == 'LOSERS') {
      return strings.bracketView_losers;
    }
    if (upper == 'ELIMINATION STAGE' ||
        upper == 'KNOCKOUT STAGE' ||
        upper == 'KNOCKOUT') {
      return strings.bracketView_knockoutStage;
    }
    if (upper == 'GROUP STAGE') {
      return strings.bracketView_groupStage;
    }
    return trimmed;
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

  /// Primary comprehensive round label formatter matching the Web format algorithm.
  static String formatRound({
    required MatchModel match,
    List<MatchModel>? allMatches,
    Tournament? tournament,
    int? bracketSize,
    bool short = false,
    bool includeBranch = true,
    AppLocalizations? l10n,
  }) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final bracketType =
        tournament?.bracketType ??
        tournament?.format ??
        match.tournamentConfig?['bracketType']?.toString() ??
        '';

    var branch = _normalize(match.bracketPosition.bracket);
    if (branch == 'MAIN') branch = 'WINNERS';

    // 1. Grand Finals (Double Elimination)
    if (branch == 'GRAND_FINALS' ||
        branch == 'GRAND_FINAL' ||
        branch == 'FINAL') {
      return short ? 'CK Tổng' : strings.matchRoundGrandFinal;
    }
    if (branch == 'GRAND_FINAL_RESET') {
      return short ? 'CK Tổng 2' : strings.matchRoundGrandFinalReset;
    }

    // 2. Swiss: plain "Round N", never knockout names.
    if (_normalize(match.stageType) == 'SWISS') {
      return strings.swissRoundLabel(match.round);
    }

    // 3. Group stage / Round robin
    if (isGroupOrRoundRobin(match, bracketType)) {
      return groupOrRoundRobinName(match, l10n: strings, short: short);
    }

    // 4. Knockout rounds resolution
    String baseLabel = '';

    // Step A: Resolution by counting matches of the same round in allMatches list
    if (allMatches != null && allMatches.isNotEmpty) {
      final sameRoundMatches = allMatches
          .where(
            (m) =>
                m.round == match.round &&
                _normalize(m.bracketPosition.bracket) == branch &&
                _normalize(m.stageName) == _normalize(match.stageName),
          )
          .toList();

      if (sameRoundMatches.isNotEmpty) {
        final slotCount = sameRoundMatches.length * 2;
        if (slotCount == 2) {
          baseLabel = strings.matchTableRoundFinal;
        } else if (slotCount == 4) {
          baseLabel = strings.matchTableRoundSemifinal;
        } else if (slotCount == 8) {
          baseLabel = strings.matchTableRoundQuarterfinal;
        } else if (knockoutRoundSizes.contains(slotCount)) {
          baseLabel = roundOfMatches(strings, sameRoundMatches.length);
        }
      }

      if (baseLabel.isEmpty) {
        final stageMatches = allMatches
            .where(
              (m) =>
                  _normalize(m.bracketPosition.bracket) == branch &&
                  _normalize(m.stageName) == _normalize(match.stageName),
            )
            .toList();
        final maxRound = stageMatches
            .map((m) => m.round)
            .fold(match.round, math.max);
        final fromEnd = maxRound - match.round;
        if (fromEnd <= 0) {
          baseLabel = strings.matchTableRoundFinal;
        } else if (fromEnd == 1) {
          baseLabel = strings.matchTableRoundSemifinal;
        } else if (fromEnd == 2) {
          baseLabel = strings.matchTableRoundQuarterfinal;
        } else if (fromEnd >= 3 && fromEnd <= 7) {
          baseLabel = roundOfMatches(strings, 1 << fromEnd);
        }
      }
    }

    // Step B: Resolution from bracketSize / maxTeams
    if (baseLabel.isEmpty) {
      final size =
          bracketSize ??
          tournament?.maxTeams ??
          (match.tournamentConfig?['bracketSize'] as num?)?.toInt();

      if (size != null && size >= 2) {
        final normalizedSize = 1 << ((math.log(size) / math.log(2)).ceil());
        final slots = normalizedSize ~/ (1 << math.max(0, match.round - 1));
        if (slots == 2) {
          baseLabel = strings.matchTableRoundFinal;
        } else if (slots == 4) {
          baseLabel = strings.matchTableRoundSemifinal;
        } else if (slots == 8) {
          baseLabel = strings.matchTableRoundQuarterfinal;
        } else if (knockoutRoundSizes.contains(slots)) {
          baseLabel = roundOfMatches(strings, slots ~/ 2);
        }
      }
    }

    // Step C: Fallback from stageName text
    if (baseLabel.isEmpty) {
      final stageName = (match.stageName ?? '').toLowerCase();
      if (stageName.contains('chung kết') || stageName.contains('final')) {
        baseLabel = strings.matchTableRoundFinal;
      } else if (stageName.contains('bán kết') ||
          stageName.contains('semifinal')) {
        baseLabel = strings.matchTableRoundSemifinal;
      } else if (stageName.contains('tứ kết') ||
          stageName.contains('quarterfinal')) {
        baseLabel = strings.matchTableRoundQuarterfinal;
      } else if (stageName.contains('1/16') || stageName.contains('vòng 16')) {
        baseLabel = roundOfMatches(strings, 16);
      } else if (stageName.contains('1/32') || stageName.contains('vòng 32')) {
        baseLabel = roundOfMatches(strings, 32);
      } else if (stageName.contains('1/64') || stageName.contains('vòng 64')) {
        baseLabel = roundOfMatches(strings, 64);
      } else if (stageName.contains('1/128') ||
          stageName.contains('vòng 128')) {
        baseLabel = roundOfMatches(strings, 128);
      }
    }

    // Step D: Generic fallback
    if (baseLabel.isEmpty) {
      if (match.round > 0) {
        baseLabel = strings.matchTableRound(match.round);
      } else if (match.matchNumber > 0) {
        baseLabel = 'Trận ${match.matchNumber}';
      } else {
        baseLabel = strings.matchTableRoundQualifying;
      }
    }

    // Wrap branch
    if (includeBranch && branch == 'LOSERS') {
      return short ? '$baseLabel (NT)' : 'Nhánh thua • $baseLabel';
    }

    return baseLabel;
  }

  static String forMatch({
    required MatchModel match,
    required String bracketType,
    int? totalRounds,
    bool includeBranch = true,
    AppLocalizations? l10n,
  }) {
    return formatRound(
      match: match,
      bracketSize: totalRounds != null ? (1 << totalRounds) : null,
      includeBranch: includeBranch,
      l10n: l10n,
    );
  }
}
