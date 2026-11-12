import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Một trang của tường camera: các camera hiện ra và vị trí trang.
class CameraWallPage {
  const CameraWallPage({
    required this.items,
    required this.page,
    required this.pageCount,
  });

  final List<TournamentCameraModel> items;

  /// Trang đã kẹp vào [1, pageCount].
  final int page;
  final int pageCount;
}

/// Lưới [layout]×[layout] ô mỗi trang; [page] (đếm từ 1) bị kẹp vào
/// [1, pageCount]. Không có camera vẫn là một trang rỗng.
CameraWallPage wallPage(
  List<TournamentCameraModel> cameras,
  int layout,
  int page,
) {
  final side = layout < 1 ? 1 : layout;
  final perPage = side * side;
  final pageCount = cameras.isEmpty
      ? 1
      : (cameras.length + perPage - 1) ~/ perPage;
  final clamped = page.clamp(1, pageCount);
  final start = (clamped - 1) * perPage;
  final end = start + perPage > cameras.length
      ? cameras.length
      : start + perPage;
  return CameraWallPage(
    items: List.unmodifiable(cameras.sublist(start, end)),
    page: clamped,
    pageCount: pageCount,
  );
}

/// Chỉ mở trình phát cho camera LIVE có URL xem và còn bật xem thử.
bool shouldMountPlayer(TournamentCameraModel camera, bool previewOn) =>
    previewOn && camera.status == 'LIVE' && camera.hasPlaybackUrl;

/// Trận hiện dưới ô camera, theo ưu tiên: trận đang phát qua camera > trận
/// ONGOING trên sân > trận SCHEDULED kế tiếp trên sân. Null khi không có.
MatchModel? cameraMatch({
  required TournamentCameraModel camera,
  required List<MatchModel> matches,
  required Map<String, MatchLivestreamSummary> livestreams,
}) {
  for (final match in matches) {
    final stream = livestreams[match.id];
    if (stream != null && stream.isLive && stream.cameraId == camera.id) {
      return match;
    }
  }
  final courtId = camera.courtId;
  if (courtId == null || courtId.isEmpty) return null;
  final onCourt = matches.where((match) => match.courtId == courtId);
  for (final match in onCourt) {
    if (match.isLive) return match;
  }
  final upcoming = onCourt.where((match) => match.isScheduled).toList()
    ..sort((a, b) {
      final left = a.scheduledTime;
      final right = b.scheduledTime;
      if (left == null || right == null) {
        return left == null ? (right == null ? 0 : 1) : -1;
      }
      return left.compareTo(right);
    });
  return upcoming.firstOrNull;
}

/// Nhãn của [cameraMatch]; [noMatchLabel] khi camera chưa có trận. Không có
/// tỉ số: dòng này chỉ cho BTC biết camera đang gắn với trận nào.
String cameraMatchLabel({
  required TournamentCameraModel camera,
  required List<MatchModel> matches,
  required Map<String, MatchLivestreamSummary> livestreams,
  required String Function(MatchModel match) labelOf,
  required String noMatchLabel,
}) {
  final match = cameraMatch(
    camera: camera,
    matches: matches,
    livestreams: livestreams,
  );
  return match == null ? noMatchLabel : labelOf(match);
}

/// Tóm tắt đầu tab: tổng camera, số LIVE và số đang lỗi (OFFLINE hoặc ERROR).
class CameraSummary {
  const CameraSummary({
    required this.total,
    required this.live,
    required this.failing,
  });

  final int total;
  final int live;
  final int failing;
}

CameraSummary cameraSummary(List<TournamentCameraModel> cameras) {
  var live = 0;
  var failing = 0;
  for (final camera in cameras) {
    switch (cameraSignal(camera)) {
      case CameraSignal.live:
      case CameraSignal.connecting:
        live++;
      case CameraSignal.failed:
        failing++;
      case CameraSignal.idle:
        break;
    }
  }
  return CameraSummary(total: cameras.length, live: live, failing: failing);
}

/// Huy hiệu tín hiệu của một ô: LIVE xanh, đang kết nối vàng (camera LIVE nhưng
/// chưa có URL xem), OFFLINE/ERROR đỏ, còn lại xám.
enum CameraSignal { live, connecting, failed, idle }

CameraSignal cameraSignal(TournamentCameraModel camera) =>
    switch (camera.status) {
      'LIVE' =>
        camera.hasPlaybackUrl ? CameraSignal.live : CameraSignal.connecting,
      'OFFLINE' || 'ERROR' => CameraSignal.failed,
      _ => CameraSignal.idle,
    };
