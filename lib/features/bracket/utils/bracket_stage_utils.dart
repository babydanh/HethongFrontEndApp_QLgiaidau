import 'package:app_quanly_giaidau/data/models/match_model.dart';

String normalizeStageText(String? value) {
  return (value ?? '').trim().toUpperCase();
}

bool isGroupStageMatch(MatchModel match) {
  final branch = normalizeStageText(match.bracketPosition.bracket);
  final stageType = normalizeStageText(match.stageType);
  final stageName = normalizeStageText(match.stageName);
  final groupName = normalizeStageText(match.groupName);

  if (stageType == 'ROUND_ROBIN' || stageType == 'GROUP_STAGE') return true;
  if (stageType == 'SINGLE_ELIMINATION' || stageType == 'DOUBLE_ELIMINATION') {
    return false;
  }

  if (branch == 'GROUP_STAGE' ||
      branch == 'GROUP' ||
      branch == 'GROUPS' ||
      branch == 'ROUND_ROBIN') {
    return true;
  }
  if (stageName.contains('GROUP') || stageName.contains('BẢNG')) return true;
  if (stageName.contains('KNOCKOUT') || stageName.contains('PLAYOFF')) {
    return false;
  }
  if (groupName.isEmpty) return false;

  return !groupName.contains('KNOCKOUT') &&
      !groupName.contains('PLAYOFF') &&
      !groupName.contains('WINNERS') &&
      !groupName.contains('LOSERS') &&
      !groupName.contains('GRAND') &&
      !groupName.contains('BRACKET');
}

bool isKnockoutMatch(MatchModel match) {
  final branch = normalizeStageText(match.bracketPosition.bracket);
  final stageType = normalizeStageText(match.stageType);
  final stageName = normalizeStageText(match.stageName);
  final groupName = normalizeStageText(match.groupName);

  if (stageType == 'SINGLE_ELIMINATION' || stageType == 'DOUBLE_ELIMINATION') {
    return true;
  }
  if (stageType == 'ROUND_ROBIN' || stageType == 'GROUP_STAGE') return false;
  if (branch == 'PLAYOFF') return false;
  if (branch == 'WINNERS' ||
      branch == 'MAIN' ||
      branch == 'GRAND_FINAL' ||
      branch == 'GRAND_FINAL_RESET') {
    return !isGroupStageMatch(match);
  }
  if (stageName.contains('KNOCKOUT') || stageName.contains('PLAYOFF')) {
    return true;
  }
  if (groupName.contains('KNOCKOUT') || groupName.contains('PLAYOFF')) {
    return true;
  }

  return !isGroupStageMatch(match);
}
