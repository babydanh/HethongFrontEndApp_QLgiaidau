import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/live_session_repository.dart';
import 'package:dio/dio.dart';

class ApiLiveSessionRepository implements ILiveSessionRepository {
  ApiLiveSessionRepository(this._dioClient);

  final DioClient _dioClient;

  Object? _unwrap(Object? value) {
    if (value is Map && value['data'] != null) return value['data'];
    return value;
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    return <String, Object?>{};
  }

  Future<void> _ensureSuccess(Response<Object?> response) async {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw DioException.badResponse(
        statusCode: status,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
  }

  @override
  Future<List<CameraDeviceModel>> listDevices(String communityId) async {
    final response = await _dioClient.dio.get<Object?>(
      '/livestream/devices',
      queryParameters: <String, Object?>{'communityId': communityId},
    );
    await _ensureSuccess(response);
    final payload = _unwrap(response.data);
    if (payload is! List) return <CameraDeviceModel>[];
    return payload
        .whereType<Map>()
        .map(
          (item) => CameraDeviceModel.fromJson(Map<String, Object?>.from(item)),
        )
        .toList(growable: false);
  }

  @override
  Future<CameraDeviceModel> pairDevice({
    required String deviceId,
    required String pairingToken,
    required String deviceFingerprint,
  }) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/devices/pair',
      data: <String, Object?>{
        'deviceId': deviceId,
        'pairingToken': pairingToken,
        'deviceFingerprint': deviceFingerprint,
      },
    );
    await _ensureSuccess(response);
    return CameraDeviceModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<CameraDeviceModel> heartbeat({
    required String deviceId,
    required String deviceFingerprint,
  }) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/devices/$deviceId/heartbeat',
      data: <String, Object?>{'deviceFingerprint': deviceFingerprint},
    );
    await _ensureSuccess(response);
    return CameraDeviceModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<LiveSessionOperatorResultModel> prepareSession({
    required String tournamentId,
    required String courtId,
    required String matchId,
    required String cameraDeviceId,
    required String title,
    required String idempotencyKey,
    String? description,
  }) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/sessions/prepare',
      data: <String, Object?>{
        'tournamentId': tournamentId,
        'courtId': courtId,
        'matchId': matchId,
        'cameraDeviceId': cameraDeviceId,
        'title': title,
        'idempotencyKey': idempotencyKey,
        ...?description == null
            ? null
            : <String, Object?>{'description': description},
      },
    );
    await _ensureSuccess(response);
    return LiveSessionOperatorResultModel.fromJson(
      _asMap(_unwrap(response.data)),
    );
  }

  @override
  Future<LiveSessionModel> getSession(String sessionId) async {
    final response = await _dioClient.dio.get<Object?>(
      '/livestream/sessions/$sessionId',
    );
    await _ensureSuccess(response);
    return LiveSessionModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<LiveSessionOperatorResultModel> markPublisherStarted(
    String sessionId,
  ) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/sessions/$sessionId/started',
    );
    await _ensureSuccess(response);
    return LiveSessionOperatorResultModel.fromJson(
      _asMap(_unwrap(response.data)),
    );
  }

  @override
  Future<LiveSessionModel> sessionHeartbeat(String sessionId) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/sessions/$sessionId/heartbeat',
    );
    await _ensureSuccess(response);
    return LiveSessionModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<LiveSessionOperatorResultModel> reconnectSession(
    String sessionId,
  ) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/sessions/$sessionId/reconnect',
    );
    await _ensureSuccess(response);
    return LiveSessionOperatorResultModel.fromJson(
      _asMap(_unwrap(response.data)),
    );
  }

  @override
  Future<LiveSessionModel> stopSession(String sessionId) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/sessions/$sessionId/stop',
    );
    await _ensureSuccess(response);
    return LiveSessionModel.fromJson(_asMap(_unwrap(response.data)));
  }
}
