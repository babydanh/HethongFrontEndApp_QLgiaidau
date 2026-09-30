import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:dio/dio.dart';

/// Camera routing for a tournament's courts.
///
/// Mirrors the envelope handling of the sibling repositories: every route is
/// unwrapped from the `{ "data": ... }` envelope before decoding.
class ApiCourtCameraRepository implements ICourtCameraRepository {
  ApiCourtCameraRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  /// Returns the envelope payload. `null` is a legitimate payload here: the
  /// playback-url upsert answers with a null `cameraId` when it archived the
  /// court camera.
  Object? _data(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    throw const FormatException('Expected API response data envelope.');
  }

  Map<String, dynamic> _map(Response<dynamic> response) {
    final value = _data(response);
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected an object in API response data.');
  }

  List<Map<String, dynamic>> _mapList(Response<dynamic> response) {
    final value = _data(response);
    if (value is List<dynamic>) {
      return value
          .map((row) {
            if (row is Map<String, dynamic>) return row;
            throw const FormatException('Expected object rows in API response.');
          })
          .toList(growable: false);
    }
    throw const FormatException('Expected a list in API response data.');
  }

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      _mapList(await _dio.get('/livestream/tournaments/$tournamentId/cameras'))
          .map((row) => TournamentCameraModel.fromJson(row))
          .toList(growable: false);

  @override
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  }) async {
    final payload = _map(
      await _dio.put(
        '/livestream/tournaments/$tournamentId/courts/$courtId/playback-url',
        data: {'playbackUrl': playbackUrl},
      ),
    );
    final cameraId = payload['cameraId']?.toString();
    return cameraId == null || cameraId.isEmpty ? null : cameraId;
  }

  @override
  Future<void> assignCamera({
    required String matchId,
    required String cameraId,
  }) async {
    await _dio.post(
      '/livestream/matches/$matchId/assign-camera',
      data: {'cameraId': cameraId},
    );
  }
}
