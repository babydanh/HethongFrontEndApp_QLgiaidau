import 'package:app_quanly_giaidau/data/models/match_model.dart';

String normalizeStageText(String? value) {
  return (value ?? '').trim().toUpperCase();
}

/// True khi trận thuộc nhánh loại trực tiếp kiểu DOUBLE ELIMINATION.
/// Dùng để nhận diện knockout stage thực chất là double elimination
/// (trong group_stage_knockout hoặc khi bracketType tổng không phản ánh đúng),
/// giúp render đúng sơ đồ nhánh thắng / nhánh thua.
bool isDoubleEliminationMatch(MatchModel match) {
  final stageType = normalizeStageText(match.stageType);
  if (stageType == 'DOUBLE_ELIMINATION') return true;
  final branch = normalizeStageText(match.bracketPosition.bracket);
  return branch == 'LOSERS' ||
      branch == 'GRAND_FINAL' ||
      branch == 'GRAND_FINAL_RESET';
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
  if (stageName.contains('KNOCKOUT') ||
      stageName.contains('PLAYOFF') ||
      stageName.contains('ELIMINATION') ||
      stageName.contains('MAIN')) {
    return false;
  }
  if (groupName.isEmpty) return false;

  return !groupName.contains('KNOCKOUT') &&
      !groupName.contains('PLAYOFF') &&
      !groupName.contains('WINNERS') &&
      !groupName.contains('LOSERS') &&
      !groupName.contains('GRAND') &&
      !groupName.contains('MAIN') &&
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
  if (branch == 'PLAYOFF') return true;
  if (branch == 'WINNERS' ||
      branch == 'MAIN' ||
      branch == 'LOSERS' ||
      branch == 'GRAND_FINAL' ||
      branch == 'GRAND_FINAL_RESET') {
    return !isGroupStageMatch(match);
  }
  if (stageName.contains('KNOCKOUT') ||
      stageName.contains('PLAYOFF') ||
      stageName.contains('ELIMINATION') ||
      stageName.contains('MAIN')) {
    return true;
  }
  if (groupName.contains('KNOCKOUT') ||
      groupName.contains('PLAYOFF') ||
      groupName.contains('MAIN') ||
      groupName.contains('BRACKET')) {
    return true;
  }

  return !isGroupStageMatch(match);
}
