import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/facebook_page_connection_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';

/// Live-session and camera-fleet endpoints the mobile app is allowed to touch.
///
/// Everything that would hand the client a publish capability (camera
/// `streamKey`, RTSP credentials, publish URLs) is deliberately absent: those
/// routes are still blocked by the backend security review and must not be
/// called from the app.
abstract class ILiveSessionRepository {
  /// Community-scoped reusable camera fleet. The server stays authoritative on
  /// membership: a non-manager gets 401/403 rather than an empty list.
  Future<List<CameraDeviceModel>> listDevices(String communityId);

  /// Registers a new reusable camera device for the community.
  ///
  /// Only the display name travels; the backend assigns the id and every
  /// publish credential. The response is the same public projection
  /// [listDevices] returns, so no secret can reach the app here.
  Future<CameraDeviceModel> createDevice({
    required String communityId,
    required String name,
  });

  Future<CameraDeviceModel> pairDevice({
    required String deviceId,
    required String pairingToken,
    required String deviceFingerprint,
  });

  /// Single-use pairing token for the QR that `DevicePairingScreen` scans.
  /// The token stays in memory for the lifetime of the QR sheet only.
  Future<DevicePairingTokenModel> createPairingToken(String deviceId);

  Future<CameraDeviceModel> heartbeat({
    required String deviceId,
    required String deviceFingerprint,
  });

  Future<LiveSessionOperatorResultModel> prepareSession({
    required String tournamentId,
    required String courtId,
    required String matchId,
    required String cameraDeviceId,
    required String title,
    required String idempotencyKey,
    String? description,
  });

  Future<LiveSessionModel> getSession(String sessionId);

  /// Monitoring rows for a tournament. Read-only: no publish capability and no
  /// stream secret is part of the response.
  Future<List<LiveSessionModel>> listSessions(String tournamentId);

  Future<LiveSessionOperatorResultModel> markPublisherStarted(String sessionId);

  Future<LiveSessionModel> sessionHeartbeat(String sessionId);

  /// Re-polls the provider for a session that is already reconnecting. It does
  /// not restart or republish anything.
  Future<LiveSessionOperatorResultModel> reconnectSession(String sessionId);

  Future<LiveSessionModel> stopSession(String sessionId);

  /// `null` when the community has never connected a Page, and a payload with
  /// `status: DISCONNECTED` after an explicit disconnect.
  Future<FacebookPageConnectionModel?> getFacebookConnection(
    String communityId,
  );

  /// Fresh Facebook OAuth URL for the organizer to complete in a browser.
  /// The URL is never persisted, logged or shared.
  Future<String> createFacebookOAuthUrl(String communityId);

  Future<FacebookPageConnectionModel> validateFacebookConnection(
    String connectionId,
  );

  Future<FacebookPageConnectionModel?> disconnectFacebookConnection(
    String communityId,
  );
}
