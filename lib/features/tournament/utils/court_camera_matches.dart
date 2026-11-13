import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Giai đoạn của một trận trong popup sân: trận chưa xong (đang đấu, sắp tới)
/// nằm trên, trận đã xong nằm dưới.
enum CourtMatchPhase { live, upcoming, done }

CourtMatchPhase courtMatchPhase(MatchModel match) {
  if (match.isLive) return CourtMatchPhase.live;
  if (match.isCompleted) return CourtMatchPhase.done;
  return CourtMatchPhase.upcoming;
}

/// Trận thuộc [courtId] cho popup sân, đã xếp thứ tự hiển thị.
///
/// Đang đấu trước, rồi sắp tới theo giờ (không có giờ thì xuống cuối nhóm,
/// theo số trận), cuối cùng trận đã xong, trận muộn hơn nằm trên. Trận BYE và
/// trận đã huỷ không có gì để xem nên bị bỏ.
List<MatchModel> courtCameraMatches(List<MatchModel> matches, String courtId) {
  final onCourt = matches
      .where(
        (match) =>
            match.courtId == courtId &&
            !match.isByeMatch &&
            !match.isFullByeMatch &&
            match.normalizedStatus != 'CANCELLED',
      )
      .toList();

  int byTime(MatchModel a, MatchModel b, {required bool newestFirst}) {
    final left = a.scheduledTime;
    final right = b.scheduledTime;
    if (left == null && right == null) return a.matchNumber - b.matchNumber;
    if (left == null) return 1;
    if (right == null) return -1;
    return newestFirst ? right.compareTo(left) : left.compareTo(right);
  }

  int compare(MatchModel a, MatchModel b) {
    final phaseA = courtMatchPhase(a);
    final phaseOrder = phaseA.index - courtMatchPhase(b).index;
    if (phaseOrder != 0) return phaseOrder;
    return byTime(a, b, newestFirst: phaseA == CourtMatchPhase.done);
  }

  return onCourt..sort(compare);
}
