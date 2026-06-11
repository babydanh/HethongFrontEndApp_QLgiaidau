import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/strategy/penalty_strategy.dart';

class PenaltyService {
  /// Xử lý logic phạt, trả về số điểm thay đổi cho ĐỘI ĐỐI PHƯƠNG
  static int calculateOpponentPoints(String sportType, String penaltyId) {
    if (sportType == AppConstants.sportBadminton) {
      if (penaltyId == 'red_card') {
        return 1;
      }
    } else if (sportType == AppConstants.sportTennis || sportType == AppConstants.sportTableTennis) {
      if (penaltyId == 'point_penalty') {
        return 1;
      }
      // Lưu ý: game_penalty hoặc match_penalty thường xử lý huỷ trận đấu hoặc xử thua trực tiếp
      // nhưng ở mức điểm số tạm cộng 1 điểm (nếu hệ thống tính theo raw point).
    } else if (sportType == AppConstants.sportPickleball) {
      if (penaltyId == 'tech_foul') {
        return 1;
      }
    } else {
      // Default (nếu penaltyId là 'foul' cho các môn khác)
      if (penaltyId == 'foul') {
        return 1;
      }
    }
    return 0;
  }
}
