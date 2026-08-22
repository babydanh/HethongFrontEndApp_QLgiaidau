import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';

abstract class ILiveSessionRepository {
  Future<List<CameraDeviceModel>> listDevices(String communityId);

  Future<CameraDeviceModel> pairDevice({
    required String deviceId,
    required String pairingToken,
    required String deviceFingerprint,
  });

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

  Future<LiveSessionOperatorResultModel> markPublisherStarted(String sessionId);

  Future<LiveSessionModel> sessionHeartbeat(String sessionId);

  Future<LiveSessionOperatorResultModel> reconnectSession(String sessionId);

  Future<LiveSessionModel> stopSession(String sessionId);
}
