import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Provider cho SportConfig mặc định theo môn
final sportDefaultsProvider = Provider.family<SportConfig, SportRuleKind>((ref, kind) {
  return _getDefaultForKind(kind);
});

/// Provider resolve SportConfig từ match
final matchSportConfigProvider = Provider.family<SportConfig, MatchModel>((ref, match) {
  final sportRules = match.sportRules;
  if (sportRules != null && sportRules.isNotEmpty) {
    final kindStr = sportRules['kind']?.toString();
    final kind = SportRuleKind.fromString(kindStr);
    return resolveSportConfig(sportRules, kind);
  }
  // Fallback: dựa vào maxScore để đoán môn
  if (match.maxScore != null) {
    if (match.maxScore! >= 21) return _getDefaultForKind(SportRuleKind.badminton);
    if (match.maxScore! >= 11) return _getDefaultForKind(SportRuleKind.pickleball);
  }
  return _getDefaultForKind(SportRuleKind.badminton);
});

SportConfig _getDefaultForKind(SportRuleKind kind) {
  return resolveSportConfig(null, kind);
}
