import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/facebook_page_connection_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/live_session_repository.dart';
import 'package:dio/dio.dart';

class ApiLiveSessionRepository implements ILiveSessionRepository {
  ApiLiveSessionRepository(this._dioClient);

  final DioClient _dioClient;

  Object? _unwrap(Object? value) {
    if (value is Map && value.containsKey('data')) return value['data'];
    return value;
  }

  FacebookPageConnectionModel? _asConnection(Object? value) {
    if (value is! Map) return null;
    return FacebookPageConnectionModel.fromJson(
      Map<String, Object?>.from(value),
    );
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
      options: Options(extra: <String, Object?>{'noCache': true}),
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
  Future<CameraDeviceModel> createDevice({
    required String communityId,
    required String name,
  }) async {
    // Only the display name is sent. Device credentials and the publish
    // capability are assigned server-side and never requested by the app.
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/devices',
      data: <String, Object?>{'communityId': communityId, 'name': name},
    );
    await _ensureSuccess(response);
    return CameraDeviceModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<DevicePairingTokenModel> createPairingToken(String deviceId) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/devices/$deviceId/pairing-token',
      data: const <String, Object?>{},
    );
    await _ensureSuccess(response);
    return DevicePairingTokenModel.fromJson(_asMap(_unwrap(response.data)));
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
      options: Options(extra: <String, Object?>{'noCache': true}),
    );
    await _ensureSuccess(response);
    return LiveSessionModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<List<LiveSessionModel>> listSessions(String tournamentId) async {
    final response = await _dioClient.dio.get<Object?>(
      '/livestream/tournaments/$tournamentId/sessions',
      options: Options(extra: <String, Object?>{'noCache': true}),
    );
    await _ensureSuccess(response);
    final payload = _unwrap(response.data);
    if (payload is! List) return <LiveSessionModel>[];
    return payload
        .whereType<Map>()
        .map(
          (item) => LiveSessionModel.fromJson(Map<String, Object?>.from(item)),
        )
        .toList(growable: false);
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

  @override
  Future<FacebookPageConnectionModel?> getFacebookConnection(
    String communityId,
  ) async {
    final response = await _dioClient.dio.get<Object?>(
      '/livestream/facebook/connection',
      queryParameters: <String, Object?>{'communityId': communityId},
      options: Options(extra: <String, Object?>{'noCache': true}),
    );
    await _ensureSuccess(response);
    return _asConnection(_unwrap(response.data));
  }

  @override
  Future<String> createFacebookOAuthUrl(String communityId) async {
    final response = await _dioClient.dio.get<Object?>(
      '/livestream/facebook/connect',
      queryParameters: <String, Object?>{'communityId': communityId},
      options: Options(extra: <String, Object?>{'noCache': true}),
    );
    await _ensureSuccess(response);
    final authorizationUrl =
        _asMap(_unwrap(response.data))['authorizationUrl']?.toString() ?? '';
    if (authorizationUrl.isEmpty) {
      throw StateError('Facebook OAuth start returned no authorizationUrl.');
    }
    return authorizationUrl;
  }

  @override
  Future<FacebookPageConnectionModel> validateFacebookConnection(
    String connectionId,
  ) async {
    final response = await _dioClient.dio.post<Object?>(
      '/livestream/facebook/validate',
      queryParameters: <String, Object?>{'connectionId': connectionId},
    );
    await _ensureSuccess(response);
    return FacebookPageConnectionModel.fromJson(_asMap(_unwrap(response.data)));
  }

  @override
  Future<FacebookPageConnectionModel?> disconnectFacebookConnection(
    String communityId,
  ) async {
    final response = await _dioClient.dio.delete<Object?>(
      '/livestream/facebook/connection',
      queryParameters: <String, Object?>{'communityId': communityId},
    );
    await _ensureSuccess(response);
    return _asConnection(_unwrap(response.data));
  }
}
