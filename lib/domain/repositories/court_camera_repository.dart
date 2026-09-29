import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';

/// Organizer-side camera routing for a tournament's courts.
///
/// Kept apart from `ILiveSessionRepository` on purpose: that contract models
/// the community hardware fleet (device pairing, publish credentials, live
/// sessions) and stays untouched. Everything declared here is public playback
/// routing — no stream key, RTSP credential or publish URL crosses it.
abstract class ICourtCameraRepository {
  /// Court cameras of a tournament. A court that has no camera is simply
  /// absent from the list.
  Future<List<TournamentCameraModel>> listCameras(String tournamentId);

  /// Upserts the PULL camera of [courtId] and returns its camera id.
  ///
  /// An empty [playbackUrl] archives the camera, which is why the returned id
  /// is nullable: after archiving the court has none.
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  });

  /// Pins [cameraId] to a match, overriding the camera the court would
  /// otherwise hand that match when its court changes.
  Future<void> assignCamera({required String matchId, required String cameraId});
}
