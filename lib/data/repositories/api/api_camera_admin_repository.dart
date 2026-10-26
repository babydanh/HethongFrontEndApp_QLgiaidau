import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:dio/dio.dart';

/// Camera administration over the same routes the web organizer uses.
///
/// Request and response bodies of these routes may hold stream credentials, so
/// nothing here logs or stringifies them: the create response is reduced to a
/// [TournamentCameraModel] and every other field is discarded; the stream-key
/// responses become a [CameraStreamKeyModel] that never prints its secrets.
class ApiCameraAdminRepository implements ICameraAdminRepository {
  ApiCameraAdminRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  @override
  Future<TournamentCameraModel> createCamera({
    required String tournamentId,
    required String name,
    required String mode,
    String? courtId,
    String? playbackUrl,
  }) async {
    final response = await _dio.post(
      '/livestream/tournaments/$tournamentId/cameras',
      data: <String, Object?>{
        'name': name,
        'mode': mode,
        // Ignored by the backend for PULL; the web sends it for both modes.
        'protocol': 'RTMP',
        'playbackUrl': ?playbackUrl,
        'courtId': ?courtId,
      },
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected an object in API response data.');
    }
    return TournamentCameraModel.fromJson(data);
  }

  @override
  Future<void> deleteCamera(String cameraId) async {
    await _dio.delete('/livestream/cameras/$cameraId');
  }

  @override
  Future<void> assignCameraCourt(String cameraId, String? courtId) async {
    await _dio.patch(
      '/livestream/cameras/$cameraId/court',
      data: <String, Object?>{'courtId': courtId},
    );
  }

  String _keyRoute(String cameraId) =>
      '/livestream/cameras/$cameraId/aqp-stream-key';

  @override
  Future<CameraStreamKeyModel> getStreamKey(String cameraId) async {
    // noCache: the response holds a secret and must be fresh after a rotate.
    final response = await _dio.get(
      _keyRoute(cameraId),
      options: Options(extra: <String, Object?>{'noCache': true}),
    );
    return _parseStreamKey(response);
  }

  @override
  Future<CameraStreamKeyModel> createStreamKey(String cameraId) async =>
      _parseStreamKey(
        await _dio.post(_keyRoute(cameraId), data: <String, Object?>{}),
      );

  @override
  Future<CameraStreamKeyModel> renameStreamKey(
    String cameraId,
    String stream,
  ) async => _parseStreamKey(
    await _dio.patch(
      _keyRoute(cameraId),
      data: <String, Object?>{'stream': stream},
    ),
  );

  @override
  Future<CameraStreamKeyModel> rotateStreamKey(String cameraId) async =>
      _parseStreamKey(
        await _dio.post(
          '${_keyRoute(cameraId)}/rotate',
          data: <String, Object?>{},
        ),
      );

  /// The message is fixed on purpose: the body holds credentials.
  CameraStreamKeyModel _parseStreamKey(Response<dynamic> response) {
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected an object in API response data.');
    }
    return CameraStreamKeyModel.fromJson(data);
  }
}
