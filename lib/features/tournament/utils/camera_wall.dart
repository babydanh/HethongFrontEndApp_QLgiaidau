import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Các lưới của tường camera (n×n), giống `wallLayouts` của Web.
const List<int> cameraWallLayouts = [1, 2, 3, 4];

/// Trận một ô đang hiện. `kind`: `live` | `ongoing` | `next`. Không có tỉ số.
/// `team1`/`team2` có thể rỗng (chưa xác định): lớp hiển thị tự điền chữ.
class CameraWallMatchLabel {
  const CameraWallMatchLabel({
    required this.kind,
    required this.code,
    required this.team1,
    required this.team2,
  });

  final String kind;
  final String code;
  final String team1;
  final String team2;
}

/// Một trang của tường: `layout × layout` camera. `page` tính từ 1 và được
/// kẹp vào khoảng hợp lệ; `pageCount >= 1`.
({List<TournamentCameraModel> items, int pageCount, int page}) cameraWallPage(
  List<TournamentCameraModel> cameras,
  int layout,
  int page,
) {
  final size = layout * layout;
  final pageCount = math.max(1, (cameras.length / size).ceil());
  final current = page.clamp(1, pageCount);
  final start = (current - 1) * size;
  final items = cameras.skip(start).take(size).toList(growable: false);
  return (items: items, pageCount: pageCount, page: current);
}

/// Chỉ camera `LIVE` có `playbackUrl` và xem thử đang bật mới mở trình phát.
bool shouldMountCameraPlayer(TournamentCameraModel camera, bool previewOn) =>
    previewOn && camera.status == 'LIVE' && camera.hasPlaybackUrl;

/// Trang (từ 1) chứa [cameraId]; không thấy thì trang 1.
int cameraWallPageOf(
  List<TournamentCameraModel> cameras,
  String cameraId,
  int layout,
) {
  final index = cameras.indexWhere((camera) => camera.id == cameraId);
  return index < 0 ? 1 : index ~/ (layout * layout) + 1;
}

int _scheduleOrder(MatchModel a, MatchModel b) {
  final timeA = a.scheduledTime;
  final timeB = b.scheduledTime;
  if (timeA != null && timeB != null) {
    final byTime = timeA.compareTo(timeB);
    if (byTime != 0) return byTime;
  } else if (timeA != null || timeB != null) {
    return timeA != null ? -1 : 1;
  }
  return a.matchNumber.compareTo(b.matchNumber);
}

CameraWallMatchLabel _describe(String kind, MatchModel match) {
  final code = match.matchCode?.trim() ?? '';
  return CameraWallMatchLabel(
    kind: kind,
    code: code.isEmpty ? '${match.matchNumber}' : code,
    team1: matchSideLabel(match, 1),
    team2: matchSideLabel(match, 2),
  );
}

/// Trận ô camera đang chiếu, theo thứ tự: trận đang phát qua chính camera,
/// trận ONGOING trên sân của camera, trận SCHEDULED sớm nhất trên sân đó.
CameraWallMatchLabel? cameraWallMatchLabel(
  TournamentCameraModel camera,
  Map<String, MatchLivestreamSummary> streams,
  List<MatchModel> matches,
) {
  final streaming = streams.values
      .where((item) => item.cameraId == camera.id && item.isLive)
      .firstOrNull;
  final live = streaming == null
      ? null
      : matches.where((match) => match.id == streaming.matchId).firstOrNull;
  if (live != null) return _describe('live', live);

  final courtId = camera.courtId;
  if (courtId == null || courtId.isEmpty) return null;
  final onCourt = matches
      .where((match) => match.courtId == courtId && !match.isByeMatch)
      .toList();

  MatchModel? earliest(bool Function(MatchModel) test) {
    final found = onCourt.where(test).toList()..sort(_scheduleOrder);
    return found.firstOrNull;
  }

  final ongoing = earliest((match) => match.isLive);
  if (ongoing != null) return _describe('ongoing', ongoing);
  final next = earliest((match) => match.isScheduled);
  return next == null ? null : _describe('next', next);
}
