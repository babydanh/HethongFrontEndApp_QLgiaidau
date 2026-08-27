import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

extension MatchStatusExtension on MatchModel {
  bool get isCompleted => status == AppConstants.matchCompleted;
  bool get isWalkover => status == AppConstants.matchWalkover;
  bool get isLive {
    final normalized = status.trim().toLowerCase();
    final isActiveStatus =
        normalized == AppConstants.matchLive ||
        normalized == 'ongoing' ||
        normalized == 'playing' ||
        normalized == 'in_progress';
    return isActiveStatus && !isCompleted && !isWalkover && !hasWinner();
  }

  bool get isScheduled => status == AppConstants.matchScheduled;
  bool get hasResult => isCompleted || isWalkover;

  bool hasWinner() => winnerId.isNotEmpty && winnerId != 'BYE';
}
