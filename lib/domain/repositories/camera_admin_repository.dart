import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';

/// Organizer-side camera administration of a tournament (create, archive,
/// move to another court).
///
/// Separate from `ICourtCameraRepository` on purpose: that contract promises
/// that no stream key, RTSP credential or publish URL crosses it. The create
/// route's response can carry such credentials, so the camera methods only
/// ever return the credential-free [TournamentCameraModel] and drop the rest
/// at the parsing boundary. The stream-key methods below are the one place a
/// credential is returned, as a [CameraStreamKeyModel] that never prints it.
abstract class ICameraAdminRepository {
  /// Creates a camera. [mode] is `PUSH` (the app only configures RTMP) or
  /// `PULL`; a PULL camera needs the https [playbackUrl] it is published on.
  /// [courtId] is optional: a camera without a court is simply unassigned.
  Future<TournamentCameraModel> createCamera({
    required String tournamentId,
    required String name,
    required String mode,
    String? courtId,
    String? playbackUrl,
  });

  /// Archives a camera. The backend refuses (409) while it is live; that
  /// refusal is rethrown untouched so the caller can show its message.
  Future<void> deleteCamera(String cameraId);

  /// Moves [cameraId] to [courtId]; a null [courtId] unassigns the court.
  Future<void> assignCameraCourt(String cameraId, String? courtId);

  /// Reads the stream-key state of a PUSH camera (fresh, never cached).
  Future<CameraStreamKeyModel> getStreamKey(String cameraId);

  /// Issues, or restores, the key of [cameraId].
  Future<CameraStreamKeyModel> createStreamKey(String cameraId);

  /// Renames the stream; the backend only allows it while no key exists.
  Future<CameraStreamKeyModel> renameStreamKey(String cameraId, String stream);

  /// Replaces the key; the publisher using the old key is cut off.
  Future<CameraStreamKeyModel> rotateStreamKey(String cameraId);
}
