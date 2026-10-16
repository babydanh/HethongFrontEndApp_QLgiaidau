import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Thời lượng một trận khi xếp lịch: `durationMinutes` đã lưu, thiếu thì
/// `minutesPerSet` × số set theo luật môn.
///
/// Dùng chung cho lưới (vẽ thẻ, kiểm tra ô trống) và cho màn vận hành (chặn
/// trùng lịch), để hai chỗ không lệch nhau.
int scheduledDurationMinutes(MatchModel match, {required int minutesPerSet}) {
  final saved = match.durationMinutes;
  if (saved != null && saved > 0) return saved;
  return minutesPerSet * scheduledSetCount(match);
}

/// Số set theo BO của trận; Lite/open hoặc thiếu luật tính 1 set.
int scheduledSetCount(MatchModel match) {
  final rules = match.sportRules;
  if (rules == null || rules.isEmpty) return 1;
  final config = resolveSportConfig(rules);
  return config.isOpenScoring ? 1 : config.bestOf;
}
